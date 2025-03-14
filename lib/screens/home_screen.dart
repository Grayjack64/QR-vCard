import 'package:flutter/material.dart';
import 'package:qr_vcard_app/screens/profile_screen.dart';
import 'package:qr_vcard_app/screens/qr_display_screen.dart';
import 'package:qr_vcard_app/screens/scan_screen.dart';
import 'package:qr_vcard_app/screens/url_qr_generator.dart';
import 'package:qr_vcard_app/screens/contact_history_screen.dart';
import 'package:qr_vcard_app/models/user_profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red River vCard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
            tooltip: 'Edit Profile',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'url_qr') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const URLQRGenerator(),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'url_qr',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, size: 20),
                      SizedBox(width: 8),
                      Text('App URL QR Generator'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or image
              const Icon(Icons.qr_code_rounded, size: 120, color: Colors.red),
              const SizedBox(height: 40),

              // App title
              const Text(
                'QR vCard Generator',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // App description
              const Text(
                'Create and scan vCard QR codes',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // Show QR button
              ElevatedButton.icon(
                onPressed: () async {
                  final profile = await UserProfile.load();
                  if (profile.name.isEmpty || profile.company.isEmpty) {
                    if (context.mounted) {
                      // Profile not set up yet, prompt user to set up profile
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please set up your profile first'),
                        ),
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      // Show QR code
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QRDisplayScreen(profile: profile),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.qr_code),
                label: const Text('Show My QR Code'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 20),

              // Scan QR button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanScreen()),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan a QR Code'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 20),

              // Contact History button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactHistoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View Scanned Contacts'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
