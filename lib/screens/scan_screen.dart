import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:js_util' as js_util;
import 'dart:js' as js;
import 'dart:html' as html;

import '../models/vcard_model.dart';
import '../services/database_helper.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController? _scannerController;
  bool _hasScanned = false;
  VCardModel? _scannedVCard;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _isWeb = _checkIfWeb();

    if (_isWeb) {
      _setupWebQRScanner();
    } else {
      _initializeScanner();
    }
  }

  bool _checkIfWeb() {
    try {
      return identical(0, 0.0);
    } catch (e) {
      return false;
    }
  }

  void _setupWebQRScanner() {
    // Register callback for QR code detection
    js.context['onQRCodeDetected'] = (String qrData) {
      _processQRData(qrData);
    };

    setState(() {
      _isLoading = false;
    });
  }

  void _startWebQRScanner() {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = js.context.callMethod('startQRScanner');

      if (result == false) {
        setState(() {
          _errorMessage = 'Failed to start camera';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeScanner() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Wait a bit for camera permissions to be established
      await Future.delayed(const Duration(seconds: 1));

      // Initialize scanner with specific settings
      _scannerController = MobileScannerController(
        facing: CameraFacing.back,
        formats: const [BarcodeFormat.qrCode],
        // For web, use lower resolution to improve performance
        detectionSpeed: DetectionSpeed.normal,
        returnImage: false,
      );

      // Try to start the scanner
      await _scannerController!.start();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Camera error: ${e.toString()}';
        print('Scanner initialization error: $e');
      });
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null &&
          barcode.rawValue!.contains('BEGIN:VCARD') &&
          barcode.rawValue!.contains('END:VCARD')) {
        _processQRData(barcode.rawValue!);
        break;
      }
    }
  }

  void _processQRData(String qrData) async {
    if (_hasScanned) return;

    if (qrData.contains('BEGIN:VCARD') && qrData.contains('END:VCARD')) {
      final vcard = VCardModel.fromVCardString(qrData);

      // Save to database
      await DatabaseHelper.instance.insertContact(vcard);

      setState(() {
        _hasScanned = true;
        _scannedVCard = vcard;
      });

      _scannerController?.stop();
    }
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _scannedVCard = null;
      _errorMessage = '';
      _isLoading = true;
    });

    if (_isWeb) {
      _setupWebQRScanner();
    } else {
      _initializeScanner();
    }
  }

  void _shareContact() {
    if (_scannedVCard != null) {
      Share.share(
        _scannedVCard!.toVCardString(),
        subject: 'Contact Information',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetScanner,
            tooltip: 'Reset Camera',
          ),
        ],
      ),
      body: _hasScanned && _scannedVCard != null
          ? _buildContactDetails()
          : _buildScannerWithState(),
    );
  }

  Widget _buildScannerWithState() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    } else if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _resetScanner,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    } else {
      return _buildScanner();
    }
  }

  Widget _buildScanner() {
    if (_isWeb) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Web QR Scanner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Click the button below to start scanning',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _startWebQRScanner,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Camera'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                setState(() {
                  _errorMessage = error.errorDetails?.message ?? 'Camera error';
                });
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _resetScanner,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Position the QR code within the frame to scan',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildContactDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Center(
              child: Text(
                'Contact Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),

            // Contact details
            _buildContactField(Icons.person, 'Name', _scannedVCard!.name),
            _buildContactField(
              Icons.business,
              'Company',
              _scannedVCard!.company,
            ),

            if (_scannedVCard!.title.isNotEmpty)
              _buildContactField(Icons.work, 'Title', _scannedVCard!.title),

            if (_scannedVCard!.email.isNotEmpty)
              _buildContactField(Icons.email, 'Email', _scannedVCard!.email),

            if (_scannedVCard!.phone.isNotEmpty)
              _buildContactField(Icons.phone, 'Phone', _scannedVCard!.phone),

            if (_scannedVCard!.website.isNotEmpty)
              _buildContactField(
                Icons.language,
                'Website',
                _scannedVCard!.website,
              ),

            if (_scannedVCard!.address.isNotEmpty)
              _buildContactField(
                Icons.location_on,
                'Address',
                _scannedVCard!.address,
              ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _shareContact,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Another'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactField(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
