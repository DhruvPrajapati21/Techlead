import 'package:flutter/material.dart';

class LackOfProductAtSite extends StatefulWidget {
  const LackOfProductAtSite({super.key});

  @override
  State<LackOfProductAtSite> createState() => _LackOfProductAtSiteState();
}

class _LackOfProductAtSiteState extends State<LackOfProductAtSite> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _requiredQuantityController = TextEditingController();
  final TextEditingController _availableQuantityController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _technicianNameController = TextEditingController();

  void _submitForm() {
    // Your form submission logic here
    print("Form submitted");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 100.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Report Details"),
                  const SizedBox(height: 20),
                  _buildCard(
                    children: [
                      _buildInputField(
                        controller: _productNameController,
                        label: "Product Name",
                        validatorMessage: "Please enter the product name",
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _requiredQuantityController,
                        label: "Required Quantity",
                        keyboardType: TextInputType.number,
                        validatorMessage: "Please enter the required quantity",
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _availableQuantityController,
                        label: "Available Quantity",
                        keyboardType: TextInputType.number,
                        validatorMessage: "Please enter the available quantity",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Additional Information"),
                  const SizedBox(height: 20),
                  _buildCard(
                    children: [
                      _buildInputField(
                        controller: _commentsController,
                        label: "Comments / Notes",
                        hintText: "Add additional information or requirements",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _locationController,
                        label: "Site Location",
                        validatorMessage: "Please enter the site location",
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _contactController,
                        label: "Contact Information",
                        validatorMessage: "Please enter the contact information",
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle("Assign Technician"),
                  const SizedBox(height: 20),
                  _buildCard(
                    children: [
                      _buildInputField(
                        controller: _technicianNameController,
                        label: "Technician Name",
                        validatorMessage: "Please enter the technician's name",
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: _buildGradientButton(
                      text: "Submit",
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _submitForm();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Text(
      "Product Shortage Report",
      style: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: Colors.lightBlueAccent, // Set the text color directly
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.4), // Light shadow for a subtle effect
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }


  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? validatorMessage,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
      maxLines: maxLines,
      validator: (value) {
        if (validatorMessage != null && (value == null || value.isEmpty)) {
          return validatorMessage;
        }
        return null;
      },
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFC5C7D), Color(0xFF6A82FB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}