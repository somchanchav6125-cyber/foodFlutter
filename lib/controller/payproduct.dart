// lib/view/mycartpay.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:myhomework/controller/DetailsRice.dart';
import 'package:myhomework/view/fromHomepage/homepage_page1.dart';

class Mycartpay extends StatelessWidget {
  Mycartpay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF0F0F0),
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFFE67823),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFF2E8B57),
        ),
      ),
      home: CheckoutPage(),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _houseNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int _currentStep = 1;
  bool _cashOnDeliverySelected = true;
  bool _creditCardSelected = false;
  bool _bankTransferSelected = false;
  bool _isSubmitting = false;

  void nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void previousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _cashOnDeliverySelected = method == 'cash';
      _creditCardSelected = method == 'credit';
      _bankTransferSelected = method == 'bank';
    });
  }
  List<CartItem> get cartItems {
    return Get.arguments?['cartItems'] ?? [];
  }

  double get totalPrice {
    return cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  String get _selectedPaymentMethod {
    if (_cashOnDeliverySelected) return 'Cash on Delivery';
    if (_creditCardSelected) return 'Credit Card';
    if (_bankTransferSelected) return 'Bank Transfer';
    return 'Unknown';
  }

  Future<void> _sendOrderToTelegram() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      List<Map<String, dynamic>> orderItems = cartItems.map((item) {
        return {
          'name': item.productName,
          'quantity': item.quantity,
          'price': item.totalPrice.toStringAsFixed(2),
          'category': item.category,
        };
      }).toList();
      bool success = await TelegramService.sendOrderNotification(
        customerName: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        houseNumber: _houseNumberController.text,
        orderItems: orderItems,
        totalAmount: totalPrice,
        paymentMethod: _selectedPaymentMethod,
      );

      if (success) {
        _showSuccessDialog(true);
      } else {
        _showSuccessDialog(false);
      }
    } catch (e) {
      print('Error sending to Telegram: $e');
      _showSuccessDialog(false);
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog(bool telegramSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: const Color(0xFF2E8B57),
                ),
                const SizedBox(height: 16),
                Text(
                  'ការកុម្ម៉ង់ជោគជ័យ!',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ការកុម្ម៉ង់របស់អ្នកត្រូវបានទទួលយក និងនឹងត្រូវបញ្ជូនទៅកាន់អ្នកឆាប់ៗនេះ។',
                  style: GoogleFonts.notoSansKhmer(),
                  textAlign: TextAlign.center,
                ),
                if (telegramSuccess) ...[
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ ទិន្នន័យមិនអាចផ្ញើទៅ Telegram បាន',
                    style: GoogleFonts.notoSansKhmer(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.offAll(() => HomepageProduct());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('យល់ព្រម', style: GoogleFonts.notoSansKhmer()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmOrder() {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all required fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    _sendOrderToTelegram();
  }
  void _testTelegramConnection() async {
    setState(() {
      _isSubmitting = true;
    });

    print(' Testing Telegram connection...');

    var botTest = await TelegramService.testConnection();

    if (botTest['success']) {
      print(' Bot connection successful');

      bool messageSent = await TelegramService.sendMessage(
        ' <b>Test Message from MyHomework App</b>\n\n'
        'This is a test message to verify Telegram Bot integration.\n'
        'Time: ${DateTime.now()}\n'
        ' If you see this, everything is working!',
      );

      if (messageSent) {
        Get.snackbar(
          'Success',
          'Telegram Bot is working! Check your Telegram.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      } else {
        Get.snackbar(
          'Action Required',
          'Please send a message to the bot first in Telegram.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );
      }
    } else {
      Get.snackbar(
        'Error',
        'Bot connection failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    String title;
    Widget body;

    switch (_currentStep) {
      case 1:
        title = 'Delivery';
        body = _buildDeliveryScreen();
        break;
      case 2:
        title = 'Order Summary';
        body = _buildSummaryScreen();
        break;
      case 3:
        title = 'Payment';
        body = _buildPaymentScreen();
        break;
      default:
        title = '';
        body = const Center(child: Text('Error'));
    }

    return Column(
      children: [
        _buildAppBar(title),
        _buildProgressBar(),
        const SizedBox(height: 20),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Color(0xFFD70C6D),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black54),
        onPressed: () {
          if (_currentStep > 1) {
            previousStep();
          } else {
            Get.back();
          }
        },
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSansKhmer(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded, color: Colors.black54),
          onPressed: _showHelpDialog,
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, 'Delivery'),
          Expanded(child: _buildLine(1, 2)),
          _buildStep(2, 'Summary'),
          Expanded(child: _buildLine(2, 3)),
          _buildStep(3, 'Payment'),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isActive
                ? Color(0xFFD70C6D)
                : Colors.grey[300],
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isActive
                  ? Color(0xFFD70C6D)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: const Color(0xFF2E8B57).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.notoSansKhmer(
            fontSize: 12,
            color: isActive ? Color(0xFFD70C6D) : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(int startStep, int endStep) {
    bool isCompleted = _currentStep >= endStep;
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Color(0xFFD70C6D) : Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildDeliveryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Enter Information'),
          _buildTextField(
            'Full Name',
            controller: _nameController,
            icon: Icons.person,
          ),
          _buildTextField(
            'Address',
            controller: _addressController,
            icon: Icons.location_on,
          ),
          _buildTextField(
            'City',
            controller: _cityController,
            icon: Icons.location_city,
          ),
          _buildTextField(
            'House Number',
            controller: _houseNumberController,
            icon: Icons.home,
          ),
          _buildTextField(
            'Phone Number',
            controller: _phoneController,
            icon: Icons.phone,
          ),
          const SizedBox(height: 25),
          _buildProfileDetailsButton(),
          const SizedBox(height: 20),
          _buildProceedButton('Proceed to Summary', nextStep),
        ],
      ),
    );
  }

  Widget _buildSummaryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Order Items'),
          _buildOrderItemsList(),
          const SizedBox(height: 25),
          _buildDeliveryLocationSection(),
          const SizedBox(height: 25),
          _buildEditOrderButton('Edit Order'),
          const SizedBox(height: 20),
          _buildProceedButton('Proceed to Payment', nextStep),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList() {
    if (cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < cartItems.length; i++)
            _buildOrderItem(cartItems[i], i),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[100],
              image: item.productData['image'] != null
                  ? DecorationImage(
                      image: NetworkImage(item.productData['image'].toString()),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.productData['image'] == null
                ? Icon(Icons.fastfood_rounded, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ប្រភេទ: ${item.category}',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ចំនួន: ${item.quantity}',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${item.totalPrice.toStringAsFixed(2)}',
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFFE67823),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'រទេះទទេ',
            style: GoogleFonts.notoSansKhmer(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Location',
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _addressController.text.isNotEmpty
                ? '${_addressController.text}, ${_cityController.text}'
                : 'Please enter delivery address',
            style: GoogleFonts.notoSansKhmer(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Select Payment Method'),
          _buildPaymentMethodCard(
            'Cash on Delivery',
            Icons.money_rounded,
            _cashOnDeliverySelected,
            () => _selectPaymentMethod('cash'),
          ),
          _buildPaymentMethodCard(
            'Credit Card',
            Icons.credit_card_rounded,
            _creditCardSelected,
            () => _selectPaymentMethod('credit'),
          ),
          _buildPaymentMethodCard(
            'Bank Transfer',
            Icons.account_balance_rounded,
            _bankTransferSelected,
            () => _selectPaymentMethod('bank'),
          ),
          const SizedBox(height: 25),
          _buildOrderSummary(),
          const SizedBox(height: 20),
          _buildProceedButton('Confirm Order', _confirmOrder),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    String title,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Color(0xFFD70C6D) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF2E8B57) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSansKhmer(
            fontWeight: FontWeight.w500,
            color: isSelected ? const Color(0xFF2E8B57) : Colors.black87,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: const Color(0xFF2E8B57))
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildOrderSummary() {
    double subtotal = totalPrice;
    double deliveryFee = 1.50;
    double tax = totalPrice * 0.1;
    double total = subtotal + deliveryFee + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          _buildSummaryRow(
            'Delivery Fee',
            '\$${deliveryFee.toStringAsFixed(2)}',
          ),
          _buildSummaryRow('Tax', '\$${tax.toStringAsFixed(2)}'),
          const Divider(height: 20),
          _buildSummaryRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFFE67823) : Colors.black87,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.notoSansKhmer(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hintText, {
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetailsButton() {
    return Container(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2E8B57),
          side: const BorderSide(color: Color(0xFF2E8B57)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Use Profile Details',
          style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildEditOrderButton(String text) {
    return Container(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          Get.back(); 
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Color(0xFFD70C6D),
          side: const BorderSide(color: Color(0xFFE67823)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildProceedButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSubmitting ? Colors.grey : Color(0xFFD70C6D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          shadowColor: const Color(0xFFE67823).withOpacity(0.3),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'កំពុងផ្ញើការកុម្ម៉ង់...',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ជំនួយ',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'សូមបំពេញព័ត៌មានអោយបានត្រឹមត្រូវ និងពិនិត្យការកុម្ម៉ង់អោយបានហ្មត់ចត់មុនពេលទូទាត់ប្រាក់។',
                  style: GoogleFonts.notoSansKhmer(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('យល់ព្រម', style: GoogleFonts.notoSansKhmer()),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _houseNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

class TelegramService {

  static final String _botToken =
      '8419982506:AAECn-_9J3GDQiUpObUGHW_0nNF4hJHUFTE';
  static final String _chatId = '5424661938';

  static final String _baseUrl = 'https://api.telegram.org/bot$_botToken';

  static Future<bool> sendMessage(String message) async {
    try {
      print(' Sending message to Telegram...');
      print(' Message: $message');

      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      print(' Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(' Message sent successfully to Telegram!');
        return true;
      } else {
        print('x Failed to send message: ${response.body}');
        return false;
      }
    } catch (e) {
      print(' Telegram error: $e');
      return false;
    }
  }

  static Future<bool> sendOrderNotification({
    required String customerName,
    required String phone,
    required String address,
    required String city,
    required String houseNumber,
    required List<Map<String, dynamic>> orderItems,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    try {

      String orderSummary = _buildOrderSummary(
        customerName: customerName,
        phone: phone,
        address: address,
        city: city,
        houseNumber: houseNumber,
        orderItems: orderItems,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
      );

      return await sendMessage(orderSummary);
    } catch (e) {
      print('Order notification error: $e');
      return false;
    }
  }

  static String _buildOrderSummary({
    required String customerName,
    required String phone,
    required String address,
    required String city,
    required String houseNumber,
    required List<Map<String, dynamic>> orderItems,
    required double totalAmount,
    required String paymentMethod,
  }) {
    StringBuffer message = StringBuffer();
    message.write(' <b> NEW ORDER RECEIVED</b>\n\n');
    message.write(' <b>Customer Information:</b>\n');
    message.write('•  Name: $customerName\n');
    message.write('•  Phone: $phone\n');
    message.write('•  Address: $address\n');
    message.write('•  City: $city\n');
    message.write('•  House No: $houseNumber\n\n');

    message.write(' <b>Order Items:</b>\n');
    for (int i = 0; i < orderItems.length; i++) {
      var item = orderItems[i];
      message.write(
        '${i + 1}. ${item['name']} - ${item['quantity']}x - \$${item['price']}\n',
      );
    }

    message.write('\n <b>Payment Details:</b>\n');
    message.write('•  Total Amount: \$${totalAmount.toStringAsFixed(2)}\n');
    message.write('•  Payment Method: $paymentMethod\n\n');

    message.write(' <b>Order Time:</b>\n');
    message.write('•  ${DateTime.now().toString()}\n');

    message.write('\n <b>Order Source:</b>\n');
    message.write('•  MyHomework App\n');

    return message.toString();
  }
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/getMe'));

      if (response.statusCode == 200) {
        print(' Telegram Bot connection successful!');
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        print(' Telegram Bot connection failed: ${response.body}');
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      print(' Telegram connection error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
