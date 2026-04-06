import 'package:flutter/material.dart';

class TransparencyReportScreen extends StatelessWidget {
  const TransparencyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transparency Report'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B2D52),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Transparency reports will appear here soon.',
          style: TextStyle(
            color: Color(0xFF52607A),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
