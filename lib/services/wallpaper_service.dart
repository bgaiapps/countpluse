import 'dart:io';

import 'package:flutter/foundation.dart';
import 'app_state.dart';

class WallpaperService {
  static Future<void> init() async {
    wallpaperPathNotifier.value = null;
    _log('init wallpaper=none');
  }

  static Future<void> setWallpaper(String? path) async {
    final previousPath = wallpaperPathNotifier.value;
    if (path == null || path.isEmpty) {
      wallpaperPathNotifier.value = null;
      _log('cleared wallpaper');
    } else {
      wallpaperPathNotifier.value = path;
      _log('updated wallpaper path=$path exists=${File(path).existsSync()}');
    }
    await _deleteIfReplaced(previousPath, nextPath: path);
  }

  static void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[wallpaper] $message');
  }

  static Future<void> _deleteIfReplaced(
    String? previousPath, {
    String? nextPath,
  }) async {
    if (previousPath == null ||
        previousPath.isEmpty ||
        previousPath == nextPath) {
      return;
    }
    final file = File(previousPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
