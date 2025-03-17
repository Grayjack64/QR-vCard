import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../models/vcard_model.dart';

class ContactHistoryScreen extends StatefulWidget {
  const ContactHistoryScreen({super.key});

  @override
  State<ContactHistoryScreen> createState() => _ContactHistoryScreenState();
}

class _ContactHistoryScreenState extends State<ContactHistoryScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _databaseInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize database first, then load contacts
    _initDatabase();
  }

  // Initialize the database explicitly
  Future<void> _initDatabase() async {
    try {
      print('Initializing database...');
      // Get the database from the helper to ensure it's created
      final db = await DatabaseHelper.instance.database;
      print('Database initialized successfully');
      setState(() {
        _databaseInitialized = true;
      });

      // Now load contacts
      _loadContacts();
    } catch (e) {
      print('Error initializing database: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error initializing database: $e';
        });
      }
    }
  }

  Future<void> _loadContacts() async {
    if (!_databaseInitialized) {
      print('Database not initialized, cannot load contacts');
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('Loading contacts from database...');
      final contacts = await DatabaseHelper.instance.getAllContacts();
      print('Loaded ${contacts.length} contacts from database');

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading contacts: $e';
        });
      }
    }
  }

  Future<void> _deleteContact(int id) async {
    try {
      print('Deleting contact with ID: $id');
      await DatabaseHelper.instance.deleteContact(id);
      print('Contact deleted successfully');
      _loadContacts();
    } catch (e) {
      print('Error deleting contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting contact: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllContacts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Contacts'),
        content:
            const Text('Are you sure you want to delete all scanned contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('Deleting all contacts');
        await DatabaseHelper.instance.deleteAllContacts();
        print('All contacts deleted successfully');
        _loadContacts();
      } catch (e) {
        print('Error deleting all contacts: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting contacts: $e')),
          );
        }
      }
    }
  }

  Future<void> _refreshContacts() async {
    print('Refreshing contacts...');
    await _loadContacts();
  }

  // This method creates a test contact for debugging
  Future<void> _createTestContact() async {
    try {
      print('Creating test contact...');
      final testContact = VCardModel(
        name: 'Test Contact ${DateTime.now().millisecondsSinceEpoch}',
        company: 'Test Company',
        email: 'test@example.com',
        phone: '+1234567890',
        website: 'https://example.com',
        title: 'Test Title',
      );

      final id = await DatabaseHelper.instance.insertContact(testContact);
      print('Test contact created with ID: $id');

      // Reload contacts
      _loadContacts();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test contact created successfully')),
        );
      }
    } catch (e) {
      print('Error creating test contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating test contact: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanned Contacts'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Add a test contact button for debugging
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTestContact,
            tooltip: 'Add Test Contact',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshContacts,
            tooltip: 'Refresh Contacts',
          ),
          if (_contacts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteAllContacts,
              tooltip: 'Delete All Contacts',
            ),
        ],
      ),
      body: _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _refreshContacts,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshContacts,
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading contacts...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _contacts.isEmpty
                      ? ListView(
                          // Ensure the RefreshIndicator works with empty lists
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height:
                                  MediaQuery.of(context).size.height / 2 - 100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No scanned contacts yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Pull down to refresh or tap + to add a test contact',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _contacts.length,
                          itemBuilder: (context, index) {
                            final contact = _contacts[index];
                            final scannedAt =
                                DateTime.parse(contact['scanned_at']);
                            final vcard = VCardModel(
                              name: contact['name'],
                              company: contact['company'],
                              email: contact['email'] ?? '',
                              phone: contact['phone'] ?? '',
                              website: contact['website'] ?? '',
                              title: contact['title'] ?? '',
                              address: contact['address'] ?? '',
                            );

                            return Dismissible(
                              key: Key(contact['id'].toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) =>
                                  _deleteContact(contact['id']),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                elevation: 2,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  title: Text(
                                    vcard.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(vcard.company),
                                      if (vcard.title.isNotEmpty)
                                        Text(
                                          vcard.title,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat.yMMMd()
                                                .add_jm()
                                                .format(scannedAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    child: Text(
                                      vcard.name[0].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(vcard.name),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              _buildContactField(
                                                  'Company', vcard.company),
                                              if (vcard.title.isNotEmpty)
                                                _buildContactField(
                                                    'Title', vcard.title),
                                              if (vcard.email.isNotEmpty)
                                                _buildContactField(
                                                    'Email', vcard.email),
                                              if (vcard.phone.isNotEmpty)
                                                _buildContactField(
                                                    'Phone', vcard.phone),
                                              if (vcard.website.isNotEmpty)
                                                _buildContactField(
                                                    'Website', vcard.website),
                                              if (vcard.address.isNotEmpty)
                                                _buildContactField(
                                                    'Address', vcard.address),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Scanned: ${DateFormat.yMMMd().add_jm().format(scannedAt)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }

  Widget _buildContactField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
