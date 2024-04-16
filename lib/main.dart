import 'dart:io';

import 'package:flutter/material.dart';
import 'package:test_webrtc_mobile/src/pages/home_page.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides(); // used for development only
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light().copyWith(
          background: const Color(0xffFEFBF6),
          primary: const Color(0xffBF3131),
        ),
      ),
      home: const HomePage(),
    );
  }
}

// class only used for development only
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
