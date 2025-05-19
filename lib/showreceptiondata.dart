import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Showreceptiondata extends StatefulWidget {
  @override
  _ShowreceptiondataState createState() => _ShowreceptiondataState();
}

class _ShowreceptiondataState extends State<Showreceptiondata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make the default background transparent
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
                      'No Reception info available',
                      style: TextStyle(fontFamily: 'Times New Roman'),
                    ),
                  );
                }
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final fullName = doc['client_name']?.toString()?.toLowerCase() ?? '';
                  return fullName.contains(_searchQuery.toLowerCase());
                }).toList();

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
                          final delete = await _showDeleteConfirmationDialog();
                          return delete == true;
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
                              Text("Client Information",style: TextStyle(fontWeight: FontWeight.bold,fontFamily: "Times New Roman",fontSize: 16,color: Colors.white)),
                              SizedBox(height: 10,),
                              buildFormField('Client Full Name: ', doc['client_name']),
                              buildFormField('Contact Number:', doc['phone_number']),
                              SizedBox(height: 10,),
                              Text("Appointment Scheduling",style: TextStyle(fontWeight: FontWeight.bold,fontFamily: "Times New Roman",fontSize: 16,color: Colors.white),),
                              SizedBox(height: 10,),
                              buildFormField('Appointment Date: ', doc['appointment_date']),
                              buildFormField('Appointment Time: ', doc['appointment_time']),
                              buildFormField('Meeting Purpose: ', doc['meeting_purpose']),
                              buildFormField('Meeting Location: ', doc['location']),
                              buildFormField('Assigned Staff/CEO: ', doc['location']),
                              SizedBox(height: 10,),
                              Text("Task Management",style: TextStyle(fontWeight: FontWeight.bold,fontFamily: "Times New Roman",fontSize: 16,color: Colors.white),),
                              SizedBox(height: 10,),
                              buildFormField('Task Priority: ', doc['task_priority']),
                              buildFormField('Task Due Date: ', doc['task_due_date']),
                              buildFormField('Task Status: ', doc['task_status']),
                              buildFormField('Client Meeting Status: ', doc['client_meeting_status']),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    child: FloatingActionButton(
                                      onPressed: (){
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => Editreceptionpage(
                                            docId: doc.id,
                                            initialData: doc.data() as Map<String, dynamic>,
                                          ),
                                        ));
                                      },
                                      backgroundColor: Colors.cyan,

                                      child: const Icon(Icons.edit, color: Colors.white),
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
                    color: Colors.cyan.shade100, // Cyan accent for the content text
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


  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('ReceptionPage').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reception Record deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
class Editreceptionpage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  Editreceptionpage({required this.docId, required this.initialData});

  @override
  _EditreceptionpageState createState() => _EditreceptionpageState();
}



class _EditreceptionpageState extends State<Editreceptionpage> {
  final _formKey = GlobalKey<FormState>();
  late String fullName, contactNumber, email, preferredContactMethod, leadSource, leadType,taskstatus,meetingcstatus, propertyType, propertySize, currentHomeAutomation, budgetRange, additionalDetails;

  final List<Map<String, dynamic>> meetingPurposes = [
    {'text': 'Initial Consultation', 'icon': FontAwesomeIcons.handshake},
    {'text': 'Installation Request', 'icon': FontAwesomeIcons.cogs},
    {'text': 'Service Inquiry', 'icon': FontAwesomeIcons.questionCircle},
    {'text': 'System Upgrade', 'icon': FontAwesomeIcons.arrowUp},
    {'text': 'Troubleshooting', 'icon': FontAwesomeIcons.tools},
    {'text': 'Home Automation Advice', 'icon': FontAwesomeIcons.lightbulb},
    {'text': 'Smart Home Integration', 'icon': FontAwesomeIcons.networkWired},
    {'text': 'Maintenance Request', 'icon': FontAwesomeIcons.wrench},
    {'text': 'Security System Setup', 'icon': FontAwesomeIcons.shieldAlt},
    {'text': 'Energy Efficiency Consultation', 'icon': FontAwesomeIcons.solarPanel},
    {'text': 'Product Demonstration', 'icon': FontAwesomeIcons.tv},
    {'text': 'Follow-Up on Services', 'icon': FontAwesomeIcons.userMd},
    {'text': 'Client Training Session', 'icon': FontAwesomeIcons.chalkboardTeacher},
    {'text': 'Custom Solutions Discussion', 'icon': FontAwesomeIcons.cogs},
    {'text': 'Troubleshooting Follow-Up', 'icon': FontAwesomeIcons.bug},
  ];

