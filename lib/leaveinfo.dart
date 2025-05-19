import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

import 'Leavemodel.dart';

class LeaveInfo extends StatefulWidget {
  const LeaveInfo({super.key});

  @override
  State<LeaveInfo> createState() => _LeaveInfoState();
}

class _LeaveInfoState extends State<LeaveInfo> {
  bool isAdmin = true;
  TextEditingController searchController = TextEditingController();
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  String? selectedFilter = 'All';
  final List<String> filters = ['All', 'Approved', 'Rejected', 'pending'];
  bool isLoading = false;
  bool isLoading2 = false;
  bool isToastVisible = false;

  void _updateLeaveStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('Empleave').doc(docId).update({
        'status': status,
      });

      Fluttertoast.showToast(
        msg: "Leave status updated to $status",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );

      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating status: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  DateTime selectedDate = DateTime.now();
  String currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());

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


  Future<void> downloadMonthlyLeaveExcel(DateTime startDate, DateTime endDate) async {
    if (!mounted) return;

    setState(() {
      isLoading2 = true;
    });

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Leave Records'];

      var pendingStyle = CellStyle(backgroundColorHex: '#FFFF00');
      var approvedStyle = CellStyle(backgroundColorHex: '#00FF00');
      var rejectedStyle = CellStyle(backgroundColorHex: '#FF0000');

      sheet.appendRow([
        'EMPID',
        'Employee Name',
        'Email ID',
        'Leave Type',
        'Start Date',
        'End Date',
        'Reason',
        'Status',
        'Reported Date'
      ]);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Empleave').get();

      List<LeaveModel> records = querySnapshot.docs.map((doc) {
        return LeaveModel.fromSnapshot(doc);
      }).toList();

      records = records.where((record) {
        DateTime? recordStartDate = parseDate(record.startdate);
        if (recordStartDate == null) return false; // Skip if startdate is invalid

        bool matchesDateRange = recordStartDate.isAfter(startDate.subtract(Duration(days: 1))) &&
            recordStartDate.isBefore(endDate.add(Duration(days: 1)));

        bool matchesSearchQuery = searchController.text.isEmpty ||
            record.name.toLowerCase().contains(searchController.text.toLowerCase());
        bool matchesFilter = selectedFilter == null ||
            selectedFilter == 'All' ||
            record.status == selectedFilter;

        return matchesDateRange && matchesSearchQuery && matchesFilter;
      }).toList();

      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          record.empid,
          record.name,
          record.emailid,
          record.leavetype,
          record.startdate,
          record.enddate,
          record.reason,
          record.status,
          record.reportedDateTime.toDate().toString(),
        ]);

        if (record.status == 'pending') {
          sheet.cell(CellIndex.indexByString('H$rowIndex')).cellStyle = pendingStyle;
        } else if (record.status == 'Approved') {
          sheet.cell(CellIndex.indexByString('H$rowIndex')).cellStyle = approvedStyle;
        } else if (record.status == 'Rejected') {
          sheet.cell(CellIndex.indexByString('H$rowIndex')).cellStyle = rejectedStyle;
        }
      }

      List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/monthly_leave_data.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        String username = "getkeyllpmain@gmail.com";
        String appSpecificPassword = "ivboubpfeghogmjv";

        final smtpServer = gmail(username, appSpecificPassword);
        final message = Message()
          ..from = Address('faydabazarhr1@gmail.com', 'FBHR')
          ..recipients.add('faydabazarhr1@gmail.com')
          ..subject = 'Monthly Leave Records Data'
          ..text = 'Please find the attached monthly leave records Excel sheet.\n'
          ..attachments.add(
            FileAttachment(tempFile)..fileName = 'monthly_leave_data.xlsx',
          );

        try {
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Monthly Leave Excel file sent via email successfully!'),
              ),
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
          SnackBar(content: Text('Error generating Leave Excel file.')),
        );
      }
      print('Error generating Leave Excel file: $e');
    } finally {
      setState(() {
        isLoading2 = false;
        isToastVisible = true;
      });

      if (isToastVisible) {
        Fluttertoast.showToast(
          msg: "Monthly Leave Data Excel file sent successfully!",
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


  Future<void> downloadLeaveExcel() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Leave Records'];

      var pendingStyle = CellStyle(
        backgroundColorHex: '#FFFF00',
      );
      var approvedStyle = CellStyle(
        backgroundColorHex: '#00FF00',
      );
      var rejectedStyle = CellStyle(
        backgroundColorHex: '#FF0000',
      );

      sheet.appendRow([
        'EMPID',
        'Employee Name',
        'Email ID',
        'Leave Type',
        'Start Date',
        'End Date',
        'Reason',
        'Status',
        'Reported Date'
      ]);

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Empleave').get();

      List<LeaveModel> records = querySnapshot.docs.map((doc) {
        return LeaveModel.fromSnapshot(doc);
      }).toList();

      records = records.where((record) {
        bool matchesSearchQuery = searchController.text.isEmpty ||
            record.name.toLowerCase().contains(searchController.text.toLowerCase());
        bool matchesFilter = selectedFilter == null ||
            selectedFilter == 'All' ||
            record.status == selectedFilter;
        return matchesSearchQuery && matchesFilter;
      }).toList();

      for (var record in records) {
        int rowIndex = sheet.maxRows + 1;
        sheet.appendRow([
          record.empid,
          record.name,
          record.emailid,
          record.leavetype,
          record.startdate,
          record.enddate,
          record.reason,
          record.status,
          record.reportedDateTime.toDate().toString(),
        ]);

        if (record.status == 'pending') {
          sheet.cell(CellIndex.indexByString('H$rowIndex')).cellStyle = pendingStyle;
        } else if (record.status == 'Approved') {
          sheet.cell(CellIndex.indexByString('H$rowIndex')).cellStyle = approvedStyle;
        } else if (record.status == 'Rejected') {
          sheet.cell(CellIndex.indexByString('H$rowIndex')).cellStyle = rejectedStyle;
        }
      }

      List<int>? fileBytes = excel.save();

      if (fileBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/leave_data.xlsx');
        await tempFile.writeAsBytes(fileBytes);

        String username = "manthanpatel26510@gmail.com";
        String appSpecificPassword = "uqvcfqumgbynnpzq";

        final smtpServer = gmail(username, appSpecificPassword);
        final message = Message()
          ..from = Address('Info@techleadsolution.in', 'Techlead')
          ..recipients.add('Info@techleadsolution.in')
          ..subject = 'Leave Records Data'
          ..text = 'Please find the attached leave records Excel Sheet.\n'
          ..attachments.add(
            FileAttachment(tempFile)
              ..fileName = 'leavxxe_data.xlsx',
          );

        try {
          final sendReport = await send(message, smtpServer);
          print('Message sent: ' + sendReport.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Leave Excel file sent via email successfully!'),
              ),
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
          SnackBar(content: Text('Error generating Leave Excel file.')),
        );
      }
      print('Error generating Leave Excel file: $e');
    } finally {
      setState(() {
        isLoading = false;
        isToastVisible = true;
      });

      if (isToastVisible) {
        Fluttertoast.showToast(
          msg: "Leave Data Excel file sent successfully!",
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
          "LeaveInfo",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: SizedBox(
                            height: 50,
                            child: TextFormField(
                              controller: searchController,
                              onChanged: (value) {
                                setState(() {});
                              },
                              style: const TextStyle(fontSize: 16),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.search_outlined),
                                labelText: 'Search by Employee Name...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            "Filter: ",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          SizedBox(
                            child: DropdownButton<String>(
                              value: selectedFilter,
                              items: filters
                                  .map(
                                    (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (item) =>
                                  setState(() => selectedFilter = item),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10,),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            child: ElevatedButton(
                              onPressed: downloadLeaveExcel,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: isLoading
                                  ? CircularProgressIndicator(color: Colors.white,)
                                  :Text(
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
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            child: ElevatedButton(
                              onPressed: () {
                                _selectMonth(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                              ),
                              child: Text(
                                "Pick a Month",
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
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('Empleave')
                        .orderBy('reportedDateTime', descending: false)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No data available'));
                      }

                      List<LeaveModel> leaveList = snapshot.data!.docs.map((doc) {
                        return LeaveModel.fromSnapshot(doc);
                      }).toList();

                      leaveList = leaveList.where((leave) {
                        bool matchesSearch = searchController.text.isEmpty ||
                            leave.name.toLowerCase().contains(searchController.text.toLowerCase());
                        bool matchesFilter = selectedFilter == null ||
                            selectedFilter == 'All' ||
                            leave.status == selectedFilter;
                        return matchesSearch && matchesFilter;
                      }).toList();

                      if (leaveList.isEmpty) {
                        return const Center(child: Text('No Data Found!',style: TextStyle(fontWeight: FontWeight.bold,),));
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: leaveList.length,
                        itemBuilder: (BuildContext context, int index) {
                          var leaveModel = leaveList[index];
                          var showButtons = (leaveModel.status == "pending" || leaveModel.status == null) && isAdmin;
                          var docId = leaveModel.documentId;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            child: Card(
                              color: Colors.white60,
                              margin: EdgeInsets.all(5.0),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
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
                                    _buildRichText('EmpId: ', leaveModel.empid),
                                    _buildRichText('EmpName: ', leaveModel.name),
                                    _buildRichText('EmpEmailId: ', leaveModel.emailid),
                                    _buildRichText('Leavetype: ', leaveModel.leavetype),
                                    _buildRichText('StartDate: ', leaveModel.startdate),
                                    _buildRichText('EndDate: ', leaveModel.enddate),
                                    _buildRichText('Reason: ', leaveModel.reason),
                                    _buildStatusRichText('Status: ', leaveModel.status ?? 'Unknown'),
                                    if (leaveModel.status == "pending") ...[
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              _updateLeaveStatus(docId, 'Approved');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: Text(
                                              'Approve',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              _updateLeaveStatus(docId, 'Rejected');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            child: Text(
                                              'Reject',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'Reported Date&Time: ',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black,fontSize: 13),
                                        ),
                                        Text(
                                          leaveModel.reportedDateTime != null
                                              ? DateFormat('dd/MM/yyyy HH:mm:ss').format((leaveModel.reportedDateTime as Timestamp).toDate())
                                              : 'N/A',
                                          style: TextStyle(color: Colors.black,fontSize: 13),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRichText(String label, String value, {Color color = Colors.black}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          TextSpan(
            text: value,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRichText(String label, String status) {
    Color statusColor = Colors.black;

    switch (status) {
      case 'Approved':
        statusColor = Colors.green;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
    }

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          TextSpan(
            text: status,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}


int hexColor(String color) {
  String newColor = '0xff' + color.replaceAll('#', '');
  return int.parse(newColor);
}

// Custom Month-Year Picker Widget
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
      mainAxisSize: MainAxisSize.min,
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
                backgroundColor: Colors.orangeAccent,
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
