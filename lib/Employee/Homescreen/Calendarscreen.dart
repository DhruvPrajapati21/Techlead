import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:provider/provider.dart';

import 'Attendancemodel.dart';
import 'Themeprovider.dart';

class Calendarscreen extends StatefulWidget {
  const Calendarscreen({Key? key}) : super(key: key);

  @override
  State<Calendarscreen> createState() => _CalendarscreenState();
}

class _CalendarscreenState extends State<Calendarscreen> {
  DateTime selectedDate = DateTime.now();
  String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
  }

  Stream<List<AttendanceRecord>> getAttendanceRecords() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('Attendance')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      print('Raw data from Firestore: ${doc.data()}');
      return AttendanceRecord.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList());
  }

  List<AttendanceRecord> getFilteredRecords(List<AttendanceRecord> records) {
    List<AttendanceRecord> filtered = records.where((record) {
      if (record.date == null || record.date!.isEmpty) return false;
      try {
        DateTime recordDate = DateFormat('dd/MM/yyyy').parse(record.date!);
        return recordDate.month == selectedDate.month && recordDate.year == selectedDate.year;
      } catch (e) {
        print('Error parsing date: ${record.date}, Error: $e');
        return false;
      }
    }).toList();

    filtered.sort((a, b) {
      DateTime dateA = DateFormat('dd/MM/yyyy').parse(a.date ?? '');
      DateTime dateB = DateFormat('dd/MM/yyyy').parse(b.date ?? '');
      return dateA.compareTo(dateB);
    });

    print('Filtered and sorted records: $filtered');
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          title: Text(
            'My Attendance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
         ),
      body: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(width: 15),
                Text(
                  currentMonth,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: GestureDetector(
                    onTap: () {
                      _selectMonth(context);
                    },
                    child: Text(
                      "Pick a Month",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<List<AttendanceRecord>>(
                stream: getAttendanceRecords(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.white,));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  List<AttendanceRecord> records = snapshot.data ?? [];
                  List<AttendanceRecord> filteredRecords = getFilteredRecords(records);

                  if (filteredRecords.isEmpty) {
                    return Center(
                      child: Text(
                        "No data available",
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      AttendanceRecord record = filteredRecords[index];

                      String formattedDate = 'N/A';
                      String shortDayOfWeek = 'N/A';

                      DateTime now = DateTime.now();

                      try {
                        DateTime dateTime = DateFormat('dd/MM/yyyy').parse(record.date ?? '');
                        formattedDate = DateFormat('d').format(dateTime);
                        shortDayOfWeek = DateFormat('EEE').format(dateTime);
                      } catch (e) {
                        formattedDate = DateFormat('d').format(now);
                        shortDayOfWeek = DateFormat('EEE').format(now);
                        print('Error formatting date: $e');
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Container(
                            width: double.infinity,
                            height: 500,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(hexColor('#FF6600')),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomLeft: Radius.circular(10),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$shortDayOfWeek\n$formattedDate',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 7,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'EMPName: ${record.employeeName}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        Text(
                                          'Address: ${record.department}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        SizedBox(height: 8.0),
                                        Text('Check-In: ${record.checkIn ?? 'N/A'}',
                                            style: TextStyle(color: Colors.white)),
                                        Text('CheckInLocation: ${record.checkInLocation ?? 'N/A'}',
                                            style: TextStyle(color: Colors.white)),
                                        SizedBox(height: 10),
                                        Text('Check-Out: ${record.checkOut ?? 'N/A'}',
                                            style: TextStyle(color: Colors.white)),
                                        Text('CheckOutLocation: ${record.checkOutLocation ?? 'N/A'}',
                                            style: TextStyle(color: Colors.white)),
                                        SizedBox(height: 10),
                                        Text('Record: ${record.record ?? 'N/A'}',
                                            style: TextStyle(color: Colors.white)),
                                        Text('Status: ${record.status ?? 'N/A'}',
                                            style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
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
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final DateTime initialDate = DateTime(selectedDate.year, selectedDate.month);
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Month and Year'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Month and Year Picker
                MonthYearPicker(
                  selectedDate: initialDate,
                  onChanged: (date) {
                    Navigator.of(context).pop(date);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = DateTime(pickedDate.year, pickedDate.month, 1);
        currentMonth = DateFormat('MMMM yyyy').format(selectedDate);
      });// Re-fetch records for the selected month
    }
  }
}

int hexColor(String color) {
  String newColor = '0xff' + color.replaceAll('#', '');
  return int.parse(newColor);
}

class MonthYearPicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  const MonthYearPicker({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MonthYearPickerState createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late DateTime _selectedDate;
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _years = List.generate(101, (index) =>
    DateTime.now().year - 50 + index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Adjust to fit content
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: DropdownButtonFormField<int>(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            value: _selectedDate.month,
            items: List.generate(12, (index) => index + 1)
                .map((month) => DropdownMenuItem<int>(
              value: month,
              child: Text(
                DateFormat('MMMM').format(DateTime(0, month)),
                style: TextStyle(fontSize: 18),
              ),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                    _selectedDate.year, value ?? _selectedDate.month);
              });
            },
            validator: (value) {
              if (value == null) {
                return "Please select a month";
              }
              return null;
            },
          ),
        ),
        SizedBox(height: 16), // Space between dropdowns
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: DropdownButtonFormField<int>(
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
            value: _selectedDate.year,
            items: _years
                .map((year) => DropdownMenuItem<int>(
              value: year,
              child: Text(
                year.toString(),
                style: TextStyle(fontSize: 18),
              ),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                    value ?? _selectedDate.year, _selectedDate.month);
              });
            },
            validator: (value) {
              if (value == null) {
                return "Please select a year";
              }
              return null;
            },
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: ElevatedButton(
              onPressed: () {
                widget.onChanged(_selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Select',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
