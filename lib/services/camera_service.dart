import 'dart:io';
import 'cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final _picker = ImagePicker();

  Future<File?> takePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (image == null) return null;
    return File(image.path);
  }

  /// Uploads [file] to Cloudinary and returns the image URL.
  Future<String> uploadProof({
    required String uid,
    required String taskId,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    return CloudinaryService.uploadProof(bytes, '$uid-$taskId.jpg');
  }
}