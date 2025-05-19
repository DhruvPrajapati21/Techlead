import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HomeAutomationSystem extends StatefulWidget {
  @override
  _HomeAutomationSystemState createState() => _HomeAutomationSystemState();
}

class _HomeAutomationSystemState extends State<HomeAutomationSystem> {
  final _formKey = GlobalKey<FormState>();
  String? customerName;
  String? customerEmail;
  String? customerPhone;
  String? customerAddress;
  String? productSelected;
  String? roomToAutomate;
  DateTime? installationDate;
  String? status = 'Pending';
  TextEditingController notesController = TextEditingController();
  TextEditingController dateController = TextEditingController();

  List<String> products = ['Smart Lights', 'Smart Thermostat', 'Security Cameras', 'Voice Assistant'];
  List<String> rooms = ['Living Room', 'Bedroom', 'Kitchen', 'Bathroom', 'Hallway'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Automation Installation'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Customer Information', theme),
                _buildTextField('Full Name', Icons.person, (value) => customerName = value),
                _buildTextField('Email', Icons.email, (value) => customerEmail = value),
                _buildTextField('Phone Number', Icons.phone, (value) => customerPhone = (double.tryParse(value!) ?? 0.0) as String?,
                  isNumeric: true,),
                _buildTextField('Address', Icons.home, (value) => customerAddress = value),

                SizedBox(height: 20),
                _buildSectionHeader('Product Selection', theme),
                _buildDropdown('Select Product', products, Icons.lightbulb, (value) => productSelected = value),
                _buildDropdown('Select Room to Automate', rooms, Icons.room, (value) => roomToAutomate = value),

                SizedBox(height: 20),
                _buildSectionHeader('Installation Details', theme),
                _buildDatePicker('Select Installation Date', Icons.calendar_today, (value) => installationDate = value),

                SizedBox(height: 20),
                _buildDropdown('Installation Status', ['Pending', 'In Progress', 'Completed'], Icons.assignment, (value) => status = value),


                SizedBox(height: 20),
                _buildSectionHeader('Notes/Comments', theme),
                _buildNotesField(),

                SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.teal,
                    ),
                    icon: Icon(Icons.send,color: Colors.white,),
                    label: Text('Submit', style: TextStyle(fontSize: 16,color: Colors.white,fontFamily: "roboto",fontWeight: FontWeight.bold)),
                    onPressed: _submitForm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String?)? onChanged, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.teal.shade50,
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text, // Numeric keyboard if specified
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] // Allow numbers and decimals
            : null,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label cannot be empty';
          }
          return null;
        },
      ),
    );
  }


  Widget _buildDropdown(String label, List<String> items, IconData icon, Function(String?)? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.teal.shade50,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(String label, IconData icon, Function(DateTime?)? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            setState(() {
              installationDate = pickedDate;
              // Format the date as "DD MMM YYYY"
              dateController.text = DateFormat('dd MMM yyyy').format(pickedDate);
            });
            onChanged?.call(pickedDate);
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: dateController,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.teal.shade50,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '$label cannot be empty';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: notesController,
      decoration: InputDecoration(
        hintText: 'Add any relevant notes or comments...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.teal.shade50,
        contentPadding: EdgeInsets.all(12),
      ),
      maxLines: 5,
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: Colors.teal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form Submitted Successfully')),
      );
      _formKey.currentState?.reset();
      notesController.clear();
      dateController.clear();
    }
  }
}
