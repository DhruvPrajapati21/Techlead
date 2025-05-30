import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'Hrdailytaskreport.dart';
import 'Financedailytaskreport.dart';
import 'Installationdailytaskreport.dart';
import 'Managementdailytaskreport.dart';
import 'Accountdailytaskreport.dart';
import 'Receptionlistdailytaskreport.dart';
import 'Salesdailytaskreport.dart';
import 'Smdailytaskreport.dart';
import 'Digitalmarketingdailytaskreport.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String label;
  final List<String> userDepartments;

  const TaskDetailsScreen({
    Key? key,
    required this.label,
    required this.userDepartments,
  }) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> taskList = [];
  List<Map<String, dynamic>> filteredList = [];

  TextEditingController searchController = TextEditingController();
  DateTime? selectedDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasksByStatus();
  }

  Future<void> _loadTasksByStatus() async {
    final status = widget.label == "Pending Tasks"
        ? "Pending"
        : widget.label == "InProgress Tasks"
        ? "In Progress"
        : "Completed";

    List<Map<String, dynamic>> collected = [];

    for (int i = 0; i < widget.userDepartments.length; i += 10) {
      final chunk = widget.userDepartments.sublist(
        i,
        (i + 10 > widget.userDepartments.length)
            ? widget.userDepartments.length
            : i + 10,
      );

      QuerySnapshot snapshot = await _firestore
          .collection('DailyTaskReport')
          .where('service_status', isEqualTo: status)
          .where('category', whereIn: chunk)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('DailyTaskReport')
            .where('service_status', isEqualTo: status)
            .where('Service_department', whereIn: chunk)
            .get();
      }

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        data['parsedDate'] = _parseDate(data['date']);
        collected.add(data);
      }
    }

    setState(() {
      taskList = collected;
      isLoading = false;
      _filterList('');
    });
  }

  String _parseDate(dynamic raw) {
    if (raw is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(raw.toDate());
    } else if (raw is String) {
      return raw;
    } else {
      return 'N/A';
    }
  }

  void _filterList(String query) {
    final lowerQuery = query.toLowerCase();
    List<Map<String, dynamic>> result = taskList.where((task) {
      final title = task['taskTitle']?.toString().toLowerCase() ?? '';
      final matchesTitle = title.contains(lowerQuery);
      final matchesDate = selectedDate == null
          ? true
          : task['parsedDate'] == DateFormat('dd/MM/yyyy').format(selectedDate!);
      return matchesTitle && matchesDate;
    }).toList();

    for (int i = 0; i < result.length; i++) {
      result[i]['index'] = i + 1;
    }

    setState(() {
      filteredList = result;
    });
  }

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _filterList(searchController.text);
      });
    }
  }

  void _handleCardTap(String category) {
    Widget target;
    switch (category) {
      case 'Human Resource':
        target = const Hrdailytaskreport();
        break;
      case 'Finance':
        target = const Financedailytaskreport();
        break;
      case 'Management':
        target = const Managementdailytaskreport();
        break;
      case 'Installation':
        target = const DailyReportRecordOfInstallation();
        break;
      case 'Sales':
        target = const DailyReportRecordOfSales();
        break;
      case 'Reception':
        target = const DailyReportRecordOfReception();
        break;
      case 'Account':
        target = const Accountdailytaskreport();
        break;
      case 'Social Media':
        target = const Smdailytaskreport();
        break;
      case 'Digital Marketing':
        target = const Digitalmarketingdailytaskreport();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => target),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> data) {
    final category = data['category'] ?? data['Service_department'] ?? 'N/A';
    final employee = data['employeeName'] ?? 'N/A';
    final location = data['location'] ?? 'N/A';
    final nextSteps = data['nextSteps'] ?? 'N/A';
    final actionsTaken = data['actionsTaken'] ?? 'N/A';
    final date = data['parsedDate'] ?? 'N/A';

    return GestureDetector(
      onTap: () => _handleCardTap(category),
      child: Container(
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
                    child: Text('${data['index']}', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['taskTitle'] ?? 'Untitled Task',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Category: $category', style: const TextStyle(fontFamily: 'Times New Roman')),
              const SizedBox(height: 7),
              Text('Submitted Name: $employee', style: const TextStyle(fontFamily: 'Times New Roman')),
              const SizedBox(height: 7),
              Text('Location: $location', style: const TextStyle(fontFamily: 'Times New Roman')),
              const SizedBox(height: 7),
              Text('Submitted Date: $date', style: const TextStyle(fontFamily: 'Times New Roman')),
              const SizedBox(height: 7),
              Text('Action Taken: $actionsTaken', style: const TextStyle(fontFamily: 'Times New Roman')),
              const SizedBox(height: 7),
              Text('Next Step: $nextSteps', style: const TextStyle(fontFamily: 'Times New Roman')),
              const SizedBox(height: 12),
              const Text(
                'Note:- Tap to see detailed report.',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: Text(
          widget.label,
          style: const TextStyle(fontFamily: 'Times New Roman', fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: _filterList,
                    decoration: InputDecoration(
                      hintText: 'Search by Project...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.date_range, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(
              child: Text(
                'No data available for this department right now!',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(filteredList[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
