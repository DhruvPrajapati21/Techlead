import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Showemployees extends StatefulWidget {
  const Showemployees({super.key});

  @override
  State<Showemployees> createState() => _ShowemployeesState();
}

class _ShowemployeesState extends State<Showemployees> {
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
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this employee?"),
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
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Employees Details",
          style: TextStyle(
            fontFamily: "Times New Roman",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.orderBy('createdAt', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;
              final id = user.id;
              final username = data['username'] ?? 'No Name';
              final email = data['email'] ?? 'No Email';
              final password = data['password'] ?? 'No Password';

              return Padding(
                padding: const EdgeInsets.all(10),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Card ${index + 1}",
                                    style: TextStyle(
                                      fontSize: constraints.maxWidth > 600 ? 22 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(id),
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 5),
                            Text(
                              "Username: $username",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Email: $email",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Password: $password",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
