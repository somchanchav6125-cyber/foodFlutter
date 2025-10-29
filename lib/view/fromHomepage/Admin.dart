import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myhomework/view/fromHomepage/homepage_page1.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({Key? key}) : super(key: key);

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final List<String> _collections = [
    'ហាងលក់ម្ហូបពេញនិយម',
    'ចុះថ្លៃ 20%',
    'បាយសាច់មាន់',
    'ភេសជ្ជៈ',
    'ភីហ្សា',
    'ជ្រើសរើសអាហារនីមួយៗ',
  ];

  String _selectedCollection = 'ហាងលក់ម្ហូបពេញនិយម';
  List<QueryDocumentSnapshot> _products = [];
  bool _isLoading = true;

  // 🎨 Beautiful Color Theme
  static const Color primaryRed = Color(0xFFD70C6D);
  static const Color lightRed = Color(0xFFFFEBEE);
  static const Color darkRed = Color(0xFFD70C6D);
  static const Color backgroundColor = Color(
    0xFFF8F9FA,
  ); // 🆕 Beautiful white background
  static const Color cardColor = Color(0xFFFFFFFF); // 🆕 Pure white cards
  static const Color textPrimary = Color(0xFF2D3748); // 🆕 Better text color

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_selectedCollection)
          .get();
      setState(() {
        _products = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteProduct(String docId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Icon
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightRed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: primaryRed,
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'បញ្ជាក់ការលុប',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: darkRed,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'តើអ្នកពិតជាចង់លុបផលិតផលនេះមែនទេ?',
                  style: GoogleFonts.notoSansKhmer(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'បោះបង់',
                          style: GoogleFonts.notoSansKhmer(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          try {
                            await FirebaseFirestore.instance
                                .collection(_selectedCollection)
                                .doc(docId)
                                .delete();
                            _loadProducts();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'បានលុបផលិតផលដោយជោគជ័យ ✅',
                                        style: GoogleFonts.notoSansKhmer(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.white),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'មានបញ្ហាក្នុងការលុបផលិតផល ❌',
                                        style: GoogleFonts.notoSansKhmer(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'លុប',
                          style: GoogleFonts.notoSansKhmer(
                            fontWeight: FontWeight.w500,
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

  void _editProduct(Map<String, dynamic> product, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditProductDialog(
          product: product,
          docId: docId,
          collection: _selectedCollection,
          onProductUpdated: _loadProducts,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // 🎨 Beautiful white background
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomepageProduct(
                    isAdmin:
                        user?.email ==
                        "chanchav@gmail.admin", // ✅ ពិនិត្យថាតើជា Admin ឬទេ
                    userEmail:
                        user?.email ??
                        'user@example.com', // ✅ ប្រើអ៊ីមែលពិត ឬតម្លៃ default
                    userName:
                        user?.displayName ??
                        'អ្នកប្រើប្រាស់', // ✅ ប្រើឈ្មោះពិត ឬតម្លៃ default
                  ),
                ),
              );
            },
          ),
        ),
        title: Text(
          'ផ្ទាំងគ្រប់គ្រងផលិតផល',
          style: GoogleFonts.notoSansKhmer(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddProductDialog(onProductAdded: _loadProducts);
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Collection Selector Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.category_rounded,
                        color: primaryRed,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'ប្រភេទផលិតផល',
                      style: GoogleFonts.notoSansKhmer(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButton<String>(
                      value: _selectedCollection,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCollection = newValue!;
                          _isLoading = true;
                          _loadProducts();
                        });
                      },
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: primaryRed,
                        size: 28,
                      ),
                      dropdownColor: cardColor,
                      items: _collections.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              value,
                              style: GoogleFonts.notoSansKhmer(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products Count and Stats
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.inventory_2_rounded,
                  'សរុប',
                  '${_products.length}',
                ),
                Container(width: 1, height: 30, color: Colors.grey[200]),
                _buildStatItem(
                  Icons.category_rounded,
                  'ប្រភេទ',
                  _selectedCollection,
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Products List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryRed,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'កំពុងទាញយកទិន្នន័យ...',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : _products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'មិនមានទិន្នន័យផលិតផលនៅឡើយទេ!',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'សូមបន្ថែមផលិតផលថ្មីដោយចុចប៊ូតុង +',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AddProductDialog(
                                  onProductAdded: _loadProducts,
                                );
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryRed,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'បន្ថែមផលិតផលថ្មី',
                                style: GoogleFonts.notoSansKhmer(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final doc = _products[index];
                      final product = doc.data() as Map<String, dynamic>;
                      return _buildProductCard(product, doc.id, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: primaryRed, size: 20),
        SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.notoSansKhmer(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value.length > 10 ? '${value.substring(0, 10)}...' : value,
          style: GoogleFonts.notoSansKhmer(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProductCard(
    Map<String, dynamic> product,
    String docId,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardColor,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: product['image'] != null && product['image'].isNotEmpty
                    ? Image.network(
                        product['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.fastfood_rounded,
                              color: primaryRed,
                              size: 30,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryRed,
                                ),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.fastfood_rounded,
                          color: primaryRed,
                          size: 30,
                        ),
                      ),
              ),
            ),
            title: Text(
              product['name'] ?? 'មិនមានឈ្មោះ',
              style: GoogleFonts.notoSansKhmer(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${product['price'] ?? 0} \$',
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                    if (product['discount'] != null &&
                        product['discount'].isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product['discount'],
                            style: GoogleFonts.notoSansKhmer(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: primaryRed,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (product['description'] != null &&
                    product['description'].isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      product['description'],
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () => _editProduct(product, docId),
                    ),
                  ),
                  // Delete Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _deleteProduct(docId),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🎨 Add Product Dialog with White Background
class AddProductDialog extends StatefulWidget {
  final VoidCallback? onProductAdded;
  const AddProductDialog({Key? key, this.onProductAdded}) : super(key: key);

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  String _selectedCollection = 'ហាងលក់ម្ហូបពេញនិយម';
  bool _isLoading = false;

  // 🎨 Colors
  static const Color primaryRed = Color(0xFFE53935);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection(_selectedCollection).add({
          'name': _nameController.text,
          'price': double.parse(_priceController.text),
          'description': _descriptionController.text,
          'image': _imageController.text,
          'discount': _discountController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });
        Navigator.pop(context);
        widget.onProductAdded?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'បន្ថែមផលិតផលដោយជោគជ័យ ✅',
                    style: GoogleFonts.notoSansKhmer(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'បញ្ហាក្នុងការបន្ថែមផលិតផល ❌',
                    style: GoogleFonts.notoSansKhmer(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: backgroundColor,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_shopping_cart_rounded,
                      color: primaryRed,
                      size: 32,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'បន្ថែមផលិតផលថ្មី',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'បំពេញព័ត៌មានផលិតផលថ្មី',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Form Fields
                _buildField(
                  'ឈ្មោះផលិតផល',
                  _nameController,
                  Icons.shopping_bag_rounded,
                ),
                _buildField(
                  'តម្លៃ (\$)',
                  _priceController,
                  Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                _buildField(
                  'ការពិពណ៌នា',
                  _descriptionController,
                  Icons.description_rounded,
                  maxLines: 2,
                ),
                _buildField(
                  'URL រូបភាព',
                  _imageController,
                  Icons.image_rounded,
                ),
                _buildField(
                  'ការបញ្ចុះតម្លៃ (%)',
                  _discountController,
                  Icons.discount_rounded,
                ),

                // Collection Dropdown
                SizedBox(height: 16),
                Text(
                  'ប្រភេទផលិតផល',
                  style: GoogleFonts.notoSansKhmer(
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCollection,
                      items:
                          [
                            'ហាងលក់ម្ហូបពេញនិយម',
                            'ចុះថ្លៃ 20%',
                            'បាយសាច់មាន់',
                            'ភេសជ្ជៈ',
                            'ភីហ្សា',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: GoogleFonts.notoSansKhmer(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCollection = newValue!;
                        });
                      },
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: primaryRed,
                      ),
                      style: GoogleFonts.notoSansKhmer(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                // Buttons
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          'បោះបង់',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'បន្ថែមផលិតផល',
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: (v) =>
                  v == null || v.isEmpty ? 'សូមបញ្ចូល $label' : null,
              decoration: InputDecoration(
                hintText: 'បញ្ចូល $label',
                hintStyle: GoogleFonts.notoSansKhmer(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(icon, color: primaryRed, size: 20),
              ),
              style: GoogleFonts.notoSansKhmer(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Edit Product Dialog with White Background
class EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final String docId;
  final String collection;
  final VoidCallback onProductUpdated;

  const EditProductDialog({
    Key? key,
    required this.product,
    required this.docId,
    required this.collection,
    required this.onProductUpdated,
  }) : super(key: key);

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageController;
  late TextEditingController _discountController;

  bool _isLoading = false;
  static const Color primaryRed = Color(0xFFE53935);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2D3748);

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing product data
    _nameController = TextEditingController(text: widget.product['name'] ?? '');
    _priceController = TextEditingController(
      text: widget.product['price']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product['description'] ?? '',
    );
    _imageController = TextEditingController(
      text: widget.product['image'] ?? '',
    );
    _discountController = TextEditingController(
      text: widget.product['discount'] ?? '',
    );
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection(widget.collection)
            .doc(widget.docId)
            .update({
              'name': _nameController.text,
              'price': double.parse(_priceController.text),
              'description': _descriptionController.text,
              'image': _imageController.text,
              'discount': _discountController.text,
              'updatedAt': FieldValue.serverTimestamp(),
            });
        Navigator.pop(context);
        widget.onProductUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'កែប្រែផលិតផលដោយជោគជ័យ ✅',
                  style: GoogleFonts.notoSansKhmer(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'បញ្ហាក្នុងការកែប្រែផលិតផល ❌',
                  style: GoogleFonts.notoSansKhmer(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: backgroundColor,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_rounded,
                      color: primaryRed,
                      size: 32,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    'កែប្រែផលិតផល',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Center(
                  child: Text(
                    'កែប្រែព័ត៌មានផលិតផល',
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Form Fields
                _buildField(
                  'ឈ្មោះផលិតផល',
                  _nameController,
                  Icons.shopping_bag_rounded,
                ),
                _buildField(
                  'តម្លៃ (\$)',
                  _priceController,
                  Icons.attach_money_rounded,
                  keyboardType: TextInputType.number,
                ),
                _buildField(
                  'ការពិពណ៌នា',
                  _descriptionController,
                  Icons.description_rounded,
                  maxLines: 2,
                ),
                _buildField(
                  'URL រូបភាព',
                  _imageController,
                  Icons.image_rounded,
                ),
                _buildField(
                  'ការបញ្ចុះតម្លៃ (%)',
                  _discountController,
                  Icons.discount_rounded,
                ),

                // Buttons
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: Text(
                          'បោះបង់',
                          style: GoogleFonts.notoSansKhmer(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'រក្សាទុក',
                                style: GoogleFonts.notoSansKhmer(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansKhmer(
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: (v) =>
                  v == null || v.isEmpty ? 'សូមបញ្ចូល $label' : null,
              decoration: InputDecoration(
                hintText: 'បញ្ចូល $label',
                hintStyle: GoogleFonts.notoSansKhmer(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Icon(icon, color: primaryRed, size: 20),
              ),
              style: GoogleFonts.notoSansKhmer(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
