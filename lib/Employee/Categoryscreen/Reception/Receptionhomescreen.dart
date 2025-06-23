import 'package:flutter/material.dart';
import 'package:techlead/Receptionlistdailytaskreport.dart';
import 'package:techlead/reception.dart';
import 'package:techlead/showreceptiondata.dart';
import '../Receivesaleshdata.dart';

class Receptionhomescreen extends StatefulWidget {
  const Receptionhomescreen({super.key});

  @override
  State<Receptionhomescreen> createState() => _ReceptionhomescreenState();
}

class _ReceptionhomescreenState extends State<Receptionhomescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Reception Page",
          style: TextStyle(
            fontFamily: "Times New Roman",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildMenuCard(
                color: Colors.blue,
                icon: Icons.assignment,
                label: "Meeting Assign",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReceptionPage()),
                ),
              ),
              _buildMenuCard(
                color: Colors.green,
                icon: Icons.report,
                label: "Meeting Report",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Receivesalesdata()),
                ),
              ),
              _buildMenuCard(
                color: Colors.deepPurple,
                icon: Icons.task,
                label: "Reception Daily-Task",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DailyReportRecordOfReception()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
