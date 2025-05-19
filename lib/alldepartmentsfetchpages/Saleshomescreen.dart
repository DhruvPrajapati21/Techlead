import 'package:flutter/material.dart';
import 'package:techlead/assignedtaskemppage.dart';
import 'package:techlead/Installtionemployeedata.dart';
import 'package:techlead/salespage.dart';
import 'package:techlead/serviceinstallationpage.dart';
import 'package:techlead/taskassignpage.dart';
import '../Receivesaleshdata.dart';
import '../Salesdailytaskreport.dart';

class Saleshomescreen extends StatefulWidget {
  const Saleshomescreen({super.key});

  @override
  State<Saleshomescreen> createState() => _SaleshomescreenState();
}

class _SaleshomescreenState extends State<Saleshomescreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Sales Page",
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
                label: "Sales Lead",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SalesPage()),
                ),
              ),
              _buildMenuCard(
                color: Colors.green,
                icon: Icons.report,
                label: "Sales Report",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Receivesalesdata()),
                ),
              ),
              _buildMenuCard(
                color: Colors.deepOrange,
                icon: Icons.task,
                label: "Sales Daily-Task",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DailyReportRecordOfSales()),
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
