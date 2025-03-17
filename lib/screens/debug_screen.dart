import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/vcard_model.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  _DebugScreenState createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _status = 'Ready';
  List<String> _logs = [];
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> _initDatabase() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing database...';
    });

    try {
      _log('Initializing database...');
      final db = await DatabaseHelper.instance.database;
      _log('Database initialized successfully');
      setState(() {
        _status = 'Database initialized';
      });
    } catch (e) {
      _log('Error initializing database: $e');
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestContact() async {
    setState(() {
      _isLoading = true;
      _status = 'Creating test contact...';
    });

    try {
      _log('Creating test contact...');
      final testContact = VCardModel(
        name: 'Test Contact ${DateTime.now().millisecondsSinceEpoch}',
        company: 'Test Company',
        email: 'test@example.com',
        phone: '+1234567890',
        website: 'https://example.com',
        title: 'Test Title',
      );

      final id = await DatabaseHelper.instance.insertContact(testContact);
      _log('Test contact created with ID: $id');
      setState(() {
        _status = 'Test contact created with ID: $id';
      });
    } catch (e) {
      _log('Error creating test contact: $e');
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _status = 'Loading contacts...';
    });

    try {
      _log('Loading contacts...');
      final contacts = await DatabaseHelper.instance.getAllContacts();
      _log('Loaded ${contacts.length} contacts');

      if (contacts.isNotEmpty) {
        _log(
            'First contact: ${contacts.first['name']} (${contacts.first['company']})');
      }

      setState(() {
        _status = 'Loaded ${contacts.length} contacts';
      });
    } catch (e) {
      _log('Error loading contacts: $e');
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllContacts() async {
    setState(() {
      _isLoading = true;
      _status = 'Deleting all contacts...';
    });

    try {
      _log('Deleting all contacts...');
      await DatabaseHelper.instance.deleteAllContacts();
      _log('All contacts deleted successfully');
      setState(() {
        _status = 'All contacts deleted';
      });
    } catch (e) {
      _log('Error deleting contacts: $e');
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _initDatabase,
                    child: const Text('Init Database'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createTestContact,
                    child: const Text('Create Test Contact'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loadContacts,
                    child: const Text('Load Contacts'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _deleteAllContacts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Logs:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final logIndex = _logs.length - 1 - index;
                    return Text(
                      _logs[logIndex],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
