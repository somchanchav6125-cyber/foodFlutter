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