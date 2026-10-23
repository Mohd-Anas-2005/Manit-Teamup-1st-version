import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile? initialProfile;
  final VoidCallback? onSaved;

  const EditProfileScreen({
    super.key,
    this.initialProfile,
    this.onSaved,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _collegeController;
  late TextEditingController _scholarController;
  late TextEditingController _branchController;
  late TextEditingController _yearController;
  late TextEditingController _bioController;
  late TextEditingController _skillsController;
  late TextEditingController _whatsappController;

  MembershipStatus _membershipStatus = MembershipStatus.manitStudent;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController = TextEditingController(text: p?.fullName ?? '');
    _membershipStatus = p?.membershipStatus ?? MembershipStatus.manitStudent;
    _collegeController = TextEditingController(
      text: p?.collegeName.isNotEmpty == true ? p!.collegeName : 'MANIT Bhopal',
    );
    _scholarController = TextEditingController(text: p?.scholarNumber ?? '');
    _branchController = TextEditingController(text: p?.branch ?? 'Computer Science & Engineering');
    _yearController = TextEditingController(text: p?.academicYear ?? '1st Year B.Tech');
    _bioController = TextEditingController(text: p?.bio ?? '');
    _skillsController = TextEditingController(text: p?.skills.join(', ') ?? '');
    _whatsappController = TextEditingController(text: p?.whatsappNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _scholarController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _onMembershipCategoryChanged(MembershipStatus? status) {
    if (status == null) return;
    setState(() {
      _membershipStatus = status;
      if (status == MembershipStatus.manitStudent) {
        _collegeController.text = 'MANIT Bhopal';
      } else if (status == MembershipStatus.nonStudent) {
        _collegeController.text = 'Not a student';
      } else if (_collegeController.text == 'MANIT Bhopal' || _collegeController.text == 'Not a student') {
        _collegeController.clear();
      }
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Supabase backend is not configured yet. Set SUPABASE_URL and SUPABASE_ANON_KEY to save profile changes to the cloud.';
      });
      return;
    }

    try {
      final user = supabase.currentUser;
      if (user != null) {
        final skillsList = _skillsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        final college = _membershipStatus == MembershipStatus.manitStudent
            ? 'MANIT Bhopal'
            : (_membershipStatus == MembershipStatus.nonStudent
                ? 'Not a student'
                : _collegeController.text.trim());

        // Note: Never send membership_verification_status or is_manit_verified
        // Ordinary profile editing interface cannot assign verification status
        final updated = UserProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: _nameController.text.trim(),
          avatarUrl: widget.initialProfile?.avatarUrl,
          collegeName: college,
          membershipStatus: _membershipStatus,
          scholarNumber: _scholarController.text.trim().isEmpty ? null : _scholarController.text.trim(),
          branch: _branchController.text.trim(),
          academicYear: _yearController.text.trim(),
          bio: _bioController.text.trim(),
          skills: skillsList,
          interests: widget.initialProfile?.interests ?? const [],
          githubUrl: widget.initialProfile?.githubUrl,
          linkedinUrl: widget.initialProfile?.linkedinUrl,
          portfolioUrl: widget.initialProfile?.portfolioUrl,
          whatsappNumber: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
          isProfilePublic: widget.initialProfile?.isProfilePublic ?? true,
          allowWhatsAppDirect: widget.initialProfile?.allowWhatsAppDirect ?? true,
        );

        // Update profile in database using safe payload omitting verification status
        await supabase.client!.from('profiles').upsert(updated.toUpdateJson());

        if (mounted) {
          widget.onSaved?.call();
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOtherCollege = _membershipStatus == MembershipStatus.otherCollege;

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        title: const Text('Edit Scholar Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coralSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 13, color: AppColors.coralLight),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Information security notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.charcoalSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.charcoalBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.cyanLight, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Institutional verification cannot be self-assigned. Verified Scholar status is granted only via authorized verification workflows.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                ),
                const SizedBox(height: 20),

                // College Membership Category
                Text('College Membership Category', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<MembershipStatus>(
                  initialValue: _membershipStatus,
                  dropdownColor: AppColors.charcoalSurfaceElevated,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Membership Type',
                    prefixIcon: Icon(Icons.school_outlined, color: AppColors.textMuted),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: MembershipStatus.manitStudent,
                      child: Text('MANIT Student'),
                    ),
                    DropdownMenuItem(
                      value: MembershipStatus.otherCollege,
                      child: Text('Student from another college'),
                    ),
                    DropdownMenuItem(
                      value: MembershipStatus.nonStudent,
                      child: Text('Not currently a student'),
                    ),
                  ],
                  onChanged: _onMembershipCategoryChanged,
                ),
                const SizedBox(height: 16),

                // College Name Input (shown if other college)
                if (isOtherCollege) ...[
                  TextFormField(
                    controller: _collegeController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'College / Institute Name',
                      hintText: 'e.g. IIT Bombay, NIT Trichy, VIT Bhopal',
                      prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) {
                      if (_membershipStatus == MembershipStatus.otherCollege &&
                          (v == null || v.trim().isEmpty)) {
                        return 'Please enter your college name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                if (_membershipStatus == MembershipStatus.manitStudent) ...[
                  TextFormField(
                    controller: _scholarController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Scholar / Roll Number (11 digits)',
                      hintText: 'e.g. 21111204001',
                    ),
                    validator: (v) {
                      final clean = v?.trim() ?? '';
                      if (clean.isNotEmpty && (clean.length != 11 || !RegExp(r'^\d{11}$').hasMatch(clean))) {
                        return 'Scholar number must be exactly 11 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _branchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Department / Branch'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _yearController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Academic Year'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _skillsController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Technical Skills (comma separated)',
                    hintText: 'Flutter, Python, React, UI/UX, TensorFlow',
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Bio / About You'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Contact Number (Private)',
                    hintText: '+91 9876543210',
                  ),
                ),
                const SizedBox(height: 28),

                AppButton(
                  label: 'Save Profile Changes',
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
