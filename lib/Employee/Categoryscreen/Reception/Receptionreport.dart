import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Admin/Meetingsection/Edit_Reception_Data/edit_reception_data.dart';

class Receptionreport extends StatefulWidget {
  @override
  _ReceptionreportState createState() => _ReceptionreportState();
}

class _ReceptionreportState extends State<Receptionreport> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  DateTime? _startDate;
  DateTime? _endDate;


  Future<void> _selectDate({required bool isStart}) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStart ? (_startDate ?? now) : (_endDate ?? now);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _selectDate(isStart: true),
                icon: Icon(Icons.date_range,color: Colors.white,),
                label: Text(_startDate != null ? 'From: ${DateFormat('dd MMM yyyy').format(_startDate!)}' : 'Start Date',style: TextStyle(fontFamily: "Times New Roman",color: Colors.white),),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
              ),
              ElevatedButton.icon(
                onPressed: () => _selectDate(isStart: false),
                icon: Icon(Icons.date_range,color: Colors.white,),
                label: Text(_endDate != null ? 'To: ${DateFormat('dd MMM yyyy').format(_endDate!)}' : 'End Date',style: TextStyle(fontFamily: "Times New Roman",color: Colors.white),),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
              ),
            ],
          ),
          SizedBox(height: 10,),

          Expanded(
            child: currentUserId == null
                ? const Center(child: Text("User not logged in"))
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('EmpProfile')
                        .doc(currentUserId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Center(
                          child: Text(
                            "User profile not found.",
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final empFullName = snapshot.data!
                          .get('fullName')
                          .toString()
                          .trim()
                          .toLowerCase();
                      print("👤 Logged-in user: $empFullName");

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('ReceptionPage')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No Reception info available!',
                                style: TextStyle(fontFamily: 'Times New Roman'),
                              ),
                            );
                          }

                          final filteredDocs = snapshot.data!.docs.where((doc) {
                            final empInfoField = doc['emp_info'];
                            final dateString = doc['appointment_date'] ?? '';
                            DateTime? appointmentDate;

                            try {
                              appointmentDate = DateTime.parse(dateString);
                            } catch (e) {
                              return false; // Skip invalid date formats
                            }

                            List<String> empList = [];

                            if (empInfoField is List) {
                              empList = List<String>.from(empInfoField)
                                  .map((e) => e.toLowerCase().trim())
                                  .toList();
                            } else if (empInfoField is String) {
                              empList = empInfoField
                                  .toLowerCase()
                                  .split(',')
                                  .map((e) => e.trim())
                                  .toList();
                            }

                            final isAssigned = empList.contains(empFullName);

                            final clientName = (doc['client_name'] ?? '')
                                .toString()
                                .toLowerCase();

                            final matchesSearch = _searchQuery.isEmpty ||
                                clientName.contains(_searchQuery.toLowerCase());

                            final matchesStartDate = _startDate == null ||
                                appointmentDate.isAfter(_startDate!.subtract(const Duration(days: 1)));

                            final matchesEndDate = _endDate == null ||
                                appointmentDate.isBefore(_endDate!.add(const Duration(days: 1)));

                            return isAssigned && matchesSearch && matchesStartDate && matchesEndDate;
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
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }


                          return ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              return Padding(
                                padding: const EdgeInsets.all(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF0A2A5A), // Deep navy blue
                                          Color(
                                              0xFF15489C), // Strong steel blue
                                          Color(0xFF1E64D8), // Vivid rich blue
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.shade900
                                              .withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(15.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("Employee Information",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: "Times New Roman",
                                                fontSize: 16,
                                                color: Colors.white)),
                                        SizedBox(
                                          height: 10,
                                        ),
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
                                        buildFormField('Contact Number:',
                                            doc['phone_number']),
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
                                        buildFormField('Appointment Date: ', _formatDate(doc['appointment_date'])),
                                        buildFormField('Appointment Time: ',
                                            doc['appointment_time']),
                                        buildFormField('Meeting Purpose: ',
                                            doc['meeting_purpose']),
                                        buildFormField('Meeting Location: ',
                                            doc['location']),
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
                                        buildFormField('Task Status: ',
                                            doc['task_status']),
                                        buildFormField(
                                            'Client Meeting Status: ',
                                            doc['client_meeting_status']),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
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
                                                          as Map<String,
                                                              dynamic>,
                                                    ),
                                                  ));
                                                },
                                                backgroundColor:
                                                    Color(0xFF0A2A5A),
                                                child: const Icon(Icons.edit,
                                                    color: Colors.white),
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
                        },
                      );
                    }),
          ),
        ],
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

  }