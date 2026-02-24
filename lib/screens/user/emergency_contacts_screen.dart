import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Contacts")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _contactCard("Sarah (Mom)", "+1 555-0123"),
            const SizedBox(height: 16),
            _contactCard("Mark (Brother)", "+1 555-0199"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6A00),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _contactCard(String name, String number) {
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
          Text(number, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}