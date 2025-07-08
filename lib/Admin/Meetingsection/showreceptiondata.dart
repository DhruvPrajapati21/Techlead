import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Edit_Reception_Data/edit_reception_data.dart';
class Showreceptiondata extends StatefulWidget {
  @override
  _ShowreceptiondataState createState() => _ShowreceptiondataState();
}

class _ShowreceptiondataState extends State<Showreceptiondata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        isStart ? (_startDate ?? now) : (_endDate ?? now);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('ReceptionPage').doc(docId).delete();
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Reception Record deleted successfully',
            style: TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting record: $e',
            style: TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.info,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Meeting Summary",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.5,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0A2A5A), // Deep navy blue
                    Color(0xFF15489C), // Strong steel blue
                    Color(0xFF1E64D8), // Vivid rich blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search by Clientname...',
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Enter Client full name',
                  hintStyle: TextStyle(
                    color: Colors.cyan.shade300,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(Icons.search, color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _selectDate(isStart: true),
                icon: Icon(
                  Icons.date_range,
                  color: Colors.white,
                ),
                label: Text(
                  _startDate != null
                      ? 'From: ${DateFormat('dd MMM yyyy').format(_startDate!)}'
                      : 'Start Date',
                  style: TextStyle(
                      fontFamily: "Times New Roman", color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5))),
              ),
              ElevatedButton.icon(
                onPressed: () => _selectDate(isStart: false),
                icon: Icon(
                  Icons.date_range,
                  color: Colors.white,
                ),
                label: Text(
                  _endDate != null
                      ? 'To: ${DateFormat('dd MMM yyyy').format(_endDate!)}'
                      : 'End Date',
                  style: TextStyle(
                      fontFamily: "Times New Roman", color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5))),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('ReceptionPage').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No Reception info available!',
                        style: TextStyle(
                            fontFamily: 'Times New Roman',),
                      ),
                    );
                  }
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final clientName =
                        (doc['client_name'] ?? '').toString().toLowerCase();
                    final dateString = doc['appointment_date'] ?? '';
                    DateTime? appointmentDate;

                    try {
                      appointmentDate = DateTime.parse(dateString);
                    } catch (e) {
                      return false;
                    }

                    final matchesSearch =
                        clientName.contains(_searchQuery.toLowerCase());
                    final matchesStartDate = _startDate == null ||
                        appointmentDate
                            .isAfter(_startDate!.subtract(Duration(days: 1)));
                    final matchesEndDate = _endDate == null ||
                        appointmentDate
                            .isBefore(_endDate!.add(Duration(days: 1)));

                    return matchesSearch && matchesStartDate && matchesEndDate;
                  }).toList();

                  String _formatDate(String rawDate) {
                    try {
                      final DateTime parsedDate = DateTime.parse(rawDate);
                      return DateFormat('dd MMMM yyyy').format(parsedDate);
                    } catch (e) {
                      return rawDate; // Fallback to original if parsing fails
                    }
                  }

                  if (filteredDocs.isEmpty) {
                    return Center(
                      child: Text(
                        'No data between selected dates!',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];

                      return Builder(
                        builder: (BuildContext newContext) {
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Dismissible(
                              key: Key(doc.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                final delete =
                                    await _showDeleteConfirmationDialog();
                                return delete == true;
                              },
                              onDismissed: (direction) async {
                                await _deleteRecord(doc.id); // now no context needed
                              },

                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.cyanAccent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 20.0),
                                    child:
                                        Icon(Icons.delete, color: Colors.white),
                                  ),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF0A2A5A),
                                      Color(0xFF15489C),
                                      Color(0xFF1E64D8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.blue.shade900.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Employee Information",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "Times New Roman",
                                            fontSize: 16,
                                            color: Colors.white)),
                                    buildFormField(
                                      'Employee Name: ',
                                      (() {
                                        final empInfo = doc['emp_info'];

                                        if (empInfo is List) {
                                          return empInfo.join(', ');
                                        } else if (empInfo is String) {
                                          return empInfo;
                                        } else {
                                          return 'N/A';
                                        }
                                      })(),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text("Client Information",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: "Times New Roman",
                                            fontSize: 16,
                                            color: Colors.white)),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    buildFormField('Client Full Name: ',
                                        doc['client_name']),
                                    buildFormField(
                                        'Contact Number:', doc['phone_number']),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "Appointment Scheduling",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "Times New Roman",
                                          fontSize: 16,
                                          color: Colors.white),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    buildFormField('Appointment Date: ',
                                        _formatDate(doc['appointment_date'])),
                                    buildFormField('Appointment Time: ',
                                        doc['appointment_time']),
                                    buildFormField('Meeting Purpose: ',
                                        doc['meeting_purpose']),
                                    buildFormField(
                                        'Meeting Location: ', doc['location']),
                                    buildFormField('Assigned Staff/CEO: ',
                                        doc['assigned_staff']),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                      "Task Management",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: "Times New Roman",
                                          fontSize: 16,
                                          color: Colors.white),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    buildFormField('Task Priority: ',
                                        doc['task_priority']),
                                    buildFormField('Task Due Date: ',
                                      _formatDate(doc['task_due_date'])),
                                    buildFormField(
                                        'Task Status: ', doc['task_status']),
                                    buildFormField('Client Meeting Status: ',
                                        doc['client_meeting_status']),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Container(
                                          child: FloatingActionButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .push(MaterialPageRoute(
                                                builder: (context) =>
                                                    Editreceptionpage(
                                                  docId: doc.id,
                                                  initialData: doc.data()
                                                      as Map<String, dynamic>,
                                                ),
                                              ));
                                            },
                                            backgroundColor: Color(0xFF0A2A5A),
                                            child: const Icon(Icons.edit,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
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
      ),
    );
  }

  Widget buildFormField(String title, String value) {
    final isLocationField = title.toLowerCase().contains('location');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Arial',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: isLocationField && value.isNotEmpty
                      ? () async {
                          final encodedLocation = Uri.encodeComponent(value);
                          final googleMapsUrl =
                              'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
                          if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
                            await launchUrl(Uri.parse(googleMapsUrl),
                                mode: LaunchMode.externalApplication);
                          } else {
                            debugPrint('Could not open map for $value');
                          }
                        }
                      : null,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Arial',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: isLocationField
                          ? Colors.lightBlueAccent
                          : Colors.white,
                      decoration: isLocationField
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
          ),
          if (isLocationField)
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Text(
                "Note: Please tap the location to view it on the map.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.redAccent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete Confirmation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete this record?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors
                        .cyan.shade100, // Cyan accent for the content text
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.cyanAccent.shade200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
