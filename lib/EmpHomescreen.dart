import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/taskreportpage.dart';
import 'Attendacescreen.dart';
import 'Calendarscreen.dart';
import 'Categoryscreen.dart';
import 'Leavescreen.dart';
import 'Taskdeatils.dart';
import 'Profilescreen.dart';
import 'Supportscreen.dart';
import 'Teammemberslist.dart';
import 'Themeprovider.dart';
import 'inhome.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int totalTasks = 0;
  int inProgress = 0;
  String? userDepartment;
  int pendingTasks = 0;
  double totalWorkingHours = 0;
  double performancePercentage = 0;
  int totalEmployees = 1;
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  int _unreadNotifications = 0;
  bool _isNavigating = false;
  StreamSubscription? _taskSubscription;
  StreamSubscription? _attendanceSubscription;
  StreamSubscription? _empProfileSubscription;
  List<String> userDepartments = [];
  String todayWorkingStatus = "Absent";
  int todayWorkingHours = 0;
  int todayWorkingMinutes = 0;
  String? profileImageUrl;
  String? fullName;
  Color todayStatusColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _initializeStats();
    _setupRealtimeListeners();
    _initializeNotifications();
    _loadProfile();
  }

  Future<void> _initializeStats() async {
    await _fetchUserDepartments();
    await _fetchDepartmentStats(userDepartments);
    await _fetchOverallStats();
    await _fetchUnreadNotifications();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _attendanceSubscription?.cancel();
    _empProfileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      setState(() {
        profileImageUrl = doc['profileImage'];
        fullName = doc['fullName'];
      });
    }
  }

  void _setupRealtimeListeners() async {
    await _fetchUserDepartments();

    _taskSubscription = _firestore.collection('DailyTaskReport').snapshots().listen((snapshot) {
      _fetchDepartmentStats(userDepartments);
      _fetchOverallStats();
    });

    _attendanceSubscription = _firestore.collection('Attendance').snapshots().listen((snapshot) {
      _fetchOverallStats();
    });

    _empProfileSubscription = _firestore.collection('EmpProfile').snapshots().listen((snapshot) {
      _fetchUnreadNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          navigatorKey.currentState?.pushNamed('/Categoryscreen', arguments: response.payload);
        }
      },
    );

    FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(
        message.notification?.title ?? "New Task",
        message.data['category'] ?? "/Categoryscreen",
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.containsKey('category')) {
        navigatorKey.currentState?.pushNamed('/Categoryscreen', arguments: message.data['category']);
      }
    });
  }

  Future<void> _showNotification(String title, String category) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'Task Assign Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      "Click to view details",
      platformChannelSpecifics,
      payload: category,
    );
  }

  void checkTaskAssignment(List<String> categories) async {
    QuerySnapshot taskSnapshot = await _firestore.collection('TaskAssign').get();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var doc in taskSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String docId = doc.id;

      if (prefs.getBool('task_\$docId') == true) continue;
      if (!data.containsKey('department')) continue;

      if (categories.contains(data['department'])) {
        _showNotification("New Task Assigned", "You have a new assigned task!");
        prefs.setBool('task_\$docId', true);
        break;
      }
    }
  }

  void checkTaskAssignment2(String empId) async {
    QuerySnapshot taskSnapshot = await _firestore.collection('TaskAssign').get();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var doc in taskSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String docId = doc.id;

      if (prefs.getBool('task_\$docId') == true) continue;
      if (!data.containsKey('empIds')) continue;

      if ((data['empIds'] as List).contains(empId)) {
        _showNotification("New Task Assigned", "You have a new assigned task!");
        prefs.setBool('task_\$docId', true);
        break;
      }
    }
  }


  Future<void> _fetchUserDepartments() async {
    if (userId == null) return;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('EmpProfile').doc(userId).get();
      if (doc.exists) {
        List<String> departments = List<String>.from(doc['categories'] ?? []);
        setState(() {
          userDepartments = departments;
        });
        print('Fetched user departments: $userDepartments');
      }
    } catch (e) {
      print("Error fetching user departments: $e");
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    if (userId == null) return;

    QuerySnapshot snapshot = await _firestore
        .collection('EmpProfile')
        .where('read', isEqualTo: false)
        .get();

    setState(() {
      _unreadNotifications = snapshot.docs.length;
    });
  }

  Future<void> _markNotificationsAsRead() async {
    if (userId == null) return;
    QuerySnapshot snapshot = await _firestore.collection('EmpProfile').get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }

    setState(() {
      _unreadNotifications = 0;
    });
  }

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _fetchDepartmentStats(List<String> departments) async {
    try {
      int completed = 0, pending = 0, inProgressCount = 0;

      if (departments.isEmpty) {
        print('No departments provided.');
        return;
      }

      final DateTime now = DateTime.now();
      final DateTime monthStart = DateTime(now.year, now.month, 1);
      final DateTime monthEnd = DateTime(now.year, now.month + 1, 1);

      // 2) Loop over each status and accumulate counts
      for (String status in ['Completed', 'Pending', 'In Progress']) {
        int totalCount = 0;

        // Firestore ".where(..., whereIn: chunk)" can only take up to 10 values at a time:
        for (int i = 0; i < departments.length; i += 10) {
          List<String> chunk = departments.sublist(
            i,
            (i + 10 > departments.length) ? departments.length : i + 10,
          );

          // A) Try querying by 'category' field first:
          QuerySnapshot snapshot = await _firestore
              .collection('DailyTaskReport')
              .where('service_status', isEqualTo: status)
              .where('category', whereIn: chunk)
              .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
              .where('date', isLessThan: Timestamp.fromDate(monthEnd))
              .get();

          // B) If none found under 'category', retry under 'Service_department':
          if (snapshot.docs.isEmpty) {
            snapshot = await _firestore
                .collection('DailyTaskReport')
                .where('service_status', isEqualTo: status)
                .where('Service_department', whereIn: chunk)
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
                .where('date', isLessThan: Timestamp.fromDate(monthEnd))
                .get();
          }

          totalCount += snapshot.docs.length;
        }

        if (status == 'Completed') {
          completed = totalCount;
        } else if (status == 'Pending') {
          pending = totalCount;
        } else if (status == 'In Progress') {
          inProgressCount = totalCount;
        }
      }

      setState(() {
        totalTasks = completed;
        pendingTasks = pending;
        inProgress = inProgressCount;
      });

      print('Current Month (${DateFormat('MMMM yyyy').format(monthStart)}) → '
          'Completed: $completed, Pending: $pending, In Progress: $inProgressCount');
    }
    catch (e) {
      print('Error fetching department stats: $e');
    }
  }


  Future<void> _fetchOverallStats() async {
    try {
      QuerySnapshot attendanceSnapshot =
      await _firestore.collection('Attendance').get();
      QuerySnapshot empSnapshot =
      await _firestore.collection('EmpProfile').get();

      int employeeCount = empSnapshot.docs.length;
      int completedTasks = 0, pendingTasksCount = 0, inProgressCount = 0;

      if (userDepartments.isNotEmpty) {
        for (String status in ['Completed', 'Pending', 'In Progress']) {
          int statusCount = 0;

          for (int i = 0; i < userDepartments.length; i += 10) {
            List<String> chunk = userDepartments.sublist(
              i,
              i + 10 > userDepartments.length ? userDepartments.length : i + 10,
            );

            QuerySnapshot snapshot = await _firestore
                .collection('DailyTaskReport')
                .where('service_status', isEqualTo: status)
                .where('category', whereIn: chunk)
                .get();

            if (snapshot.docs.isEmpty) {
              snapshot = await _firestore
                  .collection('DailyTaskReport')
                  .where('service_status', isEqualTo: status)
                  .where('Service_department', whereIn: chunk)
                  .get();
            }

            statusCount += snapshot.docs.length;
          }

          if (status == 'Completed') completedTasks = statusCount;
          if (status == 'Pending') pendingTasksCount = statusCount;
          if (status == 'In Progress') inProgressCount = statusCount;
        }
      }

      int totalDays = 0, fullDays = 0, halfDays = 0, absentDays = 0;
      double totalHours = 0;

      final now = DateTime.now();
      String todayStr =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      Map<String, Map<String, dynamic>> attendanceByUserDate = {};

      for (var doc in attendanceSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null &&
            data.containsKey('record') &&
            data.containsKey('userId') &&
            data.containsKey('date')) {
          String key = "${data['userId']}_${data['date']}";
          if (!attendanceByUserDate.containsKey(key)) {
            attendanceByUserDate[key] = data;
          }
        }
      }

      for (var data in attendanceByUserDate.values) {
        List<String> parts = data['record'].toString().split(' ');
        int hours = int.tryParse(parts[0]) ?? 0;
        int minutes = int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
        double workedHours = hours + (minutes / 60);
        totalHours += workedHours;

        String date = data['date'];
        String userId = data['userId'];

        if (date == todayStr && userId == currentUserId) {
          todayWorkingHours = hours;
          todayWorkingMinutes = minutes;

          if (workedHours < 4) {
            todayWorkingStatus = "Absent";
            todayStatusColor = Colors.red;
          } else if (workedHours < 8) {
            todayWorkingStatus = "Half Day";
            todayStatusColor = Colors.orange;
          } else {
            todayWorkingStatus = "Full Day";
            todayStatusColor = Colors.green;
          }
        }

        if (workedHours >= 8.0) {
          fullDays++;
        } else if (workedHours >= 4.0) {
          halfDays++;
        } else {
          absentDays++;
        }

        totalDays++;
      }

      double avgWorkingHours =
          totalHours / (employeeCount > 0 ? employeeCount : 1);
      double fullDayPercentage =
          (fullDays / (totalDays > 0 ? totalDays : 1)) * 100;
      double halfDayPercentage =
          (halfDays / (totalDays > 0 ? totalDays : 1)) * 50;
      double overallPerformance =
          (fullDayPercentage + halfDayPercentage + (completedTasks * 2)) / 3;

      setState(() {
        totalWorkingHours = totalHours;
        performancePercentage = overallPerformance;
        totalEmployees = employeeCount;
        todayWorkingHours = todayWorkingHours;
        todayWorkingMinutes = todayWorkingMinutes;
        todayWorkingStatus = todayWorkingStatus;
        todayStatusColor = todayStatusColor;
      });

      print('Employee count: $employeeCount, Performance: $overallPerformance');
    } catch (e) {
      print('Error fetching overall stats: $e');
    }
  }

  void _onCardTapped(String label) async {
    if (label == "Working Hours" || label == "Performance Rating") {
      List<Widget> content = [];

      try {
        final today = DateTime.now();
        final String todayStr =
            "${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}";

        if (label == "Working Hours") {
          QuerySnapshot snapshot = await _firestore
              .collection('Attendance')
              .where('userId', isEqualTo: currentUserId)
              .where('date', isEqualTo: todayStr)
              .get();

          if (snapshot.docs.isEmpty) {
            content.add(const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(
                child: Text(
                  "No attendance record for today",
                  style: TextStyle(fontFamily: 'Times New Roman', fontSize: 16),
                ),
              ),
            ));
          } else {
            int index = 1;
            for (var doc in snapshot.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String recordTime = data['record'] ?? '0 Hrs 0 Min';

              content.add(
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      '$index',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Times New Roman'),
                    ),
                  ),
                  title: Text(
                    data['employeeName'] ?? 'Unknown',
                    style: const TextStyle(fontFamily: 'Times New Roman'),
                  ),
                  subtitle: Text(
                    "Today’s working time: $recordTime",
                    style: const TextStyle(fontFamily: 'Times New Roman'),
                  ),
                ),
              );
              index++;
            }
          }
        } else if (label == "Performance Rating") {
          content.add(
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Performance is calculated as:\n"
                    "• Full Day = 100%\n"
                    "• Half Day = 50%\n"
                    "• Completed Task = 2 Points\n\n"
                    "Combined Score = Avg of all.",
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          );
        }

        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE0F0FF), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: content.isNotEmpty
                        ? ListView(children: content)
                        : const Center(
                      child: Text(
                        "No data found",
                        style: TextStyle(fontFamily: 'Times New Roman', fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } catch (e) {
        print("Error loading dialog data for $label: $e");
      }


  } else if (["Pending Tasks", "InProgress Tasks", "Completed Tasks"].contains(label)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TaskDetailsScreen(label: label, userDepartments: userDepartments),
        ),
      );
    } else if (label == "Team Members") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeamMembersScreen(userDepartments: userDepartments),
        ),
      );
    }
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Icon(icon, size: 40, color: Colors.blue),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: 5,
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard2({
    required IconData icon,
    required String label,
    required int hours,
    required int minutes,
    required String status,
    required VoidCallback onTap,
  }) {
    // Choose color based on status
    Color valueColor;
    if (status == "Full Day") {
      valueColor = Colors.green;
    } else if (status == "Half Day") {
      valueColor = Colors.orange;
    } else {
      valueColor = Colors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Icon(icon, size: 40, color: valueColor),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                "$hours Hrs $minutes Min\n$status",
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text("Employee Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D47A1),
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 40),
              Center(
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 55,
                  backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  fullName ?? 'Techlead The Engineering Solution!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: "Times New Roman",
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(thickness: 1,color: Colors.cyan,),
              SizedBox(height: 10,),
              _buildDrawerTile(
                icon: Icons.calendar_today,
                label: 'Calendar Screen',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Calendarscreen()),
                  );
                },
              ),
              _buildDrawerTile(
                icon: Icons.note_alt,
                label: 'Leave Form',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Leavescreen()),
                  );
                },
              ),
              _buildDrawerTile(
                icon: Icons.report,
                label: 'Daily Task Report',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DailyTaskReport2()),
                  );
                },
              ),
              _buildDrawerTile(
                icon: Icons.sunny_snowing,
                label: 'Theme',
                onTap: () {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text('Dashboard Metrics',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDashboardCard2(
                    icon: Icons.access_time,
                    label: "Working Hours",
                    hours: todayWorkingHours,
                    minutes: todayWorkingMinutes,
                    status: todayWorkingStatus,
                    onTap: () => _onCardTapped("Working Hours"),
                  ),
                  _buildDashboardCard(
                    icon: Icons.pending,
                    label: "Pending Tasks",
                    value: "$pendingTasks",
                    onTap: () => _onCardTapped("Pending Tasks"),
                  ),
                  _buildDashboardCard(
                    icon: Icons.production_quantity_limits,
                    label: "InProgress Tasks",
                    value: "$inProgress",
                    onTap: () => _onCardTapped("InProgress Tasks"),
                  ),
                  _buildDashboardCard(
                    icon: Icons.task_alt,
                    label: "Completed Tasks",
                    value: "$totalTasks",
                    onTap: () => _onCardTapped("Completed Tasks"),
                  ),
                  _buildDashboardCard(
                    icon: Icons.group,
                    label: "Team Members",
                    value: "$totalEmployees",
                    onTap: () => _onCardTapped("Team Members"),
                  ),
                  _buildDashboardCard(
                    icon: Icons.thumb_up,
                    label: "Performance Rating",
                    value: "${performancePercentage.toStringAsFixed(1)}%",
                    onTap: () => _onCardTapped("Performance Rating"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.home,
                label: 'Home',
                onTap: () {
                  if (ModalRoute.of(context)?.settings.name != 'HomeScreen') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                        settings: RouteSettings(name: 'HomeScreen'),
                      ),
                    );
                  }
                },
              ),
              _buildBottomNavItem(
                icon: Icons.calendar_today,
                label: 'Attendance',
                onTap: () {
                  if (ModalRoute.of(context)?.settings.name !=
                      'Attendancescreen') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Attendancescreen(),
                        settings: RouteSettings(name: 'Attendancescreen'),
                      ),
                    );
                  }
                },
              ),
              BottomNavItemWithBadge(
                icon: Icons.category,
                label: 'Category',
                badgeCount: _unreadNotifications,
                onTap: () async {
                  if (ModalRoute.of(context)?.settings.name !=
                      'CategoryScreen') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Categoryscreen(),
                        settings: const RouteSettings(name: 'CategoryScreen'),
                      ),
                    );
                    await _markNotificationsAsRead(); // Await properly
                  }
                },
              ),
              _buildBottomNavItem(
                icon: Icons.support_agent,
                label: 'Support',
                onTap: () {
                  if (ModalRoute.of(context)?.settings.name != 'ContactUs') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContactUs(),
                        settings: RouteSettings(name: 'ContactUs'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Positioned(
          top: -30,
          left: MediaQuery.of(context).size.width / 2 - 35,
          child: FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(category: '', userId: userId ?? ''),
                  settings: RouteSettings(name: 'ProfileScreen'),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, color: Colors.white),
                Text('Profile',
                    style: TextStyle(fontSize: 10, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        setState(() => _isNavigating = true);
        onTap();
        setState(() => _isNavigating = false);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.deepPurple),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavItemWithBadge extends StatefulWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final Future<void> Function() onTap;

  const BottomNavItemWithBadge({
    Key? key,
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BottomNavItemWithBadge> createState() => _BottomNavItemWithBadgeState();
}

class _BottomNavItemWithBadgeState extends State<BottomNavItemWithBadge> {
  bool _isNavigating = false;

  Future<void> _handleTap() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Icon(widget.icon, color: Colors.deepPurple),
              if (widget.badgeCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.badgeCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.deepPurple,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildDrawerTile({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: Colors.white),
    title: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    onTap: onTap,
    hoverColor: Colors.white24,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
  );
}
