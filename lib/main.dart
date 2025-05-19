import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:techlead/Adminhomescreeen.dart';
import 'package:techlead/EnLoginPage.dart';
import 'package:techlead/Enteredscreen.dart';
import 'package:techlead/Leavescreen.dart';
import 'package:techlead/Profilescreen.dart';
import 'package:techlead/Showattendancedata.dart';
import 'package:techlead/Splashscreen.dart';
import 'package:techlead/Supportscreen.dart';
import 'package:techlead/birthdayscreenpop.dart';
import 'package:techlead/leaveinfo.dart';
import 'package:techlead/Installtionemployeedata.dart';
import 'package:techlead/reception.dart';
import 'package:techlead/salespage.dart';
import 'package:techlead/serviceinstallationpage.dart';
import 'package:techlead/showreceptiondata.dart';
import 'package:techlead/taskassignpage.dart';
import 'package:techlead/taskreportpage.dart';
import 'package:techlead/welcomescreen.dart';
import 'Accounthomescreen.dart';
import 'EmpHomescreen.dart';
import 'EnSignUpPage.dart';
import 'Financeshomescreen.dart';
import 'Hrhomescreen.dart';
import 'Managementhomescreen.dart';
import 'Receptionlistdailytaskreport.dart';
import 'Showsalesdata.dart';
import 'SmHomescreen.dart';
import 'Themeprovider.dart';
import 'addinforemployee.dart';
import 'alldepartmentsfetchpages/Receptionhomescreen.dart';
import 'alldepartmentsfetchpages/Saleshomescreen.dart';
import 'assignedtaskemppage.dart';
import 'inhome.dart';
import 'newcodesample.dart';

@pragma('vm:entry-point')

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (kDebugMode) {
    print(message.notification!.title.toString());
  }
  if (kDebugMode) {
    print(message.notification!.body.toString());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) =>  ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Techlead',
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home:SplashScreen(),
    );
  }
}