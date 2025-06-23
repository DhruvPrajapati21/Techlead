import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'Default/customwidget.dart';

class TaskAssignPageDE extends StatefulWidget {
  const TaskAssignPageDE({super.key});
  @override
  State<TaskAssignPageDE> createState() => _TaskAssignPageDEState();

}

class _TaskAssignPageDEState extends State<TaskAssignPageDE> {

  Map<String, bool> checkboxValues = {};
  String? matchedDocId;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController adminNameController = TextEditingController();
  TextEditingController adminIdController = TextEditingController();
  TextEditingController employeeNameController = TextEditingController();
  TextEditingController employeeIdController = TextEditingController();
  TextEditingController projectNameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  TextEditingController siteLocationController = TextEditingController();
  TextEditingController taskDescriptionController = TextEditingController();
  final TextEditingController deadlineDateController = TextEditingController();
  TextEditingController empIdController = TextEditingController();

  List<String> employeeNames = [];
  Map<String, String> employeeNameIdMap = {};
  List<String> selectedEmployeeNames = [];

  final List<Map<String, dynamic>> departmentList = [
    {'name': 'HR', 'icon': Icons.people},
    {'name': 'Finance', 'icon': Icons.account_balance},
    {'name': 'Development', 'icon': Icons.code},
    {'name': 'Digital Marketing', 'icon': Icons.campaign},
    {'name': 'Reception', 'icon': Icons.phone},
    {'name': 'Account', 'icon': Icons.book},
    {'name': 'Human Resources', 'icon': Icons.group},
    {'name': 'Management', 'icon': Icons.business},
    {'name': 'Sales', 'icon': Icons.shopping_cart},
    {'name': 'Installation', 'icon': Icons.build},
    {'name': 'Services', 'icon': Icons.miscellaneous_services},
    {'name': 'Social Media Marketing', 'icon': Icons.share},
  ];

  String? selectedDepartment;

  List<File> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileTypes = [];
  List<TextEditingController> fileNameControllers = [];
  bool isLoading = false;

