/**
 * Project Name: Framework Diagnostic Tool
 * Purpose: Application entry point and root widget configuration.
 * Author: Ruturaj Patki
 */

import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const DependencyCheckerApp());
}

class DependencyCheckerApp extends StatelessWidget {
  const DependencyCheckerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dependency Checker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
