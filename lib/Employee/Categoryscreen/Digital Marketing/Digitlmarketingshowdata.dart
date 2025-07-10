import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../FileViwerscreen.dart';

class Digitlmarketingshowdata extends StatefulWidget {
  final String? projectName;
  final int? unreadCount;
  final String? highlightedTaskId;

  const Digitlmarketingshowdata({this.projectName, this.unreadCount,this.highlightedTaskId,});

  @override
  State<Digitlmarketingshowdata> createState() => _DigitlmarketingshowdataState();
}

class _DigitlmarketingshowdataState extends State<Digitlmarketingshowdata> {
  String searchQuery = "";
  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool scrolledToProject = false;
  bool scrolledToUnread = false;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.white, Colors.grey], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text(
                "Assigned Tasks From Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Times New Roman",
                  fontSize: 14,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue.shade900,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            _buildSearchBar(),
            _buildDateFilters(),
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
                        .where('department', isEqualTo: 'Digital Marketing')
                        .where('employeeNames', arrayContains: empId)
                        .snapshots(),
                    builder: (context, taskSnapshot) {
                      if (!taskSnapshot.hasData || taskSnapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text("No tasks assigned.", style: TextStyle(fontSize: 16,fontFamily: "Times New Roman")));
                      }

                      final assignedTasks = taskSnapshot.data!.docs.where((doc) {
                        final task = doc.data() as Map<String, dynamic>;
                        final isUnread = task['isUnread'] == true;
                        final name = task['projectName']?.toString().toLowerCase() ?? '';

                        if (searchQuery.isNotEmpty &&
                            !name.contains(searchQuery.toLowerCase())) return false;

                        if (startDate != null && endDate != null) {
                          try {
                            DateTime assignedDate = task['date'] is Timestamp
                                ? (task['date'] as Timestamp).toDate()
                                : DateFormat('dd MMMM yy').parse(task['date']);

                            DateTime start = DateTime(
                                startDate!.year, startDate!.month, startDate!.day);
                            DateTime end = DateTime(
                                endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);

                            if (assignedDate.isBefore(start) || assignedDate.isAfter(end)) {
                              return false;
                            }
                          } catch (_) {
                            return false;
                          }
                        }

                        return true;
                      }).toList();

                      if (assignedTasks.isEmpty) {
                        return const Center(child: Text("No tasks available between these dates.", style: TextStyle(fontSize: 16)));
                        // return empty widget to avoid showing text
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

                          final isTaskIdHighlighted = widget.highlightedTaskId != null &&
                              task['taskId']?.toString() == widget.highlightedTaskId;

                          final highlight = isProjectHighlighted || isTaskIdHighlighted;

                          return _buildTaskCard(task, highlight);
                        },
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          labelText: "Search by Project Name",
          labelStyle: const TextStyle(color: Colors.white),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.blue.shade900,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          setState(() => searchQuery = value);
        },
      ),
    );
  }

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDateButton("Start Date", startDate, (date) => setState(() => startDate = date)),
          _buildDateButton("End Date", endDate, (date) => setState(() => endDate = date)),
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
        if (picked != null) onDateSelected(picked);
      },
      child: Text(
        date != null ? DateFormat('dd-MMMM-yy').format(date) : label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, bool highlight) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child:Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: highlight
                  ? [Colors.green.shade800, Colors.green.shade600]
                  : [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskDetail("Admin Name", task['adminName']),
              _buildTaskDetail("Employee Id", task['empIds']),
              _buildTaskDetail("Employee Name", (task['employeeNames'] as List).join(', ')),
              _buildTaskDetail("Project Name", task['projectName']),
              _buildTaskDetail("Department", task['department']),
              _buildTaskDetail("Task Description", task['taskDescription']),
              _buildTaskDetail("Assigned Date", task['date']),
              _buildTaskDetail("Deadline Date", task['deadlineDate']),
              _buildTaskDetail("Time", task['time']),
              if (task['files'] != null && task['files'] is List && task['files'].isNotEmpty)
                _buildFilesSection(task['files']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskDetail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: "$label: ",
          style: const TextStyle(
              color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Times New Roman"),
          children: [
            TextSpan(
              text: value?.toString() ?? 'N/A',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesSection(List<dynamic> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Attached Files:", style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final url = file['downloadUrl'] ?? '';
              final fileType = (file['fileType'] ?? '').toLowerCase();
              final fileName = file['fileName'] ?? 'Unnamed';
              final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType);

              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => FileViewerScreen(url: url, fileType: fileType))),
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
                            ? Image.network(url, width: 100, height: 70, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white))
                            : Icon(
                          fileType == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
