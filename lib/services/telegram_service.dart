// TODO Implement this library.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class TelegramService {
  static final String _botToken = '8419982506:AAECn-_9J3GDQiUpObUGHW_0nNF4hJHUFTE';
  static final String _chatId = '5424661938';
  static final String _baseUrl = 'https://api.telegram.org/bot$_botToken';

  static Future<bool> sendMessage(String message) async {
    try {
      print('📤 Sending message to Telegram...');
      print('💬 Message: $message');

      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Message sent successfully to Telegram!');
        return true;
      } else {
        print('❌ Failed to send message: ${response.body}');
        return false;
      }
    } catch (e) {
      print('💥 Telegram error: $e');
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
    File? invoicePhoto,
  }) async {
    try {
      print('🛍️ Preparing to send order notification...');

      String orderSummary = _buildOrderSummary(
        customerName: customerName,
        phone: phone,
        address: address,
        city: city,
        houseNumber: houseNumber,
        orderItems: orderItems,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        hasInvoicePhoto: invoicePhoto != null,
      );

      // First send the order summary
      bool messageSent = await sendMessage(orderSummary);

      // Then send the invoice photo if available
      if (invoicePhoto != null && messageSent) {
        print('📸 Sending invoice photo...');
        bool photoSent = await _sendPhoto(invoicePhoto, 
          '🧾 Invoice for $customerName - Phone: $phone\n'
          '💰 Total: \$${totalAmount.toStringAsFixed(2)} - Payment: $paymentMethod'
        );
        
        if (!photoSent) {
          print('⚠️ Failed to send photo, but order message was sent');
        }
      }

      return messageSent;
    } catch (e) {
      print('💥 Order notification error: $e');
      return false;
    }
  }

  static Future<bool> _sendPhoto(File photo, String caption) async {
    try {
      print('📤 Uploading photo to Telegram...');
      print('📁 Photo path: ${photo.path}');
      print('📝 Caption: $caption');

      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/sendPhoto'));
      request.fields['chat_id'] = _chatId;
      request.fields['caption'] = caption;
      
      // Add the photo file
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        photo.path,
      ));

      print('🔄 Sending photo request...');
      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      
      print('📡 Photo response status: ${response.statusCode}');
      print('📄 Photo response: $responseString');

      if (response.statusCode == 200) {
        print('✅ Photo sent successfully to Telegram!');
        return true;
      } else {
        print('❌ Failed to send photo: $responseString');
        return false;
      }
    } catch (e) {
      print('💥 Telegram photo upload error: $e');
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
    required bool hasInvoicePhoto,
  }) {
    StringBuffer message = StringBuffer();

    // Header
    message.write('🛍️ <b>NEW ORDER RECEIVED!</b>\n');
    message.write('═══════════════════════════\n\n');

    // Customer Information
    message.write('📋 <b>CUSTOMER INFORMATION</b>\n');
    message.write('👤 <b>Name:</b> $customerName\n');
    message.write('📞 <b>Phone:</b> $phone\n');
    message.write('🏠 <b>Address:</b> $address\n');
    message.write('🏙️ <b>City:</b> $city\n');
    message.write('🏡 <b>House No:</b> $houseNumber\n\n');

    // Order Items
    message.write('🧾 <b>ORDER ITEMS</b>\n');
    for (int i = 0; i < orderItems.length; i++) {
      var item = orderItems[i];
      message.write(
        '${i + 1}. ${item['name']}\n'
        '   └─ Quantity: <b>${item['quantity']}x</b>\n'
        '   └─ Price: <b>\$${item['price']}</b>\n'
        '   └─ Category: ${item['category']}\n',
      );
      
      if (i < orderItems.length - 1) {
        message.write('   ─────────────────────\n');
      }
    }

    // Payment Details
    message.write('\n💰 <b>PAYMENT DETAILS</b>\n');
    message.write('💵 <b>Subtotal:</b> \$${totalAmount.toStringAsFixed(2)}\n');
    message.write('🚚 <b>Delivery Fee:</b> \$1.50\n');
    message.write('📊 <b>Tax (10%):</b> \$${(totalAmount * 0.1).toStringAsFixed(2)}\n');
    message.write('💳 <b>Payment Method:</b> <u>$paymentMethod</u>\n');
    message.write('📄 <b>Invoice Photo:</b> ${hasInvoicePhoto ? "✅ ATTACHED" : "❌ NOT PROVIDED"}\n\n');

    // Final Total
    double finalTotal = totalAmount + 1.50 + (totalAmount * 0.1);
    message.write('🎯 <b>FINAL TOTAL: \$${finalTotal.toStringAsFixed(2)}</b>\n\n');

    // Order Metadata
    message.write('⏰ <b>ORDER TIME</b>\n');
    message.write('🗓️ ${DateTime.now().toString()}\n\n');

    message.write('📱 <b>Order Source:</b> Food Store App\n');
    message.write('═══════════════════════════\n');

    return message.toString();
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🔗 Testing Telegram Bot connection...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/getMe'),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Connection test response status: ${response.statusCode}');
      print('📄 Connection test response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isBot = data['result']['is_bot'] ?? false;
        String firstName = data['result']['first_name'] ?? 'Unknown';
        
        print('✅ Telegram Bot connection successful!');
        print('🤖 Bot Name: $firstName');
        print('🔧 Is Bot: $isBot');
        
        return {
          'success': true, 
          'data': data,
          'botName': firstName,
          'isBot': isBot
        };
      } else {
        print('❌ Telegram Bot connection failed: ${response.body}');
        return {
          'success': false, 
          'error': 'HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('💥 Telegram connection error: $e');
      return {
        'success': false, 
        'error': e.toString()
      };
    }
  }

  // Additional utility method for sending simple test messages
  static Future<bool> sendTestMessage() async {
    return await sendMessage(
      '🧪 <b>TEST MESSAGE</b>\n\n'
      'This is a test message from your Flutter app.\n'
      'Time: ${DateTime.now().toString()}\n'
      'If you receive this, your Telegram bot is working correctly! 🎉'
    );
  }

  // Method to send order confirmation to customer (if you have customer's Telegram chat ID)
  static Future<bool> sendCustomerConfirmation({
    required String customerChatId,
    required String orderId,
    required double totalAmount,
    required String estimatedDeliveryTime,
  }) async {
    String message = 
      '✅ <b>ORDER CONFIRMED!</b>\n\n'
      'Thank you for your order!\n\n'
      '📦 <b>Order ID:</b> $orderId\n'
      '💰 <b>Total Amount:</b> \$${totalAmount.toStringAsFixed(2)}\n'
      '⏰ <b>Estimated Delivery:</b> $estimatedDeliveryTime\n\n'
      'We will notify you when your order is on the way!';

    return await sendMessageToChat(customerChatId, message);
  }

  // Generic method to send message to specific chat ID
  static Future<bool> sendMessageToChat(String chatId, String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendMessage'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending message to chat $chatId: $e');
      return false;
    }
  }

  // Method to check if bot can send messages to the chat
  static Future<bool> canSendToChat() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sendChatAction'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'action': 'typing',
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Cannot send to chat: $e');
      return false;
    }
  }
}