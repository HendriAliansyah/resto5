// lib/services/fcm_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/providers/auth_providers.dart';
import 'package:resto2/providers/notification_provider.dart';

class FcmService {
  final Ref _ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  FcmService(this._ref) {
    _init();
  }

  Future<void> _init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // **THE FIX IS HERE:**
    // We now proactively get the token every time this service is initialized.
    // This ensures that on every app start, we save the latest valid token.
    await updateToken();

    // Listen for any future token refreshes while the app is running
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
        _ref.read(localNotificationServiceProvider).showNotification(message);
      }
    });
  }

  /// Gets the current FCM token and saves it to Firestore.
  Future<void> updateToken() async {
    final token = await _fcm.getToken();
    debugPrint("FCM Token updated: $token");
    _saveTokenToFirestore(token);
  }

  /// Saves the FCM token to the user's document in Firestore.
  void _saveTokenToFirestore(String? token) {
    if (token == null) return;
    final user = _ref.read(currentUserProvider).asData?.value;
    if (user != null) {
      // To be more efficient, only write to Firestore if the token has changed.
      if (user.fcmToken != token) {
        _ref
            .read(firestoreServiceProvider)
            .updateUserFcmToken(uid: user.uid, token: token);
      }
    }
  }

  /// Invalidates the FCM token on the device.
  Future<void> deleteToken() async {
    // Only invalidate the token on the device. The backend will handle
    // cleaning up the token in Firestore to avoid permission errors.
    await _fcm.deleteToken();
    debugPrint(
      "FCM device token deleted. Firestore token will be cleared by the backend.",
    );
  }
}
