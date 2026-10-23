import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/team.dart';
import '../services/team_repository.dart';

/// Screen allowing authorized team owners to modify team broadcast details.
class EditTeamScreen extends StatefulWidget {
  final Team team;
  final ValueChanged<Team>? onUpdated;

  const EditTeamScreen({
    super.key,
    required this.team,
    this.onUpdated,
  });

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _eventController;
  late final TextEditingController _descController;
  late final TextEditingController _skillsController;
  late final TextEditingController _whatsappController;

  late ProjectCategory _selectedCategory;
  late int _maxTeamSize;
  late bool _isRecruiting;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final t = widget.team;
    _titleController = TextEditingController(text: t.title);
    _eventController = TextEditingController(text: t.eventName);
    _descController = TextEditingController(text: t.description);
    _skillsController = TextEditingController(text: t.requiredSkills.join(', '));
    _whatsappController = TextEditingController(text: t.whatsappGroupLink ?? '');
    _selectedCategory = t.projectCategory;
    _maxTeamSize = t.maxTeamSize;
    _isRecruiting = t.isRecruiting;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _eventController.dispose();
    _descController.dispose();
    _skillsController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final skillsList = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final res = await TeamRepository.instance.updateTeam(
      teamId: widget.team.id,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      eventName: _eventController.text.trim(),
      requiredSkills: skillsList,
      maxTeamSize: _maxTeamSize,
      isRecruiting: _isRecruiting,
      whatsappGroupLink: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.isSuccess && res.data != null) {
      widget.onUpdated?.call(res.data!);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team details updated successfully!'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.errorMessage ?? 'Failed to update team details.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        title: const Text('Edit Team Broadcast'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 36.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Update Team Information', style: AppTypography.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Changes will reflect immediately in the campus discovery feed.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coralSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.coralLight.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 13, color: AppColors.coralLight),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Team / Project Title',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter team title' : null,
                ),
                const SizedBox(height: 16),

                // Target Event
                TextFormField(
                  controller: _eventController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Target Event or Hackathon',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter event name' : null,
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<ProjectCategory>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppColors.charcoalSurfaceElevated,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project Category',
                  ),
                  items: ProjectCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Max Members
                Row(
                  children: [
                    const Text('Total Roster Size: ', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: _maxTeamSize,
                      dropdownColor: AppColors.charcoalSurfaceElevated,
                      style: const TextStyle(color: AppColors.textPrimary),
                      items: [2, 3, 4, 5, 6, 8, 10].map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text('$size members'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _maxTeamSize = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Recruitment Status Toggle Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open for Recruitment', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                    _isRecruiting
                        ? 'Applications accepted from campus scholars.'
                        : 'Recruitment is paused or closed.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  value: _isRecruiting,
                  activeThumbColor: AppColors.statusSuccess,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _isRecruiting = val);
                  },
                ),
                const SizedBox(height: 16),

                // Required Skills
                TextFormField(
                  controller: _skillsController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Required Skills (comma separated)',
                    hintText: 'Flutter, Python, FastApi, UI/UX',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Specify required skills' : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description & Vision',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 16),

                // WhatsApp
                TextFormField(
                  controller: _whatsappController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Group Link (Optional)',
                    prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 28),

                AppButton(
                  label: 'Save Changes',
                  isLoading: _isLoading,
                  variant: AppButtonVariant.primaryGradient,
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
