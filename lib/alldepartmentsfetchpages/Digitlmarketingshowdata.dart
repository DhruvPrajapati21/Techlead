import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../FileViwerscreen.dart';

class Digitlmarketingshowdata extends StatefulWidget {
  const Digitlmarketingshowdata({super.key});

  @override
  State<Digitlmarketingshowdata> createState() =>
      _DigitlmarketingshowdataState();
}

class _DigitlmarketingshowdataState extends State<Digitlmarketingshowdata> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text(
                "Assigned Tasks From Admin",
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue.shade900,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            _buildSearchBar(),
            _buildDateFilters(),
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('TaskAssign')
                    .where('department', isEqualTo: 'Digital Marketing')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tasks assigned.",
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                    );
                  }

                  var assignedTasks = snapshot.data!.docs.where((doc) {
                    var task = doc.data() as Map<String, dynamic>;

                    if (searchQuery.isNotEmpty &&
                        !task['employeeName'].toString().toLowerCase().contains(searchQuery.toLowerCase())) {
                      return false;
                    }

                    if (startDate != null && endDate != null) {
                      DateTime assignedDate = DateFormat('dd MMMM yy').parse(task['date']);
                      DateTime normalizedStartDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
                      DateTime normalizedEndDate = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
                      return assignedDate.isAfter(normalizedStartDate) && assignedDate.isBefore(normalizedEndDate);
                    }

                    return true;
                  }).toList();

                  if (assignedTasks.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tasks available between these dates.",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: assignedTasks.length,
                    itemBuilder: (context, index) {
                      var task = assignedTasks[index].data() as Map<String, dynamic>;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade900, Colors.blue.shade700],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.all(16.0),
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

                                if (task['files'] != null && task['files'] is List && task['files'].isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Attached Files:",
                                          style: TextStyle(
                                            color: Colors.tealAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 120,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: task['files'].length,
                                            itemBuilder: (context, fileIndex) {
                                              var file = task['files'][fileIndex];
                                              final String url = file['downloadUrl'] ?? '';
                                              final String fileType = (file['fileType'] ?? '').toLowerCase();
                                              final String fileName = file['fileName'] ?? 'Unnamed';

                                              bool isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType);

                                              return GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => FileViewerScreen(
                                                        url: url,
                                                        fileType: fileType,
                                                      ),
                                                    ),
                                                  );
                                                },

                                                child: Container(
                                                  width: 120,
                                                  margin: const EdgeInsets.only(right: 10),
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.1),
                                                    border: Border.all(color: Colors.tealAccent),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: isImage
                                                            ? Image.network(
                                                          url,
                                                          width: 100,
                                                          height: 70,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white),
                                                        )
                                                            : Icon(
                                                          fileType == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                                                          color: Colors.white,
                                                          size: 50,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        fileName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                                      ),
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

                              ],
                            ),
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
          labelStyle: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
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
            color: Colors.tealAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: value != null ? value.toString() : 'N/A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}