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
import 'Default/Themeprovider.dart';
import 'Employee/Categoryscreen/categoryscreen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _handleNotification(message, isFromBackground: true);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const AndroidInitializationSettings androidInitSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidInitSettings);


  runApp(
    riverpod.ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    ),
  );
}

void setupFlutterNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('targetDepartment', payload);
        navigatorKey.currentState?.pushNamed('/Categoryscreen');
      }
    },
  );
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  final data = message.data;
  final taskId = data['taskId'] ?? '';
  final title = message.notification?.title ?? 'New Task';
  final body = message.notification?.body ?? 'Check your task details';

  final prefs = await SharedPreferences.getInstance();
  final taskKey = 'task_$taskId';
  if (prefs.getBool(taskKey) ?? false) return;
  await prefs.setBool(taskKey, true);

  await flutterLocalNotificationsPlugin.show(
    taskId.hashCode,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Task Notifications',
        channelDescription: 'Task Updates',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: data['department'] ?? '',
  );
}

Future<void> _handleNotification(RemoteMessage message, {bool isFromBackground = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    debugPrint('❌ No Firebase user logged in');
    return;
  }

  final profileSnapshot = await FirebaseFirestore.instance
      .collection('EmpProfile')
      .doc(user.uid)
      .get();

  if (!profileSnapshot.exists) {
    debugPrint('❌ No employee profile found');
    return;
  }

  final currentEmpId = profileSnapshot['empId']?.toString().trim() ?? '';
  final categoriesRaw = profileSnapshot['categories'];
  final currentCategories = (categoriesRaw is List)
      ? categoriesRaw.map((e) => e.toString().trim()).toList()
      : [];

  final data = message.data;
  final taskId = data['taskId'] ?? '';
  final deptFromMessage = data['department']?.toString().trim() ?? '';
  final empIdsRaw = data['empIds'] ?? '';
  final targetEmpIds = empIdsRaw
      .toString()
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  final isEmpTargeted = targetEmpIds.contains(currentEmpId);
  final isDeptTargeted = targetEmpIds.isEmpty && currentCategories.contains(deptFromMessage);

  debugPrint('🔎 currentEmpId: $currentEmpId');
  debugPrint('🔎 targetEmpIds: $targetEmpIds');
  debugPrint('🔎 deptFromMessage: $deptFromMessage');
  debugPrint('🔎 currentCategories: $currentCategories');
  debugPrint('🔍 isEmpTargeted: $isEmpTargeted');
  debugPrint('🔍 isDeptTargeted: $isDeptTargeted');

  if (!(isEmpTargeted || isDeptTargeted)) {
    debugPrint('⛔ User not targeted – notification blocked');
    return;
  }

  final title = message.notification?.title ?? 'New Task';
  final body = message.notification?.body ?? 'Check your task details';

  if (deptFromMessage.isNotEmpty && deptFromMessage.contains(RegExp(r'[A-Za-z]'))) {
    await prefs.setString('targetDepartment', deptFromMessage);
    debugPrint('✅ Saved valid department: $deptFromMessage');
  } else {
    debugPrint('⛔ Invalid department value: $deptFromMessage');
  }

  if (title.isNotEmpty) {
    await prefs.setString('notificationTitle', title);
  }

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
    payload: taskId,
  );

  if (!isFromBackground && navigatorKey.currentContext != null) {
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('$title\n$body'),
        backgroundColor: Colors.green,
      ),
    );
  }

  await _showLocalNotification(message);
}



void initializeFirebaseMessageListener() {
  FirebaseMessaging.onMessage.listen((message) {
    debugPrint('📥 Foreground FCM: ${message.data}');
    _handleNotification(message);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((message) async {
    debugPrint('📲 Opened from background FCM');
    final dept = message.data['department'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('targetDepartment', dept);
    navigatorKey.currentState?.pushNamed('/Categoryscreen');
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) async {
    if (message != null) {
      debugPrint('🚀 App launched via FCM');
      await _handleNotification(message, isFromBackground: true);
    }
  });
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
    setupFlutterNotifications();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkAndStoreProfile();
    initializeFirebaseMessageListener();
    setState(() => _loading = false);
  }

  Future<void> _checkAndStoreProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(user.uid)
        .get();
    if (!doc.exists) return;

    final empId = doc['empId'] ?? '';
    final categories = doc['categories'];
    final categoryString = (categories is List)
        ? categories.join(',')
        : categories.toString();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('empId', empId);
    await prefs.setString('categories', categoryString);

    debugPrint('✅ Profile loaded: empId=$empId, categories=$categoryString');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Techlead',
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/Categoryscreen': (context) => Categoryscreen(),
      },
    );
  }
}
