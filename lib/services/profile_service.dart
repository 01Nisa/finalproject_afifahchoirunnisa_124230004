import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'user_service.dart';

class ProfileService {
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();

  Future<XFile?> pickImage(ImageSource source,
      {double? maxWidth = 1024, double? maxHeight = 1024, int? imageQuality = 85}) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) return null;
      } else {
        if (Platform.isAndroid) {
          var status = await Permission.photos.request();
          if (!status.isGranted) {
            status = await Permission.storage.request();
            if (!status.isGranted) return null;
          }
        } else {
          final status = await Permission.photos.request();
          if (!status.isGranted) return null;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return image;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadProfileImage({required String userId, required String imagePath}) async {
    return await _userService.updateProfile(userId: userId, profileImageUrl: imagePath);
  }
}
