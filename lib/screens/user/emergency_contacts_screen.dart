import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final supabase = Supabase.instance.client;

  List contacts = [];

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  // 🔥 Fetch contacts from Supabase
  Future<void> fetchContacts() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('contacts')
        .select()
        .eq('user_id', user!.id);

    setState(() {
      contacts = data;
    });
  }

  // 🔥 Add contact dialog
  void showAddContactDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Contact"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: "Name"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: "Parent Email"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final user = supabase.auth.currentUser;

                await supabase.from('contacts').insert({
                  'user_id': user!.id,
                  'name': nameController.text,
                  'parent_email': emailController.text,
                });

                Navigator.pop(context);
                fetchContacts(); // refresh list
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // 🔥 Contact Card UI
  Widget _contactCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Contacts")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: contacts.isEmpty
            ? const Center(child: Text("No contacts added"))
            : ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return Column(
              children: [
                _contactCard(
                  contact['name'] ?? '',
                  contact['parent_email'] ?? '',
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6A00),
        onPressed: showAddContactDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}