import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart' as mailer;  // Alias mailer package
import 'package:mailer/smtp_server/gmail.dart';
import 'package:http/http.dart' as http;

import '../customwidget.dart';
final RegExp emailRegExp = RegExp(
  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
);

class Leavescreen2 extends StatefulWidget {
  const Leavescreen2({super.key});

  @override
  State<Leavescreen2> createState() => _Leavescreen2State();
}

class _Leavescreen2State extends State<Leavescreen2> {
  List<String> leaveinfo = ['Leave Type', 'Full Leave', 'First Half Leave','Second Half Leave'];
  String? selectedLeaveinfo = 'Leave Type';
  bool isLoading = false;
  DateTime? startdate;
  DateTime? enddate;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController empIdController = TextEditingController();
  final TextEditingController empNameController = TextEditingController();
  final TextEditingController empemailidController = TextEditingController();
  final TextEditingController startdateController = TextEditingController();
  final TextEditingController enddateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your EmailID';
    } else if (!emailRegExp.hasMatch(value)) {
      return 'Please enter a valid email address';
    } else if (!value.contains('@') || !value.contains('.com') || !value.contains('gmail')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _addToFirestore() async {
    if (_validateFields()) {
      String? emailError = _validateEmail(empemailidController.text.trim());
      if (emailError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailError),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;

        if (userId == null) {
          throw Exception("User not logged in");
        }

        QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
            .collection('Empleave')
            .where('empid', isEqualTo: empIdController.text.trim())
            .where('name', isEqualTo: empNameController.text.trim())
            .where('emailid', isEqualTo: empemailidController.text.trim())
            .where('startdate', isEqualTo: _formatDate(startdate!))
            .where('enddate', isEqualTo: _formatDate(enddate!))
            .where('reason', isEqualTo: reasonController.text.trim())
            .where('userId', isEqualTo: userId)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Leave request already exists.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          await _firestore.collection('Empleave').add({
            'empid': empIdController.text.trim(),
            'name': empNameController.text.trim(),
            'emailid': empemailidController.text.trim(),
            'leavetype': selectedLeaveinfo,
            'startdate': _formatDate(startdate!),
            'enddate': _formatDate(enddate!),
            'reason': reasonController.text.trim(),
            'status': 'pending',
            'reportedDateTime': FieldValue.serverTimestamp(),
            'userId': userId,
          });
          await _sendEmail();

          setState(() {
            empIdController.clear();
            empNameController.clear();
            empemailidController.clear();
            startdateController.clear();
            enddateController.clear();
            reasonController.clear();
            selectedLeaveinfo = 'Leave Type';
            startdate = null;
            enddate = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Data added to Firestore and email sent successfully!'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error adding data to Firestore: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add data to Firestore. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All fields must be filled.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _sendEmail() async {
    final userEmail = empemailidController.text.trim();
    String username = "manthanpatel26510@gmail.com";
    String appSpecificPassword = "uqvcfqumgbynnpzq";

    final smtpServer = gmail(username, appSpecificPassword);
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('dd-MM-yyyy hh:mm:ss a').format(now);

    try {
      final message = mailer.Message()
        ..from = mailer.Address(userEmail, empNameController.text.trim())  // Use mailer.Address
        ..recipients.add('Info@techleadsolution.in')
        ..subject = 'New Leave Request'
        ..text = '''Leave Request Details:
      Empid: ${empIdController.text.trim()}
      Name: ${empNameController.text.trim()}
      Empemailid: ${empemailidController.text.trim()}
      Leave Type: ${selectedLeaveinfo}
      Start Date: ${startdateController.text.trim()}
      End Date: ${enddateController.text.trim()}
      Reason: ${reasonController.text.trim()}
      reportedDateTime: $formattedDateTime''';

      print('Sending email...');
      final sendReport = await mailer.send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on mailer.MailerException catch (e) {  // Handle mailer exceptions
      print('Message not sent. \n' + e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          startdate = pickedDate;
          startdateController.text = _formatDate(pickedDate);
        } else {
          enddate = pickedDate;
          enddateController.text = _formatDate(pickedDate);
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  bool _validateFields() {
    return empNameController.text.trim().isNotEmpty &&
        empemailidController.text.trim().isNotEmpty &&
        startdateController.text.trim().isNotEmpty &&
        enddateController.text.trim().isNotEmpty &&
        reasonController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: Text(
          "Leave Form",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,  // Light sky blue
              Colors.lightBlueAccent.shade100,  // Bluish color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildFormFields(),
                  SizedBox(height: 20),
                  _buildSubmitButton(),
                  SizedBox(height: 20),
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        "Your Leave Records",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildLeaveData(),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildFormFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildTextField(
              controller: empIdController,
              labelText: 'Enter Your EmpId',
              icon: Icons.perm_identity,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your EmpID";
                }
                return null;
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildTextField(
              controller: empNameController,
              labelText: 'Enter Your EmpName',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your EmpName";
                }
                return null;
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildTextField(
              controller: empemailidController,
              labelText: 'Enter Your EmailID',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your emailID';
                } else if (!value.contains('@') || !value.contains('.com') || !value.contains('gmail')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: buildDropdownField(
              labelText: 'Leave Type',  // Label for the dropdown
              icon: Icons.holiday_village_sharp,  // Icon for the dropdown
              value: selectedLeaveinfo,  // Selected value for the dropdown
              items: leaveinfo.map((item) => {
                'text': item,
                'icon': Icons.event, // You can customize the icon as per your requirement
              }).toList(),
              onChanged: (item) {
                setState(() {
                  selectedLeaveinfo = item;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty || value == 'Leave Type') {
                  return "Please select a Leave Type";
                }
                return null;
              },
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildDatePickerField(
              context,
              label: "StartDate",
              date: startdate,
              onTap: () {
                _selectDate(context, isStart: true);
              },
              validator: null, // You can add a validator if needed
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildDatePickerField(
              context,
              label: "EndDate",
              date: enddate,
              onTap: () {
                _selectDate(context, isStart: false);
              },
              validator: null, // You can add a validator if needed
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(8.0),
            child: buildTextField(
              controller: reasonController,
              labelText: 'Reason',
              icon: Icons.text_fields,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              validator: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SizedBox(

        child: ElevatedButton(
          onPressed: () async {
            _addToFirestore();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade900,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
            "Update Info!",
            style: TextStyle(fontSize: 16, color: Colors.white,fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }


  Widget _buildLeaveData() {
    final userId = FirebaseAuth.instance.currentUser
        ?.uid;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('Empleave')
          .orderBy('reportedDateTime', descending: false)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No leave data available.'));
        }

        final leaveDocs = snapshot.data!.docs;

        return Column(
          children: leaveDocs.asMap().map((index, doc) {
            final leave = doc.data();
            final status = leave['status'] ?? 'N/A';
            final startdate = leave['startdate'] ?? 'N/A';
            final enddate = leave['enddate'] ?? 'N/A';
            final reason = leave['reason'] ?? 'N/A';
            final reportedDateTime = leave['reportedDateTime'] ?? null;

            return MapEntry(
              index,
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 15),
                child: Card(
                  color: Colors.white60,
                  margin: EdgeInsets.all(5.0),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade900, Colors.blue.shade700],
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
                      child: ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Record: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white, // White text for visibility
                                        ),
                                      ),
                                      TextSpan(
                                        text: '${index + 1}', // Or another dynamic value
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white, // White text for visibility
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'EmpId: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: leave['empid'], // Dynamic value from your leave object
                                    style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Name: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: leave['name'], // Dynamic value from your leave object
                                    style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'EmailId: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: leave['emailid'], // Dynamic value
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10,),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Leavetype: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: leave['leavetype'], // Dynamic value
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Start Date: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: leave['startdate'], // Dynamic value
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'End Date: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: leave['enddate'], // Dynamic value
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Reason: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: leave['reason'], // Dynamic value
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Status: ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                  TextSpan(
                                    text: status, // Dynamic value
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: status == 'Approved' ? Colors.greenAccent : Colors.yellowAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Reported Date&Time: ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent, fontSize: 12),
                                ),
                                Text(
                                  reportedDateTime != null
                                      ? DateFormat('dd/MM/yyyy HH:mm:ss').format(reportedDateTime.toDate())
                                      : 'N/A',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                ),
              ),
            );
          }).values.toList(),
        );
      },
    );
  }
}