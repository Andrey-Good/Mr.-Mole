import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageProcessor {
  static const int modelSize = 260;

  static Future<String> cropByCoordinates({
    required String imagePath,
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Не удалось декодировать изображение');
      }

      int safeX = x.clamp(0, originalImage.width - 1);
      int safeY = y.clamp(0, originalImage.height - 1);
      int safeW = width.clamp(1, originalImage.width - safeX);
      int safeH = height.clamp(1, originalImage.height - safeY);

      img.Image croppedImage = img.copyCrop(
        originalImage,
        x: safeX,
        y: safeY,
        width: safeW,
        height: safeH,
      );

      croppedImage = img.copyResize(
        croppedImage,
        width: modelSize,
        height: modelSize,
        interpolation: img.Interpolation.cubic,
      );

      final Directory tempDir = await getTemporaryDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String croppedPath = '${tempDir.path}/cropped_$timestamp.jpg';
      final File croppedFile = File(croppedPath);

      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

      return croppedPath;
    } catch (e) {
      return imagePath;
    }
  }

  static Future<Map<String, dynamic>> getImageInfo(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        return {
          'error': 'Не удалось декодировать изображение',
          'path': imagePath
        };
      }

      return {
        'width': image.width,
        'height': image.height,
        'path': imagePath,
        'aspectRatio': image.width / image.height,
        'fileSize': await imageFile.length(),
      };
    } catch (e) {
      return {'error': e.toString(), 'path': imagePath};
    }
  }
}
