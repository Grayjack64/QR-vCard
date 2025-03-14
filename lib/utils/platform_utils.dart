import 'package:flutter/foundation.dart';

// Platform-specific imports
import 'platform_utils_web.dart'
    if (dart.library.io) 'platform_utils_mobile.dart';

/// Saves an image to the device (gallery on mobile, download on web)
Future<void> saveImageToDevice(
  List<int> imageBytes, {
  required Function(String) onSuccess,
  required Function(String) onError,
}) {
  return saveImageToDevicePlatformSpecific(
    imageBytes,
    onSuccess: onSuccess,
    onError: onError,
  );
}

/// Shares an image from the device
Future<void> shareImage(
  List<int> imageBytes, {
  String text = '',
  required Function(String) onError,
}) {
  return shareImagePlatformSpecific(imageBytes, text: text, onError: onError);
}

/// Checks if the current platform is web
bool get isWeb => kIsWeb;
