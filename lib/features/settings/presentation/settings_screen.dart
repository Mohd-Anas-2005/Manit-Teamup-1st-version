import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/gradient_card.dart';
import '../../authentication/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSignedOut;

  const SettingsScreen({super.key, this.onSignedOut});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _allowWhatsAppDirect = true;
  bool _publicProfile = true;
  bool _isLoadingSettings = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized) return;

    final user = supabase.currentUser;
    if (user == null) return;

    setState(() => _isLoadingSettings = true);

    try {
      final res = await supabase.client!
          .from('profiles')
          .select('is_profile_public, allow_whatsapp_direct')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (res != null) {
        setState(() {
          _publicProfile = res['is_profile_public'] as bool? ?? true;
          _allowWhatsAppDirect = res['allow_whatsapp_direct'] as bool? ?? true;
          _isLoadingSettings = false;
        });
      } else {
        setState(() => _isLoadingSettings = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSettings = false);
      }
    }
  }

  Future<void> _updateSetting(String key, bool val) async {
    HapticFeedback.selectionClick();

    final supabase = SupabaseService.instance;
    if (!supabase.isInitialized || supabase.currentUser == null) return;

    try {
      await supabase.client!
          .from('profiles')
          .update({key: val})
          .eq('id', supabase.currentUser!.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update preference on server.'),
            backgroundColor: AppColors.statusError,
          ),
        );
      }
    }
  }

  Future<void> _showPrivacyPolicy() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoalSurfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.cyanLight, size: 22),
            SizedBox(width: 8),
            Text('Privacy Policy'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('MANIT TeamUp Privacy Commitments', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              const Text(
                '1. Scholar Confidentiality: Student scholar numbers, email addresses, and verification documents are never exposed on public discovery rosters.\n\n'
                '2. Selective Visibility: You maintain full control over whether your profile appears in campus discovery via the "Public Roster Visibility" toggle.\n\n'
                '3. Direct Contact Consent: Phone numbers and direct messaging links are only accessible to team leads if you opt in.\n\n'
                '4. Data Retention & Deletion: You can delete your account and associated profile data at any time directly from these settings.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSupportInfo() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoalSurfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: AppColors.electricVioletLight, size: 22),
            SizedBox(width: 8),
            Text('Support & Helpdesk'),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Campus Support Team', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'For technical inquiries, bug reports, or account support:\n\n'
              '• Email: support@teamup.manit.ac.in\n'
              '• Campus: MANIT Bhopal, Link Road No. 3, Bhopal, MP 462003\n'
              '• Developed for MANIT Student Community',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoalSurfaceElevated,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.statusError, size: 24),
            SizedBox(width: 8),
            Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? All your profile information, created teams, memberships, and pending requests will be removed from MANIT TeamUp.\n\nThis action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final res = await AuthService.instance.deleteAccount();

    if (!mounted) return;

    if (res.isSuccess) {
      widget.onSignedOut?.call();
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your account and profile have been removed.'),
          backgroundColor: AppColors.charcoalSurfaceElevated,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to delete account.'),
          backgroundColor: AppColors.statusError,
        ),
      );
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.instance.signOut();
    if (mounted) {
      widget.onSignedOut?.call();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBackendConnected = SupabaseService.instance.isInitialized;

    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 48),
        children: [
          // Backend Connectivity Status
          StaggeredEntrance(
            index: 0,
            child: GradientCard(
              child: Row(
                children: [
                  Icon(
                    isBackendConnected ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                    color: isBackendConnected ? AppColors.statusSuccess : AppColors.statusWarning,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBackendConnected ? 'Backend Connected' : 'Supabase Not Configured',
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isBackendConnected
                              ? 'Live Supabase Cloud synchronization active.'
                              : 'Set SUPABASE_URL and SUPABASE_ANON_KEY to enable live backend synchronization.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Collaboration & Privacy
          StaggeredEntrance(
            index: 1,
            child: GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Collaboration & Privacy', style: AppTypography.titleMedium),
                      if (_isLoadingSettings)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.electricVioletLight,
                    title: const Text('Direct WhatsApp Inquiries', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text(
                      'Allow interested team leads to message you via WhatsApp link',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: _allowWhatsAppDirect,
                    onChanged: (val) {
                      setState(() => _allowWhatsAppDirect = val);
                      _updateSetting('allow_whatsapp_direct', val);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.electricVioletLight,
                    title: const Text('Public Roster Visibility', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text(
                      'Show your profile on the campus teammate discovery directory',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    value: _publicProfile,
                    onChanged: (val) {
                      setState(() => _publicProfile = val);
                      _updateSetting('is_profile_public', val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Support & Policies
          StaggeredEntrance(
            index: 2,
            child: GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Legal & Support', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_outlined, color: AppColors.cyanLight),
                    title: const Text('Privacy Policy', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('Data confidentiality and campus security commitments', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _showPrivacyPolicy,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.electricVioletLight),
                    title: const Text('Help & Support', style: TextStyle(color: AppColors.textPrimary)),
                    subtitle: const Text('Technical support and feedback contact', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: _showSupportInfo,
                  ),
                ],
              ),
            ),
          ),

          // About App
          StaggeredEntrance(
            index: 3,
            child: GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MANIT TeamUp v1.0.0', style: AppTypography.titleMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Campus Collaboration & Teammate Discovery Platform for Maulana Azad National Institute of Technology (MANIT Bhopal).',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 16, color: AppColors.cyanLight),
                      SizedBox(width: 8),
                      Text(
                        'Material 3 Dark Theme System',
                        style: TextStyle(fontSize: 12, color: AppColors.textLavender),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          StaggeredEntrance(
            index: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout_rounded, color: AppColors.coralAccent),
                    label: const Text('Sign Out', style: TextStyle(color: AppColors.coralAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.coralSubtle),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _handleDeleteAccount,
                    icon: const Icon(Icons.delete_forever_rounded, color: AppColors.statusError, size: 18),
                    label: const Text(
                      'Delete Account Permanently',
                      style: TextStyle(color: AppColors.statusError, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
