import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../emergency/presentation/sos_responders_screen.dart';
import '../../profile/presentation/profile_edit_screen.dart';
import 'caregiver_register_screen.dart';
import 'transparency_report_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({
    super.key,
    required this.user,
    this.token,
  });

  final Map<String, dynamic> user;
  final String? token;

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardFuture;
  bool _isTriggeringSos = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<Map<String, dynamic>> _loadDashboard() async {
    var token = widget.token;
    token ??= (await SharedPreferences.getInstance()).getString('auth_token');
    if (token == null || token.isEmpty) {
      return {
        'user': widget.user,
      };
    }

    final result = await AuthService.fetchUserDashboard(token: token);
    if (result.success && result.data != null) {
      return result.data!;
    }

    return {
      'user': widget.user,
    };
  }

  Future<String?> _resolveToken() async {
    if (widget.token != null && widget.token!.isNotEmpty) {
      return widget.token;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty ? token : null;
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully.')),
    );
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openProfileEdit() async {
    final token = await _resolveToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to edit your profile.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileEditScreen(
          token: token,
          user: widget.user,
        ),
      ),
    );
  }

  Future<void> _openCaregiverRegister() async {
    final token = await _resolveToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to continue.')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CaregiverRegisterScreen(
          token: token,
          user: widget.user,
        ),
      ),
    );
  }

  void _openTransparencyReport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TransparencyReportScreen()),
    );
  }

  Future<Position?> _resolveLivePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<void> _triggerSos(Map<String, dynamic> currentUser) async {
    final token = await _resolveToken();
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to trigger SOS.')),
      );
      return;
    }

    if (_isTriggeringSos) {
      return;
    }

    setState(() {
      _isTriggeringSos = true;
    });

    double? latitude;
    double? longitude;

    try {
      final livePosition = await _resolveLivePosition();
      if (livePosition != null) {
        latitude = livePosition.latitude;
        longitude = livePosition.longitude;
      }
    } catch (_) {
      latitude = null;
      longitude = null;
    }

    if (latitude == null || longitude == null) {
      final location = currentUser['location'] as Map<String, dynamic>?;
      final coordinates = (location?['coordinates'] as List<dynamic>? ?? <dynamic>[]);
      if (coordinates.length == 2) {
        longitude = (coordinates[0] as num?)?.toDouble();
        latitude = (coordinates[1] as num?)?.toDouble();
      }
    }

    if (latitude == null || longitude == null) {
      if (!mounted) return;
      setState(() {
        _isTriggeringSos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access live location for SOS.')),
      );
      return;
    }

    final result = await AuthService.triggerSos(
      token: token,
      latitude: latitude,
      longitude: longitude,
    );

    if (!mounted) return;

    setState(() {
      _isTriggeringSos = false;
    });

    if (!result.success || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SOS sent. Nearby caregivers have been alerted.')),
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SosRespondersScreen(
          user: currentUser,
          emergencyData: result.data!,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  void _openNearbyResponders(Map<String, dynamic> currentUser, Map<String, dynamic> caregiversNearby) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SosRespondersScreen(
          user: currentUser,
          emergencyData: {
            'nearbyCaregivers': caregiversNearby['caregivers'] ?? <dynamic>[],
          },
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    return '$day $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      drawer: _DashboardDrawer(
        onOpenCaregiverRegister: _openCaregiverRegister,
        onOpenTransparencyReport: _openTransparencyReport,
        onLogout: _handleLogout,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B2D52),
        title: const Text(
          'User Dashboard',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _openProfileEdit,
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE8F1FF),
              child: Text(
                (widget.user['fullName']?.toString().trim().isNotEmpty ?? false)
                    ? widget.user['fullName'].toString().trim().substring(0, 1)
                    : 'U',
                style: const TextStyle(
                  color: Color(0xFF0D4C9A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            final payload = snapshot.data ?? {};
            final user = (payload['user'] as Map<String, dynamic>?) ?? widget.user;
            final medicalProfile = (payload['medicalProfile'] as Map<String, dynamic>?) ?? {};
            final caregiversNearby = (payload['caregiversNearby'] as Map<String, dynamic>?) ?? {};
            final activityLog = (payload['activityLog'] as List<dynamic>? ?? <dynamic>[])
                .cast<Map<String, dynamic>>();

            final allergies = (medicalProfile['allergies'] as List<dynamic>? ?? <dynamic>[])
                .map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList();
            final conditions = (medicalProfile['conditions'] as List<dynamic>? ?? <dynamic>[])
                .map((item) => item.toString())
                .where((item) => item.isNotEmpty)
                .toList();

            final fullName = user['fullName']?.toString().trim();
            final userName = fullName == null || fullName.isEmpty ? 'User' : fullName.split(' ').first;
            final gpsActive = payload['gpsActive'] == true;

            final nearestKm = caregiversNearby['nearestDistanceKm'];
            final caregiversCount = caregiversNearby['count'] ?? 0;
            final caregiversList = (caregiversNearby['caregivers'] as List<dynamic>? ?? <dynamic>[])
                .cast<Map<String, dynamic>>();

            final lastCheckup = DateTime.tryParse(
              (medicalProfile['lastCheckupAt'] ?? '').toString(),
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_greeting()},',
                              style: const TextStyle(
                                color: Color(0xFF1B2D52),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Color(0xFF0D4C9A),
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Your emergency support is ready',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: gpsActive ? const Color(0xFFE9F6EF) : const Color(0xFFFCE8E8),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: gpsActive ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: gpsActive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              gpsActive ? 'GPS ACTIVE' : 'GPS OFF',
                              style: TextStyle(
                                color: gpsActive ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isTriggeringSos ? null : () => _triggerSos(user),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFFFFD5D5),
                                  Color(0xFFF06C6C),
                                  Color(0xFFCC2F2F),
                                ],
                                stops: [0.0, 0.55, 1.0],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFCC2F2F).withValues(alpha: 0.35),
                                  blurRadius: 30,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 135,
                                height: 135,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB71C1C),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: _isTriggeringSos
                                    ? const Center(
                                        child: SizedBox(
                                          width: 34,
                                          height: 34,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.emergency, color: Colors.white, size: 34),
                                          SizedBox(height: 6),
                                          Text(
                                            'SOS',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Tap in case of\nemergency',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Color(0xFFF7C9C9),
                                              fontSize: 11,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "We'll instantly connect you to\nnearby caregivers",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionCard(
                    title: 'Medical Profile',
                    trailing: _TagPill(
                      text: 'View',
                      background: const Color(0xFFE8F1FF),
                      foreground: const Color(0xFF0D4C9A),
                    ),
                    child: Column(
                      children: [
                        _ProfileRow(label: 'Blood Type', value: medicalProfile['bloodGroup'] ?? '-'),
                        _ProfileRow(
                          label: 'Allergies',
                          value: allergies.isEmpty ? 'No Allergies' : allergies.join(', '),
                        ),
                        _ProfileRow(
                          label: 'Condition',
                          value: conditions.isEmpty ? 'No Conditions' : conditions.join(', '),
                        ),
                        _ProfileRow(label: 'Age', value: medicalProfile['age'] ?? '-'),
                        _ProfileRow(
                          label: 'Last Checkup',
                          value: _formatShortDate(lastCheckup),
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Caregivers Nearby',
                    trailing: _TagPill(
                      text: '$caregiversCount available',
                      background: const Color(0xFFE9F6EF),
                      foreground: const Color(0xFF1B5E20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nearestKm == null
                              ? 'No caregivers within range'
                              : 'Closest within ${nearestKm.toString()} km',
                          style: const TextStyle(
                            color: Color(0xFF52607A),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...caregiversList.map(
                          (caregiver) {
                            final name = caregiver['fullName']?.toString().trim();
                            final safeName = (name == null || name.isEmpty) ? 'Caregiver' : name;
                            final initial = safeName.isNotEmpty ? safeName.substring(0, 1) : 'C';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFE8F1FF),
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Color(0xFF0D4C9A),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          safeName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1B2D52),
                                          ),
                                        ),
                                        Text(
                                          '${caregiver['distanceKm'] ?? '-'} km away',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7A90),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _TagPill(
                                    text: '★ ${caregiver['rating'] ?? '-'}',
                                    background: const Color(0xFFFFF3E0),
                                    foreground: const Color(0xFFEF6C00),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _openNearbyResponders(user, caregiversNearby),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0D4C9A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'View List',
                              style: TextStyle(
                                color: Color(0xFF0D4C9A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Activity Log',
                    child: Column(
                      children: activityLog.isEmpty
                          ? const [
                              Padding(
                                padding: EdgeInsets.only(top: 6, bottom: 6),
                                child: Text(
                                  'No activity yet.',
                                  style: TextStyle(color: Color(0xFF52607A)),
                                ),
                              ),
                            ]
                          : activityLog
                              .map(
                                (entry) => _ActivityRow(
                                  title: entry['title']?.toString() ?? '',
                                  subtitle: entry['subtitle']?.toString() ?? '',
                                  timestamp: _formatShortDate(
                                    DateTime.tryParse(entry['createdAt']?.toString() ?? ''),
                                  ),
                                  status: entry['status']?.toString() ?? 'INFO',
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF0D4C9A),
        unselectedItemColor: const Color(0xFF94A0B4),
        onTap: (_) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Caregivers'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardDrawer extends StatelessWidget {
  const _DashboardDrawer({
    required this.onOpenCaregiverRegister,
    required this.onOpenTransparencyReport,
    required this.onLogout,
  });

  final VoidCallback onOpenCaregiverRegister;
  final VoidCallback onOpenTransparencyReport;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DrawerItem(
                icon: Icons.dashboard_rounded,
                label: 'User Dashboard',
                isActive: true,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              _DrawerItem(
                icon: Icons.medical_services_rounded,
                label: 'Register as a caregiver',
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenCaregiverRegister();
                },
              ),
              const SizedBox(height: 12),
              _DrawerItem(
                icon: Icons.assignment_rounded,
                label: 'Transparency Report',
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenTransparencyReport();
                },
              ),
              const SizedBox(height: 12),
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'Logout',
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = isActive ? const Color(0xFF0D4C9A) : Colors.white;
    final foreground = isActive ? Colors.white : const Color(0xFF1B2D52);

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D4C9A).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1B2D52),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              ...?(trailing == null ? null : <Widget>[trailing!]),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final dynamic value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF647089),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value?.toString() ?? '-',
            style: const TextStyle(
              color: Color(0xFF1B2D52),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String timestamp;
  final String status;

  Color _statusColor() {
    switch (status) {
      case 'COMPLETED':
        return const Color(0xFF2E7D32);
      case 'ACCEPTED':
        return const Color(0xFF0D4C9A);
      case 'REJECTED':
        return const Color(0xFFD32F2F);
      case 'PENDING':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF5F6B7E);
    }
  }

  IconData _statusIcon() {
    switch (status) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'ACCEPTED':
        return Icons.local_hospital;
      case 'REJECTED':
        return Icons.cancel;
      case 'PENDING':
        return Icons.warning_amber_rounded;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(), color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2D52),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7A90),
                  ),
                ),
              ],
            ),
          ),
          Text(
            timestamp,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A0B4),
            ),
          ),
        ],
      ),
    );
  }
}
