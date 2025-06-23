import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:typed_data';

import 'Employee/Attendacescreen/Attendancemodel.dart';
import 'Employee/Attendacescreen/googlescreen.dart';

class Attendance extends StatefulWidget {
  @override
  _AttendanceState createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  Map<String, String?> imageCache = {};
  bool isLoading = false;
  bool isLoading2 = false;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  bool isToastVisible = false;
  String searchQuery = '';
  String? selectedDate;
  TextEditingController searchController = TextEditingController();
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    fetchImageUrls();
    _getCurrentLocation();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    if (statuses[Permission.storage]!.isGranted) {
      print('Storage permission granted');
    } else if (statuses[Permission.storage]!.isDenied) {
      print('Storage permission denied');
    } else if (statuses[Permission.storage]!.isPermanentlyDenied) {
      print('Storage permission permanently denied');
      await openAppSettings();
    }

    setState(() {});
  }


  Future<void> fetchImageUrls() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Attendance').get();

      for (var doc in querySnapshot.docs) {
        String? imageUrl = doc.get('Imageurl') as String?;
        imageCache[doc.id] = imageUrl;
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching image URLs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }
  Future<void> _downloadMonthlyExcel(DateTime startDate, DateTime endDate) async {
    if (!mounted) return;

    setState(() {
      isLoading2 = true;
    });

    DateTime? parseDate(String dateString) {
      try {
        if (dateString.contains('/')) {
          List<String> parts = dateString.split('/');
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          return DateTime(year, month, day);
        } else {

          return DateTime.parse(dateString);
        }
      } catch (e) {
        print('Error parsing date: $e');
        return null;
      }
    }


    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Attendance'];

      var absentStyle = CellStyle(backgroundColorHex: '#FF0000');
      var halfDayStyle = CellStyle(backgroundColorHex: '#00FF00');
      var fullDayStyle = CellStyle(
        fontColorHex: '#000000',
        backgroundColorHex: '#FFFFFF',
      );

      sheet.appendRow([
        'EMPName', 'Department', 'Date', 'CheckIn', 'CheckInLocation',
        'CheckOut', 'CheckOutLocation', 'Record', 'Status'
      ]);

      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Attendance').get();

      List<AttendanceRecord> records = querySnapshot.docs.map((doc) {
        return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      records = records.where((record) {
        if (record.date == null) return false;
        DateTime? recordDate = parseDate(record.date!); // Use parseDate function
        if (recordDate == null) return false; // Skip if date is invalid

        bool matchesDateRange = recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            recordDate.isBefore(endDate.add(Duration(days: 1)));
        return matchesDateRange;
      }).toList();


      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          record.employeeName ?? 'N/A', record.department ?? 'N/A',
          record.date ?? 'N/A', record.checkIn ?? 'N/A',
          record.checkInLocation ?? 'N/A', record.checkOut ?? 'N/A',
          record.checkOutLocation ?? 'N/A', record.record ?? 'N/A',
          record.status ?? 'Absent',
        ]);

        String status = record.status ?? 'Absent';
        if (status == 'Absent') {
          sheet.cell(CellIndex.indexByString('I$rowIndex')).cellStyle = absentStyle;
        } else if (status == 'Half Day') {
          sheet.cell(CellIndex.indexByString('I$rowIndex')).cellStyle = halfDayStyle;
        } else if (status == 'Full Day') {
          sheet.cell(CellIndex.indexByString('I$rowIndex')).cellStyle = fullDayStyle;
        }
      }

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/attendance_data_monthly.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        String username = "manthanpatel26510@gmail.com";
        String appSpecificPassword = "uqvcfqumgbynnpzq";

        final smtpServer = gmail(username, appSpecificPassword);
        final message = Message()
          ..from = Address('Info@techleadsolution.in', 'Techlead')
          ..recipients.add('Info@techleadsolution.in')
          ..subject = 'Monthly Attendance Data'
          ..text = 'Please find the attached monthly attendance data Excel sheet.\n'
          ..attachments.add(
            FileAttachment(tempFile)..fileName = 'attendance_data_monthly.xlsx',
          );

        try {
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Monthly Excel file sent via email successfully!')),
            );
          }
        } on MailerException catch (e) {
          print('Message not sent. $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sending email.')),
            );
          }
        }
      } else {
        throw Exception('Failed to save file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating Excel file.')),
        );
      }
      print('Error generating Excel file: $e');
    } finally {
      setState(() {
        isLoading2 = false;
        isToastVisible = true;
      });

      if (isToastVisible) {
        Fluttertoast.showToast(
          msg: "Monthly attendance data Excel file sent successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        setState(() {
          isToastVisible = false;
        });
      }
    }
  }

  Future<void> _downloadExcel() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Attendance'];

      var absentStyle = CellStyle(
        backgroundColorHex: '#FF0000',
      );
      var halfDayStyle = CellStyle(
        backgroundColorHex: '#00FF00',
      );
      var fullDayStyle = CellStyle(
        fontColorHex: '#000000',
        backgroundColorHex: '#FFFFFF',
      );

      sheet.appendRow([
        'EMPName',
        'Department',
        'Date',
        'CheckIn',
        'CheckInLocation',
        'CheckOut',
        'CheckOutLocation',
        'Record',
        'Status'
      ]);

      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('Attendance').get();

      List<AttendanceRecord> records = querySnapshot.docs.map((doc) {
        return AttendanceRecord.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      records = records.where((record) {
        bool matchesSearchQuery = record.employeeName
            ?.toLowerCase()
            .contains(searchQuery.toLowerCase()) ??
            false;
        bool matchesDate = selectedDate == null || record.date == selectedDate;
        return matchesSearchQuery && matchesDate;
      }).toList();

      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          record.employeeName ?? 'N/A',
          record.department ?? 'N/A',
          record.date ?? 'N/A',
          record.checkIn ?? 'N/A',
          record.checkInLocation ?? 'N/A',
          record.checkOut ?? 'N/A',
          record.checkOutLocation ?? 'N/A',
          record.record ?? 'N/A',
          record.status ?? 'Absent',
        ]);

        String status = record.status ?? 'Absent';
        if (status == 'Absent') {
          sheet.cell(CellIndex.indexByString('I$rowIndex')).cellStyle = absentStyle;
        } else if (status == 'Half Day') {
          sheet.cell(CellIndex.indexByString('I$rowIndex')).cellStyle = halfDayStyle;
        } else if (status == 'Full Day') {
          sheet.cell(CellIndex.indexByString('I$rowIndex')).cellStyle = fullDayStyle;
        }
      }

      List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/attendance_data.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        String username = "manthanpatel26510@gmail.com";
        String appSpecificPassword = "uqvcfqumgbynnpzq";

        final smtpServer = gmail(username, appSpecificPassword);
        final message = Message()
          ..from = Address('Info@techleadsolution.in', 'Techlead')
          ..recipients.add('Info@techleadsolution.in')
          ..subject = 'Attendance For Employee Data'
          ..text = 'Please find the attached attendance data Excel Sheet.\n'
          ..attachments.add(
            FileAttachment(tempFile)..fileName = 'attendance_data.xlsx',
          );

        try {
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Excel file sent via email successfully!')),
            );
          }
        } on MailerException catch (e) {
          print('Message not sent. $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sending email.')),
            );
          }
        }
      } else {
        throw Exception('Failed to save file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating Excel file.')),
        );
      }
      print('Error generating Excel file: $e');
    } finally {
      setState(() {
        isLoading = false;
        isToastVisible = true;
      });

      if (isToastVisible) {
        Fluttertoast.showToast(
          msg: "Attendance Data Excel file sent successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        setState(() {
          isToastVisible = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          'EMPAttendanceData',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search by Employee Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range),
                  onPressed: () {
                    _selectDate(context);
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 12),
                    child: ElevatedButton(
                      onPressed: _downloadExcel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Download",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11,vertical: 11),
                    child: ElevatedButton(
                      onPressed: () {
                        DateTime startOfMonth = DateTime(selectedYear, selectedMonth, 1);
                        DateTime endOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);
                        _downloadMonthlyExcel(startOfMonth, endOfMonth);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      child: isLoading2
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                        "Month Download",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('Attendance')
                  .orderBy('date', descending: true) // Sort by date, recent first
                  .orderBy('checkIn', descending: true) // Sort by check-in time within each date
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Firestore Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No data available!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }

                List<AttendanceRecord> records = snapshot.data!.docs.map((doc) {
                  return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                }).toList();

                records = records.where((record) {
                  bool matchesSearchQuery = record.employeeName
                      ?.toLowerCase()
                      .contains(searchQuery.toLowerCase()) ??
                      false;
                  bool matchesDate = selectedDate == null || record.date == selectedDate;
                  return matchesSearchQuery && matchesDate;
                }).toList();

                if (records.isEmpty) {
                  return Center(
                    child: Text(
                      'No Attendance data available',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (BuildContext context, int index) {
                    AttendanceRecord record = records[index];

                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Card(
                        color: Colors.white60,
                        margin: EdgeInsets.all(11.0),
                        child: ListTile(
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Record: ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                        ),
                                        TextSpan(
                                          text: '${index + 1}',
                                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'EMPName: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                        record.employeeName ?? 'N/A',
                                        style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Department: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: record.department ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Date: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: record.date ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'CheckIn: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: record.checkIn ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'CheckInLocation: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                      record.checkInLocation ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'CheckOut: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: record.checkOut ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'CheckOutLocation: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: record.checkOutLocation ??
                                          'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Record: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: record.record ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Status: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: record.status ?? 'N/A',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Center(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_currentLocation != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  MapScreen(
                                                    initialPosition: LatLng(
                                                      _currentLocation!
                                                          .latitude,
                                                      _currentLocation!
                                                          .longitude,
                                                    ),
                                                  ),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Unable to fetch current location.')),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.orangeAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(5.0),
                                        ),
                                      ),
                                      child: Text(
                                        "Live Map",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
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
}
