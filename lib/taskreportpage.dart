import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'customwidget.dart';

class DailyTaskReport2 extends StatefulWidget {
  const DailyTaskReport2({super.key});

  @override
  State<DailyTaskReport2> createState() => _DailyTaskReport2State();
}

class _DailyTaskReport2State extends State<DailyTaskReport2> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _challengesController = TextEditingController();
  final TextEditingController _actionsTakenController = TextEditingController();
  final TextEditingController _nextStepsController = TextEditingController();
  final TextEditingController _workController1 = TextEditingController();
  final TextEditingController _workController2 = TextEditingController();
  final TextEditingController _workController3 = TextEditingController();
  final TextEditingController _workController4 = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  DateTime _selectedDate = DateTime.now();
  File? _file;
  List<File> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileTypes = [];
  List<TextEditingController> fileNameControllers = [];
  File? _image;
  bool isLoading = false;
  bool _isLoading = false;
  String? selectedServiceStatus;
  String? selectedDepartment;

  List<String> serviceStatuses = ["Pending", "In Progress", "Completed"];
  List<String> serviceDepartment = [
    "Digital Marketing",
    "Sales",
    "Installation",
    "Human Resource",
    "Reception",
    "Account",
    "Finance",
    "Management",
    "Social Media"
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime onlyDate = DateTime(today.year, today.month, today.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(onlyDate) ? onlyDate : _selectedDate,
      firstDate: onlyDate,
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMMM yy').format(picked);
      });
    }
  }

  Future<void> replaceFile(int index) async {
    // Open the file picker to let the user choose a new file
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
      // Get the selected file
      PlatformFile file = result.files.first;

      // Replace the old file with the new file
      setState(() {
        selectedFiles[index] = File(file.path!); // Ensure path is not null
        fileNames[index] = file.name; // Update the file name
        fileTypes[index] = file.extension ?? 'unknown'; // Update the file type
      });
    } else {
      // User canceled the file picker
      print("No file selected.");
    }
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
          _employeeNameController.text =
              userSnapshot.get('fullName') ?? "Unknown";
          _employeeIdController.text = userSnapshot.get('empId') ?? "Unknown";
        });
        print(
            "Fetched Data: ${_employeeNameController.text}, ${_employeeIdController.text},}");
      } else {
        print("No user data found for userId: $userId");
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  void pickFiles() async {
    FilePickerResult? result =
    await FilePicker.platform.pickFiles(allowMultiple: true);

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

  void closeFile(int index) {
    setState(() {
      selectedFiles.removeAt(index);
      fileNames.removeAt(index);
      fileTypes.removeAt(index);
      fileNameControllers.removeAt(index);
    });
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

        Reference storageRef =
        _storage.ref().child("DailyTaskReport/$fileName");

        UploadTask uploadTask = storageRef.putData(
            fileBytes,
            SettableMetadata(
              contentType: _getContentType(fileType),
            ));

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await _firestore.collection('DailyTaskReport').add({
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

  void _showFileDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade900],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Choose an Option",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera, color: Colors.white),
                title: const Text("Take a Photo",
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _requestPermissions();
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.white),
                title: const Text("Upload Document",
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.of(context).pop();
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        List<Map<String, dynamic>> uploadedFiles = [];

        for (int index = 0; index < selectedFiles.length; index++) {
          String fileName = fileNames[index];
          File file = selectedFiles[index];
          String fileType = fileTypes[index];

          Uint8List fileBytes = await file.readAsBytes();
          Reference storageRef = _storage.ref().child("DailyTaskReport/$fileName");

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

        List<Map<String, String>> workLog = [
          {"timeSlot": "10 AM - 12 PM", "description": _workController1.text},
          {"timeSlot": "12 PM - 2 PM", "description": _workController2.text},
          {"timeSlot": "2 PM - 6 PM", "description": _workController3.text},
          {"timeSlot": "6 PM - 8 PM", "description": _workController4.text},
        ];

        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid ?? '';

        Map<String, dynamic> reportData = {
          'employeeId': _employeeIdController.text.trim(),
          "employeeName": _employeeNameController.text.trim(),
          "taskTitle": _taskTitleController.text.trim(),
          "challenges": _challengesController.text.trim(),
          "actionsTaken": _actionsTakenController.text.trim(),
          "nextSteps": _nextStepsController.text.trim(),
          "service_status": selectedServiceStatus,
          "Service_department": selectedDepartment,
          "location": _locationController.text.trim(),
          "date": _selectedDate,
          "uploadedFiles": uploadedFiles,
          "workLog": workLog,
          "userId": userId,
          "timestamp": FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance.collection("DailyTaskReport").add(reportData);

        Fluttertoast.showToast(
          msg: "Task submitted successfully!",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        setState(() {
          _isLoading = false;
        });

        _taskTitleController.clear();
        _challengesController.clear();
        _actionsTakenController.clear();
        _nextStepsController.clear();
        _locationController.clear();
        _workController1.clear();
        _workController2.clear();
        _workController3.clear();
        _workController4.clear();
        _file = null;
        _image = null;
        // ✅ clear the selected date
        _dateController.clear();
        selectedServiceStatus = null;
        selectedDepartment = null;
        selectedFiles.clear();
        fileNames.clear();
        fileTypes.clear();
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        Fluttertoast.showToast(
          msg: "Failed to submit report: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.task, color: Colors.white),
            SizedBox(width: 8),
            Text(
              "Daily Task Report",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white),
            ),
          ],
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30))),
        elevation: 8,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.blue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(color: Colors.grey, blurRadius: 8, spreadRadius: 4)
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _employeeNameController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Employee Name",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFFFE4C4),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Employee name is required'
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _employeeIdController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Employee ID",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFFFE4C4),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Employee ID is required'
                        : null,
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _dateController,
                  decoration: InputDecoration(
                    labelText: "Select Date",
                    prefixIcon:
                    const Icon(Icons.date_range, color: Colors.blueAccent),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  readOnly: true, // Prevents keyboard input
                  onTap: () =>
                      _selectDate(context), // Open date picker when tapped
                ),

                const SizedBox(height: 15),
                _buildDecoratedField(
                  controller: _taskTitleController,
                  label: "Task Title",
                  icon: Icons.task,
                  backgroundColor: Colors.blue.shade50,
                  validator: validateTaskTitle,
                ),
                SizedBox(height: 16),

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

                // If files are selected, show them in a horizontally scrollable container
                // Make sure to import the file_picker package

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
                          120, // Fixed width for each file container
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  // Display thumbnails or icons based on file type
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

                                  // File name and rename feature
                                  Text(
                                    fileNames[index],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),

                                  // Text field to rename the file
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

                              // Close button positioned inside the container but above the image preview (top-right corner of the container)
                              Positioned(
                                top: -8,
                                right: -5,
                                child: CircleAvatar(
                                  radius:
                                  16, // Circular background for the icon
                                  backgroundColor: Colors
                                      .white, // Background color for the circle
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

                if (_file != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "File selected: ${_file!.path.split('/').last}",
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                const SizedBox(height: 20),
                _buildDecoratedField(
                  controller: _actionsTakenController,
                  label: "Actions Taken",
                  icon: Icons.check_circle,
                  maxLines: 4,
                  backgroundColor: Colors.green.shade50,
                  validator: validateActionsTaken,
                ),
                const SizedBox(height: 20),

                _buildDecoratedField(
                  controller: _nextStepsController,
                  label: "Next Steps",
                  icon: Icons.arrow_forward,
                  maxLines: 4,
                  backgroundColor: Colors.purple.shade50,
                  validator: validateNextSteps,
                ),

                const SizedBox(height: 20),
                buildDropdownField(
                  labelText: "Select Department",
                  icon: Icons.assignment,
                  value: selectedDepartment,
                  items: serviceDepartment
                      .map((status) =>
                  {'text': status, 'icon': Icons.assignment})
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDepartment = value!;
                    });
                  },
                  validator: validateField,
                ),

                const SizedBox(height: 20),
                buildDropdownField(
                  labelText: "Service Status",
                  icon: Icons.assignment,
                  value: selectedServiceStatus,
                  items: serviceStatuses
                      .map((status) =>
                  {'text': status, 'icon': Icons.assignment})
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedServiceStatus = value;
                    });
                  },
                  validator: validateField,
                ),
                const SizedBox(height: 20),

// Work Log Table
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Work Log - ${DateFormat('dd MMM yyyy').format(DateTime.now())}",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                      const SizedBox(height: 10),
                      Table(
                        border: TableBorder.all(color: Colors.black54),
                        columnWidths: const {
                          0: FlexColumnWidth(1.5), // Time Slot Column
                          1: FlexColumnWidth(3), // Work Description Column
                        },
                        children: [
                          _buildTableRow("10 AM - 12 PM", _workController1),
                          _buildTableRow("12 PM - 2 PM", _workController2),
                          _buildTableRow("2 PM - 6 PM", _workController3),
                          _buildTableRow("6 PM - 8 PM", _workController4),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _buildDecoratedField(
                  controller: _locationController,
                  label: "Location",
                  icon: Icons.location_on,
                  backgroundColor: Colors.indigo.shade50,
                  validator: validateLocation,
                ),

                const SizedBox(height: 20),
                const SizedBox(height: 25),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitReport,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit Report",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
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

  String? validateField(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  TableRow _buildTableRow(String timeSlot, TextEditingController controller) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            timeSlot,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Enter work description",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDecoratedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Color backgroundColor = Colors.white,
    String? Function(String?)? validator,
    TextInputAction textInputAction =
        TextInputAction.done, // Default text input action
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        textInputAction:
        textInputAction, // Pass the textInputAction to TextFormField
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          filled: true,
          fillColor: backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: InputDecoration(
            labelText: "Select Date",
            prefixIcon: const Icon(Icons.date_range, color: Colors.blueAccent),
            filled: true,
            fillColor: Colors.blue.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          controller: TextEditingController(
            text: DateFormat('dd MMMM yy').format(_selectedDate),
          ),
        ),
      ),
    );
  }
}