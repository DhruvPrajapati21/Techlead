import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';

import '../../core/app_bar_provider.dart';

class Showemployees extends ConsumerStatefulWidget {
  const Showemployees({super.key});

  @override
  ConsumerState<Showemployees> createState() => _ShowemployeesState();
}

class _ShowemployeesState extends ConsumerState<Showemployees> {

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {

      ref.read(customTitleWidgetProvider.notifier).state = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.person_2_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Employee Authtication Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontFamily: "Times New Roman",fontSize: 14),
          ),
        ],
      );
    });
  }

  final CollectionReference usersRef =
  FirebaseFirestore.instance.collection('Empauth');

  Future<void> _deleteUser(String docId) async {
    try {
      await usersRef.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Employee deleted successfully')),
      );
    } catch (e) {
      print("Delete error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete employee')),
      );
    }
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("Confirm Delete"),
            content: const Text(
                "Are you sure you want to delete this employee?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteUser(docId);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                    "Delete", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  TableRow _buildHeaderRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.black87),
      children: [
        _tableCell("Username", isHeader: true),
        _tableCell("Email", isHeader: true),
        _tableCell("Password", isHeader: true),
        _tableCell("Delete", isHeader: true),
      ],
    );
  }

  TableRow _buildDataRow(String id, String username, String email,
      String password) {
    return TableRow(
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      children: [
        _tableCell(username, alignRight: false),
        _tableCell(email, alignRight: false),
        _tableCell(password, alignRight: false),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(id),
          ),
        ),
      ],
    );
  }

  static Widget _tableCell(String text,
      {bool isHeader = false, bool alignRight = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.bold,
          color: isHeader ? Colors.cyanAccent : Colors.white,
          fontSize: 14,
        ),
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A2A5A),
              Color(0xFF15489C),
              Color(0xFF1E64D8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 10),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by username',
                  hintStyle: const TextStyle(color: Colors.white),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.blue.shade800,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                        color: Colors.cyanAccent, width: 2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: usersRef
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                          'Something went wrong', style: TextStyle(color: Colors
                          .white)),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.cyanAccent),
                    );
                  }

                  final users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final username = (data['username'] ?? '')
                        .toString()
                        .toLowerCase();
                    return username.contains(_searchQuery);
                  }).toList();

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Table(
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        border: TableBorder.all(color: Colors.white),
                        children: [
                          _buildHeaderRow(),
                          ...users.map((user) {
                            final data = user.data() as Map<String, dynamic>;
                            final id = user.id;
                            final username = data['username'] ?? 'No Name';
                            final email = data['email'] ?? 'No Email';
                            final password = data['password'] ?? 'No Password';

                            return _buildDataRow(id, username, email, password);
                          }).toList(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
