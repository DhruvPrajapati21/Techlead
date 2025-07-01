import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Editinstallationpage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  Editinstallationpage({required this.docId, required this.initialData});

  @override
  _EditinstallationpageState createState() => _EditinstallationpageState();
}

class _EditinstallationpageState extends State<Editinstallationpage> {
  final _formKey = GlobalKey<FormState>();
  late String fullName,
      contactNumber,
      email,
      preferredContactMethod,
      remarks,
      leadSource,
      leadType,
      taskstatus,
      meetingcstatus,
      propertyType,
      propertySize,
      currentHomeAutomation,
      budgetRange,
      additionalDetails;

  List<String> serviceStatusOptions = ["Pending", "In Progress", "Completed"];
  late String selectedServiceStatus;

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
    leadSource = widget.initialData['selected_product'] ?? products.keys.first;
    selectedServiceStatus = widget.initialData['service_status'] ?? 'Pending';
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
              colors: [
                Color(0xFF0A2A5A), // Deep navy blue
                Color(0xFF15489C), // Strong steel blue
                Color(0xFF1E64D8), // Vivid rich blue
              ],
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
                colors: [
                  Color(0xFF0A2A5A), // Deep navy blue
                  Color(0xFF15489C), // Strong steel blue
                  Color(0xFF1E64D8), // Vivid rich blue
                ],
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

                          buildTextFormField('Technician Name', fullName,
                              Icons.person, (value) => fullName = value),

                          buildTextFormField('Installation Site', contactNumber,
                              Icons.phone, (value) => contactNumber = value),

                          buildTextFormField('Installation Date', email,
                              Icons.email, (value) => email = value),

                          buildTextFormField(
                              'Service Time',
                              preferredContactMethod,
                              FontAwesomeIcons.digitalOcean,
                                  (value) => preferredContactMethod = value),

                          buildDropdownField(
                            'Home Automation Product',
                            leadSource,
                            FontAwesomeIcons.user,
                            products.entries
                                .map((entry) => {'text': entry.key, 'icon': entry.value})
                                .toList(),
                                (newValue) => setState(() => leadSource = newValue!),
                          ),

                          buildDropdownField(
                              'Service Status',
                              selectedServiceStatus,
                              Icons.info,
                              serviceStatusOptions
                                  .map((status) =>
                              {'text': status, 'icon': Icons.info})
                                  .toList(),
                                  (newValue) => setState(
                                      () => selectedServiceStatus = newValue!)),

                          buildTextFormField(
                              'Customer Name',
                              additionalDetails,
                              Icons.details,
                                  (value) => additionalDetails = value),

                          buildTextFormField('Customer Contact', taskstatus,
                              Icons.details, (value) => taskstatus = value),

                          buildTextFormField(
                              'Service Description',
                              meetingcstatus,
                              Icons.details,
                                  (value) => meetingcstatus = value),

                          buildTextFormField('Remarks', remarks, Icons.details,
                                  (value) => remarks = value),

                          SizedBox(height: 20),

                          Container(

                            child: ElevatedButton(
                              onPressed: _updateRecord,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                backgroundColor: Color(0xFF0A2A5A),
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Update',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
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
    );
  }

  // Dropdown field with icons
  Widget buildDropdownField(
      String label,
      String value,
      IconData icon,
      List<Map<String, dynamic>> items,
      ValueChanged<String?> onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: items.any((item) => item['text'] == value) ? value : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.cyanAccent),
              filled: true,
              fillColor: Color(0xFF0A2A5A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: onChanged,
            dropdownColor: const Color(0xFF0A2A5A),
            items: items.map<DropdownMenuItem<String>>((Map<String, dynamic> item) {
              return DropdownMenuItem<String>(
                value: item['text'],
                child: Row(
                  children: [
                    Icon(item['icon'], color: Colors.cyanAccent),
                    SizedBox(width: 10),
                    Text(
                      item['text'],
                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  // Text form field
  Widget buildTextFormField(
      String label,
      String initialValue,
      IconData icon,
      Function(String) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          SizedBox(height: 6),
          TextFormField(
            initialValue: initialValue,
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.cyanAccent),
              filled: true,
              fillColor: Color(0xFF0A2A5A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }


  void _updateRecord() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('Installation')
            .doc(widget.docId)
            .update({
          'technician_name': fullName,
          'installation_site': contactNumber,
          'installation_date': email,
          'service_time': preferredContactMethod,
          'selected_product': leadSource,
          'service_status': selectedServiceStatus,

          'customer_name': additionalDetails,
          'customer_contact': taskstatus,
          'service_description': meetingcstatus,
          'remarks': remarks,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 6,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent, // Needed for gradient to show
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A2A5A), Color(0xFF1F4788)], // dark bluish gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Installation Record updated successfully',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );

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
