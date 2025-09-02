// lib/services/restaurant_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto2/models/charge_tax_rule_model.dart';
import 'package:resto2/models/join_request_model.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionPath = 'restaurants';

  Future<String> createRestaurant({required RestaurantModel restaurant}) async {
    final docRef = _db.collection(_collectionPath).doc();

    final newRestaurantWithId = RestaurantModel(
      id: docRef.id,
      ownerId: restaurant.ownerId,
      name: restaurant.name,
      address: restaurant.address,
      phone: restaurant.phone,
      logoUrl: restaurant.logoUrl,
    );

    await docRef.set(newRestaurantWithId.toJson());
    return docRef.id;
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    await _db.collection(_collectionPath).doc(restaurantId).delete();
  }

  Stream<RestaurantModel?> getRestaurantStream(String restaurantId) {
    return _db.collection(_collectionPath).doc(restaurantId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return RestaurantModel.fromFirestore(snapshot);
      }
      return null;
    });
  }

  Future<void> saveRestaurantDetails(RestaurantModel restaurant) async {
    await _db
        .collection(_collectionPath)
        .doc(restaurant.id)
        .set(restaurant.toJson(), SetOptions(merge: true));
  }

  Future<void> updateLogoUrl(String restaurantId, String logoUrl) async {
    await _db.collection(_collectionPath).doc(restaurantId).update({
      'logoUrl': logoUrl,
    });
  }

  Future<void> submitJoinRequest({
    required String restaurantId,
    required JoinRequestModel request,
  }) async {
    final restaurantDoc = await _db
        .collection(_collectionPath)
        .doc(restaurantId)
        .get();
    if (!restaurantDoc.exists) {
      throw Exception(
        "A restaurant with this ID does not exist. Please check the ID and try again.",
      );
    }

    await _db
        .collection(_collectionPath)
        .doc(restaurantId)
        .collection('joinRequests')
        .doc(request.userId)
        .set(request.toJson());
  }

  // New methods for Charge & Tax Rules
  Stream<List<ChargeTaxRuleModel>> getChargeTaxRulesStream(
    String restaurantId,
  ) {
    return _db
        .collection(_collectionPath)
        .doc(restaurantId)
        .collection('chargeTaxRules')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChargeTaxRuleModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> saveChargeTaxRule(String restaurantId, ChargeTaxRuleModel rule) {
    return _db
        .collection(_collectionPath)
        .doc(restaurantId)
        .collection('chargeTaxRules')
        .doc(rule.id)
        .set(rule.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteChargeTaxRule(String restaurantId, String ruleId) {
    return _db
        .collection(_collectionPath)
        .doc(restaurantId)
        .collection('chargeTaxRules')
        .doc(ruleId)
        .delete();
  }
}
