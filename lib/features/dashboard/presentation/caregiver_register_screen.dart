import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/auth_service.dart';

class CaregiverRegisterScreen extends StatefulWidget {
  const CaregiverRegisterScreen({
    super.key,
    required this.token,
    required this.user,
  });

  final String token;
  final Map<String, dynamic> user;

  @override
  State<CaregiverRegisterScreen> createState() => _CaregiverRegisterScreenState();
}

class _CaregiverRegisterScreenState extends State<CaregiverRegisterScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _imagePicker = ImagePicker();

  final Set<String> _selectedSkills = <String>{};
  final List<String> _skillOptions = const [
    'CPR',
    'Trauma Care',
    'ACLS',
    'First Aid',
  ];

  File? _governmentIdFile;
  File? _paramedicCertificateFile;
  File? _trainingCertificatesFile;
  File? _hospitalIdCardFile;
  File? _profilePhotoFile;

  String _selectedCertificationType = 'EMT / Paramedic';
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _verificationStatus = 'NOT_SUBMITTED';
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.user['fullName']?.toString() ?? '';
    _phoneController.text = widget.user['phone']?.toString() ?? '';
    _emailController.text = widget.user['email']?.toString() ?? '';
    _loadExistingRequest();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRequest() async {
    final result = await AuthService.fetchMyCaregiverVerificationRequest(
      token: widget.token,
    );

    if (!mounted) return;

    if (result.success && result.data != null) {
      final data = result.data!;
      _fullNameController.text = data['fullName']?.toString() ?? _fullNameController.text;
      _phoneController.text = data['phone']?.toString() ?? _phoneController.text;
      _emailController.text = data['email']?.toString() ?? _emailController.text;
      _experienceController.text = data['yearsExperience']?.toString() ?? '';
      _selectedCertificationType =
          data['certificationType']?.toString() ?? _selectedCertificationType;
      _hospitalController.text = data['hospitalName']?.toString() ?? '';
      _selectedSkills
        ..clear()
        ..addAll(
          (data['skills'] as List<dynamic>? ?? <dynamic>[])
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty),
        );
      _verificationStatus = data['verificationStatus']?.toString() ?? 'PENDING';
      _statusMessage = _verificationStatus == 'REJECTED'
          ? (data['rejectionReason']?.toString() ?? '')
          : 'Submitted to admin for review';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<File?> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        allowMultiple: false,
        withData: false,
      );

      final path = result?.files.single.path;
      if (path == null) {
        return null;
      }
      return File(path);
    } catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open files. ${error.toString()}')),
      );
      return null;
    }
  }

  Future<void> _captureProfilePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _profilePhotoFile = File(pickedFile.path);
    });
  }

  Future<void> _assignFile(ValueSetter<File> assigner) async {
    final file = await _pickDocument();
    if (file == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
      );
      return;
    }

    setState(() {
      assigner(file);
    });
  }

  Future<void> _submit() async {
    if (_fullNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _experienceController.text.trim().isEmpty ||
        _hospitalController.text.trim().isEmpty ||
        _selectedSkills.isEmpty ||
        _governmentIdFile == null ||
        _paramedicCertificateFile == null ||
        _trainingCertificatesFile == null ||
        _hospitalIdCardFile == null ||
        _profilePhotoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete every required field and upload.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await AuthService.submitCaregiverVerificationRequest(
      token: widget.token,
      fullName: _fullNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      yearsExperience: _experienceController.text,
      certificationType: _selectedCertificationType,
      skills: _selectedSkills.toList(),
      hospitalName: _hospitalController.text,
      governmentId: _governmentIdFile!,
      paramedicCertificate: _paramedicCertificateFile!,
      trainingCertificates: _trainingCertificatesFile!,
      hospitalIdCard: _hospitalIdCardFile!,
      profilePhoto: _profilePhotoFile!,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.success) {
      setState(() {
        _verificationStatus = 'PENDING';
        _statusMessage = 'Your documents were sent to admin for verification.';
      });
    }
  }

  Color _statusColor() {
    switch (_verificationStatus) {
      case 'APPROVED':
        return const Color(0xFF2E7D32);
      case 'REJECTED':
        return const Color(0xFFC73535);
      case 'PENDING':
        return const Color(0xFF0D4C9A);
      default:
        return const Color(0xFF6B7A90);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF143A66),
        elevation: 0,
        title: const Text(
          'Caregiver Portal',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFF5D8D8),
              child: Text(
                (_fullNameController.text.isNotEmpty
                        ? _fullNameController.text.substring(0, 1)
                        : 'C')
                    .toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF9C2D2D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              decoration: const BoxDecoration(
                color: Color(0xFF0D4C9A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F6CB8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'CAREGIVER PORTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Join as Emergency\nCaregiver',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Select your professional credential to begin providing life-saving assistance in your local community.',
                    style: TextStyle(
                      color: Color(0xFFD9E8FF),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D4C9A).withValues(alpha: 0.08),
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
                      const Icon(Icons.chevron_left_rounded, color: Color(0xFF6B7A90)),
                      const Spacer(),
                      Column(
                        children: [
                          const Text(
                            'Step 2',
                            style: TextStyle(
                              color: Color(0xFF143A66),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Verification',
                            style: TextStyle(
                              color: Color(0xFF6B7A90),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: 0.55,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE4EBF5),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0D4C9A),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Experience & Credentials'),
                  const SizedBox(height: 14),
                  _Label(text: 'Full Name'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(hintText: 'Your full name'),
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Phone Number'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: 'Your phone number'),
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Email ID'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Years of Experience'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '5'),
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Certification Type'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCertificationType,
                    items: const [
                      DropdownMenuItem(
                        value: 'EMT / Paramedic',
                        child: Text('EMT / Paramedic'),
                      ),
                      DropdownMenuItem(
                        value: 'Registered Nurse',
                        child: Text('Registered Nurse'),
                      ),
                      DropdownMenuItem(
                        value: 'Trauma Technician',
                        child: Text('Trauma Technician'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCertificationType = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Skills'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _skillOptions
                        .map(
                          (skill) => FilterChip(
                            label: Text(skill),
                            selected: _selectedSkills.contains(skill),
                            selectedColor: const Color(0xFFD9E8FF),
                            checkmarkColor: const Color(0xFF0D4C9A),
                            backgroundColor: const Color(0xFFF5F7FB),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSkills.add(skill);
                                } else {
                                  _selectedSkills.remove(skill);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(title: 'Required Documents'),
                  const SizedBox(height: 12),
                  _UploadCard(
                    title: 'Government ID',
                    subtitle: 'Passport or National ID',
                    file: _governmentIdFile,
                    onUpload: () => _assignFile((file) => _governmentIdFile = file),
                  ),
                  const SizedBox(height: 10),
                  _UploadCard(
                    title: 'Paramedic Certificate',
                    subtitle: 'Verified professional certificate.',
                    file: _paramedicCertificateFile,
                    onUpload: () => _assignFile((file) => _paramedicCertificateFile = file),
                  ),
                  const SizedBox(height: 10),
                  _UploadCard(
                    title: 'Training Certificates',
                    subtitle: 'Verified professional certificate.',
                    file: _trainingCertificatesFile,
                    onUpload: () => _assignFile((file) => _trainingCertificatesFile = file),
                  ),
                  const SizedBox(height: 14),
                  _Label(text: 'Organization'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _hospitalController,
                    decoration: const InputDecoration(hintText: 'Hospital Name'),
                  ),
                  const SizedBox(height: 10),
                  _UploadCard(
                    title: 'Hospital ID Card',
                    subtitle: 'Official staff credential.',
                    file: _hospitalIdCardFile,
                    onUpload: () => _assignFile((file) => _hospitalIdCardFile = file),
                  ),
                  const SizedBox(height: 10),
                  _ProfilePhotoCard(
                    file: _profilePhotoFile,
                    onCapture: _captureProfilePhoto,
                  ),
                  const SizedBox(height: 16),
                  if (_verificationStatus != 'NOT_SUBMITTED')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: $_verificationStatus',
                            style: TextStyle(
                              color: _statusColor(),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_statusMessage.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                color: Color(0xFF4E6078),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D4C9A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit for Verification',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: const Color(0xFF0D4C9A),
        unselectedItemColor: const Color(0xFF94A0B4),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Caregivers'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF143A66),
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF52607A),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.title,
    required this.subtitle,
    required this.file,
    required this.onUpload,
  });

  final String title;
  final String subtitle;
  final File? file;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E1EF)),
        color: const Color(0xFFFBFDFF),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0D4C9A)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF143A66),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7A8AA0),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_rounded, size: 16),
              label: Text(file == null ? 'Upload' : _fileName(file!)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D4C9A),
                side: const BorderSide(color: Color(0xFFBFD0E8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  const _ProfilePhotoCard({
    required this.file,
    required this.onCapture,
  });

  final File? file;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E1EF)),
        color: const Color(0xFFF4FAFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Live Profile Photo',
            style: TextStyle(
              color: Color(0xFF143A66),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Clear, recent headshot.',
            style: TextStyle(
              color: Color(0xFF7A8AA0),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          if (file != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                file!,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onCapture,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(file == null ? 'Open Camera' : 'Retake Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D4C9A),
              side: const BorderSide(color: Color(0xFFBFD0E8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
