import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'auth/auth_screen.dart';
import '../services/app_settings_service.dart';
import '../services/navigation_service.dart';
import '../services/app_state.dart';
import '../services/profile_photo_service.dart';
import '../services/session_service.dart';
import '../services/wallpaper_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _dailyGoal;
  int _milestoneGoal = 1000;
  late String _countTarget;
  late bool _isGuest;
  String? _wallpaperPath;
  String? _profilePhotoPath;

  @override
  void initState() {
    super.initState();
    _dailyGoal = dailyGoalNotifier.value;
    _milestoneGoal = milestoneGoalNotifier.value;
    _countTarget = countTargetNotifier.value;
    _isGuest = isGuestNotifier.value;
    _wallpaperPath = wallpaperPathNotifier.value;
    _profilePhotoPath = profilePhotoPathNotifier.value;
    isGuestNotifier.addListener(_syncGuestState);
    wallpaperPathNotifier.addListener(_syncWallpaper);
    profilePhotoPathNotifier.addListener(_syncProfilePhoto);
  }

  @override
  void dispose() {
    isGuestNotifier.removeListener(_syncGuestState);
    wallpaperPathNotifier.removeListener(_syncWallpaper);
    profilePhotoPathNotifier.removeListener(_syncProfilePhoto);
    super.dispose();
  }

  void _syncGuestState() {
    if (!mounted) return;
    setState(() => _isGuest = isGuestNotifier.value);
  }

  void _syncWallpaper() {
    if (!mounted) return;
    setState(() => _wallpaperPath = wallpaperPathNotifier.value);
  }

  void _syncProfilePhoto() {
    if (!mounted) return;
    setState(() => _profilePhotoPath = profilePhotoPathNotifier.value);
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userNameNotifier.value);
    final emailController = TextEditingController(
      text: userEmailNotifier.value,
    );
    final phoneController = TextEditingController(
      text: userPhoneNotifier.value,
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                SessionService.updateProfile(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  phone: phoneController.text.trim(),
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ext = image.path.split('.').last;
    final targetPath =
        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final saved = await File(image.path).copy(targetPath);
    await ProfilePhotoService.setProfilePhoto(saved.path);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo updated')));
  }

  Future<void> _clearProfilePhoto() async {
    await ProfilePhotoService.setProfilePhoto(null);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile photo removed')));
  }

  Future<void> _showProfilePhotoOptions() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image == null) return;
                    final dir = await getApplicationDocumentsDirectory();
                    final ext = image.path.split('.').last;
                    final targetPath =
                        '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
                    final saved = await File(image.path).copy(targetPath);
                    await ProfilePhotoService.setProfilePhoto(saved.path);
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Profile photo updated')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickProfilePhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Use default avatar'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _clearProfilePhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickWallpaper(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final ext = image.path.split('.').last;
    final targetPath =
        '${dir.path}/wallpaper_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final saved = await File(image.path).copy(targetPath);
    await WallpaperService.setWallpaper(saved.path);
    if (!mounted) return;
    setState(() => _wallpaperPath = saved.path);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wallpaper updated')));
  }

  Future<void> _showWallpaperOptions() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take photo'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickWallpaper(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickWallpaper(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _clearWallpaper() async {
    await WallpaperService.setWallpaper(null);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Wallpaper cleared')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        centerTitle: true,
        title: Text('Settings', style: AppTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
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
            icon: const Icon(
              Icons.notifications,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: AppPageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
              _isGuest
                  ? _buildGuestProfileCard(context)
                  : _buildProfileCard(context),

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
                    // What are you counting (free text input)
                    InkWell(
                      onTap: () async {
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
                                              });
                                              AppSettingsService.setCountTarget(
                                                value,
                                              );
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
                      child: _buildSettingTile(
                          icon: Icons.people,
                          title: 'What are you counting?',
                          titleStyle: AppTypography.titleSmall,
                          iconBg: AppColors.primary.withValues(alpha: 0.18),
                          iconColor: AppColors.primary,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _countTarget,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                    ),
                    _buildDivider(),
                    // Daily Goal setting (1 - 100000)
                    InkWell(
                      onTap: () => _showDailyGoalDialog(context),
                      child: _buildSettingTile(
                          icon: Icons.flag,
                          title: 'Daily Goal',
                          titleStyle: AppTypography.titleSmall,
                          iconBg: AppColors.primary.withValues(alpha: 0.18),
                          iconColor: AppColors.primary,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_dailyGoal',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.edit, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                    ),
                    _buildDivider(),
                    InkWell(
                      onTap: _showWallpaperOptions,
                      child: _buildSettingTile(
                          icon: Icons.wallpaper,
                          title: 'Home Wallpaper',
                          titleStyle: AppTypography.titleSmall,
                          iconBg: AppColors.primary.withValues(alpha: 0.18),
                          iconColor: AppColors.primary,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _wallpaperPath == null ? 'Add' : 'Change',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_wallpaperPath != null) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _clearWallpaper,
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ),
                    _buildDivider(),
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
                        content: const Text(
                          'Are you sure you want to sign out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              SessionService.clearSession();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Signed out successfully'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textPrimary,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, color: AppColors.primary),
                  label: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardBackground,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 1,
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
            ),
          ),
        ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final hasProfilePhoto =
        _profilePhotoPath != null && _profilePhotoPath!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [AppShadows.sm],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showProfilePhotoOptions,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: hasProfilePhoto
                      ? FileImage(File(_profilePhotoPath!))
                      : null,
                  child: hasProfilePhoto
                      ? null
                      : const Icon(Icons.person_outline, size: 32),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.cardBackground,
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.white),
                ),
              ],
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
            onPressed: _showEditProfileDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              foregroundColor: AppColors.primary,
              elevation: 1,
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
        boxShadow: const [AppShadows.sm],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primaryLight,
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
    int tempDaily = _dailyGoal;
    int tempMilestone = _milestoneGoal;
    final dailyController = TextEditingController(text: tempDaily.toString());
    final milestoneController = TextEditingController(
      text: tempMilestone.toString(),
    );
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Set Goals'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Daily Goal',
                      hintText: 'Enter a positive number',
                    ),
                    controller: dailyController,
                    onChanged: (v) {
                      final parsed = int.tryParse(v) ?? tempDaily;
                      tempDaily = parsed.clamp(1, 1000000);
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Milestone Goal',
                      hintText: 'Enter a positive number',
                    ),
                    controller: milestoneController,
                    onChanged: (v) {
                      final parsed = int.tryParse(v) ?? tempMilestone;
                      tempMilestone = parsed.clamp(1, 100000000);
                      setStateDialog(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final dailyVal =
                        int.tryParse(dailyController.text) ?? tempDaily;
                    final milestoneVal =
                        int.tryParse(milestoneController.text) ?? tempMilestone;
                    if (dailyVal <= 0 || milestoneVal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter positive numbers'),
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _dailyGoal = dailyVal;
                      _milestoneGoal = milestoneVal;
                    });
                    AppSettingsService.setDailyGoal(dailyVal);
                    AppSettingsService.setMilestoneGoal(milestoneVal);
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
              color: iconBg ?? AppColors.primary.withValues(alpha: 0.14),
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
