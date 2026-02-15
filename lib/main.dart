import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/providers/theme_provider.dart';
import 'package:web3_wallet/pages/landing_page.dart'; // Changed to landing page
import 'package:web3_wallet/theme/app_theme.dart';

// Firebase imports
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void testFirestore() async {
  await FirebaseFirestore.instance.collection('test').add({'web_test': DateTime.now().toIso8601String()});
  print("Data sent to Firestore from web!");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCBDiPkGKdzuvP7Kg73PYA5boccmhb9ifw",
      authDomain: "waysigning-8c0b4.firebaseapp.com",
      projectId: "waysigning-8c0b4",
      storageBucket: "waysigning-8c0b4.appspot.com",
      messagingSenderId: "873511091997",
      appId: "1:873511091997:web:33b6782c5dc3005d93abf4",
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'BORAYS Crypto Wallet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Apply a responsive font scaling
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).size.width > 600 ? 1.0 : 0.9,
          ),
          child: child!,
        );
      },
      home: const LandingPage(), // Start with the simple landing page
    );
  }
}
