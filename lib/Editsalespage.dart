import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class EditPage extends StatefulWidget {
  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _additionalDetailsController = TextEditingController();
  final TextEditingController _propertySizeController = TextEditingController();

  bool _isLoading = false;
  String? _preferredContactMethod;
  String? _leadSource;
  String? _leadType;
  String? _propertyType;
  String? _currentHomeAutomation;
  String? _budgetRange;

  bool _touchswitchboard = false;
  bool _rfremos = false;
  bool _digitaldoorlock = false;
  bool _curtainautomation = false;
  bool _hometheatre = false;
  bool _vbusautomation = false;
  bool _gateautomation = false;
  bool _cctv = false;
  bool _videodoorphone = false;
  bool _boombarrier = false;
  bool _others = false;

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (!_touchswitchboard && !_rfremos && !_digitaldoorlock && !_curtainautomation && !_hometheatre &&
          !_vbusautomation && !_gateautomation && !_cctv && !_videodoorphone && !_boombarrier && !_others) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select at least one service'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await Future.delayed(Duration(seconds: 2));
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data updated successfully'), backgroundColor: Colors.green),
        );

        Navigator.pushNamed(context, '/sales');
      } catch (error) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update data'), backgroundColor: Colors.red),
        );
      }
    }
  }


  void _deleteData() async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Confirmation'),
          content: Text('Are you sure you want to delete this data?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Yes'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirm) {
      try {
        await Future.delayed(Duration(seconds: 2));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data deleted successfully'), backgroundColor: Colors.green),
        );

        Navigator.pushNamed(context, '/sales');
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete data'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              buildTextField(
                controller: _fullNameController,
                labelText: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              buildTextField(
                controller: _contactNumberController,
                labelText: 'Contact Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your contact number';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Please enter a valid 10-digit phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              buildTextField(
                controller: _emailController,
                labelText: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              buildDropdownField(
                labelText: 'Preferred Contact Method',
                icon: Icons.contact_phone_outlined,
                value: _preferredContactMethod,
                items: [
                  {'text': 'Phone', 'icon': Icons.phone_android},
                  {'text': 'Email', 'icon': Icons.email},
                  {'text': 'Text', 'icon': Icons.message},
                  {'text': 'WhatsApp', 'icon': FontAwesomeIcons.whatsapp},
                ],
                onChanged: (value) {
                  setState(() {
                    _preferredContactMethod = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a preferred contact method';
                  }
                  return null;
                },
              ),
              // Add more TextField and DropdownField widgets as required...

              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blue.shade900),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget buildDropdownField({
    required String labelText,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required void Function(String?)? onChanged,
    required String? Function(String?) validator,
    String? value,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blue.shade900),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      value: value,
      items: items
          .map((item) => DropdownMenuItem<String>(
        value: item['text'],
        child: Row(
          children: [
            Icon(item['icon'], color: Colors.blue.shade900),
            SizedBox(width: 10),
            Text(item['text']),
          ],
        ),
      ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
