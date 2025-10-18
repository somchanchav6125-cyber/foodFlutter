import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myhomework/view/from_login/home2_fromlogin.dart';

class Home1FromLogin extends StatelessWidget {
  const Home1FromLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FancyHome(),
    );
  }
}

class FancyHome extends StatefulWidget {
  const FancyHome({super.key});

  @override
  State<FancyHome> createState() => _FancyHomeState();
}

class _FancyHomeState extends State<FancyHome> {
  String displayedText = "";
  int currentIndex = 0;
  late Timer timer;

  double scale = 0.0;
  double opacity = 0.0;

  final String fullText =
      "Restaurants are convenient, offer a variety of tasty food, and provide a nice place to relax and socialize.";

  @override
  void initState() {
    super.initState();

    // Animation for logo
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        scale = 1.0;
        opacity = 1.0;
      });
    });

    // Typing text effect
    timer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (currentIndex < fullText.length) {
        setState(() {
          displayedText += fullText[currentIndex];
          currentIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Home2FromLogin()),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // ✅ FIX: gradient must have at least 2 colors
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD70C6D),
              Color(0xFF6A0572), // added a darker pink shade
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(seconds: 2),
                opacity: opacity,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: scale),
                  duration: const Duration(seconds: 2),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      width: 210,
                      height: 210,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  displayedText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    letterSpacing: 1.2,
                    height: 1.6,
                    shadows: [
                      Shadow(
                        blurRadius: 8,
                        color: Color.fromARGB(66, 255, 255, 255),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
