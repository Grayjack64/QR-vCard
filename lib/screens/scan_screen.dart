import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:js' as js;
import 'dart:async';

import '../models/vcard_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _hasPermission = false;
  bool _isLoading = true;
  String _errorMessage = '';
  MobileScannerController? _scannerController;
  bool _showErrorIcon = false;
  bool _isWeb = false;
  bool _webScannerInitialized = false;

  // More reliable browser detection function that works on all devices
  bool isBrowser() {
    return kIsWeb;
  }

  @override
  void initState() {
    super.initState();

    // Always use web UI in browser environments (including mobile browsers)
    _isWeb = isBrowser();

    if (_isWeb) {
      // Register JavaScript callback for QR code detection
      js.context['onQRCodeDetected'] = (String qrData) {
        try {
          final vcard = VCardModel.fromVCardString(qrData);
          // Navigate back with the vCard data
          Navigator.pop(context, vcard);
        } catch (e) {
          setState(() {
            _errorMessage = 'Invalid vCard QR Code: $e';
          });
          print('Error parsing vCard: $e');
        }
      };

      // Web-specific initialization
      _initializeWebScanner();
    } else {
      // Mobile-specific initialization
      _requestCameraPermission();
    }
  }

  // Web scanner initialization
  void _initializeWebScanner() {
    setState(() {
      _isLoading = false;
      _hasPermission = true;
    });

    // Web scanner will be initialized on button press
  }

  // Start web scanner when the button is pressed
  void _startWebScanner() {
    if (_webScannerInitialized) return;

    try {
      // Call JavaScript function to start the scanner
      js.context.callMethod('startQRScanner');
      setState(() {
        _webScannerInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start web scanner: $e';
        _showErrorIcon = true;
      });
      print('Error starting web scanner: $e');
    }
  }

  // Request camera permission for mobile devices
  Future<void> _requestCameraPermission() async {
    try {
      _scannerController = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      setState(() {
        _hasPermission = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
        _errorMessage = 'Camera permission denied or camera unavailable: $e';
        _showErrorIcon = true;
      });
      print('Camera error: $e');
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        try {
          final vcard = VCardModel.fromVCardString(code);

          // Navigate back with the vCard data
          Navigator.pop(context, vcard);
          return;
        } catch (e) {
          setState(() {
            _errorMessage = 'Invalid vCard QR Code: $e';
          });
          print('Error parsing vCard: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: Center(
        child: _isLoading ? CircularProgressIndicator() : _renderContent(),
      ),
    );
  }

  Widget _renderContent() {
    if (_isWeb) {
      // Web platform - show start scanner button
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Web QR Scanner',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          if (!_webScannerInitialized)
            ElevatedButton(
              onPressed: _startWebScanner,
              child: Text('Start Camera'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
          if (_webScannerInitialized)
            Text('Camera active - point at a QR code',
                style: TextStyle(color: Colors.green)),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    } else {
      // Mobile platform
      if (!_hasPermission) {
        // Show camera permission UI
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Camera access is required to scan QR codes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              child: Text('Grant Camera Permission'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      }

      // Show scanner
      return Stack(
        alignment: Alignment.center,
        children: [
          _scannerController != null
              ? MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                )
              : Container(),
          if (_showErrorIcon)
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 80,
            ),
          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }
}
