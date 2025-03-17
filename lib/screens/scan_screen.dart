import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:js' as js;
import 'dart:async';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

import '../models/vcard_model.dart';
import '../services/database_helper.dart';

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
  bool _showFallbackOption = false;
  VCardModel? _lastScannedContact;
  bool _cameraStarting = false;

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
        print(
            'QR code detected callback with data: ${qrData.substring(0, math.min(50, qrData.length))}...');
        try {
          final vcard = VCardModel.fromVCardString(qrData);
          print('Parsed vCard: ${vcard.name}, ${vcard.company}');

          // Show the contact details popup with delay to ensure UI is ready
          Future.delayed(Duration(milliseconds: 500), () {
            _showContactPopup(vcard);
          });
        } catch (e) {
          setState(() {
            _errorMessage = 'Invalid vCard QR Code: $e';
          });
          print('Error parsing vCard: $e');
        }
      };

      // Register error callback from JavaScript
      js.context['onQRScannerError'] = (String errorMsg) {
        print('Error from QR scanner: $errorMsg');
        setState(() {
          _errorMessage = errorMsg;
          _showErrorIcon = true;
          _showFallbackOption = true;
          _isLoading = false;
          _cameraStarting = false;
        });
      };

      // Initialize and automatically start web scanner
      _initializeWebScanner();
    } else {
      // Mobile-specific initialization
      _requestCameraPermission();
    }
  }

  // Web scanner initialization
  void _initializeWebScanner() {
    print('Initializing web scanner...');

    setState(() {
      _isLoading = true;
      _cameraStarting = true;
    });

    // Inject JavaScript to setup QR scanner if needed
    js.context.callMethod('eval', [
      '''
      if (typeof window.webQRScanner === 'undefined') {
        console.log("Initializing web QR scanner...");
        window.webQRScanner = {
          scanner: null,
          start: function(callback) {
            console.log("Starting web QR scanner...");
            try {
              // Create HTML elements for camera
              var videoElement = document.getElementById('qr-video');
              if (!videoElement) {
                var scannerContainer = document.createElement('div');
                scannerContainer.id = 'scanner-container';
                scannerContainer.style.width = '100%';
                scannerContainer.style.height = '100%';
                scannerContainer.style.display = 'flex';
                scannerContainer.style.position = 'absolute';
                scannerContainer.style.top = '0';
                scannerContainer.style.left = '0';
                scannerContainer.style.backgroundColor = 'black';
                scannerContainer.style.zIndex = '999';
                
                videoElement = document.createElement('video');
                videoElement.id = 'qr-video';
                videoElement.style.width = '100%';
                videoElement.style.height = '100%';
                videoElement.style.objectFit = 'cover';
                
                scannerContainer.appendChild(videoElement);
                document.body.appendChild(scannerContainer);
              }
              
              // Start camera
              navigator.mediaDevices.getUserMedia({
                video: { facingMode: 'environment' }
              }).then(function(stream) {
                videoElement.srcObject = stream;
                videoElement.play();
                
                // Setup canvas and context for scanning
                var canvas = document.createElement('canvas');
                var context = canvas.getContext('2d');
                var scanning = true;
                
                // Scan function
                var scan = function() {
                  if (videoElement.readyState === videoElement.HAVE_ENOUGH_DATA && scanning) {
                    canvas.height = videoElement.videoHeight;
                    canvas.width = videoElement.videoWidth;
                    context.drawImage(videoElement, 0, 0, canvas.width, canvas.height);
                    
                    try {
                      // Use jsQR library if available
                      if (typeof jsQR === 'function') {
                        var imageData = context.getImageData(0, 0, canvas.width, canvas.height);
                        var code = jsQR(imageData.data, imageData.width, imageData.height);
                        
                        if (code && code.data) {
                          console.log("QR Code found:", code.data.substring(0, 50) + "...");
                          callback(code.data);
                          scanning = false;
                          
                          // Stop the camera
                          var stream = videoElement.srcObject;
                          var tracks = stream.getTracks();
                          tracks.forEach(function(track) {
                            track.stop();
                          });
                          
                          // Remove scanner container after a delay
                          setTimeout(function() {
                            if (document.getElementById('scanner-container')) {
                              document.getElementById('scanner-container').remove();
                            }
                          }, 500);
                        }
                      }
                    } catch (e) {
                      console.error("Scanning error:", e);
                    }
                    
                    if (scanning) {
                      requestAnimationFrame(scan);
                    }
                  } else {
                    requestAnimationFrame(scan);
                  }
                };
                
                // Start scanning
                requestAnimationFrame(scan);
                
                console.log("Camera started successfully");
              }).catch(function(error) {
                console.error("Camera access error:", error);
                if (document.getElementById('scanner-container')) {
                  document.getElementById('scanner-container').remove();
                }
              });
            } catch (e) {
              console.error("Scanner initialization error:", e);
            }
          },
          stop: function() {
            var videoElement = document.getElementById('qr-video');
            if (videoElement && videoElement.srcObject) {
              var stream = videoElement.srcObject;
              var tracks = stream.getTracks();
              tracks.forEach(function(track) {
                track.stop();
              });
            }
            
            if (document.getElementById('scanner-container')) {
              document.getElementById('scanner-container').remove();
            }
          }
        };
      }
      '''
    ]);

    // Start web scanner with a short delay to ensure JS is ready
    Future.delayed(Duration(milliseconds: 1000), () {
      _startWebScanner();
    });
  }

  // Start web scanner automatically
  void _startWebScanner() {
    if (_webScannerInitialized) return;

    try {
      print('Starting web scanner automatically...');
      js.context.callMethod('eval', [
        '''
        try {
          console.log("Starting web QR scanner from Flutter...");
          if (typeof window.webQRScanner === 'undefined') {
            console.error("webQRScanner is not defined");
            if (window.onQRScannerError) {
              window.onQRScannerError("QR scanner not available. Please try again or use a different browser.");
            }
            return;
          }
          
          window.webQRScanner.start(function(result) {
            console.log("QR code detected in JavaScript, sending to Flutter: " + result.substring(0, 50) + "...");
            if (window.onQRCodeDetected) {
              window.onQRCodeDetected(result);
            } else {
              console.error("onQRCodeDetected callback not registered");
              if (window.onQRScannerError) {
                window.onQRScannerError("Callback not registered. Please refresh the page and try again.");
              }
            }
          });
        } catch (e) {
          console.error("Error starting scanner:", e);
          if (window.onQRScannerError) {
            window.onQRScannerError("Error starting scanner: " + e.message);
          }
        }
      '''
      ]);

      setState(() {
        _webScannerInitialized = true;
        _isLoading = false;
        _cameraStarting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start web scanner: $e';
        _showErrorIcon = true;
        _showFallbackOption = true;
        _isLoading = false;
        _cameraStarting = false;
      });
      print('Error starting web scanner: $e');
    }
  }

  // Launch the fallback scanner
  Future<void> _openFallbackScanner() async {
    final Uri url = Uri.parse('scanner-fallback.html');
    if (!await launchUrl(url)) {
      setState(() {
        _errorMessage = 'Could not launch fallback scanner';
      });
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
    print('Detected ${barcodes.length} barcodes');

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final String code = barcode.rawValue!;
        print(
            'Barcode raw value: ${code.substring(0, math.min(50, code.length))}...');
        try {
          final vcard = VCardModel.fromVCardString(code);
          print('Successfully parsed vCard: ${vcard.name}, ${vcard.company}');

          // Handle the successful scan
          _handleSuccessfulScan(vcard);
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

  // Handle successful scan with separate UI update and database operation
  void _handleSuccessfulScan(VCardModel vcard) {
    // Stop the scanner immediately
    if (_scannerController != null) {
      _scannerController!.stop();
    }

    // Update state with the scanned contact
    setState(() {
      _lastScannedContact = vcard;
    });

    // Show the popup
    _showContactPopup(vcard);

    // Save to database in the background
    _saveContact(vcard);
  }

  // Save contact to database
  Future<void> _saveContact(VCardModel vcard) async {
    try {
      print('Saving contact to database: ${vcard.name}');
      final id = await DatabaseHelper.instance.insertContact(vcard);
      print('Contact saved with ID: $id');
    } catch (e) {
      print('Error saving contact: $e');
      // Silently fail, user can still see the contact in the popup
    }
  }

  // Show popup with contact details
  void _showContactPopup(VCardModel vcard) {
    print('Showing contact popup for: ${vcard.name}');

    if (!mounted) {
      print('Widget no longer mounted, cannot show popup');
      return;
    }

    // Use a simpler approach with a bottom sheet instead of dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Contact Scanned!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildContactField('Name', vcard.name),
                    _buildContactField('Company', vcard.company),
                    if (vcard.title.isNotEmpty)
                      _buildContactField('Title', vcard.title),
                    if (vcard.email.isNotEmpty)
                      _buildContactField('Email', vcard.email),
                    if (vcard.phone.isNotEmpty)
                      _buildContactField('Phone', vcard.phone),
                    if (vcard.website.isNotEmpty)
                      _buildContactField('Website', vcard.website),
                    if (vcard.address.isNotEmpty)
                      _buildContactField('Address', vcard.address),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Contact has been saved to your history',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the sheet
                        // Reset and continue scanning
                        if (_isWeb) {
                          _startWebScanner();
                        } else if (_scannerController != null) {
                          _scannerController!.start();
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Scan Another'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the sheet
                        Navigator.pop(
                            context, vcard); // Return to previous screen
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
      ),
      body: Center(
        child:
            _isLoading ? const CircularProgressIndicator() : _renderContent(),
      ),
    );
  }

  Widget _renderContent() {
    if (_isWeb) {
      // Web platform - show active camera status
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_cameraStarting)
              Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                ],
              ),
            Text(
              _webScannerInitialized
                  ? 'Camera active - point at a QR code'
                  : 'Starting camera...',
              style: TextStyle(
                color: _webScannerInitialized ? Colors.green : Colors.blue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'The camera should activate automatically',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 8),
            Text(
              'Please allow camera access if prompted',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
            if (_showFallbackOption)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  children: [
                    Text('Having trouble with the camera?',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _openFallbackScanner,
                      icon: Icon(Icons.launch),
                      label: Text('Try Standalone Scanner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
