import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AssignedTaskToEmpPage extends StatefulWidget {
  const AssignedTaskToEmpPage({super.key});

  @override
  State<AssignedTaskToEmpPage> createState() => _AssignedTaskToEmpPageState();
}

class _AssignedTaskToEmpPageState extends State<AssignedTaskToEmpPage> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Tasks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildDateFilters(),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('TaskAssign')
                  .where('employeeId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No tasks assigned.", style: TextStyle(color: Colors.white, fontSize: 18)),
                  );
                }

                var assignedTasks = snapshot.data!.docs.where((doc) {
                  var task = doc.data() as Map<String, dynamic>;

                  // Filter by employee name search query
                  if (searchQuery.isNotEmpty &&
                      !task['employeeName'].toString().toLowerCase().contains(searchQuery.toLowerCase())) {
                    return false;
                  }

                  // Filter by date range
                  if (startDate != null && endDate != null) {
                    // Parse the task's assigned date from Firestore (assuming it's in dd MMMM yy format)
                    DateTime assignedDate = DateFormat('dd MMMM yy').parse(task['date']);

                    // Normalize startDate and endDate to start of the day (midnight) and end of the day (11:59:59)
                    DateTime normalizedStartDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
                    DateTime normalizedEndDate = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);

                    // Compare the assigned date with the start and end date range
                    return assignedDate.isAfter(normalizedStartDate) && assignedDate.isBefore(normalizedEndDate);
                  }

                  return true;
                }).toList();

                // Show message if no tasks match the filter criteria
                if (assignedTasks.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tasks available between these dates.",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  );
                }

                // Display the tasks if any match the filter criteria
                return ListView.builder(
                  itemCount: assignedTasks.length,
                  itemBuilder: (context, index) {
                    var task = assignedTasks[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade700, Colors.blue.shade400],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTaskDetail('Admin Name', task['adminName']),
                            _buildTaskDetail('Employee Name', task['employeeName']),
                            _buildTaskDetail('Project Name', task['projectName']),
                            _buildTaskDetail('Department', task['department']),
                            _buildTaskDetail('Site Location', task['siteLocation']),
                            _buildTaskDetail('Task Description', task['taskDescription']),
                            _buildTaskDetail('Assigned Date', task['date']),
                            _buildTaskDetail('Deadline Date', task['deadlineDate']),
                            _buildTaskDetail('Time', task['time']),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Search by Employee Name",
          labelStyle: const TextStyle(color: Colors.white),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.blue.shade900,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  // Date Filters
  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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

  // Date Picker
  Widget _buildDateButton(String label, DateTime? date, Function(DateTime) onDateSelected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
      onPressed: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      child: Text(
        date != null ? DateFormat('dd-MMMM-yy').format(date) : label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // Task Detail Widget
  Widget _buildTaskDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: value != null ? value.toString() : 'N/A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
