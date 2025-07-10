import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'Employee/Authentication/Splashscreen.dart';
import 'Employee/Categoryscreen/categoryscreen.dart';
import 'Default/Themeprovider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// 🕒 Handle background & terminated notifications
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _handleNotification(message, isFromBackground: true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) async {
      final payload = response.payload ?? '';
      if (payload.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('targetDepartment', payload);
        navigatorKey.currentState?.pushNamed('/Categoryscreen');
      }
    },
  );

  runApp(
    riverpod.ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _refreshAndSaveFcmToken();
    _setupTokenRefresh();
    _checkAndStoreProfile();
    setupFirebaseListeners();

    setState(() => _loading = false);
  }

  Future<void> _refreshAndSaveFcmToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseMessaging.instance.deleteToken();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('EmpProfile')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
        debugPrint('✅ FCM token refreshed and saved: $token');
      }
    } catch (e) {
      debugPrint('❌ Token update error: $e');
    }
  }

  void _setupTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('EmpProfile')
            .doc(user.uid)
            .set({'fcmToken': token}, SetOptions(merge: true));
        debugPrint('🔁 FCM token auto-refreshed: $token');
      }
    });
  }

  Future<void> _checkAndStoreProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final empId = doc['empId']?.toString() ?? '';
    final categories = doc['categories'];
    final catString = (categories is List)
        ? (categories as List).join(',')
        : categories.toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('empId', empId);
    await prefs.setString('categories', catString);
    debugPrint('✅ Profile saved: empId=$empId, categories=$catString');
  }

  void setupFirebaseListeners() {
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('📥 Foreground message: ${msg.data}');
      _handleNotification(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) async {
      debugPrint('📲 Opened from background notification');
      final dept = msg.data['department']?.toString() ?? '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('targetDepartment', dept);
      navigatorKey.currentState?.pushNamed('/Categoryscreen');
    });

    FirebaseMessaging.instance.getInitialMessage().then((msg) async {
      if (msg != null) {
        debugPrint('🚀 Launched via notification');
        await _handleNotification(msg, isFromBackground: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Techlead',
      theme: Provider.of<ThemeProvider>(context).currentTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/Categoryscreen': (_) => const Categoryscreen(),
      },
    );
  }
}

Future<void> _handleNotification(RemoteMessage message,
    {bool isFromBackground = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('❌ No user logged in.');
    return;
  }

  final profile = await FirebaseFirestore.instance
      .collection('EmpProfile')
      .doc(user.uid)
      .get();
  if (!profile.exists) {
    debugPrint('❌ Profile not found.');
    return;
  }

  final currentEmp = profile['empId']?.toString().trim() ?? '';
  final catsRaw = profile['categories'];
  final currentCats = (catsRaw is List)
      ? catsRaw.map((e) => e.toString().trim()).toList()
      : <String>[];

  final data = message.data;
  final taskId = data['taskId']?.toString() ?? '';
  final dept = data['department']?.toString().trim() ?? '';
  final empIdsRaw = data['empIds']?.toString() ?? '';
  final targets = empIdsRaw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final empMatch = targets.contains(currentEmp);
  final deptMatch = targets.isEmpty && currentCats.contains(dept);

  debugPrint('👤 currentEmpId=$currentEmp');
  debugPrint('🎯 targetEmpIds=$targets');
  debugPrint('🏷 department=$dept');
  debugPrint('📂 currentCategories=$currentCats');
  debugPrint('➡️ empMatch=$empMatch, deptMatch=$deptMatch');

  if (!empMatch && !deptMatch) {
    debugPrint('⛔ Not a target – skipping.');
    return;
  }

  final title = message.notification?.title ?? 'New Task';
  final body = message.notification?.body ?? 'You have a new task.';

  if (dept.isNotEmpty && dept.contains(RegExp(r'[A-Za-z]'))) {
    prefs.setString('targetDepartment', dept);
    debugPrint('✅ Department saved: $dept');
  }

  if (title.isNotEmpty) {
    prefs.setString('notificationTitle', title);
  }

  await _showLocalNotification(taskId, title, body, dept);

  if (!isFromBackground && navigatorKey.currentContext != null) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(content: Text('$title\n$body'), backgroundColor: Colors.green),
    );
  }
}

Future<void> _showLocalNotification(
    String taskId, String title, String body, String payload) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'task_$taskId';
  if (prefs.getBool(key) ?? false) return;
  prefs.setBool(key, true);

  await flutterLocalNotificationsPlugin.show(
    taskId.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Task Notifications',
        channelDescription: 'For task updates',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: payload,
  );
}
