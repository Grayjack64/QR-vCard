import 'dart:html' as html;
import 'dart:js' as js;

/// Web implementation for saving an image to the device (download)
Future<void> saveImageToDevicePlatformSpecific(
  List<int> imageBytes, {
  required Function(String) onSuccess,
  required Function(String) onError,
}) async {
  try {
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor =
        html.AnchorElement(href: url)
          ..setAttribute('download', 'qr_code.png')
          ..click();
    html.Url.revokeObjectUrl(url);

    onSuccess('QR Code downloaded');
  } catch (e) {
    onError('Error downloading QR Code: $e');
  }
}

/// Web implementation for sharing an image
Future<void> shareImagePlatformSpecific(
  List<int> imageBytes, {
  String text = '',
  required Function(String) onError,
}) async {
  try {
    // Create a blob from the image bytes
    final blob = html.Blob([imageBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Check if Web Share API is available
    final navigatorObject = js.context['navigator'];
    if (navigatorObject != null &&
        navigatorObject.hasProperty('share') &&
        navigatorObject.hasProperty('canShare')) {
      // Create a file to share
      final shareData = js.JsObject.jsify({
        'files': [
          js.JsObject.fromBrowserObject(
            js.context['File'].callMethod('new', [
              [blob],
              'qr_code.png',
              {'type': 'image/png'},
            ]),
          ),
        ],
        'title': 'QR Code',
        'text': text,
      });

      // Check if we can share files
      final canShare = navigatorObject.callMethod('canShare', [shareData]);
      if (canShare == true) {
        navigatorObject.callMethod('share', [shareData]);
      } else {
        // Fallback to download if sharing not supported
        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute('download', 'qr_code.png')
              ..click();
      }
    } else {
      // Fallback to download if Web Share API not available
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute('download', 'qr_code.png')
            ..click();
    }

    html.Url.revokeObjectUrl(url);
  } catch (e) {
    onError('Error sharing QR Code: $e');
  }
}
