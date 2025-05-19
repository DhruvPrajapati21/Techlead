import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AdminFetchDataPiePage extends StatefulWidget {
  const AdminFetchDataPiePage({super.key});

  @override
  State<AdminFetchDataPiePage> createState() => _AdminFetchDataPiePageState();
}

class _AdminFetchDataPiePageState extends State<AdminFetchDataPiePage> {
  String? selectedCategoryName;
  String? selectedProjectStatus;
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  final TextEditingController percentageController = TextEditingController();

  bool isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitData() async {
    if (selectedCategoryName == null ||
        selectedProjectStatus == null ||
        projectNameController.text.isEmpty ||
        landmarkController.text.isEmpty ||
        percentageController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please fill in all the fields",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _firestore.collection('projects').add({
        'category': selectedCategoryName,
        'projectName': projectNameController.text,
        'status': selectedProjectStatus,
        'landmark': landmarkController.text,
        'completionPercentage': int.parse(percentageController.text),
        'timestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: "Data submitted successfully!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      setState(() {
        selectedCategoryName = null;
        selectedProjectStatus = null;
        projectNameController.clear();
        landmarkController.clear();
        percentageController.clear();
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error submitting data: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Admin Fetch Data",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
            color: Colors.white, // White text
          ),
        ),
        centerTitle: true,
        elevation: 10, // Increased elevation for more depth
        backgroundColor: Colors.deepPurpleAccent, // Modern purple background color
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple, Colors.deepPurpleAccent], // Gradient for AppBar
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notification icon click
            },
            iconSize: 30, // Custom size for the icon
            color: Colors.white, // White icon color
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Project Information'),
                const SizedBox(height: 20),
                _buildFormCard(),
                const SizedBox(height: 20),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add a quick action or navigation here
        },
        backgroundColor: Colors.deepPurpleAccent, // Floating Action Button in purple
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper function to build section title with creative styling
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurpleAccent, // Modern color for section title
        letterSpacing: 1.5,
        shadows: [
          BoxShadow(
            color: Colors.deepPurpleAccent.withOpacity(0.5),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // Helper function to build the form card with stylish UI
  Widget _buildFormCard() {
    return Card(
      elevation: 10,
      shadowColor: Colors.deepPurpleAccent.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white, // White background for the form card
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDropdownField('Department', selectedCategoryName, _getDepartments(), (newValue) {
              setState(() {
                selectedCategoryName = newValue;
              });
            }),
            const SizedBox(height: 16.0),
            _buildTextField(projectNameController, 'Project Name'),
            const SizedBox(height: 16.0),
            _buildDropdownField('Project Status', selectedProjectStatus, ['Not Started', 'In Progress', 'Completed'], (newValue) {
              setState(() {
                selectedProjectStatus = newValue;
              });
            }),
            const SizedBox(height: 16.0),
            _buildTextField(landmarkController, 'Landmark'),
            const SizedBox(height: 16.0),
            _buildTextField(percentageController, 'Task Completion %', isNumber: true),
          ],
        ),
      ),
    );
  }

  // Helper function to create dropdown form fields with animations
  Widget _buildDropdownField(String label, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(label),
        items: items.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Row(
            children: [
              Icon(_getDepartmentIcon(item), color: Colors.deepPurpleAccent), // Deep Purple icons
              const SizedBox(width: 10),
              Text(item),
            ],
          ),
        )).toList(),
        onChanged: onChanged,
        decoration: _inputDecoration(),
      ),
    );
  }

  // Helper function to create text form fields with more elegant design
  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.deepPurpleAccent.withOpacity(0.1), // Light purple background
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      ),
    );
  }

  // Helper function to create submit button with smooth transitions
  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurpleAccent, // Purple background for the button
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isLoading ? 0 : 6,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Submit", style: TextStyle(fontSize: 16, color: Colors.white)), // White text for submit button
      ),
    );
  }

  // Input decoration style for form fields
  InputDecoration _inputDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.deepPurpleAccent.withOpacity(0.1), // Light purple background for inputs
    );
  }

  // Function to get the corresponding department icon
  IconData _getDepartmentIcon(String departmentName) {
    switch (departmentName) {
      case 'HR': return Icons.people;
      case 'Finance': return Icons.account_balance;
      case 'Development': return Icons.code;
      case 'Digital Marketing': return Icons.campaign;
      case 'Reception': return Icons.phone;
      case 'Account': return Icons.book;
      case 'Human Resources': return Icons.group;
      case 'Management': return Icons.business;
      case 'Sales': return Icons.shopping_cart;
      case 'Installation': return Icons.build;
      case 'Services': return Icons.miscellaneous_services;
      case 'Social Media Marketing': return Icons.share;
      default: return Icons.help;
    }
  }

  // Function to return a list of departments
  List<String> _getDepartments() {
    return [
      'HR', 'Finance', 'Development', 'Digital Marketing', 'Reception', 'Account',
      'Human Resources', 'Management', 'Sales', 'Installation', 'Services', 'Social Media Marketing'
    ];
  }
}
