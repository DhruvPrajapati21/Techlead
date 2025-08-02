import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Employee/Categoryscreen/FileViwerscreen.dart';
import 'EditAdmintaskassigned.dart';

class Admintaskassigneddata extends StatefulWidget {
  final String? projectName;
  final int? unreadCount;
  final String? highlightedTaskId;

  const Admintaskassigneddata({
    this.projectName,
    this.unreadCount,
    this.highlightedTaskId,
    Key? key,
  }) : super(key: key);

  @override
  _AdmintaskassigneddataState createState() => _AdmintaskassigneddataState();
}

class _AdmintaskassigneddataState extends State<Admintaskassigneddata> {
  String searchQuery = "";
  String? filterDepartment;
  String? employeename;
  String? filterProject;
  String? filterEmployee;
  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient:
          LinearGradient(colors: [Colors.white, Colors.grey], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text(
                "Assigned Tasks From Admin",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: "Times New Roman"),
              ),
              centerTitle: true,
              backgroundColor: Colors.blue.shade900,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            if ((widget.unreadCount ?? 0) > 0)
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    '🔔You have ${widget.unreadCount} unread task(s)',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontFamily: "Times New Roman"),
                  ),
                ),
              ),
            SizedBox(height: 20,),
            _buildDropdownFilters(),
            _buildDateFilters(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('TaskAssign').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return _noRecordsWidget("No tasks assigned.");
                  }

                  List<QueryDocumentSnapshot> docs = snap.data!.docs;
                  final allDepartments = docs
                      .map((d) => (d.data() as Map<String, dynamic>)['department']?.toString() ?? '')
                      .toSet()
                      .where((s) => s.isNotEmpty)
                      .toList();
                  final allProjects = docs
                      .map((d) => (d.data() as Map<String, dynamic>)['projectName']?.toString() ?? '')
                      .toSet()
                      .where((s) => s.isNotEmpty)
                      .toList();
                  final allEmployees = docs
                      .expand((d) => (d.data() as Map<String, dynamic>)['employeeNames'] as List)
                      .map((e) => e.toString())
                      .toSet()
                      .toList();

                  final filtered = docs.where((doc) {
                    final t = doc.data() as Map<String, dynamic>;
                    final dep = t['department']?.toString() ?? '';
                    final proj = t['projectName']?.toString() ?? '';
                    final empNames = t['taskstatus']?.toString() ?? '';

                    if (searchQuery.isNotEmpty && !proj.toLowerCase().contains(searchQuery.toLowerCase())) return false;
                    if (filterDepartment != null && filterDepartment != dep) return false;
                    if (filterProject != null && filterProject != proj) return false;
                    if (filterEmployee != null && filterEmployee != empNames) return false;

                    if (startDate != null && endDate != null) {
                      DateTime assigned;
                      try {
                        assigned = t['date'] is Timestamp
                            ? (t['date'] as Timestamp).toDate()
                            : DateFormat('dd MMMM yy').parse(t['date']);
                      } catch (_) {
                        return false;
                      }
                      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
                      final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
                      if (assigned.isBefore(start) || assigned.isAfter(end)) return false;
                    }

                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _noRecordsWidget("No records match selected filters.");
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return _buildTaskCard(doc);
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _noRecordsWidget(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(fontFamily: "Times New Roman", fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDropdownFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.1,
            child: _buildFilterDropdown(
              "Department",
              filterDepartment,
                  (val) => setState(() => filterDepartment = val),
              getOptions: () {
                return FirebaseFirestore.instance
                    .collection('TaskAssign')
                    .snapshots()
                    .map((snap) => snap.docs
                    .map((d) => (d.data() as Map<String, dynamic>)['department']?.toString() ?? '')
                    .toSet()
                    .toList());
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.1,
            child: _buildFilterDropdown(
              "Project",
              filterProject,
                  (val) => setState(() => filterProject = val),
              getOptions: () {
                return FirebaseFirestore.instance
                    .collection('TaskAssign')
                    .snapshots()
                    .map((snap) => snap.docs
                    .map((d) => (d.data() as Map<String, dynamic>)['projectName']?.toString() ?? '')
                    .toSet()
                    .toList());
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.1,
            child: _buildFilterDropdown(
              "Project Status",
              filterEmployee,
                  (val) => setState(() => filterEmployee = val),
              getOptions: () {
                return FirebaseFirestore.instance
                    .collection('TaskAssign')
                    .snapshots()
                    .map((snap) => snap.docs
                    .map((d) => (d.data() as Map<String, dynamic>)['taskstatus']?.toString() ?? '')
                    .toSet()
                    .toList());
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.1,
            child: _buildFilterDropdown(
              "Employee Name",
              employeename,
                  (val) => setState(() => employeename = val),
              getOptions: () {
                return FirebaseFirestore.instance
                    .collection('TaskAssign')
                    .snapshots()
                    .map((snap) {
                  final names = <String>{};
                  for (var doc in snap.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final field = data['employeeNames'];

                    if (field is List) {
                      names.addAll(field.map((e) => e.toString()));
                    } else if (field is String) {
                      names.add(field);
                    }
                  }
                  return names.toList();
                });
              },

            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFilterDropdown(
      String label,
      String? currentValue,
      ValueChanged<String?> onChanged, {
        required Stream<List<String>> Function() getOptions,
      }) {
    return StreamBuilder<List<String>>(
      stream: getOptions(),
      builder: (context, snap) {
        final options = snap.hasData ? (List<String>.from(snap.data!)..sort()) : <String>[];
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontFamily: "Times New Roman",
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              shadows: [
                Shadow(color: Colors.black26, blurRadius: 1, offset: Offset(0.5, 0.5)),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Color(0xFF1E3A5F), // Blueish background
          ),
          dropdownColor: Color(0xFF223D64), // Dropdown list background
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            fontFamily: "Times New Roman",
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 1, offset: Offset(0.5, 0.5)),
            ],
          ),
          isDense: true,
          value: currentValue,
          items: [null, ...options].map<DropdownMenuItem<String>>((val) {
            final v = val as String?;
            return DropdownMenuItem<String>(
              value: v,
              child: Text(
                v ?? 'Any',
                style: const TextStyle(
                  fontFamily: "Times New Roman",
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        );
      },
    );
  }

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDateButton("Start Date", startDate, (d) => setState(() => startDate = d)),
          _buildDateButton("End Date", endDate, (d) => setState(() => endDate = d)),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime? date, ValueChanged<DateTime> onDateSelected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
      onPressed: () async {
        final pick = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pick != null) onDateSelected(pick);
      },
      child: Text(
        date != null ? DateFormat('dd-MMMM-yy').format(date) : label,
        style: const TextStyle(color: Colors.white, fontFamily: "Times New Roman"),
      ),
    );
  }

  Widget _buildTaskCard(QueryDocumentSnapshot doc) {
    final task = doc.data() as Map<String, dynamic>;
    final isDeprecated = (widget.highlightedTaskId != null && task['taskId'] == widget.highlightedTaskId);

    return Dismissible(
      key: Key(task['taskId'] ?? doc.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(task['taskId']),
      onDismissed: (_) async {
        await FirebaseFirestore.instance.collection('TaskAssign').doc(doc.id).delete();
        Fluttertoast.showToast(msg: "Task deleted successfully!", backgroundColor: Colors.green, textColor: Colors.white);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: isDeprecated ? [Colors.green.shade800, Colors.green.shade600] : [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final changed = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskScreen(taskData: task)));
                  if (changed == true) setState(() {});
                },
              ),
            ),
            _buildTaskDetail('Admin Name', task['adminName']),
            _buildTaskDetail('Employee Id', task['empIds']),
            _buildTaskDetail('Employee Name', (task['employeeNames'] as List).join(', ')),
            _buildTaskDetail('Project Name', task['projectName']),
            _buildTaskDetail('Department', task['department']),
            if (['Installation', 'Sales', 'Reception', 'Social Media'].contains(task['department']) && task['siteLocation'] != null)
              ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "Note: Please tap the location to view it on the map.",
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 14),
                  ),
                ),
                _buildTaskDetail('Site Location', task['siteLocation']),
              ],
            _buildTaskDetail('Task Description', task['taskDescription']),
            _buildTaskDetail('Assigned Date', task['date']),
            _buildTaskDetail('Deadline Date', task['deadlineDate']),
            _buildTaskDetail('Time', task['time']),
            _buildTaskDetail('Task Status', task['taskstatus']),
            _buildTaskDetail('Employees Description', task['employeeDescription']),
            // files viewer omitted for brevity...
          ]),
        ),
      ),
    );
  }

  Widget _buildTaskDetail(String label, dynamic value) {
    final isLocation = label == 'Site Location';
    final text = value != null ? value.toString() : 'N/A';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: isLocation && value != null
            ? () async {
          final loc = Uri.encodeComponent(value.toString());
          final url = 'https://www.google.com/maps/search/?api=1&query=$loc';
          if (await canLaunchUrl(Uri.parse(url))) {
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          }
        }
            : null,
        child: RichText(
          text: TextSpan(
            text: "$label: ",
            style: const TextStyle(
                color: Colors.tealAccent, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: "Times New Roman"),
            children: [
              TextSpan(
                text: text,
                style: TextStyle(
                    color: isLocation ? Colors.lightBlueAccent : Colors.white,
                    decoration: isLocation ? TextDecoration.underline : TextDecoration.none,
                    fontFamily: "Times New Roman",
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String? taskId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 12,
          backgroundColor: const Color(0xFF1E2A38),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 50),
              const SizedBox(height: 16),
              const Text('Confirm Delete', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: "Times New Roman")),
              const SizedBox(height: 12),
              const Text('Are you sure you want to delete this task?', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 16, fontFamily: "Times New Roman")),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: "Times New Roman")),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Yes', style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: "Times New Roman")),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }
}
