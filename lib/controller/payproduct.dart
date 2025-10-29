// lib/view/mycartpay.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:myhomework/model/CartIem.dart';
import 'package:myhomework/services/telegram_service.dart';
import 'package:myhomework/view/fromHomepage/homepage_page1.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class Mycartpay extends StatelessWidget {
  Mycartpay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFFD70C6D),
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
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  int _currentStep = 1;
  bool _cashOnDeliverySelected = true;
  bool _creditCardSelected = false;
  bool _bankTransferSelected = false;
  bool _isSubmitting = false;
  bool _hasPaidViaQR = false;
  bool _telegramConnected = false;
  bool _useCurrentLocation = false;

  // Credit card validation
  String _cardError = '';
  bool _isCardValid = false;

  // Location
  String _currentLocation = 'កំពុងទាញយកទីតាំង...';
  bool _isGettingLocation = false;
  bool _showManualLocation = false;

  // Manual location controllers
  final TextEditingController _manualAddressController =
      TextEditingController();
  final TextEditingController _manualCityController = TextEditingController();
  final TextEditingController _manualDistrictController =
      TextEditingController();
  final TextEditingController _manualStreetController = TextEditingController();

  // New variables for invoice photo
  File? _invoicePhoto;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _checkTelegramConnection();
    _getCurrentLocation();
  }

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
      _hasPaidViaQR = false;
      _invoicePhoto = null;
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
    if (_bankTransferSelected) return 'QR payment';
    return 'Unknown';
  }

  // Location methods
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    // Simulate location fetching
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _currentLocation = 'ផ្លូវព្រះស៊ីសុវត្ថិ, រាជធានីភ្នំពេញ';
      _isGettingLocation = false;
      if (_useCurrentLocation) {
        _addressController.text = _currentLocation;
        _cityController.text = 'ភ្នំពេញ';
      }
    });
  }

  void _toggleUseCurrentLocation(bool value) {
    setState(() {
      _useCurrentLocation = value;
      if (value) {
        _addressController.text = _currentLocation;
        _cityController.text = 'ភ្នំពេញ';
      } else {
        _addressController.text = '';
        _cityController.text = '';
      }
    });
  }

  void _showManualLocationInput() {
    setState(() {
      _showManualLocation = true;
    });
  }

  void _saveManualLocation() {
    if (_manualAddressController.text.isEmpty ||
        _manualCityController.text.isEmpty) {
      Get.snackbar(
        'កំហុស',
        'សូមបំពេញអាសយដ្ឋាន និងទីក្រុង',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    String fullAddress = _manualAddressController.text;
    if (_manualStreetController.text.isNotEmpty) {
      fullAddress = '${_manualStreetController.text}, $fullAddress';
    }
    if (_manualDistrictController.text.isNotEmpty) {
      fullAddress = '${_manualDistrictController.text}, $fullAddress';
    }

    setState(() {
      _addressController.text = fullAddress;
      _cityController.text = _manualCityController.text;
      _showManualLocation = false;
      _useCurrentLocation = false;
    });

    Get.snackbar(
      'ជោគជ័យ',
      'ទីតាំងត្រូវបានរក្សាទុក',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _openMapLocationPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.blue[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFF2E8B57).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    size: 30,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ការជ្រើសរើសទីតាំងនៅលើផែនទី',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'មុខងារនេះនឹងបើកផែនទីដើម្បីអោយអ្នកជ្រើសរើសទីតាំងពិតប្រាកដរបស់អ្នក។',
                  style: GoogleFonts.notoSansKhmer(fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ការរួមបញ្ចូលផែនទីទាមទារការរៀបចំបន្ថែមជាមួយ Google Maps API។',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'បោះបង់',
                          style: GoogleFonts.notoSansKhmer(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showManualLocationInput();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'បញ្ចូលដោយផ្ទាល់',
                          style: GoogleFonts.notoSansKhmer(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Credit card validation
  void _validateCreditCard() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text;
    final cvv = _cvvController.text;
    final cardName = _cardNameController.text;

    if (cardNumber.length < 16) {
      setState(() {
        _cardError = 'លេខកាតគួរតែមាន 16 ខ្ទង់';
        _isCardValid = false;
      });
      return;
    }

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(expiry)) {
      setState(() {
        _cardError = 'ប្រតិទិនត្រូវតែមានទម្រង់ MM/YY';
        _isCardValid = false;
      });
      return;
    }

    if (cvv.length < 3) {
      setState(() {
        _cardError = 'CVV ត្រូវតែមាន 3 ខ្ទង់';
        _isCardValid = false;
      });
      return;
    }

    if (cardName.isEmpty) {
      setState(() {
        _cardError = 'សូមបញ្ចូលឈ្មោះលើកាត';
        _isCardValid = false;
      });
      return;
    }

    setState(() {
      _cardError = '';
      _isCardValid = true;
    });
  }

  // Format card number with spaces
  void _formatCardNumber(String value) {
    final cleaned = value.replaceAll(' ', '');
    final formatted = StringBuffer();

    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(cleaned[i]);
    }

    _cardNumberController.value = _cardNumberController.value.copyWith(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _validateCreditCard();
  }

  // Photo methods
  Future<void> _takeInvoicePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _isUploadingPhoto = true;
        });

        setState(() {
          _invoicePhoto = File(photo.path);
          _isUploadingPhoto = false;
        });

        Get.snackbar(
          'ជោគជ័យ',
          'រូបថតវិក័យប័ត្រត្រូវបានថត',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });
      Get.snackbar(
        'កំហុស',
        'មិនអាចថតរូបបាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _selectInvoicePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _isUploadingPhoto = true;
        });

        setState(() {
          _invoicePhoto = File(photo.path);
          _isUploadingPhoto = false;
        });

        Get.snackbar(
          'ជោគជ័យ',
          'រូបថតវិក័យប័ត្រត្រូវបានជ្រើសរើស',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingPhoto = false;
      });
      Get.snackbar(
        'កំហុស',
        'មិនអាចជ្រើសរើសរូបបាន: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _checkTelegramConnection() async {
    try {
      var connectionTest = await TelegramService.testConnection();
      setState(() {
        _telegramConnected = connectionTest['success'];
      });
    } catch (e) {
      print('Error checking Telegram connection: $e');
      setState(() {
        _telegramConnected = false;
      });
    }
  }

  Future<void> _sendOrderToTelegram() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (!_telegramConnected) {
        var connectionTest = await TelegramService.testConnection();
        if (!connectionTest['success']) {
          _showTelegramErrorDialog();
          return;
        }
        setState(() {
          _telegramConnected = true;
        });
      }

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
        invoicePhoto: _invoicePhoto,
      );

      if (success) {
        _showSuccessDialog(true);
      } else {
        _showTelegramErrorDialog();
      }
    } catch (e) {
      print('Error sending to Telegram: $e');
      _showTelegramErrorDialog();
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showTelegramErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ការតភ្ជាប់មានបញ្ហា',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'មិនអាចផ្ញើទិន្នន័យទៅ Telegram បានទេ។ សូមព្យាយាមម្តងទៀត ឬជ្រើសរើសវិធីទូទាត់ផ្សេង។',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'បោះបង់',
                          style: GoogleFonts.notoSansKhmer(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _sendOrderToTelegram();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E8B57),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'ព្យាយាមម្តងទៀត',
                          style: GoogleFonts.notoSansKhmer(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(bool telegramSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.green[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF2E8B57).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 40,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ការកុម្ម៉ង់ជោគជ័យ!',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E8B57),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink[100]!),
                  ),
                  child: Text(
                    'ការកុម្ម៉ង់របស់អ្នកត្រូវបានទទួលយក និងនឹងត្រូវបញ្ជូនទៅកាន់អ្នកឆាប់ៗនេះ។',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.pink[800],
                      height: 1.5,
                    ),
                  ),
                ),
                if (!telegramSuccess) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ទិន្នន័យមិនអាចផ្ញើទៅ Telegram បាន',
                            style: GoogleFonts.notoSansKhmer(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Get.offAll(
                      () => HomepageProduct(
                        isAdmin: false,
                        userEmail: "",
                        userName: "",
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'យល់ព្រម',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
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
        'កំហុស',
        'សូមបំពេញព័ត៌មានចាំបាច់ទាំងអស់',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_creditCardSelected && !_isCardValid) {
      Get.snackbar(
        'កាតមិនត្រឹមត្រូវ',
        'សូមពិនិត្យព័ត៌មានកាតឥណទន្តរបស់អ្នក',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_bankTransferSelected) {
      if (!_hasPaidViaQR) {
        Get.snackbar(
          'ទាមទារសកម្មភាព',
          'សូមបញ្ជាក់ការទូទាត់តាមរយៈ QR code មុនពេលបញ្ជាក់ការកុម្ម៉ង់។',
          backgroundColor: Colors.yellow.shade700,
          colorText: Colors.black,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (_invoicePhoto == null) {
        Get.snackbar(
          'ទាមទាររូបថតវិក័យប័ត្រ',
          'សូមថតរូបវិក័យប័ត្រទូទាត់ប្រាក់របស់អ្នកសម្រាប់ការផ្ទៀងផ្ទាត់។',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
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
          'ជោគជ័យ',
          'Telegram Bot ដំណើរការ! សូមពិនិត្យ Telegram របស់អ្នក។',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
        );
        setState(() {
          _telegramConnected = true;
        });
      } else {
        Get.snackbar(
          'ទាមទារសកម្មភាព',
          'សូមផ្ញើសារទៅ bot ជាមុនសិននៅក្នុង Telegram។',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      Get.snackbar(
        'កំហុស',
        'ការតភ្ជាប់ Bot បរាជ័យ',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      setState(() {
        _telegramConnected = false;
      });
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    String title;
    Widget body;

    switch (_currentStep) {
      case 1:
        title = 'ការដឹកជញ្ជូន';
        body = _buildDeliveryScreen();
        break;
      case 2:
        title = 'សរុបការកុម្ម៉ង់';
        body = _buildSummaryScreen();
        break;
      case 3:
        title = 'ការទូទាត់';
        body = _buildPaymentScreen();
        break;
      default:
        title = '';
        body = const Center(child: Text('កំហុស'));
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
      backgroundColor: Color(0xFFD70C6D),
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            if (_currentStep > 1) {
              previousStep();
            } else {
              Get.back();
            }
          },
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSansKhmer(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            onPressed: _showHelpDialog,
          ),
        ),
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(
              _telegramConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _telegramConnected ? Colors.white : Colors.red[100],
            ),
            onPressed: _testTelegramConnection,
          ),
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
          _buildStep(1, 'ការដឹកជញ្ជូន'),
          Expanded(child: _buildLine(1, 2)),
          _buildStep(2, 'សរុប'),
          Expanded(child: _buildLine(2, 3)),
          _buildStep(3, 'ការទូទាត់'),
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
          width: 36,
          height: 36,
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
                  color: Color(0xFFD70C6D).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
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
        const SizedBox(height: 6),
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
        boxShadow: [
          if (isCompleted)
            BoxShadow(
              color: Color(0xFFD70C6D).withOpacity(0.2),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryScreen() {
    if (_showManualLocation) {
      return _buildManualLocationScreen();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'បញ្ចូលព័ត៌មាន',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 8),

          // Location Section
          _buildLocationSection(),
          const SizedBox(height: 20),

          _buildTextField(
            'ឈ្មោះពេញ',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
          ),
          _buildTextField(
            'អាសយដ្ឋាន',
            controller: _addressController,
            icon: Icons.location_on_outlined,
          ),
          _buildTextField(
            'ទីក្រុង',
            controller: _cityController,
            icon: Icons.location_city_outlined,
          ),
          _buildTextField(
            'លេខផ្ទះ',
            controller: _houseNumberController,
            icon: Icons.home_outlined,
          ),
          _buildTextField(
            'លេខទូរស័ព្ទ',
            controller: _phoneController,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 30),
          _buildProceedButton('បន្តទៅសរុប', nextStep),
        ],
      ),
    );
  }

  Widget _buildManualLocationScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'កំណត់ទីតាំងរបស់អ្នក',
            icon: Icons.edit_location_alt_rounded,
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple[50]!, Colors.blue[50]!],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 40,
                  color: Color(0xFFD70C6D),
                ),
                SizedBox(height: 8),
                Text(
                  'កំណត់ទីតាំងដោយខ្លួនឯង',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Color(0xFFD70C6D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'សូមបំពេញព័ត៌មានទីតាំងរបស់អ្នក',
                  style: GoogleFonts.notoSansKhmer(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _buildManualLocationField(
            'ផ្លូវ',
            _manualStreetController,
            Icons.streetview_rounded,
          ),
          _buildManualLocationField(
            'សង្កាត់/ឃុំ',
            _manualDistrictController,
            Icons.location_city_rounded,
          ),
          _buildManualLocationField(
            'ខណ្ឌ/ស្រុក',
            _manualCityController,
            Icons.place_rounded,
          ),
          _buildManualLocationField(
            'អាសយដ្ឋាន',
            _manualAddressController,
            Icons.home_work_rounded,
          ),

          const SizedBox(height: 30),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showManualLocation = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ត្រឡប់ក្រោយ',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveManualLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'រក្សាទុកទីតាំង',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualLocationField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'បញ្ចូល$label',
                hintStyle: GoogleFonts.notoSansKhmer(),
                prefixIcon: Icon(icon, color: Color(0xFF2E8B57)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E8B57),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_pin, color: Color(0xFFD70C6D), size: 24),
              SizedBox(width: 8),
              Text(
                'ទីតាំងបច្ចុប្បន្ន',
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFFD70C6D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isGettingLocation)
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFD70C6D),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'កំពុងទាញយកទីតាំង...',
                  style: GoogleFonts.notoSansKhmer(color: Colors.grey[600]),
                ),
              ],
            )
          else
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentLocation,
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 14,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _useCurrentLocation
                      ? Color(0xFF2E8B57)
                      : Colors.transparent,
                  border: Border.all(
                    color: _useCurrentLocation
                        ? Color(0xFF2E8B57)
                        : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _useCurrentLocation
                    ? Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _toggleUseCurrentLocation(!_useCurrentLocation),
                  child: Text(
                    'ប្រើទីតាំងបច្ចុប្បន្ន',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.refresh_rounded, color: Color(0xFF2E8B57)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _openMapLocationPicker,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFD70C6D),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFD70C6D), width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'កំណត់ទីតាំងដោយខ្លួនឯង',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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

  Widget _buildSummaryScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'ធាតុក្នុងការកុម្ម៉ង់',
            icon: Icons.shopping_bag_outlined,
          ),
          const SizedBox(height: 8),
          _buildOrderItemsList(),
          const SizedBox(height: 25),
          _buildDeliveryLocationSection(),
          const SizedBox(height: 25),
          _buildEditOrderButton('កែសម្រួលការកុម្ម៉ង់'),
          const SizedBox(height: 20),
          _buildProceedButton('បន្តទៅការទូទាត់', nextStep),
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
        border: index < cartItems.length - 1
            ? Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              image: item.productData['image'] != null
                  ? DecorationImage(
                      image: NetworkImage(item.productData['image'].toString()),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.productData['image'] == null
                ? Icon(
                    Icons.fastfood_rounded,
                    color: Colors.grey[400],
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
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
              color: const Color(0xFFD70C6D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'រទេះទទេ',
            style: GoogleFonts.notoSansKhmer(
              fontSize: 18,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'សូមបន្ថែមផលិតផលមុនពេលបន្ត',
            style: GoogleFonts.notoSansKhmer(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryLocationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Color(0xFFD70C6D),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'ទីតាំងដឹកជញ្ជូន',
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _addressController.text.isNotEmpty
                      ? '${_addressController.text}'
                      : 'សូមបញ្ចូលអាសយដ្ឋានដឹកជញ្ជូន',
                  style: GoogleFonts.notoSansKhmer(
                    color: Colors.blue[800],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_cityController.text.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    '${_cityController.text}',
                    style: GoogleFonts.notoSansKhmer(
                      color: Colors.blue[600],
                      fontSize: 13,
                    ),
                  ),
                ],
                if (_useCurrentLocation) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Colors.green,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ទីតាំងបច្ចុប្បន្ន',
                        style: GoogleFonts.notoSansKhmer(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (!_useCurrentLocation &&
                    _addressController.text.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.edit_location_alt_rounded,
                        size: 12,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ទីតាំងកំណត់ដោយខ្លួនឯង',
                        style: GoogleFonts.notoSansKhmer(
                          color: Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScreen() {
    bool isConfirmButtonEnabled =
        _cashOnDeliverySelected ||
        (_creditCardSelected && _isCardValid) ||
        (_bankTransferSelected && _hasPaidViaQR && _invoicePhoto != null);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(
            'ជ្រើសរើសវិធីទូទាត់',
            icon: Icons.payment_outlined,
          ),
          const SizedBox(height: 8),
          _buildPaymentMethodCard(
            'ទូទាត់រួចទើបទទួលទំនិញ',
            Icons.money_rounded,
            _cashOnDeliverySelected,
            () => _selectPaymentMethod('cash'),
          ),
          _buildPaymentMethodCard(
            'កាតឥណទន្ត',
            Icons.credit_card_rounded,
            _creditCardSelected,
            () => _selectPaymentMethod('credit'),
          ),
          _buildPaymentMethodCard(
            'ទូទាត់តាម QR',
            Icons.qr_code_rounded,
            _bankTransferSelected,
            () => _selectPaymentMethod('bank'),
          ),
          const SizedBox(height: 25),

          if (_creditCardSelected) _buildCreditCardContent(),
          if (_bankTransferSelected) _buildQRPaymentContent(),

          _buildOrderSummary(),
          const SizedBox(height: 20),

          _buildProceedButton(
            'បញ្ជាក់ការកុម្ម៉ង់',
            isConfirmButtonEnabled
                ? _confirmOrder
                : () {
                    if (_creditCardSelected && !_isCardValid) {
                      Get.snackbar(
                        'កាតមិនត្រឹមត្រូវ',
                        'សូមពិនិត្យព័ត៌មានកាតឥណទន្តរបស់អ្នក',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else if (_bankTransferSelected && !_hasPaidViaQR) {
                      Get.snackbar(
                        'ទាមទារសកម្មភាព',
                        'សូមបញ្ជាក់ការទូទាត់តាមរយៈ QR code មុនពេលបញ្ជាក់ការកុម្ម៉ង់។',
                        backgroundColor: Colors.yellow.shade700,
                        colorText: Colors.black,
                        duration: const Duration(seconds: 3),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    } else if (_bankTransferSelected && _invoicePhoto == null) {
                      Get.snackbar(
                        'ទាមទាររូបថតវិក័យប័ត្រ',
                        'សូមថតរូបវិក័យប័ត្រទូទាត់ប្រាក់របស់អ្នក។',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
            isEnabled: isConfirmButtonEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2E8B57).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.credit_card_rounded, color: Color(0xFF2E8B57)),
                SizedBox(width: 8),
                Text(
                  'ព័ត៌មានកាតឥណទន្ត',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Card Number
          _buildCreditCardField(
            'លេខកាត',
            _cardNumberController,
            Icons.credit_card_rounded,
            TextInputType.number,
            onChanged: _formatCardNumber,
            hintText: '1234 5678 9012 3456',
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildCreditCardField(
                  'ខែ/ឆ្នាំ',
                  _expiryController,
                  Icons.calendar_today_rounded,
                  TextInputType.text,
                  onChanged: (value) => _validateCreditCard(),
                  hintText: 'MM/YY',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCreditCardField(
                  'CVV',
                  _cvvController,
                  Icons.lock_rounded,
                  TextInputType.number,
                  onChanged: (value) => _validateCreditCard(),
                  hintText: '123',
                  obscureText: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildCreditCardField(
            'ឈ្មោះលើកាត',
            _cardNameController,
            Icons.person_rounded,
            TextInputType.text,
            onChanged: (value) => _validateCreditCard(),
            hintText: 'JOHN DOE',
          ),

          if (_cardError.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cardError,
                      style: GoogleFonts.notoSansKhmer(
                        color: Colors.red[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isCardValid) ...[
            const SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'កាតត្រឹមត្រូវ',
                    style: GoogleFonts.notoSansKhmer(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditCardField(
    String label,
    TextEditingController controller,
    IconData icon,
    TextInputType keyboardType, {
    Function(String)? onChanged,
    String hintText = '',
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansKhmer(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.notoSansKhmer(),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            ),
            style: GoogleFonts.notoSansKhmer(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildQRPaymentContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2E8B57).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF2E8B57)),
                SizedBox(width: 8),
                Text(
                  'ស្កេនដើម្បីទូទាត់ (KhQR)',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF2E8B57),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 1),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              children: [
                PrettyQr(
                  data: 'Payment Information for Order',
                  size: 180,
                  roundEdges: true,
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ធនាគារសាកល្បង - គណនី: 123456789',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Invoice Photo Section
          _buildInvoicePhotoSection(),
          const SizedBox(height: 15),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _hasPaidViaQR
                        ? Color(0xFF2E8B57)
                        : Colors.transparent,
                    border: Border.all(
                      color: _hasPaidViaQR ? Color(0xFF2E8B57) : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _hasPaidViaQR
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasPaidViaQR = !_hasPaidViaQR;
                      });
                    },
                    child: Text(
                      'ខ្ញុំបានបង់ប្រាក់តាមរយៈ QR code រួចហើយ។',
                      style: GoogleFonts.notoSansKhmer(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_telegramConnected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Telegram bot មិនបានតភ្ជាប់។ ការកុម្ម៉ង់អាចមិនត្រូវបានផ្ញើ។',
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoicePhotoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF2E8B57),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'ថតវិក័យប័ត្រទូទាត់',
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: const Color(0xFF2E8B57),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'សូមថតរូបវិក័យប័ត្រទូទាត់ប្រាក់របស់អ្នកសម្រាប់ការផ្ទៀងផ្ទាត់',
            style: GoogleFonts.notoSansKhmer(
              fontSize: 13,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          if (_invoicePhoto == null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildPhotoButton(
                    icon: Icons.camera_alt_rounded,
                    text: 'ថតរូប',
                    onPressed: _takeInvoicePhoto,
                    isUploading: _isUploadingPhoto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPhotoButton(
                    icon: Icons.photo_library_rounded,
                    text: 'ជ្រើសរើស',
                    onPressed: _selectInvoicePhoto,
                    isUploading: _isUploadingPhoto,
                  ),
                ),
              ],
            ),
          ] else ...[
            Column(
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(_invoicePhoto!),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallPhotoButton(
                      icon: Icons.camera_alt_rounded,
                      onPressed: _takeInvoicePhoto,
                    ),
                    const SizedBox(width: 12),
                    _buildSmallPhotoButton(
                      icon: Icons.delete_rounded,
                      onPressed: () {
                        setState(() {
                          _invoicePhoto = null;
                        });
                      },
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2E8B57).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ថតវិក័យប័ត្របានរួចរាល់',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 12,
                      color: const Color(0xFF2E8B57),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
    bool isUploading = false,
  }) {
    return Container(
      height: 56,
      child: ElevatedButton(
        onPressed: isUploading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E8B57),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: const Color(0xFF2E8B57), width: 1.5),
          ),
        ),
        child: isUploading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E8B57)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSmallPhotoButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      width: 48,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.white,
          foregroundColor: color != null
              ? Colors.white
              : const Color(0xFF2E8B57),
          elevation: 2,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: color ?? const Color(0xFF2E8B57),
              width: 1.5,
            ),
          ),
        ),
        child: Icon(icon, size: 20),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFF2E8B57) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? Color(0xFF2E8B57).withOpacity(0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xFF2E8B57) : Colors.grey[600],
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.notoSansKhmer(
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF2E8B57) : Colors.black87,
          ),
        ),
        trailing: isSelected
            ? Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Color(0xFF2E8B57),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 16, color: Colors.white),
              )
            : null,
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildOrderSummary() {
    double subtotal = totalPrice;
    double deliveryFee = 1.50;
    double tax = totalPrice * 0.1;
    double total = subtotal + deliveryFee + tax;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: Color(0xFFD70C6D)),
              SizedBox(width: 8),
              Text(
                'សរុបការកុម្ម៉ង់',
                style: GoogleFonts.notoSansKhmer(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('សរុប', '\$${subtotal.toStringAsFixed(2)}'),
          _buildSummaryRow(
            'ថ្លៃដឹកជញ្ជូន',
            '\$${deliveryFee.toStringAsFixed(2)}',
          ),
          _buildSummaryRow('ពន្ធ', '\$${tax.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          Divider(height: 20, color: Colors.grey[300]),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'ទឹកប្រាក់សរុប',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? Colors.black87 : Colors.grey[600],
              fontSize: isTotal ? 15 : 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFFD70C6D) : Colors.black87,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Color(0xFFD70C6D), size: 22),
            SizedBox(width: 8),
          ],
          Text(
            title,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hintText, {
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.notoSansKhmer(),
          prefixIcon: Container(
            width: 20,
            height: 20,
            margin: EdgeInsets.all(12),
            child: Icon(icon, color: Colors.grey[600], size: 20),
          ),
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
        style: GoogleFonts.notoSansKhmer(),
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
          foregroundColor: Color(0xFF2E8B57),
          side: const BorderSide(color: Color(0xFF2E8B57), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined, size: 18),
            SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.notoSansKhmer(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceedButton(
    String text,
    VoidCallback onPressed, {
    bool isEnabled = true,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(bottom: 20),
      child: ElevatedButton(
        onPressed: (_isSubmitting || !isEnabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: (_isSubmitting || !isEnabled)
              ? Colors.grey
              : Color(0xFFD70C6D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          shadowColor: const Color(0xFFD70C6D).withOpacity(0.3),
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
                  const SizedBox(width: 12),
                  Text(
                    'កំពុងផ្ញើការកុម្ម៉ង់...',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
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
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.blue[50]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFFD70C6D).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 30,
                    color: Color(0xFFD70C6D),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ជំនួយ',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFFD70C6D),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'សូមបំពេញព័ត៌មានអោយបានត្រឹមត្រូវ និងពិនិត្យការកុម្ម៉ង់អោយបានហ្មត់ចត់មុនពេលទូទាត់ប្រាក់។',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E8B57),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'យល់ព្រម',
                    style: GoogleFonts.notoSansKhmer(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardNameController.dispose();
    _manualAddressController.dispose();
    _manualCityController.dispose();
    _manualDistrictController.dispose();
    _manualStreetController.dispose();
    super.dispose();
  }
}
