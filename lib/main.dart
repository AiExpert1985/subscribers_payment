import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'accounts/accounts_screen.dart';
import 'payments/payments_screen.dart';
import 'reports/reports_screen.dart';

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
      home: const AppShell(),
    );
  }
}

/// App-level navigation shell with bottom navigation bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // IndexedStack preserves state between tabs
  final _screens = const [PaymentsScreen(), AccountsScreen(), ReportsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.payment),
            label: 'التسديدات',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'المشتركين'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            label: 'التقارير',
          ),
        ],
      ),
    );
  }
}
