import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myhomework/view/fromHomepage/homepage_page1.dart';

class adminLogin extends StatelessWidget {
  const adminLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFD70C6D),
        fontFamily: GoogleFonts.notoSansKhmer().fontFamily,
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Form Key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Admin credentials
  final String _adminEmail = "chanchav@gmail.admin";
  final String _adminPassword = "chav12345";

  // 🔹 ចូលគណនី
  Future<void> signIn() async {
    if (_isLoading) return;

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Check if it's admin login first
      if (email == _adminEmail && password == _adminPassword) {
        try {
          // Try to sign in with admin credentials
          final credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Save admin login data to Firestore
          await _saveAdminLoginData(credential.user!);

          // Navigate to AdminPanel
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminPanel()),
            );
          }
          return;
        } catch (e) {
          // If admin user doesn't exist, create it
          if (e is FirebaseAuthException && e.code == 'user-not-found') {
            await _createAdminAccount();
            return;
          }
          rethrow;
        }
      }

      // Regular user login
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user name from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      _showSuccessSnackBar("ចូលគណនីដោយជោគជ័យ!");

      // Wait a bit before navigation
      await Future.delayed(const Duration(milliseconds: 1500));

      // Navigate to homepage
      if (mounted) {
        onPressed:
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomepageProduct(
                isAdmin: false, // ✅ កំណត់ជា false សម្រាប់អ្នកប្រើប្រាស់ធម្មតា
                userEmail: 'user@example.com', // ✅ ប្រើអ៊ីមែលពិតប្រាកដ
                userName: 'អ្នកប្រើប្រាស់', // ✅ ប្រើឈ្មោះពិតប្រាកដ
              ),
            ),
          );
        };
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "ចូលគណនីមិនជោគជ័យ";

      if (e.code == 'user-not-found') {
        errorMessage = "រកមិនឃើញគណនីនេះ";
        // 🔄 Auto switch to signup if user not found
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              showLogin = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "គណនីមិនមានទេ។ សូមបង្កើតគណនីថ្មី!",
                        style: GoogleFonts.notoSansKhmer(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
          }
        });
      } else if (e.code == 'wrong-password') {
        errorMessage = "ពាក្យសម្ងាត់មិនត្រឹមត្រូវ";
      } else if (e.code == 'invalid-email') {
        errorMessage = "អ៊ីមែលមិនត្រឹមត្រូវ";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "សូមរង់ចាំមួយភ្លែត";
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar("មានបញ្ហាមិនបាននិយាយ: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔹 បង្កើតគណនីអ្នកគ្រប់គ្រង
  Future<void> _createAdminAccount() async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );

      // Save admin data to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': 'Admin',
        'email': _adminEmail,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save admin login data
      await _saveAdminLoginData(credential.user!);

      _showSuccessSnackBar("បង្កើតគណនីអ្នកគ្រប់គ្រងដោយជោគជ័យ!");

      // Navigate to AdminPanel
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AdminPanel()),
        );
      }
    } catch (e) {
      _showErrorSnackBar("មិនអាចបង្កើតគណនីអ្នកគ្រប់គ្រង: $e");
    }
  }

  // 🔹 ចុះឈ្មោះគណនីថ្មី
  Future<void> signUp() async {
    if (_isLoading) return;

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSuccessSnackBar("បង្កើតគណនីដោយជោគជ័យ!");

      // Wait a bit before navigation
      await Future.delayed(const Duration(milliseconds: 1500));

      // Navigate to homepage
      if (mounted) {
        onPressed:
        () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomepageProduct(
                isAdmin: false, // ✅ កំណត់ជា false សម្រាប់អ្នកប្រើប្រាស់ធម្មតា
                userEmail: 'user@example.com', // ✅ ប្រើអ៊ីមែលពិតប្រាកដ
                userName: 'អ្នកប្រើប្រាស់', // ✅ ប្រើឈ្មោះពិតប្រាកដ
              ),
            ),
          );
        };
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "បង្កើតគណនីមិនជោគជ័យ";

      if (e.code == 'email-already-in-use') {
        errorMessage = "អ៊ីមែលនេះមានរួចហើយ";
      } else if (e.code == 'weak-password') {
        errorMessage = "ពាក្យសម្ងាត់ខ្សោយពេក";
      } else if (e.code == 'invalid-email') {
        errorMessage = "អ៊ីមែលមិនត្រឹមត្រូវ";
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar("មានបញ្ហាក្នុងការបង្កើតគណនី: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 🔹 រក្សាទុកទិន្នន័យចូលរបស់អ្នកគ្រប់គ្រង
  Future<void> _saveAdminLoginData(User user) async {
    await _firestore.collection('admin_logins').doc(user.uid).set({
      'email': user.email,
      'loggedInAt': FieldValue.serverTimestamp(),
      'role': 'admin',
    });
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: GoogleFonts.notoSansKhmer(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.notoSansKhmer(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  // Validation functions
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'សូមបញ្ចូលអ៊ីមែល';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'អ៊ីមែលមិនត្រឹមត្រូវ';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'សូមបញ្ចូលពាក្យសម្ងាត់';
    }
    if (value.length < 6) {
      return 'ពាក្យសម្ងាត់ត្រូវតែ ៦ តួឡើង';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'សូមបញ្ចូលឈ្មោះ';
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _switchToSignup() {
    setState(() {
      showLogin = false;
    });
  }

  void _switchToLogin() {
    setState(() {
      showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD70C6D), Color(0xFF6A0572)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Section
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFD70C6D),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Welcome Text
                  Text(
                    "សូមស្វាគមន៍",
                    style: GoogleFonts.notoSansKhmer(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "មកកាន់ហាងអាហាររបស់យើង",
                    style: GoogleFonts.notoSansKhmer(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Tab Selection
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isLoading) {
                                _switchToLogin();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: showLogin
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: showLogin
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  "ចូលគណនី",
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: showLogin
                                        ? const Color(0xFFD70C6D)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isLoading) {
                                _switchToSignup();
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !showLogin
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: !showLogin
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  "បង្កើតគណនី",
                                  style: GoogleFonts.notoSansKhmer(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: !showLogin
                                        ? const Color(0xFFD70C6D)
                                        : Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Forms
                  Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: showLogin ? _buildLoginForm() : _buildSignupForm(),
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

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      children: [
        _buildTextField(
          controller: _emailController,
          hintText: "អាសយដ្ឋានអ៊ីមែល",
          icon: Icons.email_rounded,
          validator: _validateEmail,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _passwordController,
          hintText: "ពាក្យសម្ងាត់",
        ),
        const SizedBox(height: 25),

        // Forgot Password Text
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "សូមទាក់ទងអ្នកគ្រប់គ្រងរបស់យើង",
                    style: GoogleFonts.notoSansKhmer(color: Colors.white),
                  ),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text(
              "ភ្លេចពាក្យសម្ងាត់?",
              style: GoogleFonts.notoSansKhmer(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 25),

        _buildAuthButton(text: "ចូលគណនី", onPressed: signIn),

        const SizedBox(height: 20),

        // Admin Login Hint
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            "អ្នកគ្រប់គ្រង: $_adminEmail / $_adminPassword",
            style: GoogleFonts.notoSansKhmer(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),

        // Switch to Signup Text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "មិនទាន់មានគណនី? ",
              style: GoogleFonts.notoSansKhmer(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: _switchToSignup,
              child: Text(
                "បង្កើតគណនីថ្មី",
                style: GoogleFonts.notoSansKhmer(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      key: const ValueKey('signup_form'),
      children: [
        _buildTextField(
          controller: _nameController,
          hintText: "ឈ្មោះពេញ",
          icon: Icons.person_rounded,
          validator: _validateName,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _emailController,
          hintText: "អាសយដ្ឋានអ៊ីមែល",
          icon: Icons.email_rounded,
          validator: _validateEmail,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _passwordController,
          hintText: "បង្កើតពាក្យសម្ងាត់",
        ),
        const SizedBox(height: 25),

        // Password requirement hint
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "ពាក្យសម្ងាត់ត្រូវតែមានយ៉ាងហោចណាស់ ៦ តួអក្សរ",
            style: GoogleFonts.notoSansKhmer(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 25),
        _buildAuthButton(text: "បង្កើតគណនី", onPressed: signUp),

        const SizedBox(height: 20),

        // Switch to Login Text
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "មានគណនីរួចហើយ? ",
              style: GoogleFonts.notoSansKhmer(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: _switchToLogin,
              child: Text(
                "ចូលគណនី",
                style: GoogleFonts.notoSansKhmer(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.notoSansKhmer(
          color: const Color(0xFF2D3748),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.notoSansKhmer(
            color: Colors.grey[600],
            fontSize: 15,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD70C6D), width: 2),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD70C6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFD70C6D), size: 20),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: validator,
        enabled: !_isLoading,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: _obscurePassword,
        style: GoogleFonts.notoSansKhmer(
          color: const Color(0xFF2D3748),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.notoSansKhmer(
            color: Colors.grey[600],
            fontSize: 15,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD70C6D), width: 2),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD70C6D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Color(0xFFD70C6D),
              size: 20,
            ),
          ),
          suffixIcon: IconButton(
            onPressed: _togglePasswordVisibility,
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: const Color(0xFFD70C6D),
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        validator: _validatePassword,
        enabled: !_isLoading,
      ),
    );
  }

  Widget _buildAuthButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFD70C6D),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFD70C6D),
                ),
              )
            : Text(
                text,
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel", style: GoogleFonts.notoSansKhmer()),
        backgroundColor: const Color(0xFFD70C6D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 80,
              color: Color(0xFFD70C6D),
            ),
            const SizedBox(height: 20),
            Text(
              "សូមស្វាគមន៍អ្នកគ្រប់គ្រង",
              style: GoogleFonts.notoSansKhmer(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "អ្នកបានចូលជាអ្នកគ្រប់គ្រង",
              style: GoogleFonts.notoSansKhmer(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
