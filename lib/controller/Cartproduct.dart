import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myhomework/controller/payproduct.dart';
import 'package:myhomework/model/CartIem.dart';
import 'package:myhomework/view/fromHomepage/homepage_page1.dart';

const Color gatXPink = Color(0xFFD70C6D);
const Color gatXLightPink = Color(0xFFFDE8F1);
const Color gatXDarkPink = Color(0xFFA50953);
const Color gatXBlue = Color(0xFF2196F3);
const Color gatXGreen = Color(0xFF4CAF50);
const Color gatXOrange = Color(0xFFFF9800);

class CartProduct extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback? onCartUpdated;

  const CartProduct({Key? key, required this.cartItems, this.onCartUpdated})
    : super(key: key);

  @override
  State<CartProduct> createState() => _CartProductState();
}

class _CartProductState extends State<CartProduct> {
  static const double deliveryFee = 1.50;

  double get _totalCartPrice {
    return widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  double _getUnitPrice(CartItem item) {
    return item.totalPrice / item.quantity;
  }

  double get _grandTotalPrice {
    return _totalCartPrice + deliveryFee;
  }

  void _removeItem(int index) {
    setState(() {
      widget.cartItems.removeAt(index);
      widget.onCartUpdated?.call();
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        final item = widget.cartItems[index];
        final unitPrice = item.totalPrice / item.quantity;
        widget.cartItems[index] = CartItem(
          productName: item.productName,
          category: item.category,
          quantity: newQuantity,
          totalPrice: unitPrice * newQuantity,
          productData: item.productData,
        );
        widget.onCartUpdated?.call();
      });
    } else {
      _removeItem(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: gatXPink,
        title: Text(
          'រទេះទិញឥវ៉ាន់',
          style: GoogleFonts.notoSansKhmer(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(), // ✅ កែទៅ Get.back()
        ),
      ),
      body: widget.cartItems.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      return _buildCartItem(widget.cartItems[index], index);
                    },
                  ),
                ),
                _buildCheckoutSection(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text("រទេះទិញឥវ៉ាន់របស់អ្នកទទេ", style: GoogleFonts.notoSansKhmer()),
          const SizedBox(height: 8),
          Text("សូមបន្ថែមម្ហូបអាហារខ្លះ!", style: GoogleFonts.notoSansKhmer()),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    final unitPrice = _getUnitPrice(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // រូបភាពផលិតផល
            CircleAvatar(
              radius: 25,
              backgroundImage: item.productData['image'] != null
                  ? NetworkImage(item.productData['image'].toString())
                  : null,
              child: item.productData['image'] == null
                  ? const Icon(Icons.fastfood, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),

            // ព័ត៌មានផលិតផល
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ប្រភេទ: ${item.category}',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'តម្លៃ: \$${unitPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      color: gatXDarkPink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'សរុប: \$${item.totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: gatXPink,
                    ),
                  ),
                ],
              ),
            ),

            // ប៊ូតុងកាត់បន្ថយ/បន្ថែម
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ប៊ូតុងបន្ថយ
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.remove, size: 14),
                        onPressed: () =>
                            _updateQuantity(index, item.quantity - 1),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ចំនួន
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: gatXLightPink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: GoogleFonts.notoSansKhmer(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ប៊ូតុងបន្ថែម
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: gatXPink,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.add,
                          size: 14,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            _updateQuantity(index, item.quantity + 1),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ប៊ូតុងលុប
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete,
                      size: 14,
                      color: Colors.red.shade600,
                    ),
                    onPressed: () => _removeItem(index),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // តម្លៃផលិតផលសរុប
          _buildPriceRow("តម្លៃផលិតផល", _totalCartPrice),
          const SizedBox(height: 6),

          // តម្លៃ delivery
          _buildPriceRow("តម្លៃ Delivery", deliveryFee),
          const SizedBox(height: 8),

          // បន្ទាត់ខ័ណ្ឌ
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 12),

          // សរុបទាំងអស់
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "សរុបទាំងអស់:",
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "\$${_grandTotalPrice.toStringAsFixed(2)}",
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.bold,
                  color: gatXPink,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ប៊ូតុងទិញឥវ៉ាន់
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gatXPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              onPressed: () {
                // ✅ កែត្រឹមត្រូវ៖ ប្រើ widget.cartItems
                Get.to(() => Mycartpay(), arguments: {
                  'cartItems': widget.cartItems,
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "ទិញឥវ៉ាន់ - \$${_grandTotalPrice.toStringAsFixed(2)}",
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansKhmer(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          "\$${price.toStringAsFixed(2)}",
          style: GoogleFonts.notoSansKhmer(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}