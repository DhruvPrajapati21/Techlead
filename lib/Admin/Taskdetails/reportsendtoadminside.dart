// [Keep all your imports as-is]
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportSendToAdminSide extends StatefulWidget {
  const ReportSendToAdminSide({super.key});

  @override
  State<ReportSendToAdminSide> createState() => _ReportSendToAdminSideState();
}

class _ReportSendToAdminSideState extends State<ReportSendToAdminSide> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  Future<void> _selectStartDate(BuildContext context) async {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: previousMonth,
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return _buildCustomDatePickerTheme(child!);
      },
    );

    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return _buildCustomDatePickerTheme(child!);
      },
    );

    if (picked != null) setState(() => _endDate = picked);
  }

  Theme _buildCustomDatePickerTheme(Widget child) {
    return Theme(
      data: ThemeData(
        dialogBackgroundColor: const Color(0xFF0D1B3E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Color(0xFF0D1B3E),
          surface: Color(0xFF0D1B3E),
          onSurface: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reports Sent to Admin", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade900]),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by Employee Name",
                hintStyle: const TextStyle(color: Colors.white),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.indigo.shade900,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: _buildDateField("Start Date", _startDate),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectEndDate(context),
                    child: _buildDateField("End Date", _endDate),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection("DailyTaskReport").snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) => _buildShimmerReportCard(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No reports found", style: TextStyle(color: Colors.white)));
                }

                List<QueryDocumentSnapshot> filteredReports = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data["employeeName"]?.toString().toLowerCase() ?? '';
                  final reportDate = (data["timestamp"] as Timestamp?)?.toDate() ?? DateTime.now();

                  if (_startDate != null && reportDate.isBefore(_startDate!)) return false;
                  if (_endDate != null && reportDate.isAfter(_endDate!)) return false;
                  if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) return false;
                  return true;
                }).toList();

                if (filteredReports.isEmpty) {
                  return const Center(
                    child: Text("No reports match your search/date range!", style: TextStyle(color: Colors.black,fontFamily: "Times New Roman")),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) => _buildReportCard(filteredReports[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? selectedDate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade900, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selectedDate != null ? DateFormat('dd MMM yyyy').format(selectedDate) : label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Icon(Icons.calendar_today, color: Colors.cyanAccent, size: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 50,
          color: Colors.cyanAccent,
          margin: const EdgeInsets.only(bottom: 10),
        ),
      ],
    );
  }

  Widget _buildReportCard(QueryDocumentSnapshot report) {
    final data = report.data() as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.indigo.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Employee Info"),
            buildReportRow(Icons.person, "Name:", data["employeeName"]),
            buildReportRow(Icons.category, "Department:", data["Service_department"]),
            buildReportRow(Icons.miscellaneous_services, "Service Status:", data["service_status"]),
            buildReportRow(Icons.location_on, "Location:", data["location"]),
            buildReportRow(Icons.date_range, "Date:", DateFormat('dd MMM yyyy').format(data["timestamp"].toDate())),

            const SizedBox(height: 12),
            _buildSectionTitle("Task Info"),
            buildReportRow(Icons.title, "Task Title:", data["taskTitle"]),
            buildReportRow(Icons.build, "Actions Taken:", data["actionsTaken"]),
            buildReportRow(Icons.next_plan, "Next Steps:", data["nextSteps"]),

            const SizedBox(height: 12),
            _buildSectionTitle("Work Log"),
            _buildWorkLog(data["workLog"]),

            const SizedBox(height: 12),
            _buildSectionTitle("Uploaded Files"),
            _buildUploadedFiles(data["uploadedFiles"]),
          ],
        ),
      ),
    );
  }

  Widget buildReportRow(IconData icon, String fieldName, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$fieldName ",
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextSpan(
                    text: value?.toString() ?? "N/A",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkLog(dynamic workLog) {
    if (workLog == null || (workLog is List && workLog.isEmpty)) {
      return const Text("No work log available", style: TextStyle(color: Colors.white));
    }

    List logs = workLog as List;

    return Column(
      children: logs.map((log) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: buildReportRow(Icons.access_time, "Time Slot:", "${log['timeSlot']} - ${log['description']}"),
        );
      }).toList(),
    );
  }

  Widget _buildUploadedFiles(dynamic files) {
    if (files == null || (files is List && files.isEmpty)) {
      return const Text("No files uploaded", style: TextStyle(color: Colors.white));
    }

    List uploadedFiles = files as List;

    return Column(
      children: uploadedFiles.map((file) {
        String fileName = file['fileName'];
        String fileUrl = file['downloadUrl'];
        bool isImage = fileName.toLowerCase().endsWith(".png") ||
            fileName.toLowerCase().endsWith(".jpg") ||
            fileName.toLowerCase().endsWith(".jpeg") ||
            fileName.toLowerCase().endsWith(".gif");

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: isImage
              ? GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImage(imageUrl: fileUrl, tag: fileName),
                ),
              );
            },
            child: Hero(
              tag: fileName,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: fileUrl,
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.indigo.shade700,
                    highlightColor: Colors.indigo.shade400,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Text("Image failed to load", style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
          )
              : InkWell(
            onTap: () => _launchURL(fileUrl),
            child: Text(fileName, style: const TextStyle(color: Colors.yellowAccent, decoration: TextDecoration.underline)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShimmerReportCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Shimmer.fromColors(
        baseColor: Colors.indigo.shade700,
        highlightColor: Colors.indigo.shade400,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.indigo.shade900,
          child: Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: 150, color: Colors.indigo.shade700),
                const SizedBox(height: 10),
                Container(height: 16, width: double.infinity, color: Colors.indigo.shade700),
                const SizedBox(height: 10),
                Container(height: 16, width: 250, color: Colors.indigo.shade700),
                const SizedBox(height: 10),
                Container(height: 80, width: double.infinity, color: Colors.indigo.shade700),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint("Could not open $url");
    }
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImage({Key? key, required this.imageUrl, required this.tag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
