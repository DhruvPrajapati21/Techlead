import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../Employee/Categoryscreen/FileViwerscreen.dart';
import 'Edit_Installation_Page/edit_installation_page.dart';

class Showinstallationdata extends StatefulWidget {
  @override
  _ShowinstallationdataState createState() => _ShowinstallationdataState();
}

class _ShowinstallationdataState extends State<Showinstallationdata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  String _formatDate(String rawDate) {
    try {
      final DateTime parsedDate = DateTime.parse(rawDate);
      return DateFormat('dd MMMM yyyy').format(parsedDate);
    } catch (e) {
      return rawDate; // Fallback to original if parsing fails
    }
  }

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
      await _firestore.collection('Installation').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Installation Record deleted successfully',style: TextStyle(fontFamily: "Times New Roman", color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
    );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e',
            style: TextStyle(fontFamily: "Times New Roman", color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
            color: Colors.white), // Make the default background transparent
        elevation: 0, // Remove the default shadow
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
            Icon(
              FontAwesomeIcons.info,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Installation Summary",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1,
                color: Colors.white,
                fontFamily: 'Times New Roman',
              ),
            ),
          ],
        ),
        centerTitle: true,
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
              child: TextField(  style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
                decoration: InputDecoration(
                  labelText: 'Search by Technician name..',
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Enter Technician full name',
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
          SizedBox(height: 10,),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Installation').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 5,
                    padding: EdgeInsets.all(10),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade800,
                          highlightColor: Colors.grey.shade600,
                          child: Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No Installation info available!',
                      style: TextStyle(fontFamily: 'Times New Roman'),
                    ),
                  );
                }

                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final fullName =
                      doc['technician_name']?.toString()?.toLowerCase() ?? '';
                  final dateString = doc['installation_date'] ?? '';
                  DateTime? appointmentDate;

                  try {
                    appointmentDate = DateTime.parse(dateString);
                  } catch (e) {
                    return false;
                  }

                  final matchesSearch =
                  fullName.contains(_searchQuery.toLowerCase());
                  final matchesStartDate = _startDate == null ||
                      appointmentDate
                          .isAfter(_startDate!.subtract(Duration(days: 1)));
                  final matchesEndDate = _endDate == null ||
                      appointmentDate
                          .isBefore(_endDate!.add(Duration(days: 1)));

                  return matchesSearch && matchesStartDate && matchesEndDate;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text("No reports match your search/date range!", style: TextStyle(color: Colors.black,fontFamily: "Times New Roman")),
                  );
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
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
                          await _deleteRecord(doc.id);
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
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                        ),
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
                          padding: EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 10,
                              ),
                              buildFormField(
                                  'Technician/Executive Name: ', doc['technician_name']),
                              buildFormField('Installation Site:',
                                  doc['installation_site']),
                              buildFormField('Installation Date:',
                                _formatDate(doc['installation_date'])),
                              buildFormField(
                                  'Service Time: ', doc['service_time']),
                              buildFormField('Automation Product: ',
                                  doc['selected_product']),
                              buildFormField(
                                  'Service Status: ', doc['service_status']),
                              buildFormField(
                                  'Customer Name: ', doc['customer_name']),
                              buildFormField('Customer Contact: ',
                                  doc['customer_contact']),
                              buildFormField('Service Description: ',
                                  doc['service_description']),
                              buildFormField('Remarks: ', doc['remarks']),
                              if (doc['files'] != null &&
                                  doc['files'] is List &&
                                  (doc['files'] as List).isNotEmpty)
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
                                          itemCount:
                                          (doc['files'] as List).length,
                                          itemBuilder: (context, fileIndex) {
                                            var file =
                                            (doc['files'] as List)[fileIndex];
                                            final String url =
                                                file['downloadUrl'] ?? '';
                                            final String fileType =
                                            (file['fileType'] ?? '')
                                                .toLowerCase();
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
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FileViewerScreen(
                                                          url: url,
                                                          fileType: fileType,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                width: 120,
                                                margin: const EdgeInsets.only(
                                                    right: 10),
                                                padding:
                                                const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  border: Border.all(
                                                      color: Colors.tealAccent),
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                ),
                                                child: Column(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                      child: isImage
                                                          ? Image.network(
                                                        url,
                                                        width: 100,
                                                        height: 70,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(
                                                          Icons
                                                              .broken_image,
                                                          color:
                                                          Colors.white,
                                                        ),
                                                      )
                                                          : Icon(
                                                        fileType == 'pdf'
                                                            ? Icons
                                                            .picture_as_pdf
                                                            : Icons
                                                            .insert_drive_file,
                                                        color: Colors.white,
                                                        size: 50,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      fileName,
                                                      maxLines: 1,
                                                      overflow:
                                                      TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12),
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
                                              Editinstallationpage(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormField(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
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


