import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'Edit_Sales_Info_Page.dart';

class SalesInfoPage extends StatefulWidget {
  @override
  _SalesInfoPageState createState() => _SalesInfoPageState();
}

class _SalesInfoPageState extends State<SalesInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('Salesinfo').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sales Record deleted successfully', style: TextStyle(fontFamily: "Times New Roman", color: Colors.white)),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting record: $e', style: TextStyle(fontFamily: "Times New Roman", color: Colors.white)),
            backgroundColor: Colors.red),
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

  Future<DateTime?> _pickDate(BuildContext ctx, DateTime? current) {
    return showDatePicker(
      context: ctx,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradientBg = LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight);

    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: BoxDecoration(gradient: gradientBg)),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(FontAwesomeIcons.info, color: Colors.white),
          SizedBox(width: 10),
          Text("Sales Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.5, color: Colors.white, fontFamily: 'Roboto')),
        ]),
        centerTitle: true,
      ),
      body: Column(children: [
        Padding(
          padding: EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(gradient: gradientBg, borderRadius: BorderRadius.circular(12), boxShadow: [
              BoxShadow(color: Colors.blue.shade900.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4)),
            ]),
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontFamily: "Times New Roman"),
              decoration: InputDecoration(
                labelText: 'Search by full name...',
                labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                hintText: 'Enter full name',
                hintStyle: TextStyle(color: Colors.cyan.shade300),
                prefixIcon: Padding(padding: EdgeInsets.all(12), child: Icon(Icons.search, color: Colors.white)),
                filled: true, fillColor: Colors.transparent, border: InputBorder.none, contentPadding: EdgeInsets.all(10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            Expanded(child: _buildDateSelector('Start Date', _startDate, (picked) => setState(() => _startDate = picked))),
            SizedBox(width: 10),
            Expanded(child: _buildDateSelector('End Date', _endDate, (picked) => setState(() => _endDate = picked))),
          ]),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('Salesinfo').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No sales info available!', style: TextStyle(fontFamily: 'Times New Roman')));

              final docs = snapshot.data!.docs.where((doc) {
                final fullName = (doc['fullName']?.toString() ?? '').toLowerCase();
                if (!fullName.contains(_searchQuery.toLowerCase())) return false;

                if (_startDate != null || _endDate != null) {
                  dynamic ts = doc['reportedDateTime'];
                  DateTime? dt = ts is Timestamp ? ts.toDate() : (ts is DateTime ? ts : null);
                  if (dt == null) return false;
                  if (_startDate != null && dt.isBefore(DateTime(_startDate!.year, _startDate!.month, _startDate!.day))) return false;
                  if (_endDate != null && dt.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23,59,59))) return false;
                }

                return true;
              }).toList();

              if (docs.isEmpty) {
                final msg = (_startDate != null || _endDate != null)
                    ? 'No Sales Report found for selected dates!'
                    : 'No Sales Report found!';
                return Center(
                  child: Text(
                    msg,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                    ),
                  ),
                );
              }


              return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final doc = docs[i];
                    return Padding(
                      padding: EdgeInsets.all(10),
                      child: Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async => (await _showDeleteConfirmationDialog()) == true,
                        onDismissed: (_) => _deleteRecord(doc.id),
                        background: Container(decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(12)),
                          child: Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(right: 20), child: Icon(Icons.delete, color: Colors.white))),
                        ),
                        child: Container(
                          decoration: BoxDecoration(gradient: gradientBg, borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.blue.shade900.withOpacity(0.2), blurRadius: 10, offset: Offset(0,4))],
                          ),
                          padding: EdgeInsets.all(15),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildFormField('Lead Owner Name:', doc['executivename']),
                            _buildFormField('Full Name:', doc['fullName']),
                            _buildFormField('Contact Number:', doc['contactNumber']),
                            _buildFormField('Email Address:', doc['email']),
                            _buildFormField('Preferred Contact Method:', doc['preferredContactMethod']),
                            _buildFormField('Lead Source:', doc['leadSource']),
                            _buildFormField('Lead Type:', doc['leadType']),
                            _buildFormField('Type of Property:', doc['propertyType']),
                            _buildFormField('Property Size:', doc['propertySize']),
                            _buildFormField('Current Home Automation Setup:', doc['currentHomeAutomation']),
                            _buildFormField('Budget Range:', doc['budgetRange']),
                            _buildFormField('Reported Date:', formatReportedDateTime(doc['reportedDateTime'])),
                            SizedBox(height: 10),
                            Align(alignment: Alignment.centerRight, child: FloatingActionButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => EditSalesInfoPage(docId: doc.id, initialData: doc.data() as Map<String, dynamic>),
                              )),
                              backgroundColor: Colors.cyan,
                              child: Icon(Icons.edit, color: Colors.white),
                            )),
                          ]),
                        ),
                      ),
                    );
                  });
            },
          ),
        ),
      ]),
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

  Widget _buildFormField(String title, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(flex: 1, child: Text(title, style: TextStyle(fontFamily: 'Arial', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.cyanAccent))),
        Expanded(flex: 2, child: Text(value?.toString() ?? 'N/A', style: TextStyle(fontFamily: 'Arial', fontSize: 16, color: Colors.white))),
      ]),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12)),
          padding: EdgeInsets.all(15),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Delete Confirmation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10),
            Text('Are you sure you want to delete this record?', style: TextStyle(fontSize: 16, color: Colors.cyan.shade100), textAlign: TextAlign.center),
            SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              SizedBox(width: 10),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Delete', style: TextStyle(color: Colors.cyanAccent.shade200, fontWeight: FontWeight.bold))),
            ]),
          ]),
        ),
      ),
    );
  }
}
