import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:techlead/Managementdailytaskreport.dart';
import 'package:techlead/assignedtaskemppage.dart';
import 'package:techlead/Employee/Categoryscreen/Installation/Installtionemployeedata.dart';
import 'package:techlead/Employee/Categoryscreen/Installation/serviceinstallationpage.dart';
import 'package:techlead/shortageofdata.dart';
import 'package:techlead/taskassignpage.dart';
import 'Employee/Categoryscreen/Installation/Installationdailytaskreport.dart';
import 'alldepartmentsfetchpages/Managementshowdata.dart';
import 'alldepartmentsfetchpages/hrreceivedscreen.dart';

class Managementhomescreen extends StatefulWidget {
  const Managementhomescreen({super.key});

  @override
  State<Managementhomescreen> createState() => _ManagementhomescreenState();
}

class _ManagementhomescreenState extends State<Managementhomescreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Management Page",
          style: TextStyle(
            fontFamily: "Times New Roman",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 70,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Managementshowdata(),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment, size: 50, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          "Task Report",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Managementdailytaskreport(),
                      ),
                    );
                  },
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.report, size: 50, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          "Show Daily-Task",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

      ),
    );
  }
}