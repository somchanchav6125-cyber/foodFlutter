// lib/controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  var userName = ''.obs;
  var userEmail = ''.obs;
  var isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkAuthState();
  }

  void _checkAuthState() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        isLoggedIn.value = true;
        userEmail.value = user.email ?? '';
        _loadUserName(user.uid);
      } else {
        isLoggedIn.value = false;
        userName.value = '';
        userEmail.value = '';
      }
    });
  }

  Future<void> _loadUserName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        userName.value = doc.data()?['name'] ?? _auth.currentUser?.displayName ?? '';
      } else {
        userName.value = _auth.currentUser?.displayName ?? 
                        _auth.currentUser?.email?.split('@').first ?? 
                        'User';
      }
    } catch (e) {
      print('Error loading user name: $e');
      userName.value = _auth.currentUser?.displayName ?? 'User';
    }
  }

  String get welcomeName {
    return userName.isNotEmpty ? userName.value : 'User';
  }
}