import 'dart:io';

import 'app_state.dart';

class ProfilePhotoService {
  static Future<void> init() async {
    profilePhotoPathNotifier.value = null;
  }

  static Future<void> setProfilePhoto(String? path) async {
    final previousPath = profilePhotoPathNotifier.value;
    if (path == null || path.isEmpty) {
      profilePhotoPathNotifier.value = null;
    } else {
      profilePhotoPathNotifier.value = path;
    }
    await _deleteIfReplaced(previousPath, nextPath: path);
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
