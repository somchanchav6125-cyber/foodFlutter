import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color gatXPink = Color(0xFFD70C6D);
const Color gatXLightPink = Color(0xFFFDE8F1);
const Color gatXDarkPink = Color(0xFFA50953);
const Color gatXBlue = Color(0xFF2196F3);
const Color gatXGreen = Color(0xFF4CAF50);
const Color gatXOrange = Color(0xFFFF9800);

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String category;
  final Function(Map<String, dynamic>) onAddToCart;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.category,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;
  String? _selectedSize;

  final List<String> _sizes = ['S', 'M', 'L', 'XL'];

  @override
  void initState() {
    super.initState();
    _selectedSize = 'M';
  }

  double get _basePrice {
    return _extractPrice(widget.product['price']);
  }

  double get _totalPrice {
    return _basePrice * _quantity;
  }

  double _extractPrice(dynamic priceData) {
    if (priceData == null) return 0.0;
    String priceString = priceData.toString();
    priceString = priceString.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(priceString) ?? 0.0;
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

  @override
  Widget build(BuildContext context) {
    final String imageUrl = widget.product['image']?.toString() ?? '';
    final String productName =
        widget.product['name']?.toString() ?? 'មិនមានឈ្មោះ';
    final String productDescription =
        widget.product['description']?.toString() ?? '';
    final String productPriceDisplay = _getProductPrice(widget.product);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: Colors.black87,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'ព័ត៌មានលម្អិត',
          style: GoogleFonts.notoSansKhmer(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.favorite_border_rounded, size: 20),
              color: Colors.black87,
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with Modern Design
            Container(
              height: 320,
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Background Gradient
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.grey.shade50, Colors.grey.shade100],
                        ),
                      ),
                    ),

                    // Product Image
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: gatXPink,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fastfood_rounded,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'មិនមានរូបភាព',
                                  style: GoogleFonts.notoSansKhmer(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fastfood_rounded,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'មិនមានរូបភាព',
                              style: GoogleFonts.notoSansKhmer(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),

                    // Discount Badge (if available)
                    if (widget.product['discount'] != null)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [gatXOrange, Colors.orange],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${widget.product['discount']}% OFF',
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Product Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [gatXPink, gatXDarkPink],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: gatXPink.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.category,
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Price Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade50, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "តម្លៃគោល",
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              productPriceDisplay,
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: gatXPink,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: gatXGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: gatXGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: gatXGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.8',
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: gatXGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Size Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            color: gatXPink,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "ជ្រើសរើសទំហំ",
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _sizes.map((size) {
                          final isSelected = _selectedSize == size;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSize = size;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        colors: [gatXPink, gatXDarkPink],
                                      )
                                    : null,
                                color: isSelected ? null : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: gatXPink.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Text(
                                size,
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Quantity and Total Price Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey.shade50, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.format_list_numbered_rounded,
                                  color: gatXPink,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "ចំនួន",
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.remove_rounded,
                                      size: 20,
                                      color: _quantity > 1
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        if (_quantity > 1) _quantity--;
                                      });
                                    },
                                  ),
                                  Container(
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$_quantity',
                                      style: GoogleFonts.notoSansKhmer(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                      color: Colors.black87,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: Colors.grey.shade300, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              "តម្លៃសរុប:",
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "\$${_totalPrice.toStringAsFixed(2)}",
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: gatXPink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  if (productDescription.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_rounded,
                              color: gatXPink,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "ពណ៌នា",
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            productDescription,
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gatXPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: gatXPink.withOpacity(0.5),
                      ),
                      onPressed: () {
                        _addToCartWithOptions();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_rounded, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            "បន្ថែមទៅរទេះ ($_quantity)",
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCartWithOptions() {
    final String productName = widget.product['name']?.toString() ?? 'ផលិតផល';

    final Map<String, dynamic> productWithOptions = {
      ...widget.product,
      'selectedSize': _selectedSize,
      'quantity': _quantity,
      'totalPrice': _totalPrice,
      'category': widget.category,
      'basePrice': _basePrice,
    };

    widget.onAddToCart(productWithOptions);

    // Show success animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '✅ បានបន្ថែម $productName ($_quantity) ទៅក្នុងរទេះ!',
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: gatXGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }
}
