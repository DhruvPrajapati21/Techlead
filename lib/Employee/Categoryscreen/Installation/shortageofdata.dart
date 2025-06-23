import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

class ShortageOfProduct extends StatefulWidget {
  const ShortageOfProduct({super.key});

  @override
  State<ShortageOfProduct> createState() => _ShortageOfProductState();
}

class _ShortageOfProductState extends State<ShortageOfProduct> with TickerProviderStateMixin {

  bool _isSubmitting = false; // To track if form is being submitted
  bool _isSuccess = false; // To track success state


  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _requiredQuantityController = TextEditingController();
  final TextEditingController _availableQuantityController = TextEditingController();
  final TextEditingController _siteLocationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _assignedTechnicianController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _iconAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _iconSizeAnimation;
  late Animation<Color?> _iconColorAnimation;

  List<File> selectedFiles = [];
  List<String> fileNames = [];
  List<String> fileTypes = [];
  List<TextEditingController> fileNameControllers = [];
  List<File> files = []; // Store the list of selected files



  @override
  void initState() {
    super.initState();

    // Existing animation for page animations (if needed)
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Button animation
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      lowerBound: 0.9,
      upperBound: 1.0,
    )..forward();

    _buttonScaleAnimation = CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    );

    // New AnimationController for the app bar icon
    _iconAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true); // Repeat animation

    // Size animation for the icon
    _iconSizeAnimation = Tween<double>(begin: 30, end: 35).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeInOut),
    );

    // Color animation for the icon
    _iconColorAnimation = ColorTween(begin: Colors.white, end: Colors.yellowAccent).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.easeInOut),
    );
  }
  void showCustomSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade600], // Bluish gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Report submitted successfully!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        duration: Duration(seconds: 3), // Duration for the SnackBar to stay
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20), // Optional: space from the edge
      ),
    );
  }
  Future<void> _submitForm() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.transparent,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: CircularProgressIndicator(
                  strokeWidth: 6, // Thicker spinner line
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan), // Custom spinner color
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Submitting...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(),
        ),
      );

      setState(() {
        _isSubmitting = true;
      });

      // Collect form data
      String productName = _productNameController.text;
      String requiredQuantity = _requiredQuantityController.text;
      String availableQuantity = _availableQuantityController.text;
      String siteLocation = _siteLocationController.text;
      String description = _descriptionController.text;
      String contactInfo = _contactInfoController.text;
      String address = _addressController.text;
      String assignedTechnician = _assignedTechnicianController.text;

      // Upload files in parallel using Futures
      List<Future<TaskSnapshot>> uploadTasks = [];
      List<Map<String, dynamic>> fileData = [];

      for (int i = 0; i < selectedFiles.length; i++) {
        File file = selectedFiles[i];
        String fileName = fileNames[i];
        String fileType = fileTypes[i];

        // Upload file to Firebase Storage
        String filePath = 'product_files/${DateTime.now().millisecondsSinceEpoch}_${fileName}';
        uploadTasks.add(FirebaseStorage.instance.ref(filePath).putFile(file));
      }

      // Wait for all uploads to complete
      List<TaskSnapshot> uploadResults = await Future.wait(uploadTasks);

      // Get download URLs for each file
      for (int i = 0; i < uploadResults.length; i++) {
        TaskSnapshot uploadTask = uploadResults[i];
        String downloadUrl = await uploadTask.ref.getDownloadURL();
        fileData.add({
          'file_name': fileNames[i],
          'file_url': downloadUrl,
          'file_type': fileTypes[i],
        });
      }

      // Save data to Firestore
      await FirebaseFirestore.instance.collection('product_shortage_reports').add({
        'product_name': productName,
        'required_quantity': requiredQuantity,
        'available_quantity': availableQuantity,
        'site_location': siteLocation,
        'description': description,
        'contact_info': contactInfo,
        'address': address,
        'assigned_technician': assignedTechnician,
        'files': fileData,
        'created_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSuccess = true; // Show success
        _isSubmitting = false; // Re-enable the button after submission
      });



      // Show success message
      // Inside your submit form success handler

      showCustomSnackBar(context);


      // Optionally clear the form
      _clearForm();

      // Close the loading spinner dialog after successful submission
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isSubmitting = false; // Re-enable button if there's an error
      });
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report!')));

      // Close the loading spinner dialog if an error occurs
      Navigator.of(context).pop();
    }
  }



  void _clearForm() {
    _productNameController.clear();
    _requiredQuantityController.clear();
    _availableQuantityController.clear();
    _siteLocationController.clear();
    _descriptionController.clear();
    _contactInfoController.clear();
    _addressController.clear();
    _assignedTechnicianController.clear();
    setState(() {
      selectedFiles.clear();
      fileNames.clear();
      fileTypes.clear();
      fileNameControllers.clear();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    _iconAnimationController.dispose();
    _buttonAnimationController.dispose();
    _productNameController.dispose();
    _requiredQuantityController.dispose();
    _availableQuantityController.dispose();
    _siteLocationController.dispose();
    _descriptionController.dispose();
    _contactInfoController.dispose();
    _addressController.dispose();
    _assignedTechnicianController.dispose();
    super.dispose();
  }

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
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

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(_animation),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              labelStyle:  TextStyle(color: Colors.blue.shade900,fontWeight: FontWeight.bold ), // Blue color for the label
              filled: true,
              fillColor: Colors.white, // White background color
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue), // Blue border color
              ),
            ),
            style: const TextStyle(color: Colors.black), // Black text color for input
          ),
        ),
      ),
    );
  }

  Future<String> _loadExcelPreview(File file) async {
    try {
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      var sheet = excel.tables.keys.first;
      var rows = excel.tables[sheet]?.rows;

      // Generating a preview string
      String preview = "";
      for (int i = 0; i < (rows?.length ?? 0) && i < 5; i++) {
        preview += rows![i].map((cell) => cell?.value.toString() ?? "").join(", ") + "\n";
      }

      return preview.isNotEmpty ? preview : "Empty Excel File";
    } catch (e) {
      return "Failed to read Excel file";
    }
  }

  Widget _buildFilePreview(File file, String fileType) {
    if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png') {
      // 🖼️ Image Preview
      return Image.file(
        file,
        width: 100,
        height: 80,
        fit: BoxFit.cover,
      );
    } else if (fileType == 'txt' || fileType == 'json' || fileType == 'csv') {
      // 📝 Text File Preview
      return FutureBuilder<String>(
        future: file.readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text("Error loading text file");
          } else {
            return Container(
              width: 100,
              height: 80,
              padding: const EdgeInsets.all(8),
              color: Colors.blueGrey,
              child: Text(
                snapshot.data!.length > 100
                    ? snapshot.data!.substring(0, 100) + '...'
                    : snapshot.data!,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
          }
        },
      );
    } else if (fileType == 'xls' || fileType == 'xlsx') {
      // 📊 XLS/XLSX Preview
      return FutureBuilder<String>(
        future: _loadExcelPreview(file),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text("Error loading Excel file");
          } else {
            return Container(
              width: 100,
              height: 80,
              padding: const EdgeInsets.all(8),
              color: Colors.green.shade700,
              child: Text(
                snapshot.data!,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            );
          }
        },
      );
    }
    else if (fileType == 'pdf') {
      return FutureBuilder<pdfx.PdfDocument>(
        future: pdfx.PdfDocument.openFile(file.path),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text("Error loading PDF");
          } else if (snapshot.hasData) {
            // Use the document correctly
            return pdfx.PdfView(
              controller: pdfx.PdfController(
                document: Future.value(snapshot.data!), // Wrap in Future.value
              ),
            );
          } else {
            return const Text("No PDF available");
          }
        },
      );
    }
    else {
      // 🚫 Unsupported File Type
      return const Icon(Icons.insert_drive_file, size: 50, color: Colors.cyan);
    }
  }

  void replaceImage(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Allow all file types
    );

    if (result != null) {
      setState(() {
        selectedFiles[index] = File(result.files.single.path!);
        fileNames[index] = result.files.single.name;
        fileTypes[index] = result.files.single.extension ?? '';
        fileNameControllers[index].text = result.files.single.name;
      });
    }
  }


  Widget _buildFileList() {
    return selectedFiles.isNotEmpty
        ? SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(selectedFiles.length, (index) {
          File file = selectedFiles[index];
          String fileType = fileTypes[index];

          return Container(
            width: 150, // Fixed width to avoid overflow
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display preview
                SizedBox(
                  width: 120,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildFilePreview(file, fileType),
                  ),
                ),
                const SizedBox(height: 10),

                // Display File Name
                Flexible(
                  child: Text(
                    fileNames[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Rename TextField
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: fileNameControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Rename',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 5),

                // Rename Button
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => renameFile(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.blue.shade900,
                          width: 2,
                        ),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Rename"),
                  ),
                ),
                const SizedBox(height: 5),

                // Replace Image Button
                // Replace Image Button
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => replaceImage(index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.blue.shade900,
                          width: 2,
                        ),
                      ),
                      foregroundColor: Colors.white, // White font color
                    ),
                    child: const Text(
                      "Replace Image",
                      style: TextStyle(
                        color: Colors.white, // Text Color
                        fontWeight: FontWeight.bold, // Bold Text
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => openFile(file),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.blue.shade900,
                          width: 2,
                        ),
                      ),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Open"),
                  ),
                ),
              ],
            ),
          );

        }),
      ),
    )
        : Center(
      child: const Text(
        "No files selected yet.",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildChooseFilesButton() {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _buttonAnimationController.reverse(),
        onTapUp: (_) {
          _buttonAnimationController.forward();
          pickFiles();
        },
        child: Center(
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.cyan,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'Choose Files',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16, // Smaller font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: GestureDetector(
        onTap: _isSubmitting ? null : _submitForm,
        child: Center(
          child: Container(
            width: 270,
            padding: const EdgeInsets.symmetric(vertical: 15,horizontal: 15),
            decoration: BoxDecoration(
              color: _isSubmitting ? Colors.grey : Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isSubmitting
                ? Container()
                : _isSuccess
                ? const Center(
              child: Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : const Center(
              child: Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      appBar: AppBar(
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _iconAnimationController,
                builder: (context, child) {
                  return FaIcon(
                    FontAwesomeIcons.boxOpen,
                    color: _iconColorAnimation.value,
                    size: _iconSizeAnimation.value,
                  );
                },
              ),
              const SizedBox(width: 10),
              const Text(
                'Product Shortage Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue.shade900,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 10,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: const Text(
                'Report Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(height: 20,),
            _buildTextField('Product Name', _productNameController),
            _buildTextField('Required Quantity', _requiredQuantityController, keyboardType: TextInputType.number),
            _buildTextField('Available Quantity', _availableQuantityController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            _buildChooseFilesButton(), // <-- CHOOSE FILE BUTTON HERE
            const SizedBox(height: 20),
            _buildFileList(),
            const SizedBox(height: 20),
            _buildTextField('Site Location', _siteLocationController),
            _buildTextField('Description', _descriptionController),
            _buildTextField('Contact Information', _contactInfoController),
            _buildTextField('Address', _addressController),
            _buildTextField('Assigned Technician', _assignedTechnicianController),
            SizedBox(height: 20,),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
