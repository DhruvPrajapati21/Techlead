import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesInfoPage extends StatefulWidget {
  @override
  _SalesInfoPageState createState() => _SalesInfoPageState();
}

class _SalesInfoPageState extends State<SalesInfoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent, // Make the default background transparent
        elevation: 0, // Remove the default shadow
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.info,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Sales Summary",
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
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search by name...',
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Enter full name',
                  hintStyle: TextStyle(
                    color: Colors.cyan.shade300,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(Icons.search, color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('Salesinfo').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No sales info available',
                      style: TextStyle(fontFamily: 'Times New Roman'),
                    ),
                  );
                }
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final fullName = doc['fullName']?.toString()?.toLowerCase() ?? '';
                  return fullName.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          // Show the delete confirmation dialog when user swipes
                          final delete = await _showDeleteConfirmationDialog();
                          return delete == true; // Return true if confirmed, false if canceled
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent, // background for swipe-to-delete
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 20.0),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade900, Colors.blue.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade900.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildFormField('Full Name: ', doc['fullName']),
                              buildFormField('Contact Number:', doc['contactNumber']),
                              buildFormField('Email Address: ', doc['email']),
                              buildFormField('Preferred Contact Method: ', doc['preferredContactMethod']),
                              buildFormField('Lead Source: ', doc['leadSource']),
                              buildFormField('Lead Type: ', doc['leadType']),
                              buildFormField('Type of Property: ', doc['propertyType']),
                              buildFormField('Property Size: ', doc['propertySize']),
                              buildFormField('Current Home Automation Setup: ', doc['currentHomeAutomation']),
                              buildFormField('Budget Range: ', doc['budgetRange']),
                              buildFormField('Additional Details: ', doc['additionalDetails']),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    child: FloatingActionButton(
                                      onPressed: (){
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => EditSalesInfoPage(
                                            docId: doc.id,
                                            initialData: doc.data() as Map<String, dynamic>,
                                          ),
                                        ));
                                      },
                                      backgroundColor: Colors.cyan,

                                      child: const Icon(Icons.edit, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),

                            ],
                          ),
                        ),
                      ),

                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFormField(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.white,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(15.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete Confirmation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Are you sure you want to delete this record?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.cyan.shade100, // Cyan accent for the content text
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.cyanAccent.shade200,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _deleteRecord(String docId) async {
    try {
      await _firestore.collection('Salesinfo').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sales Record deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting record: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
class EditSalesInfoPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  EditSalesInfoPage({required this.docId, required this.initialData});

  @override
  _EditSalesInfoPageState createState() => _EditSalesInfoPageState();
}



class _EditSalesInfoPageState extends State<EditSalesInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late String fullName, contactNumber, email, preferredContactMethod, leadSource, leadType, propertyType, propertySize, currentHomeAutomation, budgetRange, additionalDetails;

  // List of lead sources with text and icons
  final List<Map<String, dynamic>> leadSources = [
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
  ];

  // List of lead types with text and icons
  final List<Map<String, dynamic>> leadTypes = [
    {'text': 'New Inquiry', 'icon': FontAwesomeIcons.userPlus},
    {'text': 'Returning Customer', 'icon': FontAwesomeIcons.recycle},
    {'text': 'Referral', 'icon': FontAwesomeIcons.peopleArrows},
  ];

  // List of property types with text and icons
  final List<Map<String, dynamic>> propertyTypes = [
    {'text': 'Apartment', 'icon': FontAwesomeIcons.city},
    {'text': 'House', 'icon': FontAwesomeIcons.home},
    {'text': 'Office', 'icon': FontAwesomeIcons.building},
  ];

  // List of current home automation options with text and icons
  final List<Map<String, dynamic>> homeAutomationOptions = [
    {'text': 'None', 'icon': FontAwesomeIcons.timesCircle},
    {'text': 'Partial', 'icon': FontAwesomeIcons.expand},
    {'text': 'Fully Automated', 'icon': FontAwesomeIcons.robot},
    {'text': 'Interested in Upgrading', 'icon': FontAwesomeIcons.arrowUp},
  ];

  // List of budget range options with text and icons
  final List<Map<String, dynamic>> budgetRanges = [
    {'text': 'Below 1 Lac', 'icon': FontAwesomeIcons.wallet},
    {'text': '1 Lac to 5 Lac', 'icon': FontAwesomeIcons.wallet},
    {'text': '5 Lac to 10 Lac', 'icon': FontAwesomeIcons.wallet},
    {'text': 'Above 10 Lac', 'icon': FontAwesomeIcons.wallet},
  ];

  @override
  void initState() {
    super.initState();
    fullName = widget.initialData['fullName'] ?? '';
    contactNumber = widget.initialData['contactNumber'] ?? '';
    email = widget.initialData['email'] ?? '';
    preferredContactMethod = widget.initialData['preferredContactMethod'] ?? 'Email'; // Assuming default value
    leadSource = widget.initialData['leadSource'] ?? leadSources[0]['text']; // Set default to the first option
    leadType = widget.initialData['leadType'] ?? leadTypes[0]['text']; // Set default to the first option
    propertyType = widget.initialData['propertyType'] ?? propertyTypes[0]['text']; // Set default to the first option
    propertySize = widget.initialData['propertySize'] ?? '';
    currentHomeAutomation = widget.initialData['currentHomeAutomation'] ?? homeAutomationOptions[0]['text']; // Set default to the first option
    budgetRange = widget.initialData['budgetRange'] ?? budgetRanges[0]['text']; // Set default to the first option
    additionalDetails = widget.initialData['additionalDetails'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.penNib,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Text(
              "Edit Sales Page",
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
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 8,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade900, Colors.indigo.shade700],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 100),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          buildTextFormField('Full Name', fullName, Icons.person, (value) => fullName = value),
                          buildTextFormField('Contact Number', contactNumber, Icons.phone, (value) => contactNumber = value),
                          buildTextFormField('Email', email, Icons.email, (value) => email = value),
                          buildDropdownField('Lead Source', leadSource, FontAwesomeIcons.digitalOcean, leadSources, (newValue) => setState(() => leadSource = newValue!)),
                          buildDropdownField('Lead Type', leadType, FontAwesomeIcons.user, leadTypes, (newValue) => setState(() => leadType = newValue!)),
                          buildDropdownField('Type of Property', propertyType, FontAwesomeIcons.home, propertyTypes, (newValue) => setState(() => propertyType = newValue!)),
                          buildTextFormField('Property Size', propertySize, Icons.square_foot, (value) => propertySize = value),
                          buildDropdownField('Current Home Automation', currentHomeAutomation, FontAwesomeIcons.cogs, homeAutomationOptions, (newValue) => setState(() => currentHomeAutomation = newValue!)),
                          buildDropdownField('Budget Range', budgetRange, FontAwesomeIcons.wallet, budgetRanges, (newValue) => setState(() => budgetRange = newValue!)),
                          buildTextFormField('Additional Details', additionalDetails, Icons.details, (value) => additionalDetails = value),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _updateRecord,
                            child: Text(
                              'Update',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateRecord,
        backgroundColor: Colors.blue.shade900,
        child: Icon(Icons.save, size: 30, color: Colors.white),
      ),
    );
  }

  // Dropdown field with icons
  Widget buildDropdownField(String label, String value, IconData icon, List<Map<String, dynamic>> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: items.any((item) => item['text'] == value) ? value : null, // Ensure the value exists in the items list
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
        items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
          return DropdownMenuItem<String>(
            value: item['text'], // Use the 'text' as the value
            child: Row(
              children: [
                Icon(item['icon'], color: Colors.deepPurple),
                SizedBox(width: 10),
                Text(item['text'], style: GoogleFonts.poppins(fontSize: 16)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  // Text form field
  Widget buildTextFormField(String label, String initialValue, IconData icon, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        style: GoogleFonts.poppins(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: onChanged,
      ),
    );
  }

  // Update the record in Firestore
  void _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Salesinfo').doc(widget.docId).update({
          'fullName': fullName,
          'contactNumber': contactNumber,
          'email': email,
          'preferredContactMethod': preferredContactMethod,
          'leadSource': leadSource,
          'leadType': leadType,
          'propertyType': propertyType,
          'propertySize': propertySize,
          'currentHomeAutomation': currentHomeAutomation,
          'budgetRange': budgetRange,
          'additionalDetails': additionalDetails,
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Record updated successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error updating record: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }
}