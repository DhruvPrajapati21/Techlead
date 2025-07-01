import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
    {'text': 'Home Automation \n Advice', 'icon': FontAwesomeIcons.lightbulb},
    {'text': 'Smart Home \n Integration', 'icon': FontAwesomeIcons.networkWired},
    {'text': 'Maintenance Request', 'icon': FontAwesomeIcons.wrench},
    {'text': 'Security System Setup', 'icon': FontAwesomeIcons.shieldAlt},
    {'text': 'Energy Efficiency \n Consultation', 'icon': FontAwesomeIcons.solarPanel},
    {'text': 'Product Demonstration', 'icon': FontAwesomeIcons.tv},
    {'text': 'Follow-Up on Services', 'icon': FontAwesomeIcons.userMd},
    {'text': 'Client Training Session', 'icon': FontAwesomeIcons.chalkboardTeacher},
    {'text': 'Custom Solutions \n Discussion', 'icon': FontAwesomeIcons.cogs},
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
          mainAxisAlignment: MainAxisAlignment.start,
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
                fontSize: 20,
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
                colors: [
                  Color(0xFF0A2A5A), // Deep navy blue
                  Color(0xFF15489C), // Strong steel blue
                  Color(0xFF1E64D8), // Vivid rich blue
                ],
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
  Widget buildDropdownField(
      String label,
      String value,
      IconData icon,
      List<Map<String, dynamic>> items,
      ValueChanged<String?> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF02274C), // Vibrant dark blue
            ),
          ),
          const SizedBox(height: 6),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: const Color(0xFF0A2A5A),
            ),
            child: DropdownButtonFormField<String>(
              value: items.any((item) => item['text'] == value) ? value : null,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.cyanAccent),
                filled: true,
                fillColor: const Color(0xFF0A2A5A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              dropdownColor: const Color(0xFF0A2A5A),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              onChanged: onChanged,
              items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
                return DropdownMenuItem<String>(
                  value: item['text'],
                  child: Row(
                    children: [
                      Icon(item['icon'], color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        item['text'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

// Text form field
  Widget buildTextFormField(
      String label,
      String initialValue,
      IconData icon,
      Function(String) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF02274C),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: initialValue,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.cyanAccent),
              filled: true,
              fillColor: const Color(0xFF0A2A5A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white24),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: onChanged,
          ),
        ],
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