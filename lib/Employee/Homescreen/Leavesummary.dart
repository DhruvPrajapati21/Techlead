import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveSummaryScreen extends StatefulWidget {
  const LeaveSummaryScreen({Key? key}) : super(key: key);

  @override
  State<LeaveSummaryScreen> createState() => _LeaveSummaryScreenState();
}

class _LeaveSummaryScreenState extends State<LeaveSummaryScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();

  final List<String> tabs = ['All', 'Approved', 'Pending', 'Rejected'];

  @override
  void initState() {
    _tabController = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  Future<void> _selectMonth() async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: MonthYearPicker(
            selectedDate: selectedDate,
            onChanged: (date) {
              Navigator.of(context).pop(date);
            },
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getLeaveStream(String statusFilter) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('Empleave')
        .where('userId', isEqualTo: userId)
        .orderBy('reportedDateTime', descending: true);

    if (statusFilter.toLowerCase() != 'all') {
      query = query.where('status', isEqualTo: statusFilter.toLowerCase());
    }

    return query.snapshots();
  }

  bool _isInSelectedMonth(DateTime date) {
    return date.year == selectedDate.year && date.month == selectedDate.month;
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave, int index) {
    final reportedDate = leave['reportedDateTime']?.toDate() ?? DateTime.now();
    if (!_isInSelectedMonth(reportedDate)) return const SizedBox.shrink();

    final String status = leave['status'] ?? '';
    final String statusFormatted = toBeginningOfSentenceCase(status) ?? status;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.greenAccent;
        break;
      case 'pending':
        statusColor = Colors.orangeAccent;
        break;
      default:
        statusColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade900, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(15),
          child: ListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    'Record: ${index + 1}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildRichText('EmpId: ', leave['empid']),
                _buildRichText('Name: ', leave['name']),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRichText('EmailId: ', leave['emailid']),
                _buildRichText('Leave Type: ', leave['leavetype']),
                _buildRichText('Start Date: ', leave['startdate']),
                _buildRichText('End Date: ', leave['enddate']),
                _buildRichText('Status: ', statusFormatted, color: statusColor),
                _buildRichText('Reason: ', leave['reason']),
                const SizedBox(height: 6),
                Text(
                  'Reported On: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(reportedDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Times New Roman',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRichText(String label, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
                fontFamily: 'Times New Roman',
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Times New Roman',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoData(String status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          "No $status leave data found for selected month!",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'Times New Roman',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFe3f2fd),
        title: const Text(
          "Leave Summary",
          style: TextStyle(
            fontFamily: 'Times New Roman',
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _selectMonth,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: Colors.black),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: const Color(0xFFFFD700),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.green,
              indicatorWeight: 4,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.black87,
              tabs: tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.map((status) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _getLeaveStream(status),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              List<Widget> cards = [];

              for (int i = 0; i < docs.length; i++) {
                final leave = docs[i].data();
                final reportedDate = leave['reportedDateTime']?.toDate();
                if (reportedDate != null && _isInSelectedMonth(reportedDate)) {
                  cards.add(_buildLeaveCard(leave, i));
                }
              }

              if (cards.isEmpty) {
                return _buildNoData(status);
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(children: cards),
              );
            },
          );
        }).toList(),
      ),
    );
  }
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
    _years = List.generate(101, (index) => DateTime.now().year - 50 + index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000F89), Color(0xFF0F52BA), Color(0xFF002147)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Month and Year',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Month Dropdown
          DropdownButtonFormField<int>(
            dropdownColor: const Color(0xFF001f4d), // Bluish dropdown background
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF001f4d),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 1, color: Colors.white),
              ),
            ),
            iconEnabledColor: Colors.white,
            value: _selectedDate.month,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: List.generate(12, (index) => index + 1)
                .map((month) => DropdownMenuItem<int>(
              value: month,
              child: Text(
                DateFormat('MMMM').format(DateTime(0, month)),
                style: const TextStyle(color: Colors.white),
              ),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                  _selectedDate.year,
                  value ?? _selectedDate.month,
                );
              });
            },
          ),

          const SizedBox(height: 16),

          // Year Dropdown
          DropdownButtonFormField<int>(
            dropdownColor: const Color(0xFF001f4d),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF001f4d),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white70),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 1, color: Colors.white),
              ),
            ),
            iconEnabledColor: Colors.white,
            value: _selectedDate.year,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            items: _years
                .map((year) => DropdownMenuItem<int>(
              value: year,
              child: Text(
                year.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedDate = DateTime(
                    value ?? _selectedDate.year, _selectedDate.month);
              });
            },
          ),

          const SizedBox(height: 24),

          // Select Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onChanged(_selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002147),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Select',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
