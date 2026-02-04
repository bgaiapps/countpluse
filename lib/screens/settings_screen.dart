import 'package:flutter/material.dart';
import 'auth/auth_screen.dart';
import '../services/navigation_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _darkMode;
  late bool _reminders;
  late int _dailyGoal;
  late String _countTarget;
  late bool _isGuest;

  @override
  void initState() {
    super.initState();
    _darkMode = darkModeNotifier.value;
    _reminders = remindersNotifier.value;
    _dailyGoal = dailyGoalNotifier.value;
    _countTarget = countTargetNotifier.value;
    _isGuest = isGuestNotifier.value;
    isGuestNotifier.addListener(_syncGuestState);
  }

  @override
  void dispose() {
    isGuestNotifier.removeListener(_syncGuestState);
    super.dispose();
  }

  void _syncGuestState() {
    if (!mounted) return;
    setState(() => _isGuest = isGuestNotifier.value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text('Settings', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              navIndexNotifier.value = 0; // switch to Home tab
            }
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Profile',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _isGuest ? _buildGuestProfileCard(context) : _buildProfileCard(context),

              const SizedBox(height: 18),
              Text(
                'App Settings',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.dark_mode,
                      iconColor: const Color(0xFF75FB4C),
                      title: 'Dark Mode',
                      titleStyle: AppTypography.titleSmall,
                      trailing: Switch(
                        value: _darkMode,
                        onChanged: (v) {
                          setState(() => _darkMode = v);
                          darkModeNotifier.value = v;
                        },
                      ),
                    ),
                    _buildDivider(),

                    _buildSettingTile(
                      icon: Icons.event_available,
                      title: 'Daily Reminders',
                      titleStyle: AppTypography.titleSmall,
                      iconColor: const Color(0xFF75FB4C),
                      trailing: Switch(
                        value: _reminders,
                        onChanged: (v) {
                          setState(() => _reminders = v);
                          remindersNotifier.value = v;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reminders ${v ? 'enabled' : 'disabled'}',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildDivider(),
                    // What are you counting (free text input)
                    InkWell(
                      onTap: _isGuest
                          ? null
                          : () async {
                              String temp = _countTarget;
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) {
                                  final controller = TextEditingController(
                                    text: temp,
                                  );
                                  return StatefulBuilder(
                                    builder: (ctx, setStateDialog) {
                                      return AlertDialog(
                                        title: const Text(
                                          'What are you counting?',
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: controller,
                                              autofocus: true,
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Enter a name (e.g. Radha, Ram, Stitches)',
                                              ),
                                              onChanged: (v) => setStateDialog(
                                                () => temp = v,
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              final value = (controller.text)
                                                  .trim();
                                              if (value.isEmpty) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Please enter a name',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              setState(() {
                                                _countTarget = value;
                                                countTargetNotifier.value =
                                                    value;
                                              });
                                              Navigator.of(ctx).pop();
                                            },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                      child: Opacity(
                        opacity: _isGuest ? 0.5 : 1,
                        child: _buildSettingTile(
                          icon: Icons.people,
                          title: 'What are you counting?',
                          titleStyle: AppTypography.titleSmall,
                          iconColor: const Color(0xFF75FB4C),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _countTarget,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    // Daily Goal setting (1 - 100000)
                    InkWell(
                      onTap: _isGuest ? null : () => _showDailyGoalDialog(context),
                      child: Opacity(
                        opacity: _isGuest ? 0.5 : 1,
                        child: _buildSettingTile(
                          icon: Icons.flag,
                          title: 'Daily Goal',
                          titleStyle: AppTypography.titleSmall,
                          iconColor: const Color(0xFF75FB4C),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_dailyGoal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    InkWell(
                      onTap: _isGuest
                          ? null
                          : () {
                              showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Export Data'),
                                  content: const Text(
                                    'Your counting data has been exported to a CSV file.',
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                      child: Opacity(
                        opacity: _isGuest ? 0.5 : 1,
                        child: _buildSettingTile(
                          icon: Icons.ios_share,
                          title: 'Data Export',
                          iconColor: const Color(0xFF75FB4C),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              if (!_isGuest)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content:
                            const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              isGuestNotifier.value = true;
                              userNameNotifier.value = '';
                              userEmailNotifier.value = '';
                              userPhoneNotifier.value = '';
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed out successfully'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(Icons.logout, color: AppColors.danger),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Version 2.4.0 (Build 892)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/150',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: userNameNotifier,
                  builder: (context, name, _) {
                    final display = name.isEmpty ? 'User' : name;
                    return Text(display, style: AppTypography.titleMedium);
                  },
                ),
                const SizedBox(height: 4),
                ValueListenableBuilder<String>(
                  valueListenable: userEmailNotifier,
                  builder: (context, email, _) {
                    final display = email.isEmpty ? 'email@example.com' : email;
                    return Text(
                      display,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit profile coming soon'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(
                alpha: 0.1,
              ),
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestProfileCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFF2E3F37),
            child: Icon(Icons.person_outline, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest User', style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Text(
                      'Login / Register',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDailyGoalDialog(BuildContext context) {
    int temp = _dailyGoal;
    final controller = TextEditingController(text: temp.toString());
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Set Daily Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Enter a number (1 - 100000)',
                    ),
                    controller: controller,
                    onChanged: (v) {
                      final parsed = int.tryParse(v) ?? temp;
                      temp = parsed.clamp(1, 100000);
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    min: 1,
                    max: 100000,
                    divisions: 1000,
                    value: temp.toDouble().clamp(1, 100000),
                    onChanged: (v) {
                      setStateDialog(() {
                        temp = v.round();
                        controller.text = temp.toString();
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      });
                    },
                  ),
                  Text('Selected: $temp'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final newVal = (int.tryParse(controller.text) ?? temp)
                        .clamp(1, 100000);
                    setState(() => _dailyGoal = newVal);
                    dailyGoalNotifier.value = newVal;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDivider() =>
      Container(height: 1, color: AppColors.divider.withValues(alpha: 0.12));

  Widget _buildSettingTile({
    required IconData icon,
    Color? iconBg,
    required String title,
    required Widget trailing,
    TextStyle? titleStyle,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg ?? Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor ?? Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: (titleStyle ?? AppTypography.titleMedium).copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

// Bottom navigation removed; use RootShell for shared navigation.
