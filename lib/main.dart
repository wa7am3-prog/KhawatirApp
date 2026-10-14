import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const KhawatirApp());
}

class KhawatirApp extends StatelessWidget {
  const KhawatirApp({Key? key}) : super(key: key);

  @override
    Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تطبيق الخواطر',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
