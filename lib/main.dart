import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myhomework/controller/payproduct.dart';
import 'package:myhomework/view/fromHomepage/homepage_page1.dart';
import 'package:myhomework/view/from_login/home1_fromlogin.dart';
import 'package:myhomework/view/from_login/home2_fromlogin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(),
      home: HomepageProduct(),
    );
  }
}