  Future<void> _selectDeadlineDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime today = DateTime(currentDate.year, currentDate.month, currentDate.day);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        String formattedDate = DateFormat('dd MMMM yyyy').format(pickedDate);
        deadlineDateController.text = formattedDate;
      });
    }
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true);

    if (result != null) {
      for (var file in result.files) {
        selectedFiles.add(File(file.path!));
        fileNames.add(file.name);
        fileTypes.add(file.extension ?? '');
        fileNameControllers.add(TextEditingController(text: file.name));
      }
      setState(() {});
    }
  }

  void openFile(File file) async {
    await OpenFile.open(file.path);
  }

  void renameFile(int index) {
    setState(() {
      fileNames[index] = fileNameControllers[index].text.isNotEmpty
          ? fileNameControllers[index].text
          : fileNames[index];
      fileNameControllers[index].clear();
    });
  }

  Future<void> updateCheckboxValue(String field, bool? value) async {
    if (matchedDocId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(matchedDocId)
          .update({field: value ?? false});
      print("Updated $field to $value");
    } catch (e) {
      print("Error updating $field: $e");
    }
  }


  Future<void> _fetchEmployeeNames() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('EmpProfile').get();

      setState(() {
        employeeNameIdMap = {
          for (var doc in snapshot.docs)
            if (doc['fullName'] != null && doc['empId'] != null)
              doc['fullName']: doc['empId']
        };

        employeeNames = employeeNameIdMap.keys
            .where((name) => name.isNotEmpty)
            .toList();
      });
    } catch (e) {
      print("Error fetching employee names and IDs: $e");
    }
  }

  Future<void> uploadFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      for (int index = 0; index < selectedFiles.length; index++) {
        String fileName = fileNames[index];
        File file = selectedFiles[index];
        String fileType = fileTypes[index];

        Uint8List fileBytes = await file.readAsBytes();

        Reference storageRef = _storage.ref().child("TaskAssign/$fileName");

        UploadTask uploadTask = storageRef.putData(fileBytes, SettableMetadata(
          contentType: _getContentType(fileType),
        ));
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('TaskAssign').add({
          'fileName': fileName,
          'fileType': fileType,
          'downloadUrl': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Files uploaded successfully!')),
      );
    } catch (e) {
      print("Error uploading files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading files: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
      case 'png':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<DateTime?> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime today = DateTime(currentDate.year, currentDate.month, currentDate.day);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
    );
    return pickedDate;
  }


  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    TimeOfDay currentTime = TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    return pickedTime;
  }

  Future<void> _submitData() async {
    if (!mounted) return;

    List<String> errors = [];

    final adminName = adminNameController.text.trim();
    final adminId = adminIdController.text.trim();

    if (adminName.isEmpty || adminId.isEmpty) {
      errors.add('Admin credentials not set. Please login again.');
    }

    if (selectedEmployeeNames.isEmpty) {
      errors.add('Please select at least one employee');
    }

    if (empIdController.text.trim().isEmpty) {
      errors.add('Employee ID field is empty');
    }

    if (selectedDepartment == null || selectedDepartment!.trim().isEmpty) {
      errors.add('Department not selected');
    }

    if (dateController.text.trim().isEmpty) {
      errors.add('Date is not selected');
    }

    if (timeController.text.trim().isEmpty) {
      errors.add('Time is not selected');
    }

    if (projectNameController.text.trim().isEmpty) {
      errors.add('Project Name is missing');
    }

    if ((selectedDepartment == 'Installation' ||
        selectedDepartment == 'Sales' ||
        selectedDepartment == 'Services' ||
        selectedDepartment == 'Social Media Marketing') &&
        siteLocationController.text.trim().isEmpty) {
      errors.add('Site Location is required for this department');
    }

    if (taskDescriptionController.text.trim().isEmpty) {
      errors.add('Task Description is missing');
    }

    if (deadlineDateController.text.trim().isEmpty) {
      errors.add('Deadline Date is missing');
    }

    if (selectedFiles.isEmpty) {
      errors.add('At least one file must be selected');
    }

    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            errors.join('\n'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot employeeSnapshot =
      await FirebaseFirestore.instance.collection('EmpProfile').get();

      Map<String, String> employeeTokens = {};
      Map<String, List<String>> departmentTokens = {};

      for (var doc in employeeSnapshot.docs) {
        String empId = doc['empId'];
        String fcmToken = doc['fcmToken'];
        List<String> categories = List<String>.from(doc['categories'] ?? []);

        if (empId.isNotEmpty && fcmToken.isNotEmpty) {
          employeeTokens[empId] = fcmToken;
        }

        for (String category in categories) {
          departmentTokens.putIfAbsent(category, () => []).add(fcmToken);
        }
      }

      List<String> enteredEmpIds = empIdController.text
          .trim()
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();

      List<String> matchedTokens = [];
      List<String> assignedEmpIds = [];

      for (String empId in enteredEmpIds) {
        if (employeeTokens.containsKey(empId)) {
          matchedTokens.add(employeeTokens[empId]!);
          assignedEmpIds.add(empId);
        }
      }

      if (selectedDepartment != null) {
        for (String department in departmentTokens.keys) {
          if (department.contains(selectedDepartment!)) {
            matchedTokens.addAll(departmentTokens[department]!);
          }
        }
      }

      matchedTokens = matchedTokens.toSet().toList();

      if (matchedTokens.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text(
              'Employee ID/Department not found! Task not assigned!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      List<Map<String, String>> uploadedFiles = await _uploadFiles();

      final taskData = {
        'adminName': adminName,
        'adminId': adminId,
        'employeeNames': selectedEmployeeNames,
        'empIds': assignedEmpIds,
        'department': selectedDepartment,
        'date': dateController.text.trim(),
        'time': timeController.text.trim(),
        'projectName': projectNameController.text.trim(),
        'siteLocation': siteLocationController.text.trim(),
        'taskDescription': taskDescriptionController.text.trim(),
        'deadlineDate': deadlineDateController.text.trim(),
        'taskId': DateTime.now().millisecondsSinceEpoch.toString(),
        'files': uploadedFiles,
      };

      await FirebaseFirestore.instance.collection('TaskAssign').add(taskData);

      for (String empId in assignedEmpIds) {
        final snapshot = await FirebaseFirestore.instance
            .collection('EmpProfile')
            .where('empId', isEqualTo: empId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final docId = snapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('EmpProfile')
              .doc(docId)
              .update({'assignedTask': FieldValue.delete()});
        }
      }

      for (String token in matchedTokens) {
        await sendNotification(token, taskData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: const Text(
            'Task assigned and notifications sent!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );

      _resetForm();
    } catch (e) {
      print('🔥 Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> _uploadFiles() async {
    List<Map<String, String>> uploadedFiles = [];

    try {
      for (int index = 0; index < selectedFiles.length; index++) {
        String fileName = fileNames[index];
        File file = selectedFiles[index];
        String fileType = fileTypes[index];

        Uint8List fileBytes = await file.readAsBytes();
        Reference storageRef = _storage.ref().child("TaskAssign/$fileName");
        UploadTask uploadTask = storageRef.putData(fileBytes, SettableMetadata(
          contentType: _getContentType(fileType),
        ));

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedFiles.add({
          'fileName': fileName,
          'fileType': fileType,
          'downloadUrl': downloadUrl,
        });
      }
    } catch (e) {
      print("Error uploading files: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading files: $e')),
      );
    }

    return uploadedFiles;
  }

  void _resetForm() {
    projectNameController.clear();
    dateController.clear();
    timeController.clear();
    siteLocationController.clear();
    taskDescriptionController.clear();
    deadlineDateController.clear();
    empIdController.clear();

    setState(() {
      selectedDepartment = null;
      selectedEmployeeNames = [];
      selectedFiles.clear();
      fileNames.clear();
      fileTypes.clear();
    });
  }

  Future<void> sendNotification(String fcmToken, Map<String, dynamic> taskData) async {
    const String firebaseServerKey = 'YOUR_SERVER_KEY_HERE';

    final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final Map<String, dynamic> notificationData = {
      'to': fcmToken,
      'notification': {
        'title': "New Task Assigned",
        'body': "You have been assigned a new task: ${taskData['taskDescription']}",
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'data': {
        'taskId': taskData['taskId'],
        'taskDescription': taskData['taskDescription'],
        'deadlineDate': taskData['deadlineDate'],
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$firebaseServerKey',
      },
      body: jsonEncode(notificationData),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent successfully!");
    } else {
      print("❌ Failed to send notification: ${response.body}");
    }
  }

  Future<void> replaceFile(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'mp4',
        'mov',
        'avi',
        'mkv',
        'gif'
      ],
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        selectedFiles[index] = File(file.path!);
        fileNames[index] = file.name;
        fileTypes[index] = file.extension ?? 'unknown';
      });
    } else {
      print("No file selected.");
    }
  }

  void closeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      fileNames.removeAt(index);
      fileTypes.removeAt(index);
      fileNameControllers.removeAt(index);
    });
  }

  Future<void> sendMulticastNotification(List<String> fcmTokens, Map<String, dynamic> taskData) async {
    const String firebaseServerKey = 'YOUR_SERVER_KEY_HERE';

    final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');

    final Map<String, dynamic> notificationData = {
      'registration_ids': fcmTokens,
      'notification': {
        'title': "New Task Assigned",
        'body': "You have been assigned a new task: ${taskData['taskDescription']}",
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
      'data': {
        'taskId': taskData['taskId'],
        'taskDescription': taskData['taskDescription'],
        'deadlineDate': taskData['deadlineDate'],
      },
    };

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Received message: ${message.notification?.title}');
      print('Task ID: ${message.data['taskId']}');

      String taskId = message.data['taskId'];

      SharedPreferences prefs = await SharedPreferences.getInstance();

      bool isNotificationShown = prefs.getBool('task_$taskId') ?? false;

      if (!isNotificationShown) {
        print('Displaying notification for task: $taskId');

        prefs.setBool('task_$taskId', true);
      } else {
        print('Notification for task $taskId has already been shown.');
      }
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$firebaseServerKey',
      },
      body: jsonEncode(notificationData),
    );

    if (response.statusCode == 200) {
      print("✅ Notifications sent to all users successfully!");
    } else {
      print("❌ Failed to send notifications: ${response.body}");
    }
  }
  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adminNameController.text = prefs.getString('name') ?? '';
      adminIdController.text = prefs.getString('id') ?? '';
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchEmployeeNames();
    _loadAdminData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.tasks,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Admin Task Assign",
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
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),
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
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade200, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 8,
                  shadowColor: Colors.deepPurpleAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        buildMultiSelectDropdownField(
                          labelText: 'Select Employees',
                          icon: Icons.person_outline,
                          items: employeeNames,
                          selectedItems: selectedEmployeeNames,
                          onChanged: (List<String> selected) {
                            setState(() {
                              selectedEmployeeNames = selected;
                              List<String> selectedIds = selected
                                  .map((name) => employeeNameIdMap[name] ?? '')
                                  .where((id) => id.isNotEmpty)
                                  .toList();
                              empIdController.text = selectedIds.join(', ');
                            });
                          },
                        ),

                        SizedBox(height: 16),
                        buildTextField(
                          controller: empIdController,
                          labelText: 'Employee IDs',
                          icon: Icons.badge_outlined,
                          keyboardType: TextInputType.text,
                          hintText: 'Auto-filled based on selected names',
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please select at least one employee';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 16),

                        Column(
                          children: checkboxValues.entries.map((entry) {
                            final field = entry.key;
                            final value = entry.value;

                            return buildCustomCheckboxTile(
                              title: field,
                              value: value,
                              onChanged: (val) {
                                setState(() {
                                  checkboxValues[field] = val ?? false;
                                });
                                updateCheckboxValue(field, val);
                              },
                              icon: Icons.check_circle_outline,
                              color: Colors.blue,
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 16),

                        buildDropdownField(
                          labelText: 'Department',
                          icon: Icons.business,
                          value: selectedDepartment,
                          items: departmentList.map((department) {
                            return {'text': department['name'], 'icon': department['icon']};
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedDepartment = value;
                            });
                          },
                        ),

                        SizedBox(height: 16),

                        GestureDetector(
                          onTap: () async {
                            DateTime? selectedDate = await _selectDate(context);
                            if (selectedDate != null) {
                              setState(() {
                                String formattedDate = DateFormat('dd MMMM yyyy').format(selectedDate);
                                dateController.text = formattedDate;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: buildTextField(
                              controller: dateController,
                              labelText: 'Select Date',
                              icon: Icons.calendar_today,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        GestureDetector(
                          onTap: () async {
                            TimeOfDay? selectedTime = await _selectTime(context);
                            if (selectedTime != null) {
                              setState(() {
                                String formattedTime = selectedTime.format(context);
                                timeController.text = formattedTime;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: buildTextField(
                              controller: timeController,
                              labelText: 'Select Time',
                              icon: Icons.access_time,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        buildTextField(
                          controller: projectNameController,
                          labelText: 'Project Name',
                          icon: Icons.work_outline,
                        ),

                        SizedBox(height: 16,),

                        if (selectedDepartment == 'Installation' ||
                            selectedDepartment == 'Sales' ||
                            selectedDepartment == 'Services' ||
                            selectedDepartment == 'Social Media Marketing')
                          buildTextField(
                            controller: siteLocationController,
                            labelText: 'Site Location',
                            icon: Icons.location_on,
                          ),

                        SizedBox(height: 16,),

                        ElevatedButton(
                          onPressed: pickFiles,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(200, 60),
                            backgroundColor: Colors.blue.shade900,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 5,
                            shadowColor: Colors.grey.withOpacity(0.5),
                            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                          ),
                          child: MouseRegion(
                            onEnter: (_) {
                              setState(() {});
                            },
                            onExit: (_) {
                              setState(() {});
                            },
                            child: Text(
                              "Choose Files",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        selectedFiles.isNotEmpty
                            ? Container(
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                              List.generate(selectedFiles.length, (index) {
                                return Container(
                                  margin: EdgeInsets.all(10),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                    Border.all(color: Colors.blue, width: 1),
                                  ),
                                  width:
                                  120,
                                  child: Stack(
                                    children: [
                                      Column(
                                        children: [
                                          if (fileTypes[index] == 'jpg' ||
                                              fileTypes[index] == 'png' ||
                                              fileTypes[index] == 'jpeg')
                                            Image.file(
                                              selectedFiles[index],
                                              width: 100,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          else if (fileTypes[index] == 'mp4' ||
                                              fileTypes[index] == 'mov' ||
                                              fileTypes[index] == 'avi' ||
                                              fileTypes[index] == 'mkv')
                                            Icon(
                                              Icons.video_file,
                                              size: 50,
                                              color: Colors.blue,
                                            )
                                          else if (fileTypes[index] == 'gif')
                                              Image.file(
                                                selectedFiles[index],
                                                width: 100,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                            else
                                              Icon(
                                                Icons.insert_drive_file,
                                                size: 50,
                                                color: Colors.blue,
                                              ),
                                          SizedBox(height: 10),

                                          Text(
                                            fileNames[index],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 5),

                                          SizedBox(
                                            width: 100,
                                            child: TextField(
                                              controller:
                                              fileNameControllers[index],
                                              decoration: InputDecoration(
                                                labelText: 'Rename',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                ),
                                                filled: true,
                                                fillColor: Colors.blue.shade50,
                                              ),
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          SizedBox(height: 5),

                                          // Rename button
                                          ElevatedButton(
                                            onPressed: () => renameFile(index),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: Size(100, 30),
                                              backgroundColor:
                                              Colors.blue.shade900,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              "Rename",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => replaceFile(index),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: Size(100, 30),
                                              backgroundColor: Colors.blue.shade900,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              "Replace",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          // Open file button
                                          ElevatedButton(
                                            onPressed: () =>
                                                openFile(selectedFiles[index]),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: Size(100, 30),
                                              backgroundColor:
                                              Colors.blue.shade900,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              "Open",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      Positioned(
                                        top: -8,
                                        right: -5,
                                        child: CircleAvatar(
                                          radius:
                                          16,
                                          backgroundColor: Colors
                                              .white,
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.red, size: 19),
                                            onPressed: () => closeFile(index),
                                          ),
                                        ),
                                      ),

                                      // Replace file button

                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        )
                            : Text("No files selected yet."),

                        SizedBox(height: 16),

                        buildTextField(
                          controller: taskDescriptionController,
                          labelText: 'Task Description',
                          icon: Icons.description,
                          maxLines: 4,
                        ),
                        SizedBox(height: 16,),
                        // Deadline Date Picker
                        GestureDetector(
                          onTap: () async {
                            await _selectDeadlineDate(context);
                          },
                          child: AbsorbPointer(
                            child: buildTextField(
                              controller: deadlineDateController,
                              labelText: 'Select Deadline Date',
                              icon: Icons.calendar_today,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () async {
                          FocusScope.of(context).unfocus();
                          await _submitData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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