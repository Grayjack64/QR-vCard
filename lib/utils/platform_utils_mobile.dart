import 'dart:io';
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

/// Mobile implementation for saving an image to the device (gallery)
Future<void> saveImageToDevicePlatformSpecific(
  List<int> imageBytes, {
  required Function(String) onSuccess,
  required Function(String) onError,
}) async {
  try {
    // Request permission
    final status = await Permission.storage.request();
    if (status.isGranted) {
      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(imageBytes),
      );

      if (result['isSuccess']) {
        onSuccess('QR Code saved to gallery');
      } else {
        onError('Failed to save QR Code');
      }
    } else {
      onError('Permission denied');
    }
  } catch (e) {
    onError('Error saving QR Code: $e');
  }
}

/// Mobile implementation for sharing an image
Future<void> shareImagePlatformSpecific(
  List<int> imageBytes, {
  String text = '',
  required Function(String) onError,
}) async {
  try {
    // Create a temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/qr_code.png');
    await file.writeAsBytes(imageBytes);

    // Share the file
    await Share.shareXFiles([XFile(file.path)], text: text);
  } catch (e) {
    onError('Error sharing QR Code: $e');
  }
}
