import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../../core/widgets/manit_badge.dart';
import '../domain/team.dart';
import '../services/team_repository.dart';

/// Screen allowing scholars to launch and broadcast a new team roster to the campus.
class CreateTeamScreen extends StatefulWidget {
  final VoidCallback? onCreated;

  const CreateTeamScreen({super.key, this.onCreated});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _eventController = TextEditingController();
  final _descController = TextEditingController();
  final _skillsController = TextEditingController();
  final _whatsappController = TextEditingController();

  ProjectCategory _selectedCategory = ProjectCategory.hackathon;
  int _maxTeamSize = 4;
  bool _isLoading = false;
  bool _showLivePreview = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_rebuildOnPreviewChange);
    _eventController.addListener(_rebuildOnPreviewChange);
    _skillsController.addListener(_rebuildOnPreviewChange);
  }

  void _rebuildOnPreviewChange() {
    if (_showLivePreview) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_rebuildOnPreviewChange);
    _eventController.removeListener(_rebuildOnPreviewChange);
    _skillsController.removeListener(_rebuildOnPreviewChange);
    _titleController.dispose();
    _eventController.dispose();
    _descController.dispose();
    _skillsController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
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

    final res = await TeamRepository.instance.createTeam(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _selectedCategory,
      eventName: _eventController.text.trim(),
      requiredSkills: skillsList,
      maxTeamSize: _maxTeamSize,
      whatsappGroupLink: _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res.isSuccess) {
      widget.onCreated?.call();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team broadcast published to campus discovery! 🚀'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.errorMessage ?? 'Failed to publish team broadcast.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewSkills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        title: const Text('Launch New Team'),
        actions: [
          IconButton(
            icon: Icon(_showLivePreview ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            tooltip: _showLivePreview ? 'Hide Live Preview' : 'Show Live Preview',
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _showLivePreview = !_showLivePreview);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 36.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Broadcast Your Team Roster', style: AppTypography.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Post your team vision to the MANIT campus community and assemble your squad.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Live Card Preview
                AnimatedCrossFade(
                  crossFadeState: _showLivePreview
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                  firstChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.preview_rounded, size: 18, color: AppColors.cyanLight),
                              const SizedBox(width: 6),
                              Text('Discovery Card Live Preview', style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.cyanSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('PREVIEW', style: TextStyle(color: AppColors.cyanLight, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GradientCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _titleController.text.trim().isNotEmpty
                                            ? _titleController.text.trim()
                                            : 'Autonomous Campus Delivery Rover',
                                        style: AppTypography.titleLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _eventController.text.trim().isNotEmpty
                                            ? _eventController.text.trim()
                                            : 'Smart India Hackathon (SIH 2026)',
                                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                ManitBadge.vacancies(_maxTeamSize - 1),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: (previewSkills.isNotEmpty
                                      ? previewSkills
                                      : ['Flutter', 'Python', 'ROS', 'FastAPI'])
                                  .map((s) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.charcoalSurfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.charcoalBorder, width: 0.8),
                                  ),
                                  child: Text(s, style: const TextStyle(fontSize: 11, color: AppColors.cyanLight)),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                  secondChild: const SizedBox.shrink(),
                ),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coralSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.coralLight.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.coralLight, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(fontSize: 13, color: AppColors.coralLight),
                          ),
                        ),
                      ],
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
                    hintText: 'e.g. AI Smart Campus Navigator',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter team title' : null,
                ),
                const SizedBox(height: 16),

                // Event
                TextFormField(
                  controller: _eventController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Target Event or Hackathon',
                    hintText: 'e.g. Smart India Hackathon (SIH 2026), Robocon',
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

                // Max Team Size
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

                // Required Skills
                TextFormField(
                  controller: _skillsController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Required Skills (comma separated)',
                    hintText: 'Flutter, Python, FastApi, UI/UX, PyTorch',
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
                    hintText: 'Explain the problem statement, tech stack, and what teammates will build...',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter description' : null,
                ),
                const SizedBox(height: 16),

                // WhatsApp Group Link
                TextFormField(
                  controller: _whatsappController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Group Link (Optional)',
                    hintText: 'https://chat.whatsapp.com/...',
                    prefixIcon: Icon(Icons.link_rounded, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 28),

                AppButton(
                  label: 'Publish Team Broadcast',
                  isLoading: _isLoading,
                  variant: AppButtonVariant.primaryGradient,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
