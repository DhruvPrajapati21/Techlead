import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddGuidelines extends StatefulWidget {
  const AddGuidelines({super.key});

  @override
  State<AddGuidelines> createState() => _AddGuidelinesState();
}

class _AddGuidelinesState extends State<AddGuidelines> {
  bool isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController headlinesController = TextEditingController();
  final TextEditingController guidelinesController = TextEditingController();
  final TextEditingController contactusController = TextEditingController();

  Future<void> _addToFirestore() async {
    if (_validateFields()) {
      setState(() => isLoading = true);

      try {
        final querySnapshot = await _firestore
            .collection('Guidelines')
            .where('headlines', isEqualTo: headlinesController.text.trim())
            .where('guidelines', isEqualTo: guidelinesController.text.trim())
            .where('contactus', isEqualTo: contactusController.text.trim())
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          _showSnackBar('Guideline already exists!', Colors.red);
        } else {
          await _firestore.collection('Guidelines').add({
            'headlines': headlinesController.text.trim(),
            'guidelines': guidelinesController.text.trim(),
            'contactus': contactusController.text.trim(),
            'reportedDateTime': FieldValue.serverTimestamp(),
          });

          setState(() {
            headlinesController.clear();
            guidelinesController.clear();
            contactusController.clear();
          });

          _showSnackBar('Guidelines added successfully!', Colors.green);
        }
      } catch (e) {
        print('Error adding data to Firestore: $e');
        _showSnackBar('Failed to add Guidelines. Please try again.', Colors.red);
      } finally {
        setState(() => isLoading = false);
      }
    } else {
      _showSnackBar('All fields must be filled!', Colors.red);
    }
  }

  bool _validateFields() {
    return headlinesController.text.trim().isNotEmpty &&
        guidelinesController.text.trim().isNotEmpty &&
        contactusController.text.trim().isNotEmpty;
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blue.shade900),
      labelStyle: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        centerTitle: true,
        title: const Text(
          "Add Guidelines",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: "Times New Roman",
            letterSpacing: 1.2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade200.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              TextFormField(
                controller: headlinesController,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                decoration: _buildInputDecoration(label: 'Headings', icon: Icons.title),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Headings is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: guidelinesController,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Guidelines is required.';
                  }
                  return null;
                },
                decoration: _buildInputDecoration(label: 'Guidelines', icon: Icons.list_alt),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contactusController,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                maxLines: 2,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required.';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
                decoration: _buildInputDecoration(label: 'Contact Us(Email-Id)', icon: Icons.contact_mail),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _addToFirestore,
                  icon: const Icon(Icons.upload_rounded),
                  label: isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text("Upload Guidelines"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
