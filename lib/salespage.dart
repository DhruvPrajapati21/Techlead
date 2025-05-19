import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _additionalDetailsController = TextEditingController();
  final TextEditingController _propertySizeController = TextEditingController();

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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sales Lead Form',style: TextStyle(fontWeight: FontWeight.bold,fontFamily: "Times New Roman"),),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Card(
            elevation: 20,
            shadowColor: Colors.cyan.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    SizedBox(height: 15),
                    buildDropdownField(
                      labelText: 'Lead Source',
                      icon: Icons.source_outlined,
                      value: _leadSource,
                      items: [
                        {'text': 'Website', 'icon': FontAwesomeIcons.globe},
                        {'text': 'Social Media', 'icon': FontAwesomeIcons.instagram},
                        {'text': 'Personal Reference', 'icon': FontAwesomeIcons.userFriends},
                        {'text': 'Advertisement', 'icon': FontAwesomeIcons.ad},
                        {'text': 'Event', 'icon': FontAwesomeIcons.calendarAlt},
                        {'text': 'Indiamart', 'icon': FontAwesomeIcons.shoppingCart},
                        {'text': 'Facebook', 'icon': FontAwesomeIcons.facebook},
                        {'text': 'Architect Interior', 'icon': FontAwesomeIcons.building},
                        {'text': 'Builder', 'icon': FontAwesomeIcons.hammer},
                        {'text': 'Walkthrough', 'icon': FontAwesomeIcons.walking},
                        {'text': 'Electrician', 'icon': FontAwesomeIcons.lightbulb},
                        {'text': 'Dealer', 'icon': FontAwesomeIcons.store},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _leadSource = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a lead source';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      labelText: 'Lead Type',
                      icon: FontAwesomeIcons.userTag,
                      value: _leadType,
                      items: [
                        {'text': 'New Inquiry', 'icon': FontAwesomeIcons.userPlus},
                        {'text': 'Returning Customer', 'icon': FontAwesomeIcons.recycle},
                        {'text': 'Referral', 'icon': FontAwesomeIcons.peopleArrows},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _leadType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a lead type';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services Interested In:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.deepPurple,
                          ),
                        ),
                        buildCustomCheckboxTile(
                          title: 'Touch Switchboard',
                          value: _touchswitchboard,
                          onChanged: (value) {
                            setState(() {
                              _touchswitchboard = value ?? false;
                            });
                          },
                          icon: Icons.lightbulb,
                          color: Colors.amber,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Rf Remos',
                          value: _rfremos,
                          onChanged: (value) {
                            setState(() {
                              _rfremos = value ?? false;
                            });
                          },
                          icon: Icons.settings_remote_rounded,
                          color: Colors.blue,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Digital Door Lock',
                          value: _digitaldoorlock,
                          onChanged: (value) {
                            setState(() {
                              _digitaldoorlock = value ?? false;
                            });
                          },
                          icon: Icons.door_back_door_rounded,
                          color: Colors.red,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Curtain Automation',
                          value: _curtainautomation,
                          onChanged: (value) {
                            setState(() {
                              _curtainautomation = value ?? false;
                            });
                          },
                          icon: Icons.curtains_closed,
                          color: Colors.purple,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Home Theatre',
                          value: _hometheatre,
                          onChanged: (value) {
                            setState(() {
                              _hometheatre = value ?? false;
                            });
                          },
                          icon: FontAwesomeIcons.tv,
                          color: Colors.green,
                        ),
                        buildCustomCheckboxTile(
                          title: 'V Bus Automation',
                          value: _vbusautomation,
                          onChanged: (value) {
                            setState(() {
                              _vbusautomation = value ?? false;
                            });
                          },
                          icon: Icons.tv,
                          color: Colors.purple,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Gate Automation',
                          value: _gateautomation,
                          onChanged: (value) {
                            setState(() {
                              _gateautomation = value ?? false;
                            });
                          },
                          icon: Icons.door_back_door_sharp,
                          color: Colors.purple,
                        ),
                        buildCustomCheckboxTile(
                          title: 'CCTV',
                          value: _cctv,
                          onChanged: (value) {
                            setState(() {
                              _cctv = value ?? false;
                            });
                          },
                          icon: Icons.video_camera_back_sharp,
                          color: Colors.purple,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Video Door Phone',
                          value: _videodoorphone,
                          onChanged: (value) {
                            setState(() {
                              _videodoorphone = value ?? false;
                            });
                          },
                          icon: Icons.phone_android,
                          color: Colors.purple,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Boom Barrier',
                          value: _boombarrier,
                          onChanged: (value) {
                            setState(() {
                              _boombarrier = value ?? false;
                            });
                          },
                          icon: Icons.desk_sharp,
                          color: Colors.purple,
                        ),
                        buildCustomCheckboxTile(
                          title: 'Others',
                          value: _others,
                          onChanged: (value) {
                            setState(() {
                              _others = value ?? false;
                            });
                          },
                          icon: Icons.devices_other_outlined,
                          color: Colors.purple,
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    buildTextField(
                      controller: _additionalDetailsController,
                      labelText: 'Additional Details',
                      icon: FontAwesomeIcons.infoCircle,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide additional details';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      labelText: 'Type of Property',
                      icon: FontAwesomeIcons.building,
                      value: _propertyType,
                      items: [
                        {'text': 'Apartment', 'icon': FontAwesomeIcons.city},
                        {'text': 'House', 'icon': FontAwesomeIcons.home},
                        {'text': 'Office', 'icon': FontAwesomeIcons.building},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _propertyType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a type of property';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildTextField(
                      controller: _propertySizeController,
                      labelText: 'Size of Property (sq ft)',
                      icon: FontAwesomeIcons.ruler,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the size of the property';
                        }
                        if (!RegExp(r'^\d+$').hasMatch(value)) {
                          return 'Please enter a valid size in square feet';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      labelText: 'Current Home Automation Setup',
                      icon: FontAwesomeIcons.robot,
                      value: _currentHomeAutomation,
                      items: [
                        {'text': 'None', 'icon': FontAwesomeIcons.timesCircle},
                        {'text': 'Partial', 'icon': FontAwesomeIcons.expand},
                        {'text': 'Fully Automated', 'icon': FontAwesomeIcons.robot},
                        {'text': 'Interested in Upgrading', 'icon': FontAwesomeIcons.arrowUp},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _currentHomeAutomation = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a current home automation setup';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    buildDropdownField(
                      labelText: 'Budget Range',
                      icon: FontAwesomeIcons.moneyBillWave,
                      value: _budgetRange,
                      items: [
                        {'text': 'Below \$1,000', 'icon': FontAwesomeIcons.dollarSign},
                        {'text': '\$1,000 - \$5,000', 'icon': FontAwesomeIcons.dollarSign},
                        {'text': 'Above \$5,000', 'icon': FontAwesomeIcons.dollarSign},
                      ],
                      onChanged: (value) {
                        setState(() {
                          _budgetRange = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a budget range';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue,shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
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
      textInputAction: TextInputAction.next,
      onEditingComplete: () =>
          FocusScope.of(context).nextFocus(),
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

  Widget buildCustomCheckboxTile({
    required String title,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required IconData icon,
    required Color color,
  }) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: color),
    );
  }

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

      Map<String, dynamic> formData = {
        'fullName': _fullNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(),
        'preferredContactMethod': _preferredContactMethod,
        'leadSource': _leadSource,
        'leadType': _leadType,
        'propertyType': _propertyType,
        'propertySize': _propertySizeController.text.trim(),
        'currentHomeAutomation': _currentHomeAutomation,
        'budgetRange': _budgetRange,
        'additionalDetails': _additionalDetailsController.text.trim(),
        'servicesInterestedIn': {
          'Touch Switchboard': _touchswitchboard,
          'Rf Remos': _rfremos,
          'Digital Door Lock': _digitaldoorlock,
          'Curtain Automation': _curtainautomation,
          'Home Theatre': _hometheatre,
          'V Bus Automation': _vbusautomation,
          'Gate Automation': _gateautomation,
          'CCTV': _cctv,
          'Video Door Phone': _videodoorphone,
          'Boom Barrier': _boombarrier,
          'Others': _others,
        },
      };

      try {
        await _firestore.collection('Salesinfo').add(formData);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form submitted successfully!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
        _resetForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _fullNameController.clear();
    _contactNumberController.clear();
    _emailController.clear();
    _additionalDetailsController.clear();
    _propertySizeController.clear();
    setState(() {
      _preferredContactMethod = null;
      _leadSource = null;
      _leadType = null;
      _propertyType = null;
      _currentHomeAutomation = null;
      _budgetRange = null;
      _touchswitchboard = false;
      _rfremos = false;
      _digitaldoorlock = false;
      _curtainautomation = false;
      _hometheatre = false;
      _vbusautomation = false;
      _gateautomation = false;
      _cctv = false;
      _videodoorphone = false;
      _boombarrier = false;
      _others = false;
    });
  }
}