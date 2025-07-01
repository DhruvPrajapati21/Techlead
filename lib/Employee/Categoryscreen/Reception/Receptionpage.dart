import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../../Default/customwidget.dart';

class Receptionpage extends StatefulWidget {
  @override
  _ReceptionpageState createState() => _ReceptionpageState();
}

class _ReceptionpageState extends State<Receptionpage> {
  DateTime? _appointmentDate;
  TimeOfDay? _appointmentTime;
  DateTime? _taskDueDate;
  String? _meetingPurpose;
  String? _assignedStaff;
  String? _taskPriority;
  String? _taskStatus;
  bool _isTaskCompleted = false;
  String? _clientMeetingStatus;
  String? fullName;

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
    {'text': 'Pratikbhai', 'icon': FontAwesomeIcons.robot},
    {'text': 'Vivekbhai', 'icon': FontAwesomeIcons.server},
    {'text': 'Ankitbhai', 'icon': FontAwesomeIcons.userShield},
    {'text': 'Krutarthbhai', 'icon': FontAwesomeIcons.cogs},
    {'text': 'Deepbhai', 'icon': FontAwesomeIcons.microchip},
  ];

  final List<Map<String, dynamic>> taskPriorities = [
    {'text': 'High', 'icon': FontAwesomeIcons.exclamationCircle},
    {'text': 'Medium', 'icon': FontAwesomeIcons.exclamationTriangle},
    {'text': 'Low', 'icon': FontAwesomeIcons.circle},
  ];

  @override
  void initState() {
    super.initState();
    _loadFullName();
  }


  Future<String?> fetchCurrentUserFullName(String? userId) async {
    if (userId == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    return doc.get('fullName') as String?;
  }

  void _loadFullName() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final name = await fetchCurrentUserFullName(userId);
    setState(() {
      fullName = name;
    });
  }

  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _locationController = TextEditingController();

  bool _isSubmitting = false;

  String? _validateNonEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  void _selectAppointmentDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _appointmentDate = pickedDate;
      });
    }


  }

  void _selectAppointmentTime(BuildContext context) async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _appointmentTime = pickedTime;
      });
    }
  }

  void _selectTaskDueDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _taskDueDate = pickedDate;
      });
    }
  }

  final user = FirebaseAuth.instance.currentUser;
  String? userId;

  void _submitForm() async {
    final form = _formKey.currentState;

    if (!_isTaskCompleted) {
      Fluttertoast.showToast(
        msg: "Please mark the task as completed",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if (form != null && form.validate() && _taskDueDate != null && _taskStatus != null) {
      setState(() {
        _isSubmitting = true;
      });

      Map<String, dynamic> formData = {
        'emp_info': fullName,
        'client_name': _clientNameController.text,
        'phone_number': _phoneNumberController.text,
        'location': _locationController.text,
        'appointment_date': _appointmentDate?.toIso8601String(),
        'appointment_time': _appointmentTime?.format(context),
        'meeting_purpose': _meetingPurpose,
        'assigned_staff': _assignedStaff,
        'task_priority': _taskPriority,
        'task_due_date': _taskDueDate?.toIso8601String(),
        'task_status': _taskStatus,
        'is_task_completed': _isTaskCompleted,
        'client_meeting_status': _clientMeetingStatus,
        'userId': FirebaseAuth.instance.currentUser!.uid,
      };

      try {
        await FirebaseFirestore.instance.collection('ReceptionPage').add(formData);
        Fluttertoast.showToast(
          msg: "Reception Data stored successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        _resetFormFields();
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error storing data: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      Fluttertoast.showToast(
        msg: "Please fill all fields",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _resetFormFields() {
    setState(() {
      _clientNameController.clear();
      _phoneNumberController.clear();
      _locationController.clear();
      _appointmentDate = null;
      _appointmentTime = null;
      _meetingPurpose = null;
      _assignedStaff = null;
      _taskPriority = null;
      _taskDueDate = null;
      _taskStatus = null;
      _isTaskCompleted = false;
      _clientMeetingStatus = null;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.accusoft,
              color: Colors.white,
            ),
            SizedBox(width: 15),
            Text(
              "Reception Page",
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
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.indigo.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                buildSection("Client Information", [
                  buildTextField(
                    context: context,
                    controller: _clientNameController,
                    labelText: "Client's Full Name",
                    hintText: "Enter client's full name",
                    icon: FontAwesomeIcons.user,
                    validator: (value) => _validateNonEmpty(value, "the client's full name"),
                  ),
                  SizedBox(height: 16),

                  buildTextField(
                    controller: _phoneNumberController,
                    context: context,
                    labelText: "Client's Phone Number",
                    hintText: "Enter client's phone number",
                    icon: FontAwesomeIcons.phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Mobile number is required.';
                      } else if (value.length != 10) {
                        return 'Mobile number must be 10 digits.';
                      } else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit number.';
                      }
                      return null;
                    },
                  ),
                ]),
                SizedBox(height: 24),
                buildSection("Appointment Scheduling", [
                  buildDatePickerField(
                    context,
                    label: "Select Appointment Date",
                    date: _appointmentDate,
                    onTap: () => _selectAppointmentDate(context),
                  ),
                  SizedBox(height: 16),
                  buildTimePickerField(
                    context,
                    label: "Select Appointment Time",
                    time: _appointmentTime,
                    onTap: () => _selectAppointmentTime(context),
                  ),
                  SizedBox(height: 16),
                  buildDropdownField(
                    labelText: "Select Meeting Purpose",
                    context: context,
                    icon: FontAwesomeIcons.calendarCheck,
                    value: _meetingPurpose,
                    items: meetingPurposes,
                    onChanged: (value) {
                      setState(() {
                        _meetingPurpose = value;
                      });
                    },
                    validator: (value) => _validateNonEmpty(value, "a meeting purpose"),
                  ),
                  SizedBox(height: 16),
                  buildTextField(
                    controller: _locationController,
                    labelText: "Meeting Location",
                    context: context,
                    hintText: "Enter meeting location",
                    icon: FontAwesomeIcons.mapMarkerAlt,
                    validator: (value) => _validateNonEmpty(value, "the meeting location"),
                  ),
                  SizedBox(height: 16),
                  buildDropdownField(
                    labelText: "Select Assigned Staff/CEO",
                    context: context,
                    icon: FontAwesomeIcons.user,
                    value: _assignedStaff,
                    items: staffList,
                    onChanged: (value) {
                      setState(() {
                        _assignedStaff = value;
                      });
                    },
                    validator: (value) => _validateNonEmpty(value, "an assigned staff"),
                  ),
                ]),
                SizedBox(height: 24),
                buildSection("Task Management", [
                  buildDropdownField(
                    labelText: "Task Priority",
                    context: context,
                    icon: FontAwesomeIcons.exclamationCircle,
                    value: _taskPriority,
                    items: taskPriorities,
                    onChanged: (value) {
                      setState(() {
                        _taskPriority = value;
                      });
                    },
                    validator: (value) => _validateNonEmpty(value, "a task priority"),
                  ),
                  SizedBox(height: 16),
                  buildDatePickerField(
                    context,
                    label: "Select Task Due Date",
                    date: _taskDueDate,
                    onTap: () => _selectTaskDueDate(context),
                  ),
                  SizedBox(height: 16),
                  buildDropdownField(
                    labelText: "Task Status",
                    context: context,
                    icon: FontAwesomeIcons.cogs,
                    value: _taskStatus,
                    items: [
                      {'text': 'Pending', 'icon': FontAwesomeIcons.hourglassHalf},
                      {'text': 'In Progress', 'icon': FontAwesomeIcons.spinner},
                      {'text': 'Completed', 'icon': FontAwesomeIcons.checkCircle},
                    ],
                    onChanged: (value) {
                      setState(() {
                        _taskStatus = value;
                      });
                    },
                    validator: (value) => _validateNonEmpty(value, "a task status"),
                  ),
                  SizedBox(height: 16),
                  buildCheckboxField(
                    label: "Mark Task as Completed",
                    context: context,
                    value: _isTaskCompleted,
                    onChanged: (value) {
                      setState(() {
                        _isTaskCompleted = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  buildDropdownField(
                    labelText: "Client Meeting Status",
                    context: context,
                    icon: FontAwesomeIcons.users,
                    value: _clientMeetingStatus,
                    items: [
                      {'text': 'Scheduled', 'icon': FontAwesomeIcons.calendarCheck},
                      {'text': 'Completed', 'icon': FontAwesomeIcons.checkCircle},
                      {'text': 'Cancelled', 'icon': FontAwesomeIcons.timesCircle},
                    ],
                    onChanged: (value) {
                      setState(() {
                        _clientMeetingStatus = value;
                      });
                    },
                    validator: (value) => _validateNonEmpty(value, "a client meeting status"),
                  ),
                ]),
                SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          shadowColor: Colors.purpleAccent.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
