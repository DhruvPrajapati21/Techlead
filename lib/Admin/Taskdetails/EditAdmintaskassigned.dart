import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class EditTaskScreen extends StatefulWidget {
  final Map<String, dynamic> taskData;
  const EditTaskScreen({required this.taskData, Key? key}) : super(key: key);

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController projectNameCtrl;
  late TextEditingController adminNameCtrl;
  late TextEditingController empIdsCtrl;
  late TextEditingController employeeNamesCtrl;
  late TextEditingController departmentCtrl;
  late TextEditingController siteLocationCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController assignedDateCtrl;
  late TextEditingController deadlineDateCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController statusCtrl;
  late TextEditingController empDescCtrl;

  List<Map<String, String>> files = [];
  XFile? newImage;

  @override
  void initState() {
    super.initState();
    final t = widget.taskData;
    projectNameCtrl = TextEditingController(text: t['projectName']);
    adminNameCtrl = TextEditingController(text: t['adminName']);
    empIdsCtrl = TextEditingController(text: t['empIds']);
    employeeNamesCtrl = TextEditingController(text: (t['employeeNames'] as List).join(', '));
    departmentCtrl = TextEditingController(text: t['department']);
    siteLocationCtrl = TextEditingController(text: t['siteLocation'] ?? '');
    descriptionCtrl = TextEditingController(text: t['taskDescription']);
    assignedDateCtrl = TextEditingController(text: t['date']);
    deadlineDateCtrl = TextEditingController(text: t['deadlineDate']);
    timeCtrl = TextEditingController(text: t['time']);
    statusCtrl = TextEditingController(text: t['taskstatus']);
    empDescCtrl = TextEditingController(text: t['employeeDescription'] ?? '');
    if (t['files'] != null && t['files'] is List) {
      files = (t['files'] as List)
          .map<Map<String, String>>((f) => Map<String, String>.from(f as Map))
          .toList();
    }

  }

  @override
  void dispose() {
    projectNameCtrl.dispose();
    adminNameCtrl.dispose();
    empIdsCtrl.dispose();
    employeeNamesCtrl.dispose();
    departmentCtrl.dispose();
    siteLocationCtrl.dispose();
    descriptionCtrl.dispose();
    assignedDateCtrl.dispose();
    deadlineDateCtrl.dispose();
    timeCtrl.dispose();
    statusCtrl.dispose();
    empDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController ctrl) async {
    DateTime? initial;
    try {
      initial = DateFormat('dd MMMM yy').parse(ctrl.text);
    } catch (_) {
      initial = DateTime.now();
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = DateFormat('dd MMMM yy').format(picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (img != null) {
      setState(() => newImage = img);
    }
  }

  Future<void> _updateTask() async {
    if (!_formKey.currentState!.validate()) return;

    String? uploadedUrl;
    if (newImage != null) {
      final ref = FirebaseStorage.instance.ref().child('task_images/${widget.taskData['taskId']}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final up = await ref.putFile(File(newImage!.path));
      uploadedUrl = await up.ref.getDownloadURL();
      files.add({'downloadUrl': uploadedUrl, 'fileType': 'jpg', 'fileName': newImage!.name});
    }

    await FirebaseFirestore.instance.collection('TaskAssign').doc(widget.taskData['taskId']).update({
      'projectName': projectNameCtrl.text.trim(),
      'adminName': adminNameCtrl.text.trim(),
      'empIds': empIdsCtrl.text.trim(),
      'employeeNames': employeeNamesCtrl.text.trim().split(',').map((e) => e.trim()).toList(),
      'department': departmentCtrl.text.trim(),
      'siteLocation': siteLocationCtrl.text.trim(),
      'taskDescription': descriptionCtrl.text.trim(),
      'date': assignedDateCtrl.text.trim(),
      'deadlineDate': deadlineDateCtrl.text.trim(),
      'time': timeCtrl.text.trim(),
      'taskstatus': statusCtrl.text.trim(),
      'employeeDescription': empDescCtrl.text.trim(),
      'files': files,
    });

    Fluttertoast.showToast(msg: "Task updated successfully!", backgroundColor: Colors.green, textColor: Colors.white);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task', style: TextStyle(fontFamily: "Times New Roman")),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('Project Name', projectNameCtrl),
              _buildTextField('Admin Name', adminNameCtrl),
              _buildTextField('Employee IDs (comma‑sep)', empIdsCtrl),
              _buildTextField('Employee Names (comma‑sep)', employeeNamesCtrl),
              _buildTextField('Department', departmentCtrl),
              if (['Installation', 'Sales', 'Reception', 'Social Media'].contains(departmentCtrl.text.trim()))
                _buildTextField('Site Location', siteLocationCtrl),
              _buildTextField('Task Description', descriptionCtrl),
              _buildDatePickerField('Assigned Date', assignedDateCtrl),
              _buildDatePickerField('Deadline Date', deadlineDateCtrl),
              _buildTextField('Time', timeCtrl),
              _buildTextField('Task Status', statusCtrl),
              _buildTextField('Employee Description', empDescCtrl),
              const SizedBox(height: 12),
              const Text('Existing Attachments:', style: TextStyle(fontFamily: "Times New Roman", fontWeight: FontWeight.bold)),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: files.length,
                  itemBuilder: (ctx, i) {
                    final f = files[i];
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(f['downloadUrl']!, width: 100, height: 80, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (newImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('New image: ${newImage!.name}', style: const TextStyle(fontFamily: "Times New Roman")),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo, color: Colors.white),
                label: const Text('Add Image', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                onPressed: _updateTask,
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontFamily: "Times New Roman")),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        style: const TextStyle(fontFamily: "Times New Roman"),
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontFamily: "Times New Roman"),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String label, TextEditingController ctrl) {
    return GestureDetector(
      onTap: () => _selectDate(context, ctrl),
      child: AbsorbPointer(child: _buildTextField(label, ctrl)),
    );
  }
}
