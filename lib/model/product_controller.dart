import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class FavoriteController extends GetxController {
  var favoriteProducts = <String, bool>{}.obs;
  var favoriteProductsData = <String, Map<String, dynamic>>{}.obs;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _loadFavoritesFromFirestore();
  }

  // បង្កើត user document reference
  DocumentReference get _userDocRef {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(user.uid);
  }

  // ផ្ទុកទិន្នន័យ Favorite ពី Firestore
  Future<void> _loadFavoritesFromFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _userDocRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final favorites = data?['favorites'] as Map<String, dynamic>? ?? {};
        
        // សម្អាតទិន្នន័យចាស់
        favoriteProducts.clear();
        favoriteProductsData.clear();

        // ផ្ទុកទិន្នន័យថ្មី
        for (final entry in favorites.entries) {
          final productId = entry.key;
          final productData = entry.value as Map<String, dynamic>;
          
          favoriteProducts[productId] = true;
          favoriteProductsData[productId] = productData;
        }
        
        update();
        print('✅ Loaded ${favoriteProducts.length} favorites from Firestore');
      }
    } catch (e) {
      print('❌ Error loading favorites from Firestore: $e');
    }
  }

  // រក្សាទុកទិន្នន័យ Favorite ទៅ Firestore - FIXED VERSION
  Future<void> saveFavoritesToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ No user logged in, cannot save favorites');
        return;
      }

      // រៀបចំទិន្នន័យសម្រាប់រក្សាទុក
      final favoritesData = <String, Map<String, dynamic>>{};
      
      for (final entry in favoriteProducts.entries) {
        if (entry.value) { // មានតែដែលជា favorite ពិតប្រាកដ
          final productId = entry.key;
          final productData = favoriteProductsData[productId];
          if (productData != null) {
            // Ensure we're only storing essential data
            favoritesData[productId] = {
              'name': productData['name'] ?? 'Unknown Product',
              'price': productData['price'] ?? 0.0,
              'image': productData['image'] ?? '',
              'category': productData['category'] ?? 'General',
              'savedAt': FieldValue.serverTimestamp(),
            };
          }
        }
      }

      print('💾 Saving ${favoritesData.length} favorites to Firestore...');

      // រក្សាទុកទៅ Firestore - ប្រើ update() ជំនួសអោយ set() ដើម្បីជៀសវាង overwrite data ផ្សេង
      await _userDocRef.set({
        'favorites': favoritesData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Successfully saved ${favoritesData.length} favorites to Firestore');
      
    } catch (e) {
      print('❌ Error saving favorites to Firestore: $e');
      // Add more specific error handling
      if (e is FirebaseException) {
        print('Firebase Error Code: ${e.code}');
        print('Firebase Error Message: ${e.message}');
      }
    }
  }

  void toggleFavorite(String productId, Map<String, dynamic>? productData) {
    try {
      if (favoriteProducts.containsKey(productId)) {
        favoriteProducts[productId] = !favoriteProducts[productId]!;
        if (!favoriteProducts[productId]!) {
          favoriteProductsData.remove(productId);
        }
      } else {
        favoriteProducts[productId] = true;
        if (productData != null) {
          favoriteProductsData[productId] = productData;
        }
      }
      
      // រក្សាទុកទៅ Firestore បន្ទាប់ពីប្តូរ
      saveFavoritesToFirestore();
      update();
      
      print('❤️ Toggle favorite for $productId: ${favoriteProducts[productId]}');
    } catch (e) {
      print('❌ Error in toggleFavorite: $e');
    }
  }

  bool isFavorite(String productId) {
    return favoriteProducts[productId] ?? false;
  }

  Map<String, dynamic>? getFavoriteProduct(String productId) {
    return favoriteProductsData[productId];
  }

  // មុខងារសម្រាប់សម្អាតទិន្នន័យ Favorite
  Future<void> clearAllFavorites() async {
    try {
      favoriteProducts.clear();
      favoriteProductsData.clear();
      await saveFavoritesToFirestore();
      update();
      print('🗑️ All favorites cleared');
    } catch (e) {
      print('❌ Error clearing favorites: $e');
    }
  }

  // មុខងារសម្រាប់យកចំនួន Favorite
  int get favoriteCount {
    return favoriteProducts.values.where((isFav) => isFav).length;
  }

  // Debug method to print current favorites
  void debugPrintFavorites() {
    print('=== 🎯 CURRENT FAVORITES DEBUG ===');
    print('Total favorites: $favoriteCount');
    favoriteProducts.forEach((productId, isFavorite) {
      print('$productId: $isFavorite');
    });
    print('================================');
  }
}