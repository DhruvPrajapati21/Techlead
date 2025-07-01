import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path/path.dart' as p;

class EditReceptionReportScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> reportData;

  const EditReceptionReportScreen({
    super.key,
    required this.docId,
    required this.reportData,
  });

  @override
  State<EditReceptionReportScreen> createState() => _EditReceptionReportScreenState();
}

class _EditReceptionReportScreenState extends State<EditReceptionReportScreen> {
  final Map<String, TextEditingController> controllers = {};
  final List<String> serviceStatuses = ["Pending", "In Progress", "Completed"];

  List<Map<String, dynamic>> uploadedFiles = [];
  List<Map<String, dynamic>> deletedFiles = [];
  Map<String, String> renamedFiles = {};

  @override
  void initState() {
    super.initState();
    widget.reportData.forEach((key, value) {
      if (key != 'userId' && (value is String || value == null)) {
        controllers[key] = TextEditingController(text: value ?? '');
      }
    });

    if (widget.reportData['uploadedFiles'] != null &&
        widget.reportData['uploadedFiles'] is List) {
      uploadedFiles = List<Map<String, dynamic>>.from(widget.reportData['uploadedFiles']);
    }
  }

  @override
  void dispose() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _deleteFile(Map<String, dynamic> file) {
    setState(() {
      deletedFiles.add(file);
      uploadedFiles.remove(file);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File marked for deletion.')),
    );
  }

  void _renameFile(Map<String, dynamic> file) async {
    String? newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final TextEditingController nameController =
        TextEditingController(text: file['fileName']);
        return AlertDialog(
          title: const Text("Rename File"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "New File Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, nameController.text.trim()),
              child: const Text("Rename"),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        renamedFiles[file['fileName']] = newName;
        file['fileName'] = newName;
      });
    }
  }

  void _replaceFile(Map<String, dynamic> oldFile) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
      final extension = p.extension(fileName).replaceAll('.', '');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploaded_reports/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      try {
        final uploadTask = await storageRef.putData(fileBytes);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        final newFile = {
          'downloadUrl': downloadUrl,
          'fileName': fileName,
          'fileType': extension,
        };

        deletedFiles.add(oldFile);

        setState(() {
          final index = uploadedFiles.indexOf(oldFile);
          if (index != -1) {
            uploadedFiles[index] = newFile;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File replaced successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error replacing file: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    Map<String, dynamic> updatedData = {};

    controllers.forEach((key, controller) {
      updatedData[key] = controller.text.trim();
    });

    updatedData['uploadedFiles'] = uploadedFiles;

    try {
      for (var file in deletedFiles) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(file['downloadUrl']);
          await ref.delete();
        } catch (e) {
          print("Failed to delete ${file['fileName']}: $e");
        }
      }

      await FirebaseFirestore.instance
          .collection('DailyTaskReport')
          .doc(widget.docId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Widget _buildFileTile(Map<String, dynamic> file) {
    final String url = file['downloadUrl'] ?? '';
    final String fileType = (file['fileType'] ?? '').toLowerCase();
    final String fileName = file['fileName'] ?? 'Unnamed';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent, // So gradient shows
          isScrollControlled: true,
          builder: (context) => Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF000F89),
                  Color(0xFF0F52BA),
                  Color(0xFF002147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Wrap(
              runSpacing: 12,
              children: [
                Center(
                  child: Text(
                    fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                _buildActionButton(
                  icon: Icons.swap_horiz,
                  label: 'Replace File',
                  color: Colors.teal,
                  onPressed: () {
                    Navigator.pop(context);
                    _replaceFile(file);
                  },
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Rename File',
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.pop(context);
                    _renameFile(file);
                  },
                ),
                _buildActionButton(
                  icon: Icons.delete,
                  label: 'Delete File',
                  color: Colors.red,
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteFile(file);
                  },
                ),
                _buildActionButton(
                  icon: Icons.close,
                  label: 'Close',
                  color: Colors.grey,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: isImage
                  ? Image.network(
                url,
                width: 100,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white),
              )
                  : Icon(
                fileType == 'pdf' ? Icons.picture_as_pdf : Icons.insert_drive_file,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }


  void _addFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);

    if (result != null && result.files.single.bytes != null) {
      final fileBytes = result.files.single.bytes!;
      final fileName = result.files.single.name;
      final extension = p.extension(fileName).replaceAll('.', '');
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploaded_reports/${DateTime.now().millisecondsSinceEpoch}_$fileName');

      try {
        final uploadTask = await storageRef.putData(fileBytes);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        final newFile = {
          'downloadUrl': downloadUrl,
          'fileName': fileName,
          'fileType': extension,
        };

        setState(() {
          uploadedFiles.add(newFile);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'File uploaded successfully!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF000F89), // Royal Blue
            Color(0xFF0F52BA), // Cobalt Blue (replacing Indigo)
            Color(0xFF002147), // Light Sky Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FontAwesomeIcons.tasks, color: Colors.white),
              const SizedBox(width: 10),
              const Text(
                "Edit Your Tasks",
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
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 8,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000F89), // Royal Blue
                  Color(0xFF0F52BA), // Cobalt Blue (replacing Indigo)
                  Color(0xFF002147), // Light Sky Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),

            ),
          ),
        ),
        body: Container(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var entry in controllers.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: entry.key == 'service_status'
                        ? Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF000F89),
                            Color(0xFF0F52BA),
                            Color(0xFF002147),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: entry.value.text.isNotEmpty ? entry.value.text : null,
                        onChanged: (value) {
                          setState(() {
                            entry.value.text = value!;
                          });
                        },
                        items: serviceStatuses
                            .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status, style: const TextStyle(color: Colors.white)),
                        ))
                            .toList(),
                        dropdownColor: const Color(0xFF0F52BA),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        iconEnabledColor: Colors.white,
                      ),
                    )
                        : Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF000F89),
                            Color(0xFF0F52BA),
                            Color(0xFF002147),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white),
                      ),
                      child: TextField(
                        controller: entry.value,
                        readOnly: ['employeeName', 'Service_department', 'employeeId'].contains(entry.key),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          labelText: entry.key.replaceAll("_", " ").toUpperCase(),
                          labelStyle: const TextStyle(color: Colors.cyanAccent,fontWeight: FontWeight.bold),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                if (uploadedFiles.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Attached Files:",
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: uploadedFiles.length,
                      itemBuilder: (context, index) =>
                          _buildFileTile(uploadedFiles[index]),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Add File Button with gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF000F89),
                            Color(0xFF0F52BA),
                            Color(0xFF002147),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _addFile,
                        icon: const Icon(Icons.add),
                        label: const Text("Add File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // Important: transparent so gradient shows
                          shadowColor: Colors.transparent, // Remove shadow to keep it clean
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),

                    // Submit Button with gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF000F89),
                            Color(0xFF0F52BA),
                            Color(0xFF002147),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _submit,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          "Submit",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, // transparent again for gradient
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}