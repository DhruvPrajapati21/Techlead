import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:techlead/Digitalmarketingdailytaskreport.dart';
import 'package:techlead/assignedtaskemppage.dart';
import 'package:techlead/Installtionemployeedata.dart';
import 'package:techlead/serviceinstallationpage.dart';
import 'package:techlead/shortageofdata.dart';
import 'package:techlead/taskassignpage.dart';
import 'Installationdailytaskreport.dart';
import 'alldepartmentsfetchpages/Accountshowdata.dart';
import 'alldepartmentsfetchpages/Digitlmarketingshowdata.dart';
import 'alldepartmentsfetchpages/Socialmediamarketingshowdata.dart';
import 'alldepartmentsfetchpages/hrreceivedscreen.dart';

class Digitalmarketinghomescreen extends StatefulWidget {
  const Digitalmarketinghomescreen({super.key});

  @override
  State<Digitalmarketinghomescreen> createState() => _DigitalmarketinghomescreenState();
}

class _DigitalmarketinghomescreenState extends State<Digitalmarketinghomescreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          "Digital Marketing Page",
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
                        builder: (context) => Digitlmarketingshowdata(),
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
                        builder: (context) => Digitalmarketingdailytaskreport(),
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