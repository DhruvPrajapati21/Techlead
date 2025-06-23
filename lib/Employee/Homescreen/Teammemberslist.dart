import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMembersScreen extends StatefulWidget {
  final List<String> userDepartments;

  const TeamMembersScreen({Key? key, required this.userDepartments}) : super(key: key);

  @override
  _TeamMembersScreenState createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> allMembers = [];
  List<Map<String, dynamic>> filteredMembers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    final snapshot = await _firestore.collection('EmpProfile').get();
    final List<Map<String, dynamic>> matchedMembers = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final empCategories = List<dynamic>.from(data['categories'] ?? []);

      final bool isSameDepartment = empCategories.any(
            (cat) => widget.userDepartments.contains(cat.toString()),
      );

      if (isSameDepartment) {
        matchedMembers.add({
          'fullName': data['fullName'] ?? 'Unknown',
          'address': data['address'] ?? 'N/A',
          'categories': empCategories.join(', '),
          'mobile': data['mobile'] ?? 'N/A',
          'email': data['email'] ?? 'N/A',
        });
      }
    }

    setState(() {
      allMembers = matchedMembers;
      _filterMembers('');
    });
  }

  void _filterMembers(String query) {
    final filtered = allMembers.where((member) {
      final name = member['fullName'].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    for (int i = 0; i < filtered.length; i++) {
      filtered[i]['index'] = i + 1;
    }

    setState(() {
      filteredMembers = filtered;
    });
  }

  Future<void> launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> launchEmail(BuildContext context, String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else if (Platform.isAndroid) {
      final Uri gmailUri = Uri.parse("https://mail.google.com/mail/?view=cm&fs=1&to=$email");
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else {
        _showError(context);
      }
    } else {
      _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No email app found or unable to launch.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F0FF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.4), blurRadius: 4, offset: const Offset(2, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    '${member['index']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member['fullName'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Times New Roman', fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Address: ${member['address']}', style: const TextStyle(fontFamily: 'Times New Roman')),
            const SizedBox(height: 7),
            Text('Department: ${member['categories']}', style: const TextStyle(fontFamily: 'Times New Roman')),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => launchPhone(member['mobile']),
                    child: Text(
                      'Phone: ${member['mobile']}',
                      style: const TextStyle(fontFamily: 'Times New Roman', color: Colors.black),
                    ),
                  ),
                ),
                const Text('Please tap them', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => launchEmail(context, member['email']),
                    child: Text(
                      'Email: ${member['email']}',
                      style: const TextStyle(fontFamily: 'Times New Roman', color: Colors.black),
                    ),
                  ),
                ),
                const Text('Please tap them', style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text(
          'Team Members',
          style: TextStyle(fontFamily: 'Times New Roman', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: _filterMembers,
              decoration: InputDecoration(
                labelText: 'Search by name',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          Expanded(
            child: filteredMembers.isEmpty
                ? const Center(
              child: Text(
                'No data available for this department right now!',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                return _buildMemberCard(filteredMembers[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
