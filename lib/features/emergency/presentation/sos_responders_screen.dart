import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SosRespondersScreen extends StatefulWidget {
  const SosRespondersScreen({
    super.key,
    required this.user,
    required this.emergencyData,
  });

  final Map<String, dynamic> user;
  final Map<String, dynamic> emergencyData;

  @override
  State<SosRespondersScreen> createState() => _SosRespondersScreenState();
}

class _SosRespondersScreenState extends State<SosRespondersScreen> {
  String _selectedRole = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _caregivers {
    final source = (widget.emergencyData['nearbyCaregivers'] as List<dynamic>?) ??
        (widget.emergencyData['caregivers'] as List<dynamic>?) ??
        <dynamic>[];

    final query = _searchController.text.trim().toLowerCase();
    final all = source.whereType<Map<String, dynamic>>().toList();

    if (query.isEmpty) {
      return all;
    }

    return all.where((caregiver) {
      final name = caregiver['fullName']?.toString().toLowerCase() ?? '';
      return name.contains(query);
    }).toList();
  }

  String _distanceLabel(Map<String, dynamic> caregiver) {
    final distanceMeters = caregiver['distanceMeters'];
    final meters = (distanceMeters is num) ? distanceMeters.toDouble() : null;
    if (meters != null) {
      if (meters < 1000) return '${meters.round()} m away';
      return '${(meters / 1000).toStringAsFixed(1)} km away';
    }

    final km = caregiver['distanceKm'];
    if (km is num) return '${km.toStringAsFixed(1)} km away';
    return 'Nearby responder';
  }

  Future<void> _openDialer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open phone dialer.')),
    );
  }

  Future<void> _openSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open messages app.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.user['fullName']?.toString().trim().split(' ').firstWhere(
              (part) => part.isNotEmpty,
              orElse: () => 'User',
            ) ??
        'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF7F9FC),
        foregroundColor: const Color(0xFF12335B),
        title: const Text(
          'Help is on the way',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'EMERGENCY SOS ACTIVE',
                  style: TextStyle(
                    color: Color(0xFFC73535),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Help is on the way',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF12335B),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your live coordinates have been shared with nearby verified caregivers for immediate assistance, $userName.',
              style: const TextStyle(
                color: Color(0xFF60708A),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F6EC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA9D9B7)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS signal and live location shared',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Health profile shared with responders.')),
                );
              },
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Share Health Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF12335B),
                side: const BorderSide(color: Color(0xFFD6DFEC)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, specialty, or hospital...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD8E2F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0D4C9A)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['All', 'Doctor', 'Nurse', 'EMT']
                  .map(
                    (role) => ChoiceChip(
                      label: Text(role),
                      selected: _selectedRole == role,
                      onSelected: (_) => setState(() => _selectedRole = role),
                      selectedColor: const Color(0xFF0D4C9A),
                      labelStyle: TextStyle(
                        color: _selectedRole == role ? Colors.white : const Color(0xFF355070),
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD8E2F0)),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 18),
            Text(
              'Nearby Verified Responders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF12335B),
                  ),
            ),
            const SizedBox(height: 12),
            ..._caregivers.map((caregiver) => _ResponderCard(
                  caregiver: caregiver,
                  distanceLabel: _distanceLabel(caregiver),
                  onCall: () => _openDialer(caregiver['phone']?.toString() ?? ''),
                  onMessage: () => _openSms(caregiver['phone']?.toString() ?? ''),
                )),
            if (_caregivers.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0E7F2)),
                ),
                child: const Text(
                  'We are still searching for nearby verified responders.',
                  style: TextStyle(color: Color(0xFF60708A)),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing nearby responders...')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF12335B),
                side: const BorderSide(color: Color(0xFFD6DFEC)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Loading More Responders'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponderCard extends StatelessWidget {
  const _ResponderCard({
    required this.caregiver,
    required this.distanceLabel,
    required this.onMessage,
    required this.onCall,
  });

  final Map<String, dynamic> caregiver;
  final String distanceLabel;
  final VoidCallback onMessage;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final name = caregiver['fullName']?.toString().trim().isNotEmpty == true
        ? caregiver['fullName'].toString().trim()
        : 'Responder';
    final initial = name.substring(0, 1).toUpperCase();
    final rating = caregiver['rating']?.toString() ?? '5.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D4C9A).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE8F1FF),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF0D4C9A),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Color(0xFF12335B),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Verified Caregiver',
                      style: TextStyle(
                        color: Color(0xFFC85353),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.star_rounded, color: Color(0xFFF5A623), size: 18),
              const SizedBox(width: 2),
              Text(
                rating,
                style: const TextStyle(
                  color: Color(0xFF12335B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF7A8AA0)),
              const SizedBox(width: 4),
              Text(
                distanceLabel,
                style: const TextStyle(
                  color: Color(0xFF7A8AA0),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF2E7D32)),
              const SizedBox(width: 4),
              const Text(
                'Available now',
                style: TextStyle(
                  color: Color(0xFF7A8AA0),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D4C9A),
                    side: const BorderSide(color: Color(0xFFD6DFEC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D4C9A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
