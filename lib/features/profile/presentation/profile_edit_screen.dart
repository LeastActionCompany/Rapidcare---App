import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({
    super.key,
    required this.token,
    required this.user,
  });

  final String token;
  final Map<String, dynamic> user;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _conditionController = TextEditingController();
  final _medicationController = TextEditingController();
  final _allergyController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _gpsActive = true;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _conditions = [];
  final List<String> _medications = [];
  final List<String> _allergies = [];
  final List<Map<String, String>> _emergencyContacts = [];

  static const List<String> _genders = ['Male', 'Female', 'Other'];
  static const List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _conditionController.dispose();
    _medicationController.dispose();
    _allergyController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await AuthService.fetchUserProfile(token: widget.token);
    final profile = result.success ? (result.user ?? widget.user) : widget.user;

    _fullNameController.text = profile['fullName']?.toString() ?? '';
    _phoneController.text = profile['phone']?.toString() ?? '';
    _ageController.text = profile['age']?.toString() ?? '';
    _selectedGender = profile['gender']?.toString();
    _selectedBloodGroup = profile['bloodGroup']?.toString();

    final physicalDetails = (profile['physicalDetails'] as Map<String, dynamic>?) ?? {};
    _heightController.text = physicalDetails['heightCm']?.toString() ?? '';
    _weightController.text = physicalDetails['weightKg']?.toString() ?? '';

    final medicalHistory = (profile['medicalHistory'] as Map<String, dynamic>?) ?? {};
    _conditions
      ..clear()
      ..addAll(
        (medicalHistory['conditions'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty),
      );
    _medications
      ..clear()
      ..addAll(
        (medicalHistory['medications'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty),
      );
    _allergies
      ..clear()
      ..addAll(
        (medicalHistory['allergies'] as List<dynamic>? ?? <dynamic>[])
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty),
      );

    final emergencyContact = (profile['emergencyContact'] as Map<String, dynamic>?) ?? {};
    final emergencyContacts = (profile['emergencyContacts'] as List<dynamic>? ?? <dynamic>[])
        .cast<Map<String, dynamic>>();
    _emergencyContacts
      ..clear()
      ..addAll(
        emergencyContacts
            .where((item) => (item['name'] ?? '').toString().isNotEmpty)
            .map(
              (item) => {
                'name': item['name']?.toString() ?? '',
                'phone': item['phone']?.toString() ?? '',
              },
            ),
      );
    if (_emergencyContacts.isEmpty &&
        (emergencyContact['name']?.toString().isNotEmpty ?? false)) {
      _emergencyContacts.add({
        'name': emergencyContact['name']?.toString() ?? '',
        'phone': emergencyContact['phone']?.toString() ?? '',
      });
    }
    _emergencyNameController.text = '';
    _emergencyPhoneController.text = '';

    final location = profile['location'] as Map<String, dynamic>?;
    _gpsActive = location != null && (location['coordinates'] as List<dynamic>? ?? []).length == 2;

    setState(() {
      _isLoading = false;
    });
  }

  void _addItem({
    required TextEditingController controller,
    required List<String> target,
  }) {
    final value = controller.text.trim();
    if (value.isEmpty) return;
    setState(() {
      target.add(value);
    });
    controller.clear();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    final payload = {
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()),
      'gender': _selectedGender,
      'bloodGroup': _selectedBloodGroup,
      'physicalDetails': {
        'heightCm': double.tryParse(_heightController.text.trim()),
        'weightKg': double.tryParse(_weightController.text.trim()),
      },
      'medicalHistory': {
        'conditions': _conditions,
        'medications': _medications,
        'allergies': _allergies,
      },
      'emergencyContact': _emergencyContacts.isNotEmpty
          ? {
              'name': _emergencyContacts.first['name'] ?? '',
              'phone': _emergencyContacts.first['phone'] ?? '',
            }
          : {
              'name': '',
              'phone': '',
            },
      'emergencyContacts': _emergencyContacts,
    };

    final result = await AuthService.updateUserProfileExtended(
      token: widget.token,
      payload: payload,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _showAddContactSheet() async {
    _emergencyNameController.text = '';
    _emergencyPhoneController.text = '';
    final created = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ContactSheet(
        title: 'Add Emergency Contact',
        nameController: _emergencyNameController,
        phoneController: _emergencyPhoneController,
      ),
    );

    if (created == null) return;
    setState(() => _emergencyContacts.add(created));
  }

  Future<void> _showEditContactSheet(int index) async {
    final existing = _emergencyContacts[index];
    _emergencyNameController.text = existing['name'] ?? '';
    _emergencyPhoneController.text = existing['phone'] ?? '';

    final updated = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ContactSheet(
        title: 'Edit Emergency Contact',
        nameController: _emergencyNameController,
        phoneController: _emergencyPhoneController,
      ),
    );

    if (updated == null) return;
    setState(() => _emergencyContacts[index] = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B2D52),
        elevation: 0,
        title: const Text(
          'Health Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your health information helps caregivers provide\nsafe and accurate assistance.',
                    style: TextStyle(color: Color(0xFF6B7A90), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Personal Details',
                    child: Column(
                      children: [
                        _LabeledField(label: 'Full Name', controller: _fullNameController),
                        const SizedBox(height: 12),
                        _LabeledField(label: 'Phone Number', controller: _phoneController),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _LabeledField(
                                label: 'Age',
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DropdownField(
                                label: 'Gender',
                                value: _selectedGender,
                                items: _genders,
                                onChanged: (value) => setState(() => _selectedGender = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _DropdownField(
                          label: 'Blood Type',
                          value: _selectedBloodGroup,
                          items: _bloodGroups,
                          onChanged: (value) => setState(() => _selectedBloodGroup = value),
                        ),
                        const SizedBox(height: 12),
                        _InlineSwitch(
                          label: 'Current Location',
                          value: _gpsActive,
                          onChanged: (value) => setState(() => _gpsActive = value),
                          subtitle: _gpsActive ? 'Location sharing active' : 'Location sharing off',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Physical Details',
                    child: Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Height (cm)',
                            controller: _heightController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Weight (kg)',
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Medical Information',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChipSection(
                          label: 'Pre-existing Conditions',
                          items: _conditions,
                          onRemove: (value) => setState(() => _conditions.remove(value)),
                        ),
                        _AddRow(
                          controller: _conditionController,
                          hintText: 'Add condition',
                          onAdd: () => _addItem(
                            controller: _conditionController,
                            target: _conditions,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChipSection(
                          label: 'Medications',
                          items: _medications,
                          onRemove: (value) => setState(() => _medications.remove(value)),
                        ),
                        _AddRow(
                          controller: _medicationController,
                          hintText: 'Add medication',
                          onAdd: () => _addItem(
                            controller: _medicationController,
                            target: _medications,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChipSection(
                          label: 'Allergies',
                          items: _allergies,
                          onRemove: (value) => setState(() => _allergies.remove(value)),
                        ),
                        _AddRow(
                          controller: _allergyController,
                          hintText: 'Add allergy',
                          onAdd: () => _addItem(
                            controller: _allergyController,
                            target: _allergies,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Emergency Contacts',
                    child: Column(
                      children: [
                        ..._emergencyContacts.asMap().entries.map((entry) {
                          final index = entry.key;
                          final contact = entry.value;
                          final name = contact['name'] ?? 'Contact';
                          final phone = contact['phone'] ?? '';
                          return _ContactRow(
                            name: name,
                            phone: phone,
                            onEdit: () => _showEditContactSheet(index),
                            onDelete: () => setState(() => _emergencyContacts.removeAt(index)),
                          );
                        }),
                        if (_emergencyContacts.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No emergency contacts added yet.',
                              style: TextStyle(color: Color(0xFF6B7A90), fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _showAddContactSheet,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0D4C9A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Add New Contact',
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
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D4C9A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                          : const Text(
                              'Save Profile',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1B2D52),
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7A90),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7A90),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

class _InlineSwitch extends StatelessWidget {
  const _InlineSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.subtitle,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7A90),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF1B2D52),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFF1B9E61),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.items,
    required this.onRemove,
  });

  final String label;
  final List<String> items;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7A90),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.isEmpty
              ? [
                  const Chip(
                    label: Text('None'),
                    backgroundColor: Color(0xFFF1F4F9),
                    labelStyle: TextStyle(color: Color(0xFF8A98AD)),
                  ),
                ]
              : items
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => onRemove(item),
                      backgroundColor: const Color(0xFFE8F1FF),
                      labelStyle: const TextStyle(color: Color(0xFF0D4C9A)),
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({
    required this.controller,
    required this.hintText,
    required this.onAdd,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF0D4C9A)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Add',
              style: TextStyle(
                color: Color(0xFF0D4C9A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.name,
    required this.phone,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final String phone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8F1FF),
            child: Text(
              initials,
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B2D52),
                  ),
                ),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7A90),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18, color: Color(0xFF0D4C9A)),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF6B7A90)),
          ),
        ],
      ),
    );
  }
}

class _ContactSheet extends StatelessWidget {
  const _ContactSheet({
    required this.title,
    required this.nameController,
    required this.phoneController,
  });

  final String title;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, padding + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2D52),
            ),
          ),
          const SizedBox(height: 12),
          _LabeledField(label: 'Full Name', controller: nameController),
          const SizedBox(height: 12),
          _LabeledField(
            label: 'Phone Number',
            controller: phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter name and phone number.')),
                  );
                  return;
                }
                Navigator.of(context).pop({'name': name, 'phone': phone});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D4C9A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Contact'),
            ),
          ),
        ],
      ),
    );
  }
}
