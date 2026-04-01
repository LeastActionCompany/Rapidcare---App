import 'package:flutter/material.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({
    super.key,
    required this.user,
  });

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final medicalHistory = (user['medicalHistory'] as Map<String, dynamic>?) ?? {};
    final conditions = (medicalHistory['conditions'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
    final physicalDetails = (user['physicalDetails'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      appBar: AppBar(
        title: const Text('RapidCare Dashboard'),
        backgroundColor: const Color(0xFF0D4C9A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0D4C9A),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user['fullName'] ?? 'User'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user['email']?.toString() ?? '',
                    style: const TextStyle(
                      color: Color(0xFFD8E7FF),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _InfoCard(
                  title: 'Profile',
                  lines: [
                    'Age: ${user['age'] ?? '-'}',
                    'Gender: ${user['gender'] ?? '-'}',
                    'Blood Group: ${user['bloodGroup'] ?? '-'}',
                  ],
                ),
                _InfoCard(
                  title: 'Physical Details',
                  lines: [
                    'Height: ${physicalDetails['heightCm'] ?? '-'} cm',
                    'Weight: ${physicalDetails['weightKg'] ?? '-'} kg',
                  ],
                ),
                _InfoCard(
                  title: 'Medical Information',
                  lines: conditions.isEmpty ? const ['No conditions added yet'] : conditions,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110D4C9A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0D4C9A),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                line,
                style: const TextStyle(
                  color: Color(0xFF465066),
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
