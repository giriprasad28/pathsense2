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

  List requests = [];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  /// ================= FETCH REQUESTS =================
  Future<void> fetchRequests() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('link_requests')
        .select()
        .eq('user_id', user!.id);

    setState(() {
      requests = data;
    });
  }

  /// ================= SEND REQUEST =================
  void showAddContactDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Send Request"),
          content: TextField(
            controller: emailController,
            decoration:
            const InputDecoration(hintText: "Enter Parent Email"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final user = supabase.auth.currentUser;

                try {
                  /// 🔍 FIND PARENT
                  final parent = await supabase
                      .from('profiles')
                      .select()
                      .eq('email', emailController.text.trim().toLowerCase())
                      .single();

                  print("PARENT FOUND: $parent");

                  /// 🚀 INSERT REQUEST
                  await supabase.from('link_requests').insert({
                    'user_id': user!.id,
                    'parent_id': parent['id'],
                    'status': 'pending',
                  });

                  print("REQUEST INSERTED SUCCESS");

                  Navigator.pop(context);
                  fetchRequests();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Request Sent!")),
                  );
                } catch (e) {
                  print("ERROR: $e");

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Send"),
            ),
          ],
        );
      },
    );
  }

  /// ================= UI CARD =================
  Widget _requestCard(Map req) {
    Color statusColor;

    switch (req['status']) {
      case 'accepted':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(req['parent_id'] ?? ''),
              const SizedBox(height: 6),
              Text(req['status'] ?? '',
                  style: TextStyle(color: statusColor)),
            ],
          ),
          Icon(Icons.person, color: statusColor)
        ],
      ),
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Link Parent")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: requests.isEmpty
            ? const Center(child: Text("No requests yet"))
            : ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];

            return Column(
              children: [
                _requestCard(req),
                const SizedBox(height: 12),
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
