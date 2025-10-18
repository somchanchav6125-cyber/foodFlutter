import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:http/http.dart';
import 'package:myhomework/controller/Cartproduct.dart';
import 'package:myhomework/controller/DetailsRice.dart';
import 'package:myhomework/model/check.dart';

const Color gatXPink = Color(0xFFD70C6D);
const Color gatXLightPink = Color(0xFFFDE8F1);
const Color gatXDarkPink = Color(0xFFA50953);
const Color gatXBlue = Color(0xFF2196F3);
const Color gatXGreen = Color(0xFF4CAF50);
const Color gatXOrange = Color(0xFFFF9800);
const Color gatXGold = Color(0xFFFFD700);
const Color gatXRed = Color(0xFFFF4757);

class HomepageProduct extends StatefulWidget {
  const HomepageProduct({super.key});

  @override
  State<HomepageProduct> createState() => _GatXAppState();
}

class CartItem {
  final String productName;
  final String category;
  final int quantity;
  final double totalPrice;
  final Map<String, dynamic> productData;

  CartItem({
    required this.productName,
    required this.category,
    required this.quantity,
    required this.totalPrice,
    required this.productData,
  });
}
class _GatXAppState extends State<HomepageProduct>
    with TickerProviderStateMixin {
  final favIconfood favIcon = Get.put(favIconfood());
  int cartItemCount = 0;
  List<CartItem> cartItems = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentIndex = 0;
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
  List<String> _recentSearches = [];
  final List<Map<String, dynamic>> _featuredProducts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _initializeAnimations();
    _loadFeaturedProducts();
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

  void _loadFeaturedProducts() async {
    try {
      final snapshot = await _product1Collection.limit(5).get();
      _featuredProducts.addAll(
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>),
      );
      setState(() {});
    } catch (e) {
      print('Error loading featured products: $e');
    }
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

  void _addToRecentSearch(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      });
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

  String _getOriginalPrice(Map<String, dynamic> data) {
    if (!_hasDiscount(data)) return '';

    final originalPrice =
        data['original_price'] ??
        data['old_price'] ??
        data['regular_price'] ??
        data['before_discount'] ??
        '';

    if (originalPrice.toString().isNotEmpty && originalPrice != 'null') {
      if (originalPrice is num) {
        return '\$${originalPrice.toStringAsFixed(2)}';
      }
      if (originalPrice is String) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(originalPrice);
        if (match != null) {
          final number = double.tryParse(match.group(1)!) ?? 0;
          return '\$${number.toStringAsFixed(2)}';
        }
      }
    }
    return '';
  }

  String _getDiscountPercentage(Map<String, dynamic> data) {
    if (!_hasDiscount(data)) return '';

    final currentPrice = _getProductPriceValue(data);
    final originalPriceValue =
        data['original_price'] ??
        data['old_price'] ??
        data['regular_price'] ??
        0;

    double originalPrice = 0.0;
    if (originalPriceValue is num) {
      originalPrice = originalPriceValue.toDouble();
    } else if (originalPriceValue is String) {
      originalPrice = double.tryParse(originalPriceValue) ?? 0.0;
    }

    if (originalPrice > 0 && currentPrice < originalPrice) {
      final percentage = ((originalPrice - currentPrice) / originalPrice * 100)
          .round();
      return '$percentage%';
    }

    return '';
  }

  void _addProductToCart(Map<String, dynamic> productData) {
    print(' _addProductToCart called with: $productData');

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

    print(
      ' Processed - Name: $productName, Qty: $quantity, Total: \$$totalPrice',
    );

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
        print(' Updated existing item: $productName');
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
        print(' Added new item: $productName');
      }

      _animationController.forward(from: 0.0);
      _bounceController.forward(from: 0.0);
    });

    _debugCartInfo();

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

  void _debugCartInfo() {
    print('=== 🛒 CART DEBUG INFO ===');
    print('Cart Item Count: $cartItemCount');
    print('Cart Items Length: ${cartItems.length}');
    for (int i = 0; i < cartItems.length; i++) {
      final item = cartItems[i];
      print(
        'Item $i: ${item.productName} - Qty: ${item.quantity} - Price: \$${item.totalPrice}',
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDiscountBadge(Map<String, dynamic> data) {
    if (!_hasDiscount(data)) return const SizedBox.shrink();

    final discountText = _getProductDiscount(data);
    final discountPercentage = _getDiscountPercentage(data);

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
              discountPercentage.isNotEmpty ? discountPercentage : discountText,
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
    final originalPrice = _getOriginalPrice(data);
    final discountPercentage = _getDiscountPercentage(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDiscount && originalPrice.isNotEmpty)
          Text(
            originalPrice,
            style: GoogleFonts.notoSansKhmer(
              fontSize: 12,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
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
            if (hasDiscount && discountPercentage.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: gatXRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: gatXRed.withOpacity(0.3)),
                ),
                child: Text(
                  discountPercentage,
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: gatXRed,
                  ),
                ),
              ),
            ],
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

  Widget _buildEnhancedProductCard(Map<String, dynamic> data, String category) {
    final name =
        data['name']?.toString() ??
        _getTranslatedText('មិនមានឈ្មោះ', 'No Name');
    final hasDiscount = _hasDiscount(data);

    return GestureDetector(
      // onTap: () {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => ProductDetailPage(
      //         product: data,
      //         category: category,
      //         onAddToCart: (productWithOptions) {
      //           _addProductToCart(productWithOptions);
      //         },
      //       ),
      //     ),
      //   );
      // },
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
                SafeArea(
                  child: InkWell(
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
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade200],
                        ),
                      ),
                      child: _buildProductImage(data),
                    ),
                  ),
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
                        setState(() {
                          favIcon.checkfavicon();
                        });
                      },
                      child: Obx(
                        () => Icon(
                          favIcon.favIcons.value
                              ? Icons.favorite
                              : Icons.favorite_border_outlined,
                          color: favIcon.favIcons.value
                              ? const Color.fromARGB(255, 255, 0, 0)
                              : const Color.fromARGB(255, 40, 39, 39),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Product Info
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

  Widget _buildEnhancedProductCard1(
    Map<String, dynamic> data,
    String category,
  ) {
    final name =
        data['name']?.toString() ??
        _getTranslatedText('មិនមានឈ្មោះ', 'No Name');
    final hasDiscount = _hasDiscount(data);

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
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.grey.shade600,
                      size: 18,
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
    print(' Building GatX App - Cart items: ${cartItems.length}');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        drawer: _buildDrawer(),
        drawerScrimColor: Colors.white,

        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
        appBar: _buildAppBar(),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
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
                    child: Icon(
                      Icons.favorite_border,
                      color: Colors.grey.shade600,
                      size: 18,
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

                    // 📝 Title
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
      // Calculate discount from prices
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

  Widget _buildSafeDiscountBadge(int discountPercent) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: gatXRed,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '-$discountPercent%',
          style: GoogleFonts.notoSansKhmer(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
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
          backgroundColor: gatXPink,
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

  Widget _buildProduct6Section() {
    return _buildProductSection2(
      collection: _product6Collection,
      title: _getTranslatedText(
        '🍽️ ជ្រើសរើសអារហារនីមួយៗ',
        '🍽️ Choose Each Dish',
      ),
    );
  }

  Widget _buildBody() {
    if (_currentIndex == 0) {
      return _buildHomeScreen();
    } else if (_currentIndex == 1) {
      return _buildSearchScreen();
    } else if (_currentIndex == 2) {
      return _buildFavoritesScreen();
    } else {
      return _buildProfileScreen();
    }
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslatedText('សួស្តី 👋', 'Hello 👋'),
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
              onSubmitted: (value) {
                _addToRecentSearch(value);
              },
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
                  'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500',
                ),
                _buildSlide(
                  'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=500',
                ),
                _buildSlide(
                  'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=500',
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
                                  print('Added to cart: $productWithOptions');
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
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailPage(
                                                    product: data,
                                                    category:
                                                        _getTranslatedText(
                                                          'ផលិតផល',
                                                          'Product',
                                                        ),
                                                    onAddToCart:
                                                        (productWithOptions) {
                                                          _addProductToCart(
                                                            productWithOptions,
                                                          );
                                                        },
                                                  ),
                                            ),
                                          );
                                        },
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

  Widget _buildSearchScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSearchSection(),
          const SizedBox(height: 20),
          if (_recentSearches.isNotEmpty) ...[
            Text(
              _getTranslatedText('ការស្វែងរកថ្មីៗ', 'Recent Searches'),
              style: GoogleFonts.notoSansKhmer(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _recentSearches
                  .map(
                    (search) => Chip(
                      label: Text(search),
                      onDeleted: () {
                        setState(() {
                          _recentSearches.remove(search);
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  Widget _buildFavoritesScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _getTranslatedText(
              'មិនទាន់មានផលិតផលដែលអ្នកចូលចិត្ត',
              'No favorites yet',
            ),
            style: GoogleFonts.notoSansKhmer(),
          ),
          const SizedBox(height: 8),
          Text(
            _getTranslatedText(
              'ចុចចូលចិត្តលើផលិតផលដើម្បីបន្ថែម',
              'Click heart on products to add',
            ),
            style: GoogleFonts.notoSansKhmer(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(
                  "https://scontent.fpnh9-1.fna.fbcdn.net/v/t39.30808-6/533836142_736540199262249_6166508347464764313_n.jpg?_nc_cat=107&ccb=1-7&_nc_sid=6ee11a&_nc_eui2=AeHPI2JCUZemlQXJ5jd2H5T0gJL2rRty0i-AkvatG3LSL0QqWBIAyGNWhb9LmJ5SqOO-fLADaZpC9xd21QmGzJQ_&_nc_ohc=IVTrZMgfNNcQ7kNvwFGg9ra&_nc_oc=AdlCGjVQyETscJn8ARGNz-CC1plmf8CoNQvgSbKYVxSc82P--4X2PZGXbsxzcvb3Pr8&_nc_zt=23&_nc_ht=scontent.fpnh9-1.fna&_nc_gid=RdLeU3WGX7FGQedAtFzqRA&oh=00_AfeI7jvxUo1v98RJ7cLmHBZLF1jJ9MqSXGuVSB6-KjArLw&oe=68F44D29",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'ឯកឧត្ដម​ ចាន់ចាវ',
            style: GoogleFonts.notoSansKhmer(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'somchanchav@gmail.com',
            style: GoogleFonts.notoSansKhmer(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          _buildProfileMenuItem(
            Icons.history,
            _getTranslatedText('ប្រវត្តិការកុម្ម៉ង់', 'Order History'),
          ),
          _buildProfileMenuItem(
            Icons.settings,
            _getTranslatedText('ការកំណត់', 'Settings'),
          ),
          _buildProfileMenuItem(
            Icons.help,
            _getTranslatedText('ជំនួយ', 'Help'),
          ),
          _buildProfileMenuItem(
            Icons.logout,
            _getTranslatedText('ចាកចេញ', 'Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: gatXPink),
      title: Text(title, style: GoogleFonts.notoSansKhmer()),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {},
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
          trailing: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: gatXPink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_forward_ios, color: gatXPink, size: 14),
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

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gatXPink, gatXDarkPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            Text(
              'ហាងលក់ម្ហូប',
              style: GoogleFonts.notoSansKhmer(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(child: _buildDrawerMenu()),
        ],
      ),
    );
  }

  Widget _buildDrawerMenu() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildDrawerMenuItem(
          Icons.home,
          _getTranslatedText('ទំព័រដើម', 'Home'),
          () {
            setState(() => _currentIndex = 0);
            Navigator.pop(context);
          },
        ),
        _buildDrawerMenuItem(
          Icons.search,
          _getTranslatedText('ស្វែងរក', 'Search'),
          () {
            setState(() => _currentIndex = 1);
            Navigator.pop(context);
          },
        ),
        _buildDrawerMenuItem(
          Icons.favorite,
          _getTranslatedText('ចំណូលចិត្ត', 'Favorites'),
          () {
            setState(() => _currentIndex = 2);
            Navigator.pop(context);
          },
        ),
        _buildDrawerMenuItem(
          Icons.person,
          _getTranslatedText('គណនីខ្ញុំ', 'My Account'),
          () {
            setState(() => _currentIndex = 3);
            Navigator.pop(context);
          },
        ),
        _buildDrawerMenuItem(
          Icons.history,
          _getTranslatedText('ប្រវត្តិការកុម្ម៉ង់', 'Order History'),
          () {},
        ),
        _buildDrawerMenuItem(
          Icons.settings,
          _getTranslatedText('ការកំណត់', 'Settings'),
          () {},
        ),
        _buildDrawerMenuItem(
          Icons.help,
          _getTranslatedText('ជំនួយ', 'Help'),
          () {},
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : gatXLightPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isDarkMode ? Colors.black54 : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: _isDarkMode ? Colors.amber : Colors.grey[700],
                    size: 20,
                  ),
                  onPressed: _toggleDarkMode,
                  tooltip: _getTranslatedText('ប្តូររបៀប', 'Toggle Theme'),
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.black54 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildLanguageSwitcher(),
                ),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [Colors.grey[800]!, Colors.grey[700]!]
                  : [gatXLightPink, Color(0xFFFCE4EC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title
              Text(
                _getTranslatedText(' ហាងម្ហូបគុណភាព ', ' Quality Food Store '),
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : gatXDarkPink,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                _getTranslatedText(
                  'ជំនួយពីហាងយើងខ្ញុំ',
                  'Support from our store',
                ),
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.grey[300] : gatXPink,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              _buildFeatureItem(
                ' ${_getTranslatedText('ដឹកជញ្ជូនឥតគិតថ្លៃ 20\$+', 'Free delivery for 20\$+')}',
              ),
              _buildFeatureItem(
                ' ${_getTranslatedText('បញ្ចុះតម្លៃ 10% លើកដំបូង', '10% discount on first order')}',
              ),
              _buildFeatureItem(
                ' ${_getTranslatedText('ដឹកជញ្ជូន 15-30នាទី', '15-30 minutes delivery')}',
              ),
              _buildFeatureItem(
                ' ${_getTranslatedText('គុណភាពប្រាកដ', 'Quality guaranteed')}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isDarkMode ? Colors.grey[800] : gatXLightPink,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: _isDarkMode ? Colors.white : gatXPink,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSansKhmer(
          color: _isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.notoSansKhmer(
                fontSize: 12,
                color: _isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          selectedItemColor: gatXPink,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
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
              icon: Stack(
                children: [
                  ScaleTransition(
                    scale: _bounceAnimation,
                    child: const Icon(Icons.favorite),
                  ),
                ],
              ),
              label: _getTranslatedText('ចូលចិត្ត', 'Favorites'),
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.person),
                  if (cartItemCount > 0)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cartItemCount > 99 ? "99+" : "$cartItemCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: _getTranslatedText('គណនី', 'Account'),
            ),
          ],
        ),
      ),
    );
  }
}
