import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../dashboard/presentation/user_dashboard_screen.dart';

class UserOnboardingScreen extends StatefulWidget {
  const UserOnboardingScreen({
    super.key,
    required this.token,
    required this.user,
  });

  final String token;
  final Map<String, dynamic> user;

  @override
  State<UserOnboardingScreen> createState() => _UserOnboardingScreenState();
}

class _UserOnboardingScreenState extends State<UserOnboardingScreen> {
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _otherConditionController = TextEditingController();

  int _currentStep = 0;
  bool _isSaving = false;
  String? _errorText;
  String? _selectedGender;
  String? _selectedBloodGroup;
  final Set<String> _selectedConditions = <String>{};

  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  static const List<String> _commonConditions = [
    'Diabetes',
    'High Blood Pressure',
    'Asthma',
    'Heart Disease',
    'Allergy',
  ];

  @override
  void initState() {
    super.initState();
    _ageController.text = widget.user['age']?.toString() ?? '';
    _selectedGender = _safeValue(widget.user['gender']);
    _selectedBloodGroup = _safeValue(widget.user['bloodGroup']);

    final physicalDetails = (widget.user['physicalDetails'] as Map<String, dynamic>?) ?? {};
    _heightController.text = physicalDetails['heightCm']?.toString() ?? '';
    _weightController.text = physicalDetails['weightKg']?.toString() ?? '';

    final medicalHistory = (widget.user['medicalHistory'] as Map<String, dynamic>?) ?? {};
    final conditions = (medicalHistory['conditions'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty);
    _selectedConditions.addAll(conditions);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }

  String? _safeValue(dynamic value) {
    final parsed = value?.toString().trim();
    return parsed == null || parsed.isEmpty ? null : parsed;
  }

  Future<void> _continueFlow() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorText = null;
    });

    if (_currentStep == 0) {
      final age = int.tryParse(_ageController.text.trim());
      if (age == null || age <= 0) {
        setState(() {
          _errorText = 'Please enter a valid age.';
        });
        return;
      }
      if (_selectedGender == null || _selectedBloodGroup == null) {
        setState(() {
          _errorText = 'Please choose gender and blood group.';
        });
        return;
      }
    }

    if (_currentStep == 1) {
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());
      if (height == null || height <= 0 || weight == null || weight <= 0) {
        setState(() {
          _errorText = 'Please enter valid height and weight.';
        });
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep += 1;
      });
      return;
    }

    final otherCondition = _otherConditionController.text.trim();
    if (otherCondition.isNotEmpty) {
      _selectedConditions.add(otherCondition);
    }

    setState(() {
      _isSaving = true;
    });

    final result = await AuthService.updateUserProfile(
      token: widget.token,
      age: int.parse(_ageController.text.trim()),
      gender: _selectedGender!,
      bloodGroup: _selectedBloodGroup!,
      heightCm: double.tryParse(_heightController.text.trim()),
      weightKg: double.tryParse(_weightController.text.trim()),
      conditions: _selectedConditions.toList(),
      onboardingCompleted: true,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!result.success) {
      setState(() {
        _errorText = result.message;
      });
      return;
    }

    final updatedUser = <String, dynamic>{
      ...widget.user,
      ...?result.user,
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserDashboardScreen(user: updatedUser),
      ),
    );
  }

  void _skipFlow() {
    if (_currentStep < 2) {
      setState(() {
        _errorText = null;
        _currentStep += 1;
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserDashboardScreen(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildBasicCard(),
      _buildPhysicalCard(),
      _buildMedicalCard(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FD),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Complete Your RapidCare Profile',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF0D4C9A),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _stepSubtitle(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF52607A),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Container(
                        width: index == _currentStep ? 34 : 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentStep
                              ? const Color(0xFF0D4C9A)
                              : const Color(0xFFD3DEEF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: steps[_currentStep],
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _errorText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD32F2F),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _skipFlow,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            side: const BorderSide(color: Color(0xFF0D4C9A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(_currentStep == 2 ? 'Skip for Now' : 'Skip'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _continueFlow,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            backgroundColor: const Color(0xFF0D4C9A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_currentStep == 2 ? 'Finish' : 'Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicCard() {
    return _ProfileCardShell(
      key: const ValueKey('basic-step'),
      title: 'Basic Information',
      child: Column(
        children: [
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: 'Enter your age',
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _genders.contains(_selectedGender) ? _selectedGender : null,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: _genders
                .map((value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedGender = value),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _bloodGroups.contains(_selectedBloodGroup) ? _selectedBloodGroup : null,
            decoration: const InputDecoration(labelText: 'Blood Group'),
            items: _bloodGroups
                .map((value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedBloodGroup = value),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalCard() {
    return _ProfileCardShell(
      key: const ValueKey('physical-step'),
      title: 'Physical Details',
      child: Column(
        children: [
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Height',
              hintText: 'Enter height in cm',
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Weight',
              hintText: 'Enter weight in kg',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard() {
    return _ProfileCardShell(
      key: const ValueKey('medical-step'),
      title: 'Medical Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose any conditions that apply',
            style: TextStyle(
              color: Color(0xFF52607A),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _commonConditions.map((condition) {
              final selected = _selectedConditions.contains(condition);
              return FilterChip(
                label: Text(condition),
                selected: selected,
                selectedColor: const Color(0xFFD9E7FF),
                checkmarkColor: const Color(0xFF0D4C9A),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      _selectedConditions.add(condition);
                    } else {
                      _selectedConditions.remove(condition);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _otherConditionController,
            decoration: const InputDecoration(
              labelText: 'Other condition',
              hintText: 'Type another disease if needed',
            ),
          ),
        ],
      ),
    );
  }

  String _stepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Step 1 of 3: Age, gender, and blood group';
      case 1:
        return 'Step 2 of 3: Height and weight';
      default:
        return 'Step 3 of 3: Medical information';
    }
  }
}

class _ProfileCardShell extends StatelessWidget {
  const _ProfileCardShell({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140D4C9A),
            blurRadius: 28,
            offset: Offset(0, 14),
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
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}
