import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import 'add_emergency_contact_screen.dart';
import 'calling_contact_screen.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<EmergencyContact> _contacts = [
    const EmergencyContact(
      name: 'Amir amour',
      phoneNumber: '01134658497',
      relationship: 'Friend',
    ),
    const EmergencyContact(
      name: 'samir shafor',
      phoneNumber: '02345698741',
      relationship: 'Brother',
    ),
    const EmergencyContact(
      name: 'hussin sandour',
      phoneNumber: '0234591873',
      relationship: 'Cousin',
    ),
    const EmergencyContact(
      name: 'shady morour',
      phoneNumber: '01934658497',
      relationship: 'Friend',
    ),
    const EmergencyContact(
      name: 'Nayera nemo',
      phoneNumber: '01124658464',
      relationship: 'Sister',
    ),
  ];

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _contacts.where((c) {
      if (_searchQuery.isEmpty) return true;
      final lower = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(lower) ||
          c.phoneNumber.contains(lower);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () async {
          final newContact = await Navigator.push<EmergencyContact>(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEmergencyContactScreen(),
            ),
          );
          if (newContact != null) {
            setState(() {
              _contacts.add(newContact);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: Colors.grey[900],
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: filteredContacts.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final contact = filteredContacts[index];
                  return _buildContactTile(contact);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(EmergencyContact contact) {
    final initials = contact.name.isNotEmpty
        ? contact.name
              .trim()
              .split(' ')
              .where((part) => part.isNotEmpty)
              .map((part) => part[0].toUpperCase())
              .take(2)
              .join()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CallingContactScreen(contact: contact),
            ),
          );
        },
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[700],
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.phoneNumber,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                onPressed: () {
                  // Future: show edit/delete options
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
