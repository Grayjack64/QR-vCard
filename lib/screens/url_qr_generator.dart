import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../utils/platform_utils.dart';

class URLQRGenerator extends StatefulWidget {
  const URLQRGenerator({super.key});

  @override
  State<URLQRGenerator> createState() => _URLQRGeneratorState();
}

class _URLQRGeneratorState extends State<URLQRGenerator> {
  final _qrKey = GlobalKey();
  final _urlController = TextEditingController();
  String _currentUrl = '';
  bool _hasGeneratedQR = false;

  @override
  void initState() {
    super.initState();
    // Default to a placeholder URL
    _urlController.text = 'https://your-app-url.web.app';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    if (_urlController.text.isNotEmpty) {
      setState(() {
        _currentUrl = _urlController.text;
        _hasGeneratedQR = true;
      });
    }
  }

  Future<void> _saveQRToGallery() async {
    try {
      // Capture QR code as image
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Use platform-specific implementation
      await saveImageToDevice(
        pngBytes,
        onSuccess: (message) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _shareQRCode() async {
    try {
      // Capture QR code as image
      final boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Use platform-specific implementation
      await shareImage(
        pngBytes,
        text:
            'Scan this QR code to access the Prosper Show QR vCard app: $_currentUrl',
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App URL QR Generator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generate a QR code for your app URL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use this to create a QR code that attendees can scan to access your app',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // URL input field
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'App URL',
                  hintText: 'https://your-app-url.web.app',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),

              // Generate button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _generateQRCode,
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Generate QR Code'),
                ),
              ),

              if (_hasGeneratedQR) ...[
                const SizedBox(height: 32),

                // QR Code display
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: RepaintBoundary(
                      key: _qrKey,
                      child: QrImageView(
                        data: _currentUrl,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Text(
                    _currentUrl,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveQRToGallery,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _shareQRCode,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  'Instructions for Attendees:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Scan this QR code with your phone camera\n'
                  '2. Tap the link that appears\n'
                  '3. For the best experience, add to home screen:\n'
                  '   • iOS: Tap share icon, then "Add to Home Screen"\n'
                  '   • Android: Tap menu, then "Add to Home Screen"',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
