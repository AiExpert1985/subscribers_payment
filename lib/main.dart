import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'payments/payments_screen.dart';

void main() {
  // Initialize FFI database factory for desktop (Windows/macOS/Linux)
  databaseFactory = databaseFactoryFfi;
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام التسديدات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      // Force RTL for Arabic-only interface
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const PaymentsScreen(),
    );
  }
}
