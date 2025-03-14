import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';

import '../models/vcard_model.dart';
import '../services/database_helper.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _hasScanned = false;
  VCardModel? _scannedVCard;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (barcode.rawValue != null &&
          barcode.rawValue!.contains('BEGIN:VCARD') &&
          barcode.rawValue!.contains('END:VCARD')) {
        final vcard = VCardModel.fromVCardString(barcode.rawValue!);

        // Save to database
        await DatabaseHelper.instance.insertContact(vcard);

        setState(() {
          _hasScanned = true;
          _scannedVCard = vcard;
        });

        _scannerController.stop();
        break;
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _scannedVCard = null;
    });
    _scannerController.start();
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
      ),
      body: _hasScanned && _scannedVCard != null
          ? _buildContactDetails()
          : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
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
