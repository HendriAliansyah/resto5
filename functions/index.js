// functions/index.js

const { onDocumentUpdated, onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onValueWritten } = require("firebase-functions/v2/database");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

initializeApp();

// This function should ONLY handle session token cleanup.
exports.onUserPresenceChange = onValueWritten("status/{uid}", async (event) => {
  const firestore = getFirestore();
  const uid = event.params.uid;
  const status = event.data.after.val();

  // If the user has gone offline (which includes signing out)
  if (status && status.state === "offline") {
    // Get the session token of the device that just went offline.
    const offlineToken = event.data.before.val()?.sessionToken;
    if (!offlineToken) {
      console.log(`User ${uid} went offline but had no session token.`);
      return;
    }

    const userDocRef = firestore.collection("users").doc(uid);

    try {
      // Use a transaction to prevent race conditions.
      await firestore.runTransaction(async (transaction) => {
        const userDoc = await transaction.get(userDocRef);
        if (!userDoc.exists) {
          return;
        }

        const currentToken = userDoc.data().sessionToken;

        // **THE FIX IS HERE:**
        // We now ONLY clear the sessionToken. The fcmToken will persist
        // so the user can receive notifications when the app is in the background.
        if (currentToken === offlineToken) {
          transaction.update(userDocRef, {
            sessionToken: null,
            // fcmToken: null, // <-- THIS LINE HAS BEEN REMOVED
          });
          console.log(`Session token cleared for user: ${uid}`);
        } else {
          console.log(`Session token for user ${uid} has already been updated. No action taken.`);
        }
      });
    } catch (error) {
      console.error(`Failed to clear session token for user: ${uid}`, error);
    }
  }
});


exports.onUserStatusChange = onDocumentUpdated("users/{userId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const uid = event.params.userId;

  if (beforeData.isDisabled === afterData.isDisabled) {
    return null;
  }

  if (afterData.isDisabled === true) {
    try {
      await getAuth().revokeRefreshTokens(uid);
      await getAuth().updateUser(uid, { disabled: true });
    } catch (error) {
      console.error(`Error disabling user ${uid}`, error);
    }
  } else if (afterData.isDisabled === false) {
    console.log(`Enabling user in Firebase Auth: ${uid}`);
    try {
      await getAuth().updateUser(uid, { disabled: false });
    } catch (error) {
      console.error(`Error enabling user ${uid}`, error);
    }
  }

  return null;
});

/**
 * Helper function to create a notification body from the notification data.
 * @param {object} notificationData The data from the notification document.
 * @return {string} The notification body text.
 */
function getNotificationBody(notificationData) {
  const { type, wasApproved, itemName, userDisplayName } = notificationData;
  switch (type) {
    case "joinRequest":
      return "A new user has requested to join your restaurant.";
    case "joinRequestResponse":
      return wasApproved ?
        "Your request to join the restaurant has been approved!" :
        "Your request to join the restaurant has been rejected.";
    case "stockEdit":
      return `${itemName} stock was updated by ${userDisplayName}.`;
    default:
      return "You have a new notification.";
  }
}

// This function triggers when a new notification is created for a user.
exports.sendPushNotification = onDocumentCreated("users/{userId}/notifications/{notificationId}", async (event) => {
  const userId = event.params.userId;
  const notificationData = event.data.data();

  // Get the user's document to retrieve their FCM token
  const userDocRef = getFirestore().collection("users").doc(userId);
  const userDoc = await userDocRef.get();

  if (!userDoc.exists) {
    console.log(`User document not found for userId: ${userId}`);
    return;
  }

  const fcmToken = userDoc.data().fcmToken;

  if (!fcmToken) {
    console.log(`FCM token not found for user: ${userId}`);
    return;
  }

  // Construct the push notification payload
  const payload = {
    token: fcmToken,
    notification: {
      title: notificationData.title,
      body: getNotificationBody(notificationData),
    },
    data: {
      // You can send additional data here for the app to handle on tap
      type: notificationData.type || "generic",
    },
  };

  try {
    console.log(`Sending notification to user: ${userId}`);
    await getMessaging().send(payload);
    console.log("Successfully sent push notification.");
  } catch (error) {
    console.error("Error sending push notification:", error);
    // If the token is no longer registered, remove it from the user's document
    if (error.code === "messaging/registration-token-not-registered") {
      console.log(`Invalid token for user ${userId}. Deleting it from Firestore.`);
      await userDocRef.update({ fcmToken: null });
    }
  }
});


exports.requestToJoinRestaurant = onCall(async (request) => {
  const { restaurantId } = request.data;
  const user = request.auth;

  if (!user) {
    throw new HttpsError("unauthenticated", "The function must be called while authenticated.");
  }

  const db = getFirestore();
  const restaurantRef = db.collection("restaurants").doc(restaurantId);
  const restaurantDoc = await restaurantRef.get();

  if (!restaurantDoc.exists) {
    throw new HttpsError(
        "not-found",
        "No restaurant with this ID exists.",
        { reason: "RESTAURANT_NOT_FOUND" },
    );
  }

  const userProfile = (await db.collection("users").doc(user.uid).get()).data();
  const joinRequest = {
    userId: user.uid,
    userDisplayName: userProfile.displayName || "No Name",
    userEmail: user.token.email,
    status: "pending",
    createdAt: new Date(),
  };
  await restaurantRef.collection("joinRequests").doc(user.uid).set(joinRequest);

  const adminQuery = await db.collection("users")
      .where("restaurantId", "==", restaurantId)
      .where("role", "in", ["owner", "admin"])
      .get();

  if (adminQuery.empty) {
    console.log("No admins found for restaurant:", restaurantId);
    return { success: true };
  }

  const batch = db.batch();
  const notificationPayload = {
    title: "New Join Request",
    type: "joinRequest",
    createdAt: new Date(),
    isRead: false,
    body: `${userProfile.displayName} has requested to join your restaurant.`,
  };

  adminQuery.docs.forEach((adminDoc) => {
    const notificationRef = adminDoc.ref.collection("notifications").doc();
    batch.set(notificationRef, notificationPayload);
  });

  await batch.commit();

  return { success: true };
});
