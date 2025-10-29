import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myhomework/view/fromHomepage/homepage_page1.dart';

class Home2FromLogin extends StatelessWidget {
  const Home2FromLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFD70C6D),
        fontFamily: GoogleFonts.notoSansKhmer().fontFamily,
        useMaterial3: true,
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

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 🔹 បង្កើតគណនីថ្មី
  Future<void> signUp() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await credential.user?.updateDisplayName(nameController.text.trim());

      await _firestore.collection('datalogin').doc(credential.user!.uid).set({
        'email': emailController.text.trim(),
        'name': nameController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'userType': 'regular',
        'uid': credential.user!.uid,
      });

      print(
        ' សរសេរទិន្នន័យទៅ Firestore ដោយជោគជ័យ: ${nameController.text.trim()}',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.celebration, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "🎉 បង្កើតគណនីដោយជោគជ័យ!",
                style: GoogleFonts.notoSansKhmer(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF00C853),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.all(20),
        ),
      );

      nameController.clear();
      setState(() => showLogin = true);
    } on FirebaseAuthException catch (e) {
      String errorMessage = "មានបញ្ហាក្នុងការបង្កើតគណនី";

      if (e.code == 'email-already-in-use') {
        errorMessage = "📧 អ៊ីមែលនេះមានរួចហើយ";
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => showLogin = true);
        });
      } else if (e.code == 'weak-password') {
        errorMessage = "🔒 ពាក្យសម្ងាត់ខ្សោយពេក";
      } else if (e.code == 'invalid-email') {
        errorMessage = "❌ អ៊ីមែលមិនត្រឹមត្រូវ";
      } else if (e.code == 'network-request-failed') {
        errorMessage = "📡 បញ្ហាការតភ្ជាប់អ៊ីនធឺណិត";
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar("⚠️ មានបញ្ហាមិនបាននិយាយ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔹 ចូលគណនី
  Future<void> signIn() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      if (email == "chanchav@gmail.admin" && password == "chav12345") {
        print('Admin login successful - bypassing Firebase');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "👑 ចូលជាអ្នកគ្រប់គ្រងដោយជោគជ័យ!",
                  style: GoogleFonts.notoSansKhmer(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF7B1FA2),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: EdgeInsets.all(20),
          ),
        );

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomepageProduct(
                isAdmin: true,
                userEmail: email,
                userName: "Admin",
              ),
            ),
          );
        }
        return;
      }

      // 🔹 Firebase login សម្រាប់អ្នកប្រើប្រាស់ធម្មតា
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('ចូលគណនីដោយជោគជ័យ: ${credential.user!.email}');

      final userDoc = await _firestore
          .collection('datalogin')
          .doc(credential.user!.uid)
          .get();

      String userName = "User"; // តម្លៃ default

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        userName =
            userData['name']?.toString().trim() ??
            credential.user?.displayName?.trim() ??
            "User";

        print(' ទាញយកឈ្មោះដោយជោគជ័យ: $userName');
        print(' Firestore Document Data: ${userDoc.data()}');
      } else {
        print('⚠️ មិនមានទិន្នន័យក្នុង Firestore');
        userName =
            credential.user?.displayName?.trim() ??
            credential.user?.email?.split('@').first ??
            "User";
      }

      // កត់ត្រាការចូលគណនី
      await _firestore.collection('user_logins').doc(credential.user!.uid).set({
        'last_login': FieldValue.serverTimestamp(),
        'email': email,
        'name': userName,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                " ចូលគណនីដោយជោគជ័យ!",
                style: GoogleFonts.notoSansKhmer(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF00C853),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.all(20),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        // បោះពុម្ពសម្រាប់ត្រួតពិនិត្យ
        print('🎯 ព័ត៌មានអ្នកប្រើប្រាស់:');
        print('   - ឈ្មោះ: $userName');
        print('   - អ៊ីមែល: $email');
        print('   - UID: ${credential.user!.uid}');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomepageProduct(
              isAdmin: false,
              userEmail: email,
              userName: userName,
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "ចូលគណនីមិនជោគជ័យ";

      if (e.code == 'user-not-found') {
        errorMessage = "🔍 រកមិនឃើញគណនីនេះ";
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) setState(() => showLogin = false);
        });
      } else if (e.code == 'wrong-password') {
        errorMessage = "🔒 ពាក្យសម្ងាត់មិនត្រឹមត្រូវ";
      } else if (e.code == 'invalid-email') {
        errorMessage = "❌ អ៊ីមែលមិនត្រឹមត្រូវ";
      } else if (e.code == 'user-disabled') {
        errorMessage = "🚫 គណនីនេះត្រូវបានបិទ";
      } else if (e.code == 'network-request-failed') {
        errorMessage = "📡 បញ្ហាការតភ្ជាប់អ៊ីនធឺណិត";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "⏰ ការព្យាយាមច្រើនពេក，សូមរង់ចាំមួយភ្លែត";
      }

      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar("⚠️ មានបញ្ហាមិនបាននិយាយ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: GoogleFonts.notoSansKhmer(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFFD32F2F),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.all(20),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'សូមបញ្ចូលអ៊ីមែល';

    final String trimmedValue = value.trim();

    if (trimmedValue == "chanchav@gmail.admin") {
      return null;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmedValue)) {
      return 'អ៊ីមែលមិនត្រឹមត្រូវ';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'សូមបញ្ចូលពាក្យសម្ងាត់';
    if (value.length < 6) return 'ពាក្យសម្ងាត់ត្រូវតែ ៦ តួឡើង';
    return null;
  }

  String? _validateName(String? value) {
    if (!showLogin && (value == null || value.isEmpty)) {
      return 'សូមបញ្ចូលឈ្មោះ';
    }
    return null;
  }

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _switchToSignup() => setState(() => showLogin = false);
  void _switchToLogin() => setState(() => showLogin = true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD70C6D), Color(0xFF6A0572), Color(0xFF2E1A47)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.6, 1.0],
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
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(70),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(70),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFD70C6D), Color(0xFF6A0572)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(70),
                          ),
                          child: Icon(
                            Icons.restaurant,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Welcome Text
                  Text(
                    "សូមស្វាគមន៍",
                    style: GoogleFonts.notoSansKhmer(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "មកកាន់ហាងអាហាររបស់យើងខ្ញុំ",
                    style: GoogleFonts.notoSansKhmer(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  _tabSwitcher(),

                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
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

  Widget _tabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _switchToLogin,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: showLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: showLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
                      color: showLogin ? Color(0xFFD70C6D) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _isLoading ? null : _switchToSignup,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !showLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: !showLogin
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
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
                      color: !showLogin ? Color(0xFFD70C6D) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      children: [
        _buildTextField(
          controller: emailController,
          hintText: "អាសយដ្ឋានអ៊ីមែល",
          icon: Icons.email_rounded,
          validator: _validateEmail,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: passwordController,
          hintText: "ពាក្យសម្ងាត់",
        ),
        const SizedBox(height: 30),
        _buildAuthButton(text: "ចូលគណនី", onPressed: signIn),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      key: const ValueKey('signup_form'),
      children: [
        _buildTextField(
          controller: nameController,
          hintText: "ឈ្មោះពេញ",
          icon: Icons.person,
          validator: _validateName,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: emailController,
          hintText: "អាសយដ្ឋានអ៊ីមែល",
          icon: Icons.email,
          validator: _validateEmail,
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: passwordController,
          hintText: "បង្កើតពាក្យសម្ងាត់",
        ),
        const SizedBox(height: 30),
        _buildAuthButton(text: "បង្កើតគណនី", onPressed: signUp),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.notoSansKhmer(
          color: Color(0xFF2D3748),
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
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Color(0xFFD70C6D), width: 2),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            child: Icon(icon, color: Color(0xFFD70C6D), size: 22),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: _obscurePassword,
        style: GoogleFonts.notoSansKhmer(
          color: Color(0xFF2D3748),
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
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Color(0xFFD70C6D), width: 2),
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            child: Icon(Icons.lock, color: Color(0xFFD70C6D), size: 22),
          ),
          suffixIcon: Container(
            margin: EdgeInsets.all(12),
            child: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Color(0xFFD70C6D),
                size: 22,
              ),
              onPressed: _togglePasswordVisibility,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
          foregroundColor: Color(0xFFD70C6D),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFD70C6D),
                ),
              )
            : Text(
                text,
                style: GoogleFonts.notoSansKhmer(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
