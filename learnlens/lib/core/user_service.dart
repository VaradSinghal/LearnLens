import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle user document operations in Firestore
class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'users';

  /// Create or update user document in Firestore
  /// This should be called after successful signup or login
  static Future<void> createOrUpdateUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection(_collectionName).doc(user.uid);
      
      final snapshot = await userDoc.get();
      
      final Map<String, dynamic> data = {
        'email': user.email ?? '',
        'display_name': user.displayName ?? '',
        'photo_url': user.photoURL ?? '',
        'updated_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        data['created_at'] = FieldValue.serverTimestamp();
      }
      
      await userDoc.set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user document: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Ensure user document exists (called on login)
  static Future<void> ensureUserDocumentExists(User user) async {
    try {
      final userDoc = _firestore.collection(_collectionName).doc(user.uid);
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        // Create user document if it doesn't exist
        await createOrUpdateUserDocument(user);
      } else {
        // Just update last_login
        await userDoc.update({
          'last_login': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error ensuring user document exists: $e');
      throw Exception('Failed to verify user profile: $e');
    }
  }

  /// Get user document from Firestore
  static Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final docSnapshot = await _firestore.collection(_collectionName).doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('Error getting user document: $e');
      return null;
    }
  }
}
