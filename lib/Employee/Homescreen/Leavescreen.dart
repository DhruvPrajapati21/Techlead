import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:http/http.dart' as http;
import '../../Default/customwidget.dart';

final RegExp emailRegExp = RegExp(
  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
);

class Leavescreen extends StatefulWidget {
  const Leavescreen({super.key});

  @override
  State<Leavescreen> createState() => _LeavescreenState();
}

class _LeavescreenState extends State<Leavescreen> {
  List<String> leaveinfo = ['Leave Type', 'Full Leave', 'First Half Leave','Second Half Leave'];
  String? selectedLeaveinfo = 'Leave Type';
  bool isLoading = false;
  String userName = '';
  String empId = '';
  String email = '';
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

  Future<void> fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No authenticated user found.");
        return;
      }

      String userId = user.uid;
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(userId)
          .get();

      if (userSnapshot.exists && userSnapshot.data() != null) {
        setState(() {
          empNameController.text = userSnapshot.get('fullName') ?? "Unknown";
          empIdController.text = userSnapshot.get('empId') ?? "Unknown";
          empemailidController.text = userSnapshot.get('email') ?? "Unknown";
        });
        print("Fetched Data: ${empNameController.text}, ${empIdController.text}, ${empemailidController.text}");
      } else {
        print("No user data found for userId: $userId");
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _addToFirestore() async {
    if (_validateFields()) {
      // Validate Leave Type first
      if (selectedLeaveinfo == 'Leave Type') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a valid Leave Type.'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String? emailError = _validateEmail(empemailidController.text.trim());
      if (emailError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(emailError),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
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
              backgroundColor: Colors.orange,
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
            startdateController.clear();
            enddateController.clear();
            reasonController.clear();
            selectedLeaveinfo = 'Leave Type';
            startdate = null;
            enddate = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Leave Data added and email sent successfully!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error adding data to Firestore: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add data. Please try again.', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
    final message = Message()
      ..from = Address(userEmail, empNameController.text.trim())
      ..recipients.add('Deep6796@gmail.com')
      ..subject = 'New Leave Request'
      ..text = 'Leave Request Details:\n'
          'Empid:${empIdController.text.trim()}\n'
          'Name: ${empNameController.text.trim()}\n'
          'Empemailid: ${empemailidController.text.trim()}\n'
          'Leave Type: ${selectedLeaveinfo}\n'
          'Start Date: ${startdateController.text.trim()}\n'
          'End Date: ${enddateController.text.trim()}\n'
          'Reason: ${reasonController.text.trim()}\n'
          'reportedDateTime: $formattedDateTime';

    try {
      print('Sending email...');
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, {required bool isStart}) async {
    final DateTime today = DateTime.now();
    final DateTime onlyDate = DateTime(today.year, today.month, today.day);

    DateTime initialDate = isStart
        ? (startdate ?? onlyDate)
        : (enddate ?? (startdate ?? onlyDate));

    DateTime firstDate = isStart
        ? onlyDate
        : (startdate ?? onlyDate);

    DateTime lastDate = isStart
        ? (enddate ?? DateTime(2101))
        : DateTime(2101);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      if (isStart && enddate != null && pickedDate.isAfter(enddate!)) {
        _showValidationDialog(context, "Start date cannot be after End date.");
        return;
      }

      if (!isStart && startdate != null && pickedDate.isBefore(startdate!)) {
        _showValidationDialog(context, "End date cannot be before Start date.");
        return;
      }

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

  void _showValidationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Invalid Date Selection"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
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
  void initState() {
    super.initState();
    fetchUserName();
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
              Colors.white,
              Colors.lightBlueAccent.shade100,
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
                  buildLeaveFields(),
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

  Widget buildLeaveFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: Column(
        children: [
          buildLeaveField(
            context: context,
            controller: empIdController,
            labelText: 'Enter Your EmpId',
            icon: Icons.perm_identity,
            readOnly: empIdController.text.isNotEmpty,
            validator: (value) => value == null || value.isEmpty ? "Please enter your EmpID" : null,
          ),
          buildLeaveField(
            controller: empNameController,
            context: context,
            labelText: 'Enter Your EmpName',
            icon: Icons.person,
            readOnly: empNameController.text.isNotEmpty,
            validator: (value) => value == null || value.isEmpty ? "Please enter your EmpName" : null,
          ),
          buildLeaveField(
            controller: empemailidController,
            labelText: 'Enter Your EmailID',
            context: context,
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            readOnly: empemailidController.text.isNotEmpty,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your emailID';
              if (!value.contains('@') || !value.contains('.com') || !value.contains('gmail')) return 'Please enter a valid email';
              return null;
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonFormField<String>(
              dropdownColor: Colors.blue.shade700,
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.category, color: Colors.white),
                ),
                labelText: 'Leave Type',
                labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              value: selectedLeaveinfo,
              items: leaveinfo
                  .map((item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: TextStyle(fontSize: 18, color: Colors.white)),
              ))
                  .toList(),
              onChanged: (item) => setState(() => selectedLeaveinfo = item),
              validator: (value) => value == null || value.isEmpty || value == 'Leave Type'
                  ? "Please select a Leave Type"
                  : null,
            ),
          ),
          buildLeaveField(
            controller: startdateController,
            labelText: "Start Date",
            context: context,
            icon: Icons.calendar_today,
            readOnly: true,
            onTap: () => _selectDate(context, isStart: true),
          ),
          buildLeaveField(
            controller: enddateController,
            labelText: "End Date",
            context: context,
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () => _selectDate(context, isStart: false),
          ),
          buildLeaveField(
            controller: reasonController,
            labelText: "Reason",
            icon: Icons.description,
            context: context,
            maxLines: 6,
            hintText: "Explain the reason for leave...",
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
            style: TextStyle(fontSize: 16, color: Colors.white),
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
                                      color: status == 'Approved'
                                          ? Colors.greenAccent
                                          : status == 'pending'
                                          ? Colors.orange
                                          : Colors.red,

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