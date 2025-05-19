import 'package:flutter/material.dart';

class MeetingManagementSection extends StatefulWidget {
  const MeetingManagementSection({super.key});

  @override
  State<MeetingManagementSection> createState() => _MeetingManagementSectionState();
}

class _MeetingManagementSectionState extends State<MeetingManagementSection> {
  final List<Map<String, String>> meetings = []; // List to hold scheduled meetings
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController meetingTimeController = TextEditingController();
  final TextEditingController meetingStatusController = TextEditingController();
  final TextEditingController assignedMeetingController = TextEditingController();
  final TextEditingController reasonForVisitController = TextEditingController();
  final TextEditingController attendanceMarkController = TextEditingController();
  final TextEditingController rescheduleOptionController = TextEditingController();
  final TextEditingController clientContactInfoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Meeting Management",style: TextStyle(fontFamily: "Times New Roman",fontWeight: FontWeight.bold,color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[800]!, Colors.blueGrey[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  color: Colors.white.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTextField(
                            clientNameController,
                            "Client Name",
                            Icons.person
                        ),
                        _buildTextField(
                            meetingTimeController,
                            "Meeting Time",
                            Icons.schedule
                        ),
                        _buildTextField(
                            meetingStatusController,
                            "Meeting Status",
                            Icons.info_outline
                        ),
                        _buildTextField(
                            assignedMeetingController,
                            "Assigned Meeting",
                            Icons.assignment
                        ),
                        _buildTextField(
                            reasonForVisitController,
                            "Reason for Visit",
                            Icons.edit_note
                        ),
                        _buildTextField(
                            attendanceMarkController,
                            "Attendance Mark",
                            Icons.check_circle_outline
                        ),
                        _buildTextField(
                            rescheduleOptionController,
                            "Reschedule Option",
                            Icons.refresh
                        ),
                        _buildTextField(
                            clientContactInfoController,
                            "Client Contact Info",
                            Icons.contact_phone
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _addMeeting,
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text("Add Meeting",style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 20),
                Divider(color: Colors.white),
                SizedBox(height: 10),
                Text(
                  "Scheduled Meetings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                meetings.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "No meetings scheduled.",
                    style: TextStyle(color: Colors.white),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: meetings.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        title: Text(meetings[index]['clientName'] ?? ""),
                        subtitle: Text('Time: ${meetings[index]['meetingTime']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                _markAttendance(index);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, color: Colors.orange),
                              onPressed: () {
                                _rescheduleMeeting(index);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red),
                              onPressed: () {
                                _cancelMeeting(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueGrey[700]),
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[700]),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _addMeeting() {
    setState(() {
      meetings.add({
        'clientName': clientNameController.text,
        'meetingTime': meetingTimeController.text,
        'meetingStatus': meetingStatusController.text,
        'assignedMeeting': assignedMeetingController.text,
        'reasonForVisit': reasonForVisitController.text,
        'attendanceMark': attendanceMarkController.text,
        'rescheduleOption': rescheduleOptionController.text,
        'clientContactInfo': clientContactInfoController.text,
      });
    });

    clientNameController.clear();
    meetingTimeController.clear();
    meetingStatusController.clear();
    assignedMeetingController.clear();
    reasonForVisitController.clear();
    attendanceMarkController.clear();
    rescheduleOptionController.clear();
    clientContactInfoController.clear();

    _showNotification("Meeting added successfully.");
  }

  void _markAttendance(int index) {
    setState(() {
      meetings[index]['attendanceMark'] = 'Present';
    });
    _showNotification('Attendance marked for ${meetings[index]['clientName']}');
  }

  void _rescheduleMeeting(int index) {
    setState(() {
      meetings[index]['meetingTime'] = 'Rescheduled Time'; // Change to actual rescheduled time
    });
    _showNotification('Meeting for ${meetings[index]['clientName']} has been rescheduled');
  }

  void _cancelMeeting(int index) {
    setState(() {
      meetings.removeAt(index);
    });
    _showNotification('Meeting for ${meetings[index]['clientName']} has been canceled');
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
