import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Showinstallationdata extends StatefulWidget {
  @override
  _ShowinstallationdataState createState() => _ShowinstallationdataState();
}

class _ShowinstallationdataState extends State<Showinstallationdata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Colors.white),// Make the default background transparent
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
              "Installation Summary",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
                  labelText: 'Search by Technician...',
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'Enter Technician full name',
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
              stream: _firestore.collection('Installation').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No Installation info available',
                      style: TextStyle(fontFamily: 'Times New Roman'),
                    ),
                  );
                }
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final fullName = doc['technician_name']?.toString()?.toLowerCase() ?? '';
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
                          final delete = await _showDeleteConfirmationDialog();
                          return delete == true;
                        },
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent,
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
                              SizedBox(height: 10,),
                              buildFormField('Technician Name: ', doc['technician_name']),
                              buildFormField('Installation Site:', doc['installation_site']),
                              buildFormField('Installation Date:', doc['installation_date']),
                              buildFormField('Service Time: ', doc['service_time']),
                              buildFormField('Automation Product: ', doc['selected_product']),
                              buildFormField('Service Status: ', doc['service_status']),
                              buildFormField('Customer Name: ', doc['customer_name']),
                              buildFormField('Customer Contact: ', doc['customer_contact']),
                              buildFormField('Service Description: ', doc['service_description']),
                              buildFormField('Remarks: ', doc['remarks']),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    child: FloatingActionButton(
                                      onPressed: (){
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => Editinstallationpage(
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
      await _firestore.collection('Installation').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Installation Record deleted successfully'),
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
class Editinstallationpage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  Editinstallationpage({required this.docId, required this.initialData});

  @override
  _EditinstallationpageState createState() => _EditinstallationpageState();
}



class _EditinstallationpageState extends State<Editinstallationpage> {
  final _formKey = GlobalKey<FormState>();
  late String fullName, contactNumber, email, preferredContactMethod,remarks, leadSource, leadType,taskstatus,meetingcstatus, propertyType, propertySize, currentHomeAutomation, budgetRange, additionalDetails;


  List<String> serviceStatuses = ["Pending", "In Progress", "Completed"];
  final Map<String, IconData> products = {
    'Smart Lights': FontAwesomeIcons.lightbulb,
    'Smart Thermostat': FontAwesomeIcons.thermometerHalf,
    'Security Cameras': FontAwesomeIcons.video,
    'Smart Plugs': FontAwesomeIcons.plug,
    'Smart Door Locks': FontAwesomeIcons.lock,
    'Smart Smoke Detectors': FontAwesomeIcons.cloud,
    'Smart Speakers': FontAwesomeIcons.volumeUp,
    'Smart Blinds': FontAwesomeIcons.windowMaximize,
    'Home Security Systems': FontAwesomeIcons.shieldAlt,
    'Smart Doorbells': FontAwesomeIcons.bell,
    'Motion Sensors': FontAwesomeIcons.walking,
    'Smart Cameras': FontAwesomeIcons.camera,
    'Smart Switches': FontAwesomeIcons.toggleOn,
    'Smart Air Purifiers': FontAwesomeIcons.wind,
    'Smart Fans': FontAwesomeIcons.fan,
    'Smart Heaters': FontAwesomeIcons.fire,
    'Smart Humidifiers': FontAwesomeIcons.cloudRain,
    'Smart Radiators': FontAwesomeIcons.radiation,
    'Smart Refrigerators': FontAwesomeIcons.iceCream,
    'Smart Ovens': FontAwesomeIcons.breadSlice,
    'Smart Washing \n Machines': FontAwesomeIcons.soap,
    'Smart Dishwashers': FontAwesomeIcons.handsWash,
    'Smart Coffee Makers': FontAwesomeIcons.mugHot,
    'Smart Projectors': FontAwesomeIcons.projectDiagram,
    'Streaming Devices': FontAwesomeIcons.stream,
    'Smart Remotes': FontAwesomeIcons.contao,
    'Smart Hubs': FontAwesomeIcons.networkWired,
    'Smart Meters': FontAwesomeIcons.tachometerAlt,
    'Solar Energy Systems': FontAwesomeIcons.solarPanel,
    'Smart Batteries': FontAwesomeIcons.batteryFull,
    'Smart Chargers': FontAwesomeIcons.chargingStation,
    'Smart Curtains': FontAwesomeIcons.windowRestore,
    'Robotic Vacuums': FontAwesomeIcons.robot,
    'Smart Window Openers': FontAwesomeIcons.windowMaximize,
    'Smart Home \n Automation Hubs': FontAwesomeIcons.home,
    'Smart Security Systems': FontAwesomeIcons.shieldVirus,
    'Smart Light Panels': FontAwesomeIcons.lightbulb,
    'LED Strips': FontAwesomeIcons.ribbon,
    'Smart Home Assistants': FontAwesomeIcons.headset,
    'Voice Assistants': FontAwesomeIcons.microphone,
    'Automated Home \n Theater Systems': FontAwesomeIcons.tv,
    'Automated Shades': FontAwesomeIcons.accusoft,
    'Automatic \n Watering Systems': FontAwesomeIcons.water,
    'Smart Smoke Alarms': FontAwesomeIcons.bell,
    'Smart Leak Detectors': FontAwesomeIcons.water,
    'Smart Water Heaters': FontAwesomeIcons.fire,
    'Smart Air Conditioners': FontAwesomeIcons.snowflake,
    'Smart Vacuum Cleaners': FontAwesomeIcons.robot,
    'Smart Bed Frames': FontAwesomeIcons.bed,
    'Home Automation \n Controller Systems': FontAwesomeIcons.server,
  };


  @override
  void initState() {
    super.initState();
    fullName = widget.initialData['technician_name'] ?? '';
    contactNumber = widget.initialData['installation_site'] ?? '';
    email = widget.initialData['installation_date'] ?? '';
    preferredContactMethod = widget.initialData['service_time'] ?? '';
    leadSource = widget.initialData['selected_product'] ?? products[0];
    serviceStatuses = widget.initialData['service_status'] ?? serviceStatuses[0];
    additionalDetails = widget.initialData['customer_name'] ?? '';
    taskstatus = widget.initialData['customer_contact'] ?? '';
    meetingcstatus = widget.initialData['service_description'] ?? '';
    remarks = widget.initialData['remarks'] ?? '';
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
              "Edit Installation Page",
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
                          buildTextFormField('Technician Name', fullName, Icons.person, (value) => fullName = value),
                          buildTextFormField('Installation Site', contactNumber, Icons.phone, (value) => contactNumber = value),
                          buildTextFormField('Installation Date', email, Icons.email, (value) => email = value),
                          buildTextFormField('Service Time', preferredContactMethod, FontAwesomeIcons.digitalOcean, (value) => preferredContactMethod = value),
                          buildDropdownField('Home Automation Product', leadSource, FontAwesomeIcons.user, products as List<Map<String, dynamic>>, (newValue) => setState(() => leadSource = newValue!)),
                          buildTextFormField('Service Status', serviceStatuses as String, Icons.email, (value) => propertySize = value),
                          buildTextFormField('Customer Name', additionalDetails, Icons.details, (value) => additionalDetails = value),
                          buildTextFormField('Customer Contact', taskstatus, Icons.details, (value) => taskstatus = value),
                          buildTextFormField('Service Description', meetingcstatus, Icons.details, (value) => meetingcstatus = value),
                          buildTextFormField('Remarks', remarks, Icons.details, (value) => remarks = value),
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

  void _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('Installation').doc(widget.docId).update({
          'technician_name': fullName,
          'installation_site': contactNumber,
          'installation_date': email,
          'service_time': preferredContactMethod,
          'selected_product': leadSource,
          'service_status': serviceStatuses,
          'customer_name': additionalDetails,
          'customer_contact': taskstatus,
          'service_description': meetingcstatus,
          'remarks': remarks,
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Installation Record updated successfully'),
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