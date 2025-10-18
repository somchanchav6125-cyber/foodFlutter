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
  String? _selectedColor;

  final List<String> _sizes = ['S', 'M', 'L', 'XL'];

  @override
  void initState() {
    super.initState();
    _selectedSize = 'M';
    _selectedColor = 'ខ្មៅ';
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
        backgroundColor: gatXPink,
        title: Text(
          'ព័ត៌មានលម្អិត',
          style: GoogleFonts.notoSansKhmer(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey.shade100, Colors.grey.shade200],
                    ),
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: gatXPink,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.fastfood,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.fastfood,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Product Details Section
            Padding(
              padding: const EdgeInsets.all(20.0),
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: gatXPink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.category,
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 14,
                                  color: gatXPink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Base Price
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "តម្លៃគោល",
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        productPriceDisplay,
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: gatXPink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Size Selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ជ្រើសរើសទំហំ",
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _sizes.map((size) {
                          return ChoiceChip(
                            label: Text(size),
                            selected: _selectedSize == size,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSize = selected ? size : null;
                              });
                            },
                            selectedColor: gatXPink,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: GoogleFonts.notoSansKhmer(
                              color: _selectedSize == size
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Text(
                        "ចំនួន",
                        style: GoogleFonts.notoSansKhmer(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
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
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
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

                  const SizedBox(height: 20),

                  // Total Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: gatXPink.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gatXPink.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "តម្លៃសរុប:",
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "\$${_totalPrice.toStringAsFixed(2)}",
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: gatXPink,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  if (productDescription.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ពណ៌នា",
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            productDescription,
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gatXPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: gatXPink.withOpacity(0.5),
                      ),
                      onPressed: () {
                        _addToCartWithOptions();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shopping_cart, size: 24),
                          const SizedBox(width: 10),
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
      'selectedColor': _selectedColor,
      'quantity': _quantity,
      'totalPrice': _totalPrice,
      'category': widget.category,
      'basePrice': _basePrice,
    };

    print('🛒 Adding to cart: $productWithOptions');

    widget.onAddToCart(productWithOptions);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ បានបន្ថែម $productName ($_quantity) ទៅក្នុងរទេះ!',
          style: GoogleFonts.notoSansKhmer(),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: gatXPink,
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) Navigator.pop(context);
    });
  }
}
