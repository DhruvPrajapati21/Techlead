import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Editrecepationdailytaskreport.dart';
import 'FileViwerscreen.dart';

class DailyReportRecordOfSales extends StatefulWidget {
  const DailyReportRecordOfSales({super.key});

  @override
  State<DailyReportRecordOfSales> createState() =>
      _DailyReportRecordOfSalesState();
}

class _DailyReportRecordOfSalesState extends State<DailyReportRecordOfSales> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String searchQuery = '';
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Daily Task Report",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search Task Title',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.date_range, color: Colors.white),
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("DailyTaskReport")
            .where("Service_department", isEqualTo: "Sales")
            .where("userId", isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error fetching data."));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allReports = snapshot.data!.docs;
          final filteredReports = allReports.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['taskTitle'] ?? '').toString().toLowerCase();

            final matchesSearch = title.contains(searchQuery);
            final matchesDate = selectedDate == null ||
                (data['date'] != null &&
                    DateFormat('yyyy-MM-dd')
                        .format((data['date'] as Timestamp).toDate()) ==
                        DateFormat('yyyy-MM-dd').format(selectedDate!));

            return matchesSearch && matchesDate;
          }).toList();

          if (filteredReports.isEmpty) {
            return const Center(
              child: Text(
                "No Data Found!",
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              final doc = filteredReports[index];
              final report = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              return _buildReportCard(report, docId);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> task, String docId) {
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
              _buildTaskDetail('Employee ID', task['employeeId']),
              _buildTaskDetail('Employee Name', task['employeeName']),
              _buildTaskDetail('Task Title', task['taskTitle']),
              _buildTaskDetail('Department', task['Service_department']),
              _buildTaskDetail('Service Status', task['service_status']),
              _buildTaskDetail('Location', task['location']),
              _buildTaskDetail(
                'SubmittedDate',
                task['date'] != null
                    ? DateFormat('dd MMM yyyy').format((task['date'] as Timestamp).toDate())
                    : '',
              ),
              _buildTaskDetail('Challenges', task['challenges']),
              _buildTaskDetail('Actions Taken', task['actionsTaken']),
              _buildTaskDetail('Next Steps', task['nextSteps']),
              const SizedBox(height: 10),
              const Text(
                'Work Log:',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              if (task['workLog'] != null)
                ...List<Widget>.from((task['workLog'] as List)
                    .map((log) => _buildTaskDetail(
                  log['timeSlot'],
                  log['description'],
                ))),
              if (task['uploadedFiles'] != null &&
                  task['uploadedFiles'] is List &&
                  task['uploadedFiles'].isNotEmpty)
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
                          itemCount: task['uploadedFiles'].length,
                          itemBuilder: (context, fileIndex) {
                            var file = task['uploadedFiles'][fileIndex];
                            final String url = file['downloadUrl'] ?? '';
                            final String fileType =
                            (file['fileType'] ?? '').toLowerCase();
                            final String fileName =
                                file['fileName'] ?? 'Unnamed';

                            bool isImage = [
                              'jpg',
                              'jpeg',
                              'png',
                              'gif',
                              'bmp',
                              'webp'
                            ].contains(fileType);

                            return GestureDetector(
                              onTap: () async {
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  border:
                                  Border.all(color: Colors.tealAccent),
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
                                        errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Icon(
                                          Icons.broken_image,
                                          color: Colors.white,
                                        ),
                                      )
                                          : Icon(
                                        fileType == 'pdf'
                                            ? Icons.picture_as_pdf
                                            : Icons.insert_drive_file,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12),
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditReceptionReportScreen(
                          docId: docId,
                          reportData: task,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDetail(String title, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$title: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 14),
            ),
            TextSpan(
              text: value.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