  final List<Map<String, dynamic>> staffList = [
    {'text': 'Dr. Smith', 'icon': FontAwesomeIcons.userMd},
    {'text': 'Nurse John', 'icon': FontAwesomeIcons.userNurse},
  ];

  final List<Map<String, dynamic>> taskPriorities = [
    {'text': 'High', 'icon': FontAwesomeIcons.exclamationCircle},
    {'text': 'Medium', 'icon': FontAwesomeIcons.exclamationTriangle},
    {'text': 'Low', 'icon': FontAwesomeIcons.circle},
  ];

  @override
  void initState() {
    super.initState();
    fullName = widget.initialData['client_name'] ?? '';
    contactNumber = widget.initialData['phone_number'] ?? '';
    email = widget.initialData['appointment_date'] ?? '';
    preferredContactMethod = widget.initialData['appointment_time'] ?? ''; // Assuming default value
    leadSource = widget.initialData['meeting_purpose'] ?? meetingPurposes[0]['text']; // Set default to the first option// Set default to the first option// Set default to the first option
    propertySize = widget.initialData['location'] ?? '';
    currentHomeAutomation = widget.initialData['assigned_staff'] ?? staffList[0]['text']; // Set default to the first option// Set default to the first option
    budgetRange = widget.initialData['task_priority'] ?? taskPriorities[0]['text'];
    additionalDetails = widget.initialData['task_due_date'] ?? '';
    taskstatus = widget.initialData['task_status'] ?? '';
    meetingcstatus = widget.initialData['meeting_purpose'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.penNib,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Edit Reception Page",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.5,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 8,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.indigo.shade700],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 100),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          buildTextFormField('Client Full Name', fullName, Icons.person, (value) => fullName = value),
                          buildTextFormField('Contact Number', contactNumber, Icons.phone, (value) => contactNumber = value),
                          buildTextFormField('Appointment Date', email, Icons.email, (value) => email = value),
                          buildTextFormField('Appointment Time', preferredContactMethod, FontAwesomeIcons.digitalOcean, (value) => preferredContactMethod = value),
                          buildDropdownField('Meeting Purpose', leadSource, FontAwesomeIcons.user, meetingPurposes, (newValue) => setState(() => leadSource = newValue!)),
                          buildTextFormField('Meeting Location', propertySize, Icons.email, (value) => propertySize = value),
                          buildTextFormField('Assigned Staff/CEO', currentHomeAutomation, Icons.square_foot, (value) => currentHomeAutomation = value),
                          buildDropdownField('Task Priority', currentHomeAutomation, FontAwesomeIcons.cogs, taskPriorities, (newValue) => setState(() => currentHomeAutomation = newValue!)),
                          buildTextFormField('Task Due Date', budgetRange, Icons.details, (value) => budgetRange = value),
                          buildTextFormField('Task Status', taskstatus, Icons.details, (value) => taskstatus = value),
                          buildTextFormField('Client Meeting Status', meetingcstatus, Icons.details, (value) => meetingcstatus = value),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _updateRecord,
                            child: Text(
                              'Update',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateRecord,
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.save, size: 30, color: Colors.white),
      ),
    );
  }

  // Dropdown field with icons
  Widget buildDropdownField(String label, String value, IconData icon, List<Map<String, dynamic>> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: items.any((item) => item['text'] == value) ? value : null, // Ensure the value exists in the items list
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
          return DropdownMenuItem<String>(
            value: item['text'], // Use the 'text' as the value
            child: Row(
              children: [
                Icon(item['icon'], color: Colors.deepPurple),
                SizedBox(width: 10),
                Text(item['text'], style: GoogleFonts.poppins(fontSize: 16)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  // Text form field
  Widget buildTextFormField(String label, String initialValue, IconData icon, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // Update the record in Firestore
  void _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('ReceptionPage').doc(widget.docId).update({
          'client_name': fullName,
          'phone_number': contactNumber,
          'appointment_date': email,
          'appointment_time': preferredContactMethod,
          'meeting_purpose': leadSource,
          'location': propertySize,
          'assigned_staff': currentHomeAutomation,
          'task_priority': budgetRange,
          'task_due_date': additionalDetails,
          'task_status': taskstatus,
          'meeting_purpose': meetingcstatus,
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Reception Record updated successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating record: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}