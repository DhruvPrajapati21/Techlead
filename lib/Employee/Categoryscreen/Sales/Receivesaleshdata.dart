import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../FileViwerscreen.dart';

class Receivesalesdata extends StatefulWidget {
  final String? projectName;
  final int? unreadCount;
  final String? highlightedTaskId;

  const Receivesalesdata({this.projectName, this.unreadCount,this.highlightedTaskId,});

  @override
  State<Receivesalesdata> createState() => _ReceivesalesdataState();
}

class _ReceivesalesdataState extends State<Receivesalesdata> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool scrolledToProject = false;
  bool scrolledToUnread = false;
  String? editingDocId;
  Map<String, dynamic> editingData = {};
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assigned Tasks From Admin",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontFamily: "Times New Roman",fontSize: 14)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          if ((widget.unreadCount ?? 0) > 0)
            Container(
              width: double.infinity,
              color: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: Text(
                  '🔔You have ${widget.unreadCount} unread task(s) as a green color card',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold,fontFamily: "Times New Roman"),
                ),
              ),
            ),
          _buildSearchBar(),
          _buildDateFilters(),
          Expanded(
            child: currentUserId == null
                ? const Center(child: Text("User not logged in"))
                : FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('EmpProfile').doc(currentUserId).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("User profile not found.", style: TextStyle(color: Colors.red)));
                }

                final empId = snapshot.data!.get('fullName');

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('TaskAssign')
                      .where('department', isEqualTo: 'Sales')
                      .where('employeeNames', arrayContains: empId)
                      .snapshots(),
                  builder: (context, taskSnapshot) {
                    if (!taskSnapshot.hasData || taskSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No tasks assigned.", style: TextStyle(fontSize: 16)));
                    }

                    final assignedTasks = taskSnapshot.data!.docs.where((doc) {
                      final task = doc.data() as Map<String, dynamic>;
                      final isUnread = task['isUnread'] == true;
                      final name = task['projectName']?.toString().toLowerCase() ?? '';
                      if (searchQuery.isNotEmpty && !name.contains(searchQuery.toLowerCase())) return false;

                      if (startDate != null && endDate != null) {
                        try {
                          DateTime assignedDate = task['date'] is Timestamp
                              ? (task['date'] as Timestamp).toDate()
                              : DateFormat('dd MMMM yy').parse(task['date']);
                          DateTime start = DateTime(startDate!.year, startDate!.month, startDate!.day);
                          DateTime end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
                          if (assignedDate.isBefore(start) || assignedDate.isAfter(end)) return false;
                        } catch (_) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();


                    if (assignedTasks.isEmpty) {
                      return Center(
                        child: Text(
                          (widget.unreadCount ?? 0) > 0
                              ? "You have unread tasks, but none match the filters."
                              : "No tasks assigned.",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: "Times New Roman",
                          ),
                        ),
                      );
                    }

                    if (assignedTasks.isEmpty) {
                      return const Center(child: Text("No tasks available between these dates.", style: TextStyle(fontSize: 16)));
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!scrolledToProject && widget.projectName != null) {
                      } else if (!scrolledToUnread && widget.highlightedTaskId != null) {
                        final unreadIndex = assignedTasks.indexWhere((doc) {
                          final task = doc.data() as Map<String, dynamic>;
                          return task['taskId'] == widget.highlightedTaskId;
                        });
                        if (unreadIndex != -1) {
                          _scrollController.animateTo(
                            unreadIndex * 280.0,
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeInOut,
                          );
                          scrolledToUnread = true;
                        }
                      } else if (!scrolledToUnread && (widget.unreadCount ?? 0) > 0) {
                        final unreadIndex = assignedTasks.indexWhere((doc) {
                          final task = doc.data() as Map<String, dynamic>;
                          return task['isUnread'] == true;
                        });
                        if (unreadIndex != -1) {
                          _scrollController.animateTo(
                            unreadIndex * 280.0,
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeInOut,
                          );
                          scrolledToUnread = true;
                        }
                      }
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: assignedTasks.length,
                      itemBuilder: (context, index) {
                        final doc = assignedTasks[index];
                        final task = doc.data() as Map<String, dynamic>;

                        final isProjectHighlighted = widget.projectName != null &&
                            task['projectName']?.toString().toLowerCase().trim() ==
                                widget.projectName!.toLowerCase().trim();

                        final isUnreadHighlighted = widget.highlightedTaskId != null &&
                            task['taskId']?.toString() == widget.highlightedTaskId;


                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: (isProjectHighlighted || isUnreadHighlighted ||
                                      (widget.highlightedTaskId != null &&
                                          task['taskId']?.toString() == widget.highlightedTaskId))
                                      ? [Colors.green.shade800, Colors.green.shade600]
                                      : [Colors.blue.shade900, Colors.blue.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  _buildTaskDetail(
                                      'Admin Name', task['adminName']),
                                  _buildTaskDetail(
                                      'Employee Id', task['empIds']),
                                  _buildTaskDetail(
                                      'Employee Name',
                                      (task['employeeNames'] as List)
                                          .join(', ')),
                                  _buildTaskDetail('Project Name',
                                      task['projectName']),
                                  _buildTaskDetail(
                                      'Department', task['department']),
                                  if (task['siteLocation'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 12.0),
                                      child: Text(
                                        "Note: Please tap the location to view it on the map.",
                                        style: TextStyle(
                                            color: Colors.orangeAccent,
                                            fontSize: 14),
                                      ),
                                    ),
                                  _buildTaskDetail('Site Location',
                                      task['siteLocation']),
                                  _buildTaskDetail('Task Description',
                                      task['taskDescription']),
                                  _buildTaskDetail(
                                      'Assigned Date', task['date']),
                                  _buildTaskDetail('Deadline Date',
                                      task['deadlineDate']),
                                  _buildTaskDetail('Time', task['time']),

                                  // 📂 Show Files If Present
                                  // 📂 Show Files If Present
                                  if (task['files'] != null &&
                                      task['files'] is List &&
                                      task['files'].isNotEmpty)
                                    Padding(
                                      padding:
                                      const EdgeInsets.only(top: 10),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              scrollDirection:
                                              Axis.horizontal,
                                              itemCount:
                                              task['files'].length,
                                              itemBuilder:
                                                  (context, fileIndex) {
                                                var file = task['files']
                                                [fileIndex];
                                                final String url =
                                                    file['downloadUrl'] ??
                                                        '';
                                                final String fileType =
                                                (file['fileType'] ??
                                                    '')
                                                    .toLowerCase();
                                                final String fileName =
                                                    file['fileName'] ??
                                                        'Unnamed';

                                                bool isImage = [
                                                  'jpg',
                                                  'jpeg',
                                                  'png',
                                                  'gif',
                                                  'bmp',
                                                  'webp'
                                                ].contains(fileType);

                                                return GestureDetector(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            FileViewerScreen(
                                                              url: url,
                                                              fileType:
                                                              fileType,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 120,
                                                    margin:
                                                    const EdgeInsets
                                                        .only(
                                                        right: 10),
                                                    padding:
                                                    const EdgeInsets
                                                        .all(6),
                                                    decoration:
                                                    BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(
                                                          0.1),
                                                      border: Border.all(
                                                          color: Colors
                                                              .tealAccent),
                                                      borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                          10),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                              6),
                                                          child: isImage
                                                              ? Image
                                                              .network(
                                                            url,
                                                            width:
                                                            100,
                                                            height:
                                                            70,
                                                            fit: BoxFit
                                                                .cover,
                                                            errorBuilder: (context, error, stackTrace) => const Icon(
                                                                Icons
                                                                    .broken_image,
                                                                color:
                                                                Colors.white),
                                                          )
                                                              : Icon(
                                                            fileType ==
                                                                'pdf'
                                                                ? Icons.picture_as_pdf
                                                                : Icons.insert_drive_file,
                                                            color: Colors
                                                                .white,
                                                            size:
                                                            50,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 5),
                                                        Text(
                                                          fileName,
                                                          maxLines: 1,
                                                          overflow:
                                                          TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize:
                                                              12),
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
          labelText: "Search by Project Name",
          labelStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
  Widget _buildDateButton(
      String label, DateTime? date, Function(DateTime) onDateSelected) {
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
    final isLocationField = label == 'Site Location';
    final displayText = value != null ? value.toString() : 'N/A';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: isLocationField && value != null
            ? () async {
          final location = Uri.encodeComponent(value.toString());
          final googleMapsUrl =
              'https://www.google.com/maps/search/?api=1&query=$location';
          if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
            await launchUrl(Uri.parse(googleMapsUrl),
                mode: LaunchMode.externalApplication);
          } else {
            debugPrint('Could not launch Maps for location: $location');
          }
        }
            : null,
        child: RichText(
          text: TextSpan(
            text: "$label: ",
            style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: "Times New Roman"),
            children: [
              TextSpan(
                text: displayText,
                style: TextStyle(
                  color:
                  isLocationField ? Colors.lightBlueAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Times New Roman",
                  decoration: isLocationField
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
