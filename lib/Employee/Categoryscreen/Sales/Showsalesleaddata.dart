import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Admin/Sales/Edit_Sales_Info_Page.dart';

// import statements remain same...

class Showsalesleaddata extends StatefulWidget {
  @override
  _ShowsalesleaddataState createState() => _ShowsalesleaddataState();
}

class _ShowsalesleaddataState extends State<Showsalesleaddata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('Salesinfo').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sales Record deleted successfully', style: TextStyle(fontFamily: "Times New Roman", color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e', style: TextStyle(fontFamily: "Times New Roman", color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatReportedDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd‑MMMM‑yyyy hh:mm:ss a').format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat('dd‑MMMM‑yyyy hh:mm:ss a').format(timestamp);
    } else {
      return 'N/A';
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.info, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Sales Summary",
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
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(10.0),
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
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontFamily: "Times New Roman"
                ),
                decoration: InputDecoration(
                  labelText: 'Search by full name...',
                  labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  hintText: 'Enter full name',
                  hintStyle: TextStyle(color: Colors.cyan.shade300),
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

          // Date Range Pickers
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Expanded(child: _buildDateSelector('Start Date', _startDate, (picked) => setState(() => _startDate = picked))),
              SizedBox(width: 10),
              Expanded(child: _buildDateSelector('End Date', _endDate, (picked) => setState(() => _endDate = picked))),
            ]),
          ),

          // StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Salesinfo').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No sales report available!',
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: 18, color: Colors.black),
                    ),
                  );
                }

                final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final fullName = doc['fullName']?.toString()?.toLowerCase() ?? '';
                  if (_startDate != null || _endDate != null) {
                    dynamic ts = doc['reportedDateTime'];
                    DateTime? dt = ts is Timestamp ? ts.toDate() : (ts is DateTime ? ts : null);
                    if (dt == null) return false;
                    if (_startDate != null && dt.isBefore(DateTime(_startDate!.year, _startDate!.month, _startDate!.day))) return false;
                    if (_endDate != null && dt.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59))) return false;
                  }

                  final docUid = doc['uid']?.toString() ?? '';
                  return fullName.contains(_searchQuery.toLowerCase()) && docUid == currentUid;
                }).toList();

                if (filteredDocs.isEmpty) {
                  String message = '';
                  if (_searchQuery.isNotEmpty) {
                    message = 'No sales data found as you searched!';
                  } else if (_startDate != null || _endDate != null) {
                    message = 'No sales report found for selected date range!';
                  } else {
                    message = 'No sales report available!';
                  }

                  return Center(
                    child: Text(
                      message,
                      style: TextStyle(fontFamily: 'Times New Roman', fontSize: 18, color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return buildSalesCard(doc);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSalesCard(DocumentSnapshot doc) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Dismissible(
        key: Key(doc.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async => await _showDeleteConfirmationDialog(),
        onDismissed: (direction) async => await _deleteRecord(doc.id),
        background: Container(
          decoration: BoxDecoration(
            color: Colors.cyanAccent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Icon(Icons.delete, color: Colors.white),
            ),
          ),
        ),
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
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFormField('Lead Owner Name: ', doc['executivename']),
              buildFormField('Full Name: ', doc['fullName']),
              buildTappableField('Contact Number:', doc['contactNumber'], _launchPhone),
              noteText(),
              buildTappableField('Email Address: ', doc['email'], _launchEmail),
              noteText(),
              buildFormField('Preferred Contact Method: ', doc['preferredContactMethod']),
              buildFormField('Lead Source: ', doc['leadSource']),
              buildFormField('Lead Type: ', doc['leadType']),
              buildFormField('Type of Property: ', doc['propertyType']),
              buildFormField('Property Size: ', doc['propertySize']),
              buildFormField('Current Home Automation Setup: ', doc['currentHomeAutomation']),
              buildFormField('Budget Range: ', doc['budgetRange']),
              buildFormField('Additional Details: ', doc['additionalDetails']),
              buildFormField('Reported Date&Time:', formatReportedDateTime(doc['reportedDateTime'])),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.bottomRight,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EditSalesInfoPage(
                        docId: doc.id,
                        initialData: doc.data() as Map<String, dynamic>,
                      ),
                    ));
                  },
                  backgroundColor: Colors.cyan,
                  child: Icon(Icons.edit, color: Colors.white),
                  mini: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget noteText() => Padding(
    padding: const EdgeInsets.only(bottom: 10.0),
    child: Text(
      "Note: Please tap them",
      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
    ),
  );

  Future<DateTime?> _pickDate(BuildContext ctx, DateTime? current) {
    return showDatePicker(
      context: ctx,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, ValueChanged<DateTime?> onPicked) {
    final gradientBg = LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight);

    return GestureDetector(
      onTap: () async {
        final picked = await _pickDate(context, date);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        decoration: BoxDecoration(gradient: gradientBg, borderRadius: BorderRadius.circular(12), boxShadow: [
          BoxShadow(color: Colors.blue.shade900.withOpacity(0.2), blurRadius: 10, offset: Offset(0,4)),
        ]),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Row(children: [
          Icon(Icons.date_range, color: Colors.white),
          SizedBox(width: 8),
          Text(date != null ? DateFormat('dd‑MMM‑yyyy').format(date) : label,
              style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Times New Roman')),
        ]),
      ),
    );
  }

  Widget buildFormField(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(fontFamily: 'Arial', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(value, style: TextStyle(fontFamily: 'Arial', fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildTappableField(String title, String value, Function(String) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(title, style: TextStyle(fontFamily: 'Arial', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => onTap(value),
              child: Text(value, style: TextStyle(decoration: TextDecoration.underline, fontFamily: 'Arial', fontSize: 16, color: Colors.white)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Delete Confirmation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 10),
                Text('Are you sure you want to delete this record?',
                    style: TextStyle(fontSize: 16, color: Colors.cyan.shade100), textAlign: TextAlign.center),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text('Delete', style: TextStyle(color: Colors.cyanAccent.shade200, fontWeight: FontWeight.bold)),
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
