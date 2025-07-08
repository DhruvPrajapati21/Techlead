import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../Employee/Homescreen/Date_And_Time_Code/Customize_Date_001.dart';
import '../../../Employee/Homescreen/Date_And_Time_Code/Customize_Time_001.dart';

class Editinstallationpage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  Editinstallationpage({required this.docId, required this.initialData});

  @override
  _EditinstallationpageState createState() => _EditinstallationpageState();
}

class _EditinstallationpageState extends State<Editinstallationpage> {
  final _formKey = GlobalKey<FormState>();
  FocusNode dropdownFocus = FocusNode();
  FocusNode nextFieldFocus = FocusNode();
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


  late TextEditingController _dateController;
  late TextEditingController _timeController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;


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

    _selectedDate = email.isNotEmpty
        ? DateTime.tryParse(email) ?? DateTime.now()
        : DateTime.now();

    _selectedTime = preferredContactMethod.isNotEmpty
        ? TimeOfDay(
        hour: int.tryParse(preferredContactMethod.split(':')[0]) ?? 0,
        minute: int.tryParse(preferredContactMethod.split(':')[1]) ?? 0)
        : TimeOfDay.now();

    _dateController = TextEditingController();
    _timeController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _dateController.text = DateFormat('dd MMMM yyyy').format(_selectedDate);
    _timeController.text = _selectedTime.format(context);
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
                fontSize: 16,
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

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Installation Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () =>
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            buildGradientCalendar(
                                              context,
                                              _selectedDate,
                                                  (pickedDate) {
                                                setState(() {
                                                  _selectedDate = pickedDate;
                                                  email = pickedDate
                                                      .toIso8601String(); // Save for Firestore
                                                  _dateController.text =
                                                      DateFormat('dd MMMM yyyy')
                                                          .format(
                                                          pickedDate); // Display format
                                                });
                                              },
                                            ),
                                      ),
                                  child: AbsorbPointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF000F89),
                                            Color(0xFF0F52BA),
                                            Color(0xFF002147),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white),
                                      ),
                                      child: TextFormField(
                                        controller: _dateController,
                                        style: GoogleFonts.poppins(
                                            fontSize: 16, color: Colors.white),
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.calendar_today,
                                              color: Colors.cyanAccent),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Service Time',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () =>
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            buildGradientTimePicker(
                                              context,
                                              _selectedTime,
                                                  (pickedTime) {
                                                setState(() {
                                                  _selectedTime = pickedTime;
                                                  preferredContactMethod =
                                                  "${pickedTime
                                                      .hour}:${pickedTime
                                                      .minute}";
                                                  _timeController.text =
                                                      pickedTime.format(
                                                          context);
                                                });
                                              },
                                            ),
                                      ),
                                  child: AbsorbPointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF000F89),
                                            Color(0xFF0F52BA),
                                            Color(0xFF002147),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white),
                                      ),
                                      child: TextFormField(
                                        controller: _timeController,
                                        style: GoogleFonts.poppins(
                                            fontSize: 16, color: Colors.white),
                                        decoration: const InputDecoration(
                                          prefixIcon: Icon(Icons.access_time,
                                              color: Colors.cyanAccent),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          buildDropdownField(
                            'Home Automation Product',
                            leadSource,
                            FontAwesomeIcons.user,
                            products.entries
                                .map((entry) =>
                            {
                              'text': entry.key,
                              'icon': entry.value
                            })
                                .toList(),
                                (newValue) =>
                                setState(() => leadSource = newValue!),
                            currentFocus: dropdownFocus,
                            nextFocus: nextFieldFocus,
                          ),

                          buildDropdownField(
                              'Service Status',
                              selectedServiceStatus,
                              Icons.info,
                              serviceStatusOptions
                                  .map((status) =>
                              {'text': status, 'icon': Icons.info})
                                  .toList(),
                                  (newValue) =>
                                  setState(
                                          () =>
                                      selectedServiceStatus = newValue!),
                            currentFocus: dropdownFocus,
                            nextFocus: nextFieldFocus,
                          ),

                          buildTextFormField(
                              'Customer Name',
                              additionalDetails,
                              Icons.details,
                                  (value) => additionalDetails = value),

                          buildTextFormField(
                            'Customer Contact',
                            taskstatus,
                            Icons.details,
                                (val) => taskstatus = val,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Please enter contact number';
                              if (!RegExp(r'^\d{10}$').hasMatch(value))
                                return 'Contact number must be exactly 10 digits';
                              return null;
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              // ⬅ Limits max length
                              FilteringTextInputFormatter.digitsOnly,
                              // ⬅ Allows only digits
                            ],
                          ),


                          buildTextFormField(
                              'Service Description',
                              meetingcstatus,
                              Icons.details,
                                  (value) => meetingcstatus = value),

                          buildTextFormField('Remarks', remarks, Icons.details,
                                  (value) => remarks = value),

                          SizedBox(height: 20),

                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF000F89), // Royal Blue
                                  Color(0xFF0F52BA), // Cobalt Blue
                                  Color(0xFF002147), // Navy Blue
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                child: ElevatedButton(
                                  onPressed: _updateRecord,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 12),
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
      ValueChanged<String?> onChanged, {
        String? Function(String?)? validator,
        required FocusNode currentFocus,
        FocusNode? nextFocus,
      }) {
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
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF000F89),
                  Color(0xFF0F52BA),
                  Color(0xFF002147),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Focus(
              focusNode: currentFocus,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: items.any((item) => item['text'] == value) ? value : null,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.arrow_drop_down, color: Colors.cyanAccent),
                  border: InputBorder.none,
                  errorStyle: TextStyle(color: Colors.cyanAccent),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                dropdownColor: const Color(0xFF002147),
                iconEnabledColor: Colors.cyanAccent,
                onChanged: (val) {
                  onChanged(val);
                  // Move focus to next field if specified
                  if (nextFocus != null) {
                    FocusScope.of(currentFocus.context!).requestFocus(nextFocus);
                  }
                },
                validator: validator,
                items: items.map<DropdownMenuItem<String>>((item) {
                  return DropdownMenuItem<String>(
                    value: item['text'],
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item['icon'], color: Colors.cyanAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item['text'],
                            style: const TextStyle(color: Colors.white),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Text form field
  Widget buildTextFormField(String label,
      String initialValue,
      IconData icon,
      Function(String) onChanged, {
        String? Function(String?)? validator,
        List<TextInputFormatter>? inputFormatters,
        bool readOnly = false,
      }) {
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
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF000F89), // Royal Blue
                  Color(0xFF0F52BA), // Cobalt Blue
                  Color(0xFF002147), // Navy Blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white),
            ),
            child: TextFormField(
              initialValue: initialValue,
              readOnly: readOnly,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.cyanAccent),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                errorStyle: const TextStyle(
                    color: Colors.cyanAccent), // ✅ Error text color
              ),

              onChanged: readOnly ? null : onChanged,
              validator: validator,
              inputFormatters: inputFormatters,
              textInputAction: TextInputAction.next,
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
              keyboardType: inputFormatters != null
                  ? TextInputType.number
                  : TextInputType.text,
            ),
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
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF28A745), Color(0xFF218838)],
                  // Green gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_outline, color: Colors.white,
                      size: 26),
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
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.of(context).pop();
      } catch (e) {
        // ❌ Error Snackbar with red gradient
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            elevation: 6,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  // Red gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                      Icons.error_outline, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error updating record: $e',
                      style: const TextStyle(
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
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}