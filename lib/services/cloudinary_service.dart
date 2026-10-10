import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const _cloudName = 'xnoysgec';
  static const _uploadPreset = 'focuslock_proof';

  /// Uploads image bytes and returns the secure URL.
  static Future<String> uploadProof(Uint8List bytes, String filename) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: filename));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 200) {
      throw Exception('Cloudinary ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body)['secure_url'] as String;
  }
}