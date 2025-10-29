import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:myhomework/controller/Cartproduct.dart';
import 'package:myhomework/controller/DetailsRice.dart'
    hide gatXPink, gatXOrange, gatXDarkPink, gatXGreen, gatXLightPink;
import 'package:myhomework/model/Admin_model.dart';
import 'package:myhomework/model/color.dart'
    hide gatXOrange, gatXPink, gatXDarkPink, gatXGreen, gatXLightPink;
import 'package:myhomework/model/product_controller.dart';
import 'package:myhomework/model/CartIem.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myhomework/view/fromHomepage/Admin.dart';
import 'package:myhomework/view/from_login/home2_fromlogin.dart';

class HomepageProduct extends StatefulWidget {
  final bool isAdmin;
  final String userEmail;
  final String userName;

  const HomepageProduct({
    super.key,
    required this.isAdmin,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<HomepageProduct> createState() => _HomepageProductState();
}

class _HomepageProductState extends State<HomepageProduct>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  final FavoriteController favoriteController = Get.put(FavoriteController());
  int cartItemCount = 0;
  List<CartItem> cartItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentIndex = 0;

  String _userName = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference _product1Collection = FirebaseFirestore.instance
      .collection('ហាងលក់ម្ហូបពេញនិយម');
  final CollectionReference _product2Collection = FirebaseFirestore.instance
      .collection('ចុះថ្លៃ 20%');
  final CollectionReference _product3Collection = FirebaseFirestore.instance
      .collection('បាយសាច់មាន់');
  final CollectionReference _product4Collection = FirebaseFirestore.instance
      .collection('ភេសជ្ជ:');
  final CollectionReference _product5Collection = FirebaseFirestore.instance
      .collection('ភីហ្សា');
  final CollectionReference _product6Collection = FirebaseFirestore.instance
      .collection('ជ្រើសរើសអារហារនីមួយៗ');

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isDarkMode = false;
  String _selectedLanguage = 'km';
  List<Map<String, dynamic>> _orderHistory = [];

  final String _adminEmail = 'chanchav@gmail.admin';
  bool _isAdmin = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _initializeAnimations();
    _loadUserName();
    _loadOrderHistoryFromStorage();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _bounceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _checkAdminStatus() {
    if (widget.isAdmin) {
      setState(() {
        _isAdmin = true;
      });
    } else {
      final User? user = _auth.currentUser;
      if (user != null && user.email == _adminEmail) {
        setState(() {
          _isAdmin = true;
        });
      }
      if (widget.userEmail == _adminEmail) {
        setState(() {
          _isAdmin = true;
        });
      }
    }
  }

  void _loadUserName() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _userName =
            user.displayName ??
            user.email?.split('@').first ??
            _getTranslatedText('អ្នក', 'You');
      });
    } else if (_isAdmin) {
      setState(() {
        _userName = 'Admin';
      });
    } else {
      setState(() {
        _userName = widget.userName;
      });
    }
  }

  // ========== ORDER HISTORY WITH LOCAL STORAGE ==========
  void _loadOrderHistoryFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? orderHistoryJson = prefs.getString('order_history');

      if (orderHistoryJson != null && orderHistoryJson.isNotEmpty) {
        final List<dynamic> orderList = json.decode(orderHistoryJson);
        setState(() {
          _orderHistory = orderList
              .map((item) => item as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      print('Error loading order history from storage: $e');
    }
  }

  void _saveOrderToStorage(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? existingHistory = prefs.getString('order_history');
      List<dynamic> orderList = [];

      if (existingHistory != null && existingHistory.isNotEmpty) {
        orderList = json.decode(existingHistory);
      }

      orderList.add({
        ...orderData,
        'id': 'order_${DateTime.now().millisecondsSinceEpoch}',
        'orderDate': DateTime.now().toIso8601String(),
      });

      await prefs.setString('order_history', json.encode(orderList));
      _loadOrderHistoryFromStorage();
    } catch (e) {
      print('Error saving order to storage: $e');
    }
  }

  void _clearOrderHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('order_history');

      setState(() {
        _orderHistory = [];
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _getTranslatedText(
              'បានសម្អាតប្រវត្តិការកុម្ម៉ង់',
              'Order history cleared',
            ),
            style: GoogleFonts.notoSansKhmer(),
          ),
          backgroundColor: gatXGreen,
        ),
      );
    } catch (e) {
      print('Error clearing order history: $e');
    }
  }

  // ========== FIXED DRAWER NAVIGATION METHODS ==========
  void _closeDrawerAndNavigate(int index) {
    // Close drawer first
    Navigator.of(context).pop();

    // Use a small delay to ensure drawer is fully closed
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _currentIndex = index;
        });
      }
    });
  }

  void _closeDrawerAndOpenAdmin() {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _navigateToAdminPanel();
      }
    });
  }

  void _closeDrawerAndAddProduct() {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showAddProductDialog();
      }
    });
  }

  void _closeDrawerAndShowHistory() {
    Navigator.of(context).pop();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _showOrderHistoryDialog();
      }
    });
  }

  // ========== FIXED BODY BUILD METHOD ==========
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeScreen();
      case 1:
        return _buildSearchScreen();
      case 2:
        return _buildFavoritesScreen();
      case 3:
        return _buildProfileScreen();
      default:
        return _buildHomeScreen();
    }
  }

  // ========== FIXED DRAWER MENU ITEM ==========
  Widget _buildEnhancedDrawerMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    int? tabIndex,
    bool isAdmin = false,
  }) {
    final bool isActive = tabIndex != null && _currentIndex == tabIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Close drawer and execute callback
            Navigator.of(context).pop();
            Future.delayed(const Duration(milliseconds: 100), onTap);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? (isAdmin
                        ? Colors.amber.withOpacity(0.2)
                        : gatXPink.withOpacity(0.2))
                  : (_isDarkMode ? Colors.grey[800] : Colors.white),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                if (isActive)
                  BoxShadow(
                    color: (isAdmin ? Colors.amber : gatXPink).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
              border: Border.all(
                color: isActive
                    ? (isAdmin ? Colors.amber : gatXPink).withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? (isAdmin
                              ? LinearGradient(
                                  colors: [Colors.amber, Colors.orange],
                                )
                              : LinearGradient(
                                  colors: [gatXPink, gatXDarkPink],
                                ))
                        : (isAdmin
                              ? LinearGradient(
                                  colors: [
                                    Colors.amber.withOpacity(0.6),
                                    Colors.orange.withOpacity(0.6),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    gatXPink.withOpacity(0.6),
                                    gatXDarkPink.withOpacity(0.6),
                                  ],
                                )),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      if (isActive)
                        BoxShadow(
                          color: (isAdmin ? Colors.amber : gatXPink)
                              .withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.notoSansKhmer(
                      color: _isDarkMode ? Colors.white : Colors.black,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: (isAdmin ? Colors.amber : gatXPink).withOpacity(
                        0.1,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.circle_rounded,
                      color: isAdmin ? Colors.amber : gatXPink,
                      size: 8,
                    ),
                  ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isActive
                      ? (isAdmin ? Colors.amber : gatXPink)
                      : (_isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========== REMAINING METHODS (SAME AS BEFORE) ==========
  void _showOrderHistoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: _isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[850]!,
                        Colors.grey[900]!,
                        Colors.grey[800]!,
                      ],
                      stops: [0.0, 0.6, 1.0],
                    )
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Color(0xFFFDF2F8),
                        Color(0xFFFCE8F3),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
              ],
              border: Border.all(
                color: _isDarkMode
                    ? Colors.grey[700]!.withOpacity(0.5)
                    : Colors.white.withOpacity(0.8),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Column(
                children: [
                  // Header with improved gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _isDarkMode
                            ? [
                                Color(0xFF4A5568),
                                Color(0xFF2D3748),
                                Color(0xFF1A202C),
                              ]
                            : [gatXPink, Color(0xFFEC407A), Color(0xFFE91E63)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isDarkMode ? Colors.black : gatXPink)
                              .withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _getTranslatedText(
                              '📦 ប្រវត្តិការកុម្ម៉ង់',
                              '📦 Order History',
                            ),
                            style: GoogleFonts.notoSansKhmer(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomepageProduct(
                                  isAdmin: false,
                                  userEmail: "",
                                  userName: "",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Enhanced Stats Card
                  if (_orderHistory.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isDarkMode
                              ? [Color(0xFF4A5568), Color(0xFF2D3748)]
                              : [Colors.white, Color(0xFFFDF2F8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                            spreadRadius: -4,
                          ),
                        ],
                        border: Border.all(
                          color: _isDarkMode
                              ? Colors.grey[700]!.withOpacity(0.3)
                              : Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.shopping_bag_outlined,
                            _orderHistory.length.toString(),
                            _getTranslatedText('ការកុម្ម៉ង់', 'Orders'),
                            _isDarkMode ? Color(0xFFE91E63) : gatXPink,
                          ),
                          _buildStatItem(
                            Icons.monetization_on_outlined,
                            '\$${_calculateTotalSpent().toStringAsFixed(2)}',
                            _getTranslatedText('សរុបចំណាយ', 'Total Spent'),
                            _isDarkMode ? Color(0xFF4CAF50) : Color(0xFF66BB6A),
                          ),
                          _buildStatItem(
                            Icons.star_rate_rounded,
                            _calculateAverageRating().toStringAsFixed(1),
                            _getTranslatedText('អត្រានិងមតិ', 'Rating'),
                            _isDarkMode ? Color(0xFFFF9800) : Color(0xFFFFB74D),
                          ),
                        ],
                      ),
                    ),

                  // Order List with improved styling
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _isDarkMode
                            ? Colors.grey[900]!.withOpacity(0.5)
                            : Colors.white.withOpacity(0.7),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _orderHistory.isEmpty
                            ? _buildEmptyOrderHistory()
                            : _buildOrderHistoryList(),
                      ),
                    ),
                  ),

                  // Enhanced Actions Section
                  if (_orderHistory.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: _isDarkMode
                            ? LinearGradient(
                                colors: [Colors.grey[900]!, Colors.grey[800]!],
                              )
                            : LinearGradient(
                                colors: [Colors.white, Color(0xFFFDF2F8)],
                              ),
                        border: Border(
                          top: BorderSide(
                            color: _isDarkMode
                                ? Colors.grey[700]!.withOpacity(0.5)
                                : Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    _isDarkMode
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: OutlinedButton.icon(
                                icon: Icon(Icons.delete_outline, size: 18),
                                label: Text(
                                  _getTranslatedText(
                                    'សម្អាតទាំងអស់',
                                    'Clear All',
                                  ),
                                  style: GoogleFonts.notoSansKhmer(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: Colors.red.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor: Colors.transparent,
                                ),
                                onPressed: _clearOrderHistory,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [gatXPink, Color(0xFFEC407A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: gatXPink.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  _getTranslatedText('ទិញទៀត', 'Shop More'),
                                  style: GoogleFonts.notoSansKhmer(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {
                                    _currentIndex = 0;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Updated _buildStatItem method to match new design
  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.notoSansKhmer(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: _isDarkMode ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.notoSansKhmer(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  double _calculateTotalSpent() {
    return _orderHistory.fold(0.0, (sum, order) {
      return sum + (order['totalPrice'] ?? 0.0);
    });
  }

  double _calculateAverageRating() {
    if (_orderHistory.isEmpty) return 0.0;
    final totalRating = _orderHistory.fold(0.0, (sum, order) {
      return sum + (order['rating'] ?? 5.0);
    });
    return totalRating / _orderHistory.length;
  }

  Widget _buildEmptyOrderHistory() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : gatXLightPink,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 50,
            color: _isDarkMode ? Colors.grey[400] : gatXPink,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _getTranslatedText(
            'មិនទាន់មានប្រវត្តិការកុម្ម៉ង់',
            'No order history yet',
          ),
          style: GoogleFonts.notoSansKhmer(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            _getTranslatedText(
              'ការកុម្ម៉ង់របស់អ្នកនឹងត្រូវបានរក្សាទុកនៅទីនេះ\nចាប់ផ្ដើមទិញឥវ៉ាន់ឥឡូវនេះ!',
              'Your orders will be saved here\nStart shopping now!',
            ),
            style: GoogleFonts.notoSansKhmer(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: Icon(Icons.shopping_cart),
          label: Text(
            _getTranslatedText('ចាប់ផ្ដើមទិញ', 'Start Shopping'),
            style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: gatXPink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              _currentIndex = 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildOrderHistoryList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_getTranslatedText('សរុបការកុម្ម៉ង់', 'Total Orders')}: ${_orderHistory.length}',
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.grey[300] : gatXPink,
              fontSize: 16,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _orderHistory.length,
            itemBuilder: (context, index) {
              final order = _orderHistory.reversed.toList()[index];
              return _buildOrderHistoryItem(order);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHistoryItem(Map<String, dynamic> order) {
    final orderDate = DateTime.parse(
      order['orderDate'] ?? DateTime.now().toIso8601String(),
    );
    final productName =
        order['productName'] ?? _getTranslatedText('ផលិតផល', 'Product');
    final quantity = order['quantity'] ?? 1;
    final totalPrice = order['totalPrice'] ?? 0.0;
    final status = order['status'] ?? 'completed';
    final rating = order['rating'] ?? 5.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Order Icon with Gradient
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: status == 'completed'
                    ? [gatXGreen, Color(0xFF4CAF50)]
                    : [gatXOrange, Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: (status == 'completed' ? gatXGreen : gatXOrange)
                      .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              status == 'completed' ? Icons.check_circle : Icons.pending,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        productName,
                        style: GoogleFonts.notoSansKhmer(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'completed'
                            ? gatXGreen.withOpacity(0.2)
                            : gatXOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status == 'completed' ? gatXGreen : gatXOrange,
                        ),
                      ),
                      child: Text(
                        _getTranslatedText(
                          status == 'completed' ? 'បានបញ្ចប់' : 'កំពុងដំណើរការ',
                          status == 'completed' ? 'Completed' : 'Processing',
                        ),
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 11,
                          color: status == 'completed' ? gatXGreen : gatXOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildOrderDetailChip(
                      '${_getTranslatedText('ចំនួន', 'Qty')}: $quantity',
                      Icons.shopping_cart,
                    ),
                    const SizedBox(width: 8),
                    _buildOrderDetailChip(
                      '${_getTranslatedText('តម្លៃ', 'Price')}: \$${totalPrice.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(orderDate),
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[700] : gatXLightPink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: gatXPink),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.notoSansKhmer(
              fontSize: 11,
              color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return _getTranslatedText('មុននាទីបន្តិច', 'Just now');
        }
        return '${difference.inMinutes} ${_getTranslatedText('នាទីមុន', 'minutes ago')}';
      }
      return '${difference.inHours} ${_getTranslatedText('ម៉ោងមុន', 'hours ago')}';
    } else if (difference.inDays == 1) {
      return _getTranslatedText('ម្សិលមិញ', 'Yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${_getTranslatedText('ថ្ងៃមុន', 'days ago')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      favoriteController.saveFavoritesToFirestore();
    }
    super.didChangeAppLifecycleState(state);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.5),
            weight: 50,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.5, end: 1.0),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _bounceAnimation =
        TweenSequence<double>([
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.2),
            weight: 33,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.2, end: 0.9),
            weight: 33,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(begin: 0.9, end: 1.0),
            weight: 34,
          ),
        ]).animate(
          CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
        );
  }

  String _getTranslatedText(String khText, String enText) {
    return _selectedLanguage == 'km' ? khText : enText;
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _changeLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _openDrawer() {
    if (!(_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  String _getProductPrice(Map<String, dynamic> data) {
    final priceValue =
        data['price'] ??
        data['Price'] ??
        data['cost'] ??
        data['Cost'] ??
        data['amount'] ??
        data['តម្លៃ'] ??
        '0';

    if (priceValue is num) {
      return '\$${priceValue.toStringAsFixed(2)}';
    }

    if (priceValue is String) {
      final match = RegExp(r'(\d+\.?\d*)').firstMatch(priceValue);
      if (match != null) {
        final number = double.tryParse(match.group(1)!) ?? 0;
        return '\$${number.toStringAsFixed(2)}';
      }
    }

    return '\$0.00';
  }

  double _getProductPriceValue(Map<String, dynamic> data) {
    final priceValue =
        data['price'] ??
        data['Price'] ??
        data['cost'] ??
        data['Cost'] ??
        data['amount'] ??
        data['តម្លៃ'] ??
        0;

    if (priceValue is num) return priceValue.toDouble();

    if (priceValue is String) {
      final cleanString = priceValue.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleanString) ?? 0.0;
    }

    return 0.0;
  }

  String _getProductDiscount(Map<String, dynamic> data) {
    final discount =
        data['Discount'] ??
        data['discount'] ??
        data['promotion'] ??
        data['special_offer'] ??
        data['sale'] ??
        '';
    return discount.toString();
  }

  bool _hasDiscount(Map<String, dynamic> data) {
    final discount = _getProductDiscount(data);
    return discount.isNotEmpty && discount != 'null';
  }

  void _addProductToCart(Map<String, dynamic> productData) {
    final productName = productData['name']?.toString() ?? 'ផលិតផល';
    final category = productData['category']?.toString() ?? 'ផលិតផល';

    final quantity = productData['quantity'] != null
        ? (productData['quantity'] is int
              ? productData['quantity']
              : int.tryParse(productData['quantity'].toString()) ?? 1)
        : 1;

    final totalPrice = productData['totalPrice'] != null
        ? (productData['totalPrice'] is double
              ? productData['totalPrice']
              : productData['totalPrice'] is int
              ? productData['totalPrice'].toDouble()
              : double.tryParse(productData['totalPrice'].toString()) ??
                    _getProductPriceValue(productData))
        : _getProductPriceValue(productData);

    // Save order to local storage
    final orderData = {
      'productName': productName,
      'category': category,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'productData': productData,
      'status': 'completed',
      'rating': 5.0,
    };
    _saveOrderToStorage(orderData);

    _addToCart(productName, category, totalPrice, productData, quantity);
  }

  void _addToCart(
    String productName,
    String category,
    double totalPrice,
    Map<String, dynamic> productData,
    int quantity,
  ) {
    setState(() {
      final existingIndex = cartItems.indexWhere(
        (item) => item.productName == productName && item.category == category,
      );

      if (existingIndex >= 0) {
        final existingItem = cartItems[existingIndex];
        cartItems[existingIndex] = CartItem(
          productName: productName,
          category: category,
          quantity: existingItem.quantity + quantity,
          totalPrice: existingItem.totalPrice + totalPrice,
          productData: productData,
        );
      } else {
        cartItemCount += quantity;
        cartItems.add(
          CartItem(
            productName: productName,
            category: category,
            quantity: quantity,
            totalPrice: totalPrice,
            productData: productData,
          ),
        );
      }

      _animationController.forward(from: 0.0);
      _bounceController.forward(from: 0.0);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _getTranslatedText(
            'បានបន្ថែម $productName ($quantity) ទៅក្នុងរទេះ',
            'Added $productName ($quantity) to cart',
          ),
          style: GoogleFonts.notoSansKhmer(),
        ),
        backgroundColor: gatXPink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToAdminPanel() {
    if (_isAdmin) {
      Get.to(() => AdminPanel());
    } else {
      _showErrorSnackBar(
        _getTranslatedText('អ្នកមិនមានសិទ្ធិចូល', 'You do not have permission'),
      );
    }
  }

  void _showAddProductDialog() {
    if (_isAdmin) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AddProductDialog();
        },
      );
    } else {
      _showErrorSnackBar(
        _getTranslatedText('អ្នកមិនមានសិទ្ធិ', 'You do not have permission'),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.notoSansKhmer()),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDiscountBadge(Map<String, dynamic> data) {
    if (!_hasDiscount(data)) return const SizedBox.shrink();

    final discountText = _getProductDiscount(data);

    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gatXRed, gatXOrange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: gatXRed.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              discountText,
              style: GoogleFonts.notoSansKhmer(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceWithDiscount(Map<String, dynamic> data) {
    final hasDiscount = _hasDiscount(data);
    final currentPrice = _getProductPrice(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              currentPrice,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasDiscount ? gatXRed : gatXDarkPink,
              ),
            ),
          ],
        ),
        if (_hasDiscount(data))
          Text(
            _getProductDiscount(data),
            style: GoogleFonts.notoSansKhmer(
              fontSize: 12,
              color: gatXGreen,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildProductImage(Map<String, dynamic> data) {
    if (data['image'] != null && data['image'].toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          data['image'].toString(),
          width: 110,
          height: 110,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade400,
              child: Icon(
                Icons.fastfood,
                size: 40,
                color: Colors.grey.shade700,
              ),
            );
          },
        ),
      );
    } else {
      return Center(
        child: Icon(Icons.fastfood, size: 40, color: Colors.grey.shade700),
      );
    }
  }

  Widget _buildEnhancedProductCard(Map<String, dynamic> data, String category) {
    final name =
        data['name']?.toString() ??
        _getTranslatedText('មិនមានឈ្មោះ', 'No Name');
    final hasDiscount = _hasDiscount(data);
    final productId =
        data['id']?.toString() ?? data['name']?.toString() ?? 'default_id';

    return GestureDetector(
      onTap: () {
        Get.to(
          ProductDetailPage(
            product: data,
            category: category,
            onAddToCart: (addProduct) {
              _addProductToCart(addProduct);
            },
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
          border: hasDiscount
              ? Border.all(color: gatXGold.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade200],
                    ),
                  ),
                  child: _buildProductImage(data),
                ),
                _buildDiscountBadge(data),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: InkWell(
                      onTap: () {
                        favoriteController.toggleFavorite(productId, data);
                      },
                      child: Obx(() {
                        final isFavorite = favoriteController.isFavorite(
                          productId,
                        );
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.red.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_outlined,
                            color: isFavorite
                                ? Colors.red
                                : Colors.grey.shade600,
                            size: 18,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: _buildPriceWithDiscount(data)),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasDiscount ? gatXRed : gatXPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: hasDiscount ? 4 : 2,
                          ),
                          onPressed: () => _addProductToCart(data),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_cart, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _getTranslatedText("ទិញ", "Buy"),
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCartIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(
          scale: _bounceAnimation,
          child: IconButton(
            onPressed: () {
              Get.to(
                () => CartProduct(
                  cartItems: cartItems,
                  onCartUpdated: () => setState(() {}),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (cartItemCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  cartItemCount > 99 ? "99+" : "$cartItemCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _getTranslatedText('ហាងលក់ម្ហូប ', 'Food Store'),
        style: GoogleFonts.notoSansKhmer(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: gatXPink,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: _openDrawer,
      ),
      actions: [_buildAnimatedCartIcon(), const SizedBox(width: 8)],
    );
  }

  Widget _buildLanguageSwitcher() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: gatXPink),
      onSelected: _changeLanguage,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: 'km',
          child: Row(
            children: [Text('🇰🇭'), const SizedBox(width: 8), Text('ខ្មែរ')],
          ),
        ),
        PopupMenuItem(
          value: 'en',
          child: Row(
            children: [Text('🇺🇸'), const SizedBox(width: 8), Text('English')],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        drawerScrimColor: Colors.white.withOpacity(0.5),
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 20),
            _buildSearchSection(),
            const SizedBox(height: 24),
            _buildCategoriesSection(),
            const SizedBox(height: 24),
            _buildUsersSection(),
            const SizedBox(height: 24),
            _buildProduct1Section(),
            const SizedBox(height: 24),
            _buildProduct2Section(),
            const SizedBox(height: 24),
            _buildProduct3Section(),
            const SizedBox(height: 24),
            _buildProduct4Section(),
            const SizedBox(height: 24),
            _buildProduct5Section(),
            const SizedBox(height: 24),
            _buildProduct6Section(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getTranslatedText('សួស្តី', 'Hello')} $_userName',
          style: GoogleFonts.notoSansKhmer(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.notoSansKhmer(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            children: [
              TextSpan(
                text: _getTranslatedText(
                  "តើអ្នកចង់ទិញ ",
                  "What do you want to ",
                ),
              ),
              TextSpan(
                text: _getTranslatedText("អ្វីនៅថ្ងៃនេះ?", "buy today?"),
                style: TextStyle(color: gatXPink),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: gatXPink),
                hintText: _getTranslatedText(
                  "ស្វែងរកផលិតផល...",
                  "Search products...",
                ),
                hintStyle: GoogleFonts.notoSansKhmer(color: Colors.grey),
                filled: true,
                fillColor: _isDarkMode ? Colors.grey[800] : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: gatXPink, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gatXPink, gatXDarkPink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: gatXPink.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.filter_list, size: 24, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslatedText('🍔 ប្រភេទម្ហូប', '🍔 Food Categories'),
          style: GoogleFonts.notoSansKhmer(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ImageSlideshow(
              width: double.infinity,
              height: 180,
              autoPlayInterval: 4000,
              isLoop: true,
              indicatorColor: gatXPink,
              indicatorBackgroundColor: Colors.grey[300]!,
              indicatorRadius: 4,
              children: [
                _buildSlide(
                  'https://i.pinimg.com/1200x/df/c2/d0/dfc2d0ff30ebbc5754c8d4a172fb6c4f.jpg',
                ),
                _buildSlide(
                  'https://i.pinimg.com/736x/97/32/35/973235b5f5eac13abb1cfba44e45f8bb.jpg',
                ),
                _buildSlide(
                  'https://i.pinimg.com/1200x/f1/32/cb/f132cb237125cad7668a19596906c33a.jpg',
                ),
                _buildSlide(
                  'https://i.pinimg.com/1200x/85/9f/94/859f9438b5abc627523ff2c767d55ed6.jpg',
                ),
                _buildSlide(
                  'https://i.pinimg.com/736x/ee/fd/7e/eefd7e864fb3215123454d669251f573.jpg',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlide(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslatedText('🍣 ការបញ្ចុះតម្លៃពិសេស', '🍣 Special Discounts'),
          style: GoogleFonts.notoSansKhmer(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: StreamBuilder<QuerySnapshot>(
            stream: _usersCollection.snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError)
                    return _buildErrorWidget(
                      _getTranslatedText(
                        'មានបញ្ហាកើតឡើង 😢',
                        'Something went wrong 😢',
                      ),
                    );
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return _buildLoadingWidget();
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return _buildEmptyWidget();

                  final users = snapshot.data!.docs;
                  final filteredUsers = _searchQuery.isEmpty
                      ? users
                      : users.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              data['name']?.toString().toLowerCase() ?? '';
                          final email =
                              data['email']?.toString().toLowerCase() ?? '';
                          return name.contains(_searchQuery.toLowerCase()) ||
                              email.contains(_searchQuery.toLowerCase());
                        }).toList();

                  if (filteredUsers.isEmpty) return _buildNoResultsWidget();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final document = filteredUsers[index];
                      final data = document.data() as Map<String, dynamic>;
                      final productId =
                          data['id']?.toString() ??
                          data['name']?.toString() ??
                          'default_id';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(
                                product: data,
                                category: _getTranslatedText(
                                  'ផលិតផល',
                                  'Product',
                                ),
                                onAddToCart: (productWithOptions) {
                                  _addProductToCart(productWithOptions);
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isDarkMode
                                ? Colors.grey[800]
                                : const Color.fromARGB(255, 237, 234, 234),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.grey.shade200,
                                            Colors.grey.shade300,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: _buildProductImage(data),
                                    ),
                                  ),
                                  _buildDiscountBadge(data),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          favoriteController.toggleFavorite(
                                            productId,
                                            data,
                                          );
                                        },
                                        child: Obx(() {
                                          final isFavorite = favoriteController
                                              .isFavorite(productId);
                                          return Icon(
                                            isFavorite
                                                ? Icons.favorite
                                                : Icons
                                                      .favorite_border_outlined,
                                            color: isFavorite
                                                ? Colors.red
                                                : Colors.grey.shade600,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      data['name']?.toString() ??
                                          _getTranslatedText(
                                            'មិនមានឈ្មោះ',
                                            'No Name',
                                          ),
                                      style: GoogleFonts.notoSansKhmer(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 30),
                                      child: Text(
                                        data['description']?.toString() ??
                                            _getTranslatedText(
                                              'មិនមានពណ៌នា',
                                              'No Description',
                                            ),
                                        style: GoogleFonts.notoSansKhmer(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 40),
                                      child: _buildPriceWithDiscount(data),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 38,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _hasDiscount(data)
                                              ? gatXRed
                                              : gatXPink,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        onPressed: () =>
                                            _addProductToCart(data),
                                        icon: const Icon(
                                          Icons.shopping_cart,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          _getTranslatedText(
                                            "បន្ថែមទៅរទេះ",
                                            "Add to Cart",
                                          ),
                                          style: GoogleFonts.notoSansKhmer(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
          ),
        ),
      ],
    );
  }

  // Product Sections
  Widget _buildProduct1Section() {
    return _buildProductSection(
      collection: _product1Collection,
      title: _getTranslatedText(
        '🍣 ហាងលក់ម្ហូបពេញនិយម',
        '🍣 Popular Food Shops',
      ),
    );
  }

  Widget _buildProduct2Section() {
    return _buildProductSection(
      collection: _product2Collection,
      title: _getTranslatedText('🔥 ចុះថ្លៃ 20%', '🔥 20% Discount'),
    );
  }

  Widget _buildProductSection({
    required CollectionReference collection,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gatXLightPink,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gatXPink.withOpacity(0.3)),
                ),
                child: Text(
                  _getTranslatedText('មើលទាំងអស់', 'View All'),
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gatXPink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: StreamBuilder<QuerySnapshot>(
            stream: collection.snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError)
                    return _buildErrorWidget(
                      _getTranslatedText(
                        'មានបញ្ហាកើតឡើង 😢',
                        'Something went wrong 😢',
                      ),
                    );
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return _buildLoadingWidget();
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return _buildEmptyWidget();

                  final products = snapshot.data!.docs;
                  final filteredProducts = _searchQuery.isEmpty
                      ? products
                      : products.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              data['name']?.toString().toLowerCase() ?? '';
                          final description =
                              data['description']?.toString().toLowerCase() ??
                              '';
                          return name.contains(_searchQuery.toLowerCase()) ||
                              description.contains(_searchQuery.toLowerCase());
                        }).toList();

                  if (filteredProducts.isEmpty) return _buildNoResultsWidget();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredProducts.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final document = filteredProducts[index];
                      final data = document.data() as Map<String, dynamic>;
                      return _buildEnhancedProductCard(data, title);
                    },
                  );
                },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProduct3Section() {
    return _buildProductSection1(
      collection: _product3Collection,
      title: _getTranslatedText('🍚 បាយសាច់មាន់', '🍚 Chicken Rice'),
    );
  }

  Widget _buildProduct4Section() {
    return _buildProductSection1(
      collection: _product4Collection,
      title: _getTranslatedText('🥤 ភេសជ្ជ:', '🥤 Beverages'),
    );
  }

  Widget _buildProduct5Section() {
    return _buildProductSection1(
      collection: _product5Collection,
      title: _getTranslatedText('🍕 ភីហ្សា', '🍕 Pizza'),
    );
  }

  Widget _buildProductSection1({
    required CollectionReference collection,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gatXLightPink,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gatXPink.withOpacity(0.3)),
                ),
                child: Text(
                  _getTranslatedText('មើលទាំងអស់', 'View All'),
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gatXPink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 275,
          child: StreamBuilder<QuerySnapshot>(
            stream: collection.snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError)
                    return _buildErrorWidget(
                      _getTranslatedText(
                        'មានបញ្ហាកើតឡើង 😢',
                        'Something went wrong 😢',
                      ),
                    );
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return _buildLoadingWidget();
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return _buildEmptyWidget();

                  final products = snapshot.data!.docs;
                  final filteredProducts = _searchQuery.isEmpty
                      ? products
                      : products.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name =
                              data['name']?.toString().toLowerCase() ?? '';
                          final description =
                              data['description']?.toString().toLowerCase() ??
                              '';
                          return name.contains(_searchQuery.toLowerCase()) ||
                              description.contains(_searchQuery.toLowerCase());
                        }).toList();

                  if (filteredProducts.isEmpty) return _buildNoResultsWidget();

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredProducts.length,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, index) {
                      final document = filteredProducts[index];
                      final data = document.data() as Map<String, dynamic>;
                      return _buildEnhancedProductCard1(data, title);
                    },
                  );
                },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEnhancedProductCard1(
    Map<String, dynamic> data,
    String category,
  ) {
    final name =
        data['name']?.toString() ??
        _getTranslatedText('មិនមានឈ្មោះ', 'No Name');
    final hasDiscount = _hasDiscount(data);
    final productId =
        data['id']?.toString() ?? data['name']?.toString() ?? 'default_id';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: data,
              category: category,
              onAddToCart: (productWithOptions) {
                _addProductToCart(productWithOptions);
              },
            ),
          ),
        );
      },
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
          border: hasDiscount
              ? Border.all(color: gatXGold.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade200],
                    ),
                  ),
                  child: _buildProductImage(data),
                ),
                _buildDiscountBadge(data),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: InkWell(
                      onTap: () {
                        favoriteController.toggleFavorite(productId, data);
                      },
                      child: Obx(() {
                        final isFavorite = favoriteController.isFavorite(
                          productId,
                        );
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.red.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_outlined,
                            color: isFavorite
                                ? Colors.red
                                : Colors.grey.shade600,
                            size: 18,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildPriceWithDiscount(data)),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasDiscount ? gatXRed : gatXPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: hasDiscount ? 4 : 2,
                          ),
                          onPressed: () => _addProductToCart(data),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_cart, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _getTranslatedText("ទិញ", "Buy"),
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProduct6Section() {
    return _buildProductSection2(
      collection: _product6Collection,
      title: _getTranslatedText(
        '🍽️ ជ្រើសរើសអារហារនីមួយៗ',
        '🍽️ Choose Each Dish',
      ),
    );
  }

  Widget _buildProductSection2({
    required CollectionReference collection,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: gatXLightPink,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gatXPink.withOpacity(0.3)),
                ),
                child: Text(
                  _getTranslatedText('មើលទាំងអស់', 'View All'),
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: gatXPink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: collection.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError)
                  return _buildErrorWidget(
                    _getTranslatedText(
                      'មានបញ្ហាកើតឡើង 😢',
                      'Something went wrong 😢',
                    ),
                  );
                if (snapshot.connectionState == ConnectionState.waiting)
                  return _buildLoadingWidget();
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                  return _buildEmptyWidget();

                final products = snapshot.data!.docs;
                final filteredProducts = _searchQuery.isEmpty
                    ? products
                    : products.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                            data['name']?.toString().toLowerCase() ?? '';
                        final description =
                            data['description']?.toString().toLowerCase() ?? '';
                        return name.contains(_searchQuery.toLowerCase()) ||
                            description.contains(_searchQuery.toLowerCase());
                      }).toList();

                if (filteredProducts.isEmpty) return _buildNoResultsWidget();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProducts.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final document = filteredProducts[index];
                    final data = document.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildEnhancedProductCard2(data, title),
                    );
                  },
                );
              },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildEnhancedProductCard2(
    Map<String, dynamic> data,
    String category,
  ) {
    final name =
        data['name']?.toString() ??
        _getTranslatedText('មិនមានឈ្មោះ', 'No Name');
    final price = _getSafePrice(data['price']);
    final originalPrice = _getSafePrice(data['originalPrice']);
    final discountPercent = _getDiscountPercent(data);
    final imageUrl =
        data['image']?.toString() ?? data['imageUrl']?.toString() ?? '';
    final hasDiscount = discountPercent > 0;
    final star = data['Star']?.toString() ?? '';
    final time = data['result']?.toString() ?? '';
    final tital = data['tital']?.toString() ?? '';
    final productId =
        data['id']?.toString() ?? data['name']?.toString() ?? 'default_id';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              product: data,
              category: category,
              onAddToCart: (productWithOptions) {
                _addProductToCart(productWithOptions);
              },
            ),
          ),
        );
      },
      child: Container(
        width: 300,
        height: 345,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
          border: hasDiscount
              ? Border.all(color: gatXGold.withOpacity(0.3))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade200],
                    ),
                  ),
                  child: _buildSafeProductImage(imageUrl),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: gatXRed,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '-$discountPercent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: InkWell(
                      onTap: () {
                        favoriteController.toggleFavorite(productId, data);
                      },
                      child: Obx(() {
                        final isFavorite = favoriteController.isFavorite(
                          productId,
                        );
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.red.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border_outlined,
                            color: isFavorite
                                ? Colors.red
                                : Colors.grey.shade600,
                            size: 18,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      children: [
                        if (star.isNotEmpty) ...[
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            star,
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (time.isNotEmpty) ...[
                          Icon(Icons.access_time, color: gatXPink, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            time,
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tital.isNotEmpty)
                      Text(
                        tital,
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildSafePriceWidget(
                            price,
                            originalPrice,
                            hasDiscount,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasDiscount ? gatXRed : gatXPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            elevation: 2,
                          ),
                          onPressed: () => _addProductToCart(data),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_cart, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _getTranslatedText("ទិញ", "Buy"),
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (hasDiscount)
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: gatXPink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: gatXPink),
                            ),
                            child: Text(
                              'បញ្ចុះតម្លៃ $discountPercent%',
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 12,
                                color: gatXPink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: gatXRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: gatXRed),
                            ),
                            child: Text(
                              'ដឹកជញ្ជូនឥតគិតថ្លៃ',
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 12,
                                color: gatXRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getSafePrice(dynamic priceData) {
    try {
      if (priceData is String) {
        return double.tryParse(priceData) ?? 0.0;
      }
      return (priceData as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  int _getDiscountPercent(Map<String, dynamic> data) {
    try {
      if (data['Discount'] is String) {
        final discountText = data['Discount'] as String;
        final regex = RegExp(r'(\d+)');
        final match = regex.firstMatch(discountText);
        if (match != null) {
          return int.tryParse(match.group(1)!) ?? 0;
        }
      }
      final price = _getSafePrice(data['price']);
      final originalPrice = _getSafePrice(data['originalPrice']);
      if (originalPrice > price && originalPrice > 0) {
        return ((originalPrice - price) / originalPrice * 100).round();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Widget _buildSafeProductImage(String imageUrl) {
    if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return Center(
        child: Icon(Icons.fastfood, size: 60, color: Colors.grey.shade400),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Icon(Icons.fastfood, size: 60, color: Colors.grey.shade400),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  Widget _buildSafePriceWidget(
    double price,
    double originalPrice,
    bool hasDiscount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDiscount && originalPrice > price) ...[
          Text(
            '\$${originalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.notoSansKhmer(
              fontSize: 12,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          '\$${price.toStringAsFixed(2)}',
          style: GoogleFonts.notoSansKhmer(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: hasDiscount ? gatXRed : Colors.black,
          ),
        ),
      ],
    );
  }

  // Error and Loading Widgets
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: gatXPink),
            const SizedBox(height: 16),
            Text(
              _getTranslatedText('កំពុងផ្ទុក...', 'Loading...'),
              style: GoogleFonts.notoSansKhmer(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Colors.grey.shade400,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _getTranslatedText('មិនមានផលិតផល', 'No products available'),
              style: GoogleFonts.notoSansKhmer(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _getTranslatedText('មិនមានលទ្ធផល', 'No results found'),
              style: GoogleFonts.notoSansKhmer(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Other Screens
  Widget _buildSearchScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchSection(),
          const SizedBox(height: 20),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersCollection.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError)
          return _buildErrorWidget(
            _getTranslatedText('មានបញ្ហាកើតឡើង 😢', 'Something went wrong 😢'),
          );
        if (snapshot.connectionState == ConnectionState.waiting)
          return _buildLoadingWidget();
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return _buildEmptyWidget();

        final users = snapshot.data!.docs;
        final filteredUsers = _searchQuery.isEmpty
            ? users
            : users.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name']?.toString().toLowerCase() ?? '';
                final email = data['email']?.toString().toLowerCase() ?? '';
                return name.contains(_searchQuery.toLowerCase()) ||
                    email.contains(_searchQuery.toLowerCase());
              }).toList();

        if (filteredUsers.isEmpty) return _buildNoResultsWidget();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredUsers.length,
          itemBuilder: (context, index) {
            final document = filteredUsers[index];
            final data = document.data() as Map<String, dynamic>;
            return _buildUserCard(data);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> data) {
    final productId =
        data['id']?.toString() ?? data['name']?.toString() ?? 'default_id';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, gatXLightPink.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: _buildUserAvatar(data),
          title: Text(
            data['name']?.toString() ??
                _getTranslatedText('មិនមានឈ្មោះ', 'No Name'),
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: gatXDarkPink,
            ),
          ),
          subtitle: _buildUserDetails(data),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final isFavorite = favoriteController.isFavorite(productId);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    favoriteController.toggleFavorite(productId, data);
                  },
                );
              }),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gatXPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios, color: gatXPink, size: 14),
              ),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: data,
                category: _getTranslatedText('ផលិតផល', 'Product'),
                onAddToCart: (productWithOptions) {
                  _addProductToCart(productWithOptions);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(Map<String, dynamic> data) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: gatXLightPink,
      backgroundImage:
          (data['image'] != null && data['image'].toString().isNotEmpty)
          ? NetworkImage(data['image'].toString())
          : null,
      child: (data['image'] == null || data['image'].toString().isEmpty)
          ? Text(
              data['name'] != null && data['name'].toString().isNotEmpty
                  ? data['name'].toString()[0].toUpperCase()
                  : "?",
              style: TextStyle(
                color: gatXPink,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  Widget _buildUserDetails(Map<String, dynamic> data) {
    final details = <Widget>[];

    if (data['email'] != null) {
      details.add(_buildDetailRow(Icons.email, data['email'].toString()));
    }
    if (data['phone'] != null) {
      details.add(_buildDetailRow(Icons.phone, data['phone'].toString()));
    }
    if (data['price'] != null) {
      details.add(
        _buildDetailRow(
          Icons.attach_money,
          "${_getTranslatedText('តម្លៃ', 'Price')}: \$${data['price']}",
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details,
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesScreen() {
    return Obx(() {
      final favoriteCount = favoriteController.favoriteCount;
      final favoriteItems = favoriteController.favoriteProducts.entries
          .where((entry) => entry.value)
          .toList();

      if (favoriteItems.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 90, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _getTranslatedText(
                  'មិនទាន់មានផលិតផលដែលអ្នកចូលចិត្ត',
                  'No favorites yet',
                ),
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_getTranslatedText('ចំណូលចិត្ត', 'Favorites')} ($favoriteCount)',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                final productId = favoriteItems[index].key;
                final productData = favoriteController.getFavoriteProduct(
                  productId,
                );

                if (productData == null) return SizedBox();

                return _buildFavoriteProductCard(productData, productId);
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFavoriteProductCard(
    Map<String, dynamic> data,
    String productId,
  ) {
    final name =
        data['name']?.toString() ??
        _getTranslatedText('មិនមានឈ្មោះ', 'No Name');
    final imageUrl = data['image']?.toString() ?? '';
    final hasDiscount = _hasDiscount(data);
    final currentPrice = _getProductPrice(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade200],
                  ),
                ),
                child: _buildSafeProductImage(imageUrl),
              ),
              if (hasDiscount)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: gatXRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getProductDiscount(data),
                      style: GoogleFonts.notoSansKhmer(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentPrice,
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: hasDiscount ? gatXRed : gatXDarkPink,
                        ),
                      ),
                      if (_hasDiscount(data) &&
                          _getProductDiscount(data).isNotEmpty)
                        Text(
                          _getProductDiscount(data),
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            color: gatXGreen,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: gatXPink,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => _addProductToCart(data),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_cart, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                _getTranslatedText("ទិញ", "Buy"),
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () {
                            favoriteController.toggleFavorite(productId, data);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    final User? user = _auth.currentUser;
    final String userName = user?.displayName ?? widget.userName;
    final String userEmail = user?.email ?? widget.userEmail;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
              image: DecorationImage(
                image: NetworkImage(
                  "https://i.pinimg.com/736x/68/a5/62/68a562bd838379759f3243fdfb32f7aa.jpg",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.notoSansKhmer(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(userEmail, style: GoogleFonts.notoSansKhmer(color: Colors.grey)),
          const SizedBox(height: 30),
          _buildProfileMenuItem(
            Icons.history,
            _getTranslatedText('ប្រវត្តិការកុម្ម៉ង់', 'Order History'),
            onTap: _closeDrawerAndShowHistory,
          ),
          _buildProfileMenuItem(
            Icons.settings,
            _getTranslatedText('ការកំណត់', 'Settings'),
            onTap: () {},
          ),
          _buildProfileMenuItem(
            Icons.help,
            _getTranslatedText('ជំនួយ', 'Help'),
            onTap: () {},
          ),
          _buildProfileMenuItem(
            Icons.logout,
            _getTranslatedText('ចាកចេញ', 'Logout'),
            onTap: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: gatXPink),
      title: Text(title, style: GoogleFonts.notoSansKhmer()),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _getTranslatedText('ចាកចេញ', 'Logout'),
            style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.bold),
          ),
          content: Text(
            _getTranslatedText(
              'តើអ្នកពិតជាចង់ចាកចេញពីគណនីមែនទេ?',
              'Are you sure you want to logout?',
            ),
            style: GoogleFonts.notoSansKhmer(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_getTranslatedText('បោះបង់', 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Home2FromLogin(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                _getTranslatedText('ចាកចេញ', 'Logout'),
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(25)),
      ),
      elevation: 16,
      shadowColor: Colors.black.withOpacity(0.3),
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(child: _buildDrawerMenu()),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFD70C6D)!,
            const Color.fromARGB(255, 217, 70, 136)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.8],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  255,
                  255,
                  255,
                ).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with enhanced styling
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: Image.asset("assets/logo.png", fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),

                // Store name with background
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ហាងលក់ម្ហូប',
                    style: GoogleFonts.notoSansKhmer(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                Text(
                  _getTranslatedText('ម្ហូបថ្មីៗរាល់ថ្ងៃ', 'Fresh Food Daily'),
                  style: GoogleFonts.notoSansKhmer(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenu() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 10),
        _buildEnhancedDrawerMenuItem(
          Icons.home_filled,
          _getTranslatedText('ទំព័រដើម', 'Home'),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomepageProduct(isAdmin: false, userEmail: '', userName: ''),
            ),
          ),

          tabIndex: 0,
        ),
        _buildEnhancedDrawerMenuItem(
          Icons.search_rounded,
          _getTranslatedText('ស្វែងរក', 'Search'),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => _buildSearchScreen()),
          ),
          tabIndex: 1,
        ),
        _buildEnhancedDrawerMenuItem(
          Icons.favorite_rounded,
          _getTranslatedText('ចំណូលចិត្ត', 'Favorites'),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => _buildFavoritesScreen()),
          ),
          tabIndex: 2,
        ),
        _buildEnhancedDrawerMenuItem(
          Icons.person_rounded,
          _getTranslatedText('គណនីខ្ញុំ', 'My Account'),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => _buildProfileScreen()),
          ),
          tabIndex: 3,
        ),
        if (_isAdmin) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _getTranslatedText('ផ្នែកអ្នកគ្រប់គ្រង', 'ADMIN'),
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ),
          _buildEnhancedDrawerMenuItem(
            Icons.admin_panel_settings_rounded,
            _getTranslatedText('ផ្នែកអ្នកគ្រប់គ្រង', 'Admin Panel'),
            () => _closeDrawerAndOpenAdmin(),
            isAdmin: true,
          ),
          _buildEnhancedDrawerMenuItem(
            Icons.add_circle_rounded,
            _getTranslatedText('បន្ថែមផលិតផល', 'Add Product'),
            () => _closeDrawerAndAddProduct(),
            isAdmin: true,
          ),
        ],

        _buildEnhancedDrawerMenuItem(
          Icons.history_rounded,
          _getTranslatedText('ប្រវត្តិការកុម្ម៉ង់', 'Order History'),
          () => _closeDrawerAndShowHistory(),
        ),

        const SizedBox(height: 16),

        // Enhanced Theme and Language Switcher
        _buildEnhancedThemeLanguageSwitcher(),

        const SizedBox(height: 16),

        // Enhanced Store Information
        _buildEnhancedStoreInfo(),
      ],
    );
  }

  Widget _buildEnhancedThemeLanguageSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [Colors.grey[800]!, Colors.grey[700]!]
              : [Colors.white, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode ? Colors.grey[600]! : Colors.pink.shade100!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Theme Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[700] : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDarkMode
                          ? [Colors.amber, Colors.orangeAccent]
                          : [Colors.grey[700]!, Colors.grey[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTranslatedText('ប្ដូររូបរាង', 'Theme Mode'),
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (value) => _toggleDarkMode(),
                  activeColor: Colors.red,
                  activeTrackColor: Colors.red.withOpacity(0.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Language Switcher
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[700] : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.lightBlueAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.language_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTranslatedText('ភាសា', 'Language'),
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode ? Colors.white : Colors.grey[800],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkMode
                        ? Colors.grey[600]!
                        : Colors.pink.shade100!,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isDarkMode
                          ? Colors.grey[500]!
                          : Colors.pink.shade300!,
                    ),
                  ),
                  child: _buildLanguageSwitcher(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStoreInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [Colors.grey[800]!, Colors.grey[700]!]
              : [Colors.pink.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_rounded,
                color: _isDarkMode ? Colors.amber : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getTranslatedText('ហាងម្ហូបគុណភាព', 'Quality Food Store'),
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Features with enhanced styling
          _buildEnhancedFeatureItem(
            Icons.local_shipping_rounded,
            _getTranslatedText(
              'ដឹកជញ្ជូនឥតគិតថ្លៃ 20\$+',
              'Free delivery for 20\$+',
            ),
          ),
          _buildEnhancedFeatureItem(
            Icons.discount_rounded,
            _getTranslatedText(
              'បញ្ចុះតម្លៃ 10% លើកដំបូង',
              '10% discount on first order',
            ),
          ),
          _buildEnhancedFeatureItem(
            Icons.access_time_rounded,
            _getTranslatedText('ដឹកជញ្ជូន 15-30នាទី', '15-30 minutes delivery'),
          ),
          _buildEnhancedFeatureItem(
            Icons.verified_user_rounded,
            _getTranslatedText('គុណភាពប្រាកដ', 'Quality guaranteed'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFeatureItem(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Color(0xFFD70C6D)!.withOpacity(0.5)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isDarkMode ? Colors.grey[200] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Color(0xFFD70C6D),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.notoSansKhmer(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.notoSansKhmer(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: _getTranslatedText('ទំព័រដើម', 'Home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: _getTranslatedText('ស្វែងរក', 'Search'),
            ),
            BottomNavigationBarItem(
              icon: ScaleTransition(
                scale: _bounceAnimation,
                child: const Icon(Icons.favorite),
              ),
              label: _getTranslatedText('ចូលចិត្ត', 'Favorites'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: _getTranslatedText('គណនី', 'Account'),
            ),
          ],
        ),
      ),
    );
  }

  // Theme
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.pink,
      primaryColor: gatXPink,
      appBarTheme: const AppBarTheme(
        color: gatXPink,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFD70C6D),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: gatXPink,
      appBarTheme: const AppBarTheme(
        color: gatXPink,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gatXPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
