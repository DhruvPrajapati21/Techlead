import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Categoryscreen/Account/Accountshowdata.dart';
import '../Categoryscreen/Digital Marketing/Digitlmarketingshowdata.dart';
import '../Categoryscreen/Finance/Financeshowdata.dart';
import '../Categoryscreen/HR/hrreceivedscreen.dart';
import '../Categoryscreen/Installation/Installtionemployeedata.dart';
import '../Categoryscreen/Management/Managementshowdata.dart';
import '../Categoryscreen/Reception/Receptionshowdata.dart';
import '../Categoryscreen/Sales/Receivesaleshdata.dart';
import '../Categoryscreen/Social Media/Socialmediamarketingshowdata.dart';

class Admintasksummury extends StatefulWidget {
  const Admintasksummury({Key? key}) : super(key: key);

  @override
  State<Admintasksummury> createState() => _AdmintasksummuryState();
}

class _AdmintasksummuryState extends State<Admintasksummury> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;
  String selectedStatus = 'All';

  final TextEditingController searchController = TextEditingController();
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  final DateTime now = DateTime.now();
  late final DateTime startOfMonth;
  late final DateTime endOfMonth;

  @override
  void initState() {
    super.initState();
    startOfMonth = DateTime(now.year, now.month, 1);
    endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Admin Tasks",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Times New Roman')),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchAndStatusRow(),
          const SizedBox(height: 10),
          _buildDateFilters(),
          const SizedBox(height: 10),

          Expanded(
            child: currentUserId == null
                ? const Center(
                child: Text("User not logged in",
                    style: TextStyle(fontFamily: 'Times New Roman')))
                : FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('EmpProfile')
                    .doc(currentUserId)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                        child: Text("User profile not found.",
                            style: TextStyle(
                                color: Colors.red,
                                fontFamily: 'Times New Roman')));
                  }

                  final fullName = snapshot.data!.get('fullName');
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('TaskAssign')
                        .where('employeeNames', arrayContains: fullName)
                        .snapshots(),
                    builder: (context, taskSnapshot) {
                      if (!taskSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return Center(
                          child: Text(
                            "No tasks available",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Times New Roman',
                              color: Colors.black,
                            ),
                          ),
                        );
                      }

                      final filteredTasks = taskSnapshot.data!.docs.where((doc) {
                        final task = doc.data() as Map<String, dynamic>;
                        final status = task['taskstatus'] ?? 'Pending';
                        final name = task['projectName']?.toString().toLowerCase() ?? '';

                        if (selectedStatus != 'All' && status != selectedStatus) return false;
                        if (searchQuery.isNotEmpty && !name.contains(searchQuery.toLowerCase())) return false;

                        try {
                          DateTime taskDate = DateFormat('dd MMMM yyyy').parse(task['date']);
                          if (taskDate.isBefore(startOfMonth) || taskDate.isAfter(endOfMonth)) {
                            return false;
                          }
                        } catch (_) {
                          return false;
                        }

                        if (startDate != null && endDate != null) {
                          try {
                            DateTime assignedDate = DateFormat('dd MMMM yyyy').parse(task['date']);
                            DateTime start = DateTime(startDate!.year, startDate!.month, startDate!.day);
                            DateTime end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
                            if (assignedDate.isBefore(start) || assignedDate.isAfter(end)) {
                              return false;
                            }
                          } catch (_) {
                            return false;
                          }
                        }

                        return true;
                      }).toList();

                      if (filteredTasks.isEmpty) {
                        String message;

                        if (searchQuery.isNotEmpty) {
                          message = "No tasks found matching your search.";
                        } else {
                          switch (selectedStatus) {
                            case 'Pending':
                              message = "No pending task data available.";
                              break;
                            case 'In Progress':
                              message = "No in-progress task data available.";
                              break;
                            case 'Completed':
                              message = "No completed task data available.";
                              break;
                            default:
                              message = "No current month task data available.";
                          }
                        }

                        return Center(
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Times New Roman',
                              color: Colors.black,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index].data() as Map<String, dynamic>;

                          void navigateToDepartmentPage(String department) {
                            switch (department) {
                              case 'Account':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Accountshowdata()),
                                );
                                break;
                              case 'Digital Marketing':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Digitlmarketingshowdata()),
                                );
                                break;
                              case 'Finance':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Financeshowdata()),
                                );
                                break;
                              case 'Human Resource':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Hrreceiveddata()),
                                );
                                break;
                              case 'Installation':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AssignedTaskForInstallation()),
                                );
                                break;
                              case 'Management':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Managementshowdata()),
                                );
                                break;
                              case 'Reception':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Receptionshowdata()),
                                );
                                break;
                              case 'Sales':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Receivesalesdata()),
                                );
                                break;
                              case 'Social Media':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Socialmediamarketingshowdata()),
                                );
                                break;
                              default:
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No route defined for department: $department')),
                                );
                            }
                          }

                          return GestureDetector(
                            onTap: () {
                              final department = task['department'] ?? '';
                              navigateToDepartmentPage(department);
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    colors: task['taskstatus'] == 'Approved'
                                        ? [Colors.green.shade800, Colors.green.shade600]
                                        : task['taskstatus'] == 'Rejected'
                                        ? [Colors.red.shade800, Colors.red.shade600]
                                        : [Colors.blue.shade900, Colors.blue.shade700],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTaskDetail('Admin Name', task['adminName']),
                                    _buildTaskDetail('Department', task['department']),
                                    _buildTaskDetail('Project Name', task['projectName']),
                                    _buildTaskDetail('Description', task['taskDescription']),
                                    _buildTaskDetail('Assigned Date', task['date']),
                                    _buildTaskDetail('Deadline Date', task['deadlineDate']),
                                    _buildTaskDetail('Assigned Time', task['time']),
                                    _buildTaskDetail('Status', task['taskstatus']),
                                    _buildTaskDetail('Employee Description', task['employeeDescription']),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Note:- Tap to see detailed report.',
                                      style: TextStyle(
                                        color: Color(0xFFFF0038),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndStatusRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: Row(
        children: [
          // Search Field - 50% width
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search by Project Name",
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Times New Roman',
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.blue.shade900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontFamily: 'Times New Roman'),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
          ),

          // Status Dropdown - 50% width
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: DropdownButtonFormField<String>(
                value: selectedStatus,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
                items: ['Pending', 'In Progress', 'Completed', 'All']
                    .map((status) => DropdownMenuItem<String>(
                  value: status,
                  child: Text(status, style: const TextStyle(fontFamily: 'Times New Roman')),
                ))
                    .toList(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.blue.shade900,
                  labelText: "Filter by Status",
                  labelStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Times New Roman',
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white, fontFamily: 'Times New Roman'),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDateButton("Start Date", startDate, (date) {
            setState(() {
              startDate = date;
            });
          }),
          _buildDateButton("End Date", endDate, (date) {
            setState(() {
              endDate = date;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, Function(DateTime) onDateSelected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
      onPressed: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
      child: Text(
        date != null ? DateFormat('dd-MMMM-yy').format(date) : label,
        style: const TextStyle(color: Colors.white, fontFamily: 'Times New Roman'),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: DropdownButtonFormField<String>(
        value: selectedStatus,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              selectedStatus = value;
            });
          }
        },
        items: ['Pending', 'In Progress', 'Completed', 'All']
            .map((status) => DropdownMenuItem<String>(
          value: status,
          child: Text(status, style: const TextStyle(fontFamily: 'Times New Roman')),
        ))
            .toList(),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.blue.shade900,
          labelText: "Filter by Status",
          labelStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Times New Roman'),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        dropdownColor: Colors.black,
        style: const TextStyle(color: Colors.white, fontFamily: 'Times New Roman'),
      ),
    );
  }

  Widget _buildTaskDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
              fontFamily: 'Times New Roman'),
          children: [
            TextSpan(
              text: value != null ? value.toString() : 'N/A',
              style: const TextStyle(color: Colors.white, fontFamily: 'Times New Roman'),
            ),
          ],
        ),
      ),
    );
  }
}
