import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:techlead/Employee/Categoryscreen/Social%20Media/Smdailytaskreport.dart';
import 'package:techlead/Employee/Categoryscreen/Installation/Installtionemployeedata.dart';
import 'package:techlead/Employee/Categoryscreen/Installation/serviceinstallationpage.dart';
import 'package:techlead/Employee/Categoryscreen/Installation/shortageofdata.dart';
import 'package:techlead/Admin/Taskdetails/taskassignpage.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import '../../../core/app_bar_provider.dart';
import '../All_Home_Screen_Card_Ui/All_Home_Screen_Card_Ui.dart';
import '../Installation/Installationdailytaskreport.dart';
import '../Account/Accountshowdata.dart';
import 'Socialmediamarketingshowdata.dart';
import '../HR/hrreceivedscreen.dart';


class Smhomescreen extends ConsumerStatefulWidget {
  const Smhomescreen({super.key});

  @override
  ConsumerState<Smhomescreen> createState() => _SmhomescreenState();
}

class _SmhomescreenState extends ConsumerState<Smhomescreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(appBarTitleProvider.notifier).state = "Social Media Task Section";
      ref.read(appBarGradientColorsProvider.notifier).state = [
        Color(0xFF2F68AA),
        Color(0xFF025BB6),
      ];
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF415A77),
              Color(0xFF778DA9),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.8),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              MenuCard(
                color: Colors.blue.shade900,
                icon: Icons.assignment,
                label: "Admin Task Report",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Socialmediamarketingshowdata()),
                ),
              ),
              MenuCard(
                color: Colors.green.shade800,
                icon: Icons.report,
                label: "Show Daily-Task",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => Smdailytaskreport()),
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}