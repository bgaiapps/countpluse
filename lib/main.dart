import 'package:flutter/material.dart';
import 'screens/root_shell.dart';
import 'services/app_settings_service.dart';
import 'services/counts_service.dart';
import 'services/profile_photo_service.dart';
import 'services/session_service.dart';
import 'services/wallpaper_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettingsService.init();
  await SessionService.init();
  await CountsService.init();
  await ProfilePhotoService.init();
  await WallpaperService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Countpluse',
      theme: AppTheme.theme,
      home: const RootShell(),
    );
  }
}
