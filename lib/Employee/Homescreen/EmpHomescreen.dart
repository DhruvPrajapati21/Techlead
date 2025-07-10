import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Employee/Homescreen/taskreportpage.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import '../../core/app_bar_provider.dart';
import '../Attendacescreen/Attendacescreen.dart';
import 'Calendarscreen.dart';
import '../Categoryscreen/Categoryscreen.dart';
import 'Home_Screen_Bottom_code/home_screen_bottom_code.dart';
import 'Leavescreen.dart';
import 'Taskdeatils.dart';
import '../Profilescreen/Profilescreen.dart';
import '../Supportscreen/Supportscreen.dart';
import 'Teammemberslist.dart';
import '../../Default/Themeprovider.dart';
import '../Categoryscreen/Installation/installationhome.dart';
import 'Viewguildlines.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final int cardCount = 6;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  List<Widget> get _screens => [
        _buildHomeScreenContent(),
        Attendancescreen(),
        Categoryscreen(),
        ContactUs(),
        ProfileScreen(category: '', userId: userId ?? ''),
      ];

  int _currentIndex = 0;
  int profileIndex = 4;

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
  String todayWorkingStatus = "No Attendance Today";
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
    _loadProfile();
    _listenToUnreadNotifications();

    _controllers = List.generate(
      cardCount,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      );
    }).toList();

    _startStaggeredAnimation();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appBarTitleProvider.notifier).state = "Your Task Dashboard";

      ref.read(appBarGradientColorsProvider.notifier).state = [
        const Color(0xFF283593),
        const Color(0xFF1E88E5), // Blue shade
      ];
    });
  }

  Future<void> _startStaggeredAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      _controllers[i].forward();
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.exit_to_app, color: Colors.blueAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exit Techlead App?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: "Times New Roman",
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit?',
          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Exit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Future<void> _initializeStats() async {
    await _fetchUserDepartments();
    await _fetchDepartmentStats(userDepartments);
    await _fetchOverallStats();
    _listenToUnreadNotifications();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _attendanceSubscription?.cancel();
    _empProfileSubscription?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildAnimatedCard(int index, Widget child) {
    return ScaleTransition(
      scale: _animations[index],
      child: FadeTransition(
        opacity: _animations[index],
        child: child,
      ),
    );
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

    _taskSubscription =
        _firestore.collection('DailyTaskReport').snapshots().listen((snapshot) {
      _fetchDepartmentStats(userDepartments);
      _fetchOverallStats();
    });

    _attendanceSubscription =
        _firestore.collection('Attendance').snapshots().listen((snapshot) {
      _fetchOverallStats();
    });

    _empProfileSubscription =
        _firestore.collection('EmpProfile').snapshots().listen((snapshot) {
      _listenToUnreadNotifications();
    });
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

  void _listenToUnreadNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final uid = currentUser.uid;

    FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(uid)
        .snapshots()
        .listen((profileDoc) async {
      if (!profileDoc.exists) {
        print("⚠️ No EmpProfile found. Setting unread count to 0.");
        if (mounted) {
          setState(() {
            _unreadNotifications = 0;
          });
        }
        return;
      }

      final profileData = profileDoc.data();
      if (profileData == null) return;

      final empId = profileData['empId']?.toString().trim() ?? '';
      final department = (profileData['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      print(
          "✅ Listening for notifications assigned to empId: $empId and departments: $department");

      FirebaseFirestore.instance
          .collection('TaskAssign')
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((taskSnapshot) {
        final unreadDocs = taskSnapshot.docs.where((doc) {
          final data = doc.data();

          final empIdsRaw = data['empIds'] ?? '';
          final empIds = empIdsRaw
              .toString()
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          final taskDepartment = data['department']?.toString().trim() ?? '';

          final bool isEmpIdMatched = empIds.contains(empId);
          final bool isDepartmentMatched = department.contains(taskDepartment);
          final bool matched = isEmpIdMatched && isDepartmentMatched;

          print(
              "🎯 CHECK MATCH:\n🔸 empIds=$empIds\n🔸 empId=$empId\n🔸 taskDepartment=$taskDepartment\n🔸 userDepartments=$department\n🔸 matched=$matched");

          return matched;
        }).toList();

        print(
            "🔔 Total matched unread tasks (empId + department): ${unreadDocs.length}");

        if (mounted) {
          setState(() {
            _unreadNotifications = unreadDocs.length;
          });
        }
      });
    });
  }

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  Future<void> _fetchDepartmentStats(List<String> departments) async {
    try {
      final profileDoc =
          await _firestore.collection('EmpProfile').doc(currentUserId).get();

      if (!profileDoc.exists || profileDoc.data() == null) {
        print("⚠️ EmpProfile not found for user. Skipping department stats.");
        setState(() {
          totalTasks = 0;
          pendingTasks = 0;
          inProgress = 0;
        });
        return;
      }

      final empId = profileDoc.get('empId') ?? '';
      if (empId.isEmpty) {
        print("⚠️ empId is empty. Skipping user-specific stats.");
        return;
      }

      final DateTime now = DateTime.now();
      final DateTime monthStart = DateTime(now.year, now.month, 1);
      final DateTime monthEnd = DateTime(now.year, now.month + 1, 1);

      int completed = 0, pending = 0, inProgressCount = 0;

      for (String status in ['Completed', 'Pending', 'In Progress']) {
        int totalCount = 0;

        for (int i = 0; i < departments.length; i += 10) {
          List<String> chunk = departments.sublist(
            i,
            (i + 10 > departments.length) ? departments.length : i + 10,
          );

          QuerySnapshot snapshot = await _firestore
              .collection('DailyTaskReport')
              .where('employeeId', isEqualTo: empId)
              .where('service_status', isEqualTo: status)
              .where('Service_department', whereIn: chunk)
              .where('date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
              .where('date', isLessThan: Timestamp.fromDate(monthEnd))
              .get();

          if (snapshot.docs.isEmpty) {
            snapshot = await _firestore
                .collection('DailyTaskReport')
                .where('employeeId', isEqualTo: empId)
                .where('service_status', isEqualTo: status)
                .where('Service_department', whereIn: chunk)
                .where('date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
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

      print(
          '📊 Stats for $empId (${DateFormat('MMMM yyyy').format(monthStart)}) → '
          'Completed: $completed, Pending: $pending, In Progress: $inProgressCount');
    } catch (e) {
      print('❌ Error fetching department stats: $e');
    }
  }

  Future<void> _fetchOverallStats() async {
    try {
      final profileDoc =
      await _firestore.collection('EmpProfile').doc(currentUserId).get();

      if (!profileDoc.exists) {
        print("⚠️ EmpProfile not found for user. Skipping overall stats.");
        setState(() {
          totalWorkingHours = 0;
          performancePercentage = 0;
          totalEmployees = 0;
          todayWorkingHours = 0;
          todayWorkingMinutes = 0;
          todayWorkingStatus = "No Record of User";
          todayStatusColor = Colors.grey;
        });
        return;
      }

      final empId = profileDoc.get('empId') ?? '';
      if (empId.isEmpty) {
        print("⚠️ empId is empty. Skipping user-specific stats.");
        return;
      }

      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('Attendance')
          .where('userId', isEqualTo: currentUserId)
          .get();

      QuerySnapshot empSnapshot =
      await _firestore.collection('EmpProfile').get();
      int employeeCount = empSnapshot.docs.length;

      int completedTasks = 0, pendingTasksCount = 0, inProgressCount = 0;

      final now = DateTime.now();
      int currentMonth = now.month;
      int currentYear = now.year;
      String todayStr =
          "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";

      // 🔄 Filter task reports for current month only
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
                .where('employeeId', isEqualTo: empId)
                .where('category', whereIn: chunk)
                .get();

            if (snapshot.docs.isEmpty) {
              snapshot = await _firestore
                  .collection('DailyTaskReport')
                  .where('service_status', isEqualTo: status)
                  .where('employeeId', isEqualTo: empId)
                  .where('Service_department', whereIn: chunk)
                  .get();
            }

            // ⏱️ Filter current month tasks only
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data.containsKey('date')) {
                try {
                  final parts = data['date'].toString().split('/');
                  int m = int.tryParse(parts[1]) ?? 0;
                  int y = int.tryParse(parts[2]) ?? 0;
                  if (m == currentMonth && y == currentYear) {
                    statusCount++;
                  }
                } catch (e) {
                  continue; // skip invalid date formats
                }
              }
            }
          }

          if (status == 'Completed') completedTasks = statusCount;
          if (status == 'Pending') pendingTasksCount = statusCount;
          if (status == 'In Progress') inProgressCount = statusCount;
        }
      }

      int totalDays = 0, fullDays = 0, halfDays = 0, absentDays = 0;
      double totalHours = 0;

      for (var doc in attendanceSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null &&
            data.containsKey('record') &&
            data.containsKey('date')) {
          List<String> dateParts = data['date'].toString().split('/');
          if (dateParts.length != 3) continue;

          int day = int.tryParse(dateParts[0]) ?? 0;
          int month = int.tryParse(dateParts[1]) ?? 0;
          int year = int.tryParse(dateParts[2]) ?? 0;

          if (month != currentMonth || year != currentYear) continue;

          List<String> parts = data['record'].toString().split(' ');
          int hours = int.tryParse(parts[0]) ?? 0;
          int minutes = int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0;
          double workedHours = hours + (minutes / 60);
          totalHours += workedHours;

          String date = data['date'];

          if (date == todayStr) {
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
      }

      double fullDayPercentage =
          (fullDays / (totalDays > 0 ? totalDays : 1)) * 100;
      double halfDayPercentage =
          (halfDays / (totalDays > 0 ? totalDays : 1)) * 50;
      double overallPerformance =
          (fullDayPercentage + halfDayPercentage + (completedTasks * 2)) / 3;

      if (fullDays == 0 && halfDays == 0 && completedTasks == 0) {
        overallPerformance = 0;
      }

      setState(() {
        totalWorkingHours = totalHours;
        performancePercentage = overallPerformance;
        totalEmployees = employeeCount;
        todayWorkingHours = todayWorkingHours;
        todayWorkingMinutes = todayWorkingMinutes;
        todayWorkingStatus = todayWorkingStatus;
        todayStatusColor = todayStatusColor;
      });

      print('📊 Performance for $empId → $overallPerformance');
    } catch (e) {
      print('❌ Error fetching overall stats: $e');
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
                      style: const TextStyle(
                          color: Colors.white, fontFamily: 'Times New Roman'),
                    ),
                  ),
                  title: Text(
                    data['employeeName'] ?? 'Unknown',
                    style: const TextStyle(
                        fontFamily: 'Times New Roman', color: Colors.white),
                  ),
                  subtitle: Text(
                    "Today’s working time: $recordTime",
                    style: const TextStyle(
                        fontFamily: 'Times New Roman', color: Colors.white),
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
                "Combined Score = Avg of all\n\n"
                "Current Performance rating based on visits in the current month.",
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF000F89),
                    Color(0xFF0F52BA),
                    Color(0xFF002147)
                  ],
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
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
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
                              style: TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
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
    } else if (["Pending Tasks", "InProgress Tasks", "Completed Tasks"]
        .contains(label)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TaskDetailsScreen(label: label, userDepartments: userDepartments),
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
          gradient: LinearGradient(
            colors: [
              Color(0xFF000F89),
              Color(0xFF0F52BA),
              Color(0xFF002147),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: Icon(icon, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: "Times New Roman",
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: "Times New Roman"),
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
    Color valueColor;
    List<Color> gradientColors;

    if (status == "Full Day") {
      valueColor = Colors.green;
      gradientColors = [Color(0xFF43A047), Color(0xFF66BB6A)];
    } else if (status == "Half Day") {
      valueColor = Colors.orange;
      gradientColors = [Color(0xFFF57C00), Color(0xFFFFA726)];
    } else {
      valueColor = Colors.red;
      gradientColors = [Color(0xFFD32F2F), Color(0xFFEF5350)];
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: valueColor.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  border: Border.all(color: Colors.white24, width: 1.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                    fontFamily: "Times New Roman"),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                "$hours Hrs $minutes Min",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Times New Roman",
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.95),
                    fontFamily: "Times New Roman"),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreenContent() {
    return Padding(
      padding: const EdgeInsets.only(top: 35),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF004FF9),
              Color(0xFF000000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    SizedBox(
                      width: 6,
                    ),
                    const Text(
                      'Dashboard Metrics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Times New Roman",
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 45),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 600 ? 2 : 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildAnimatedCard(
                        0,
                        _buildDashboardCard2(
                          icon: Icons.access_time,
                          label: "Working Hours",
                          hours: todayWorkingHours,
                          minutes: todayWorkingMinutes,
                          status: todayWorkingStatus,
                          onTap: () => _onCardTapped("Working Hours"),
                        )),
                    _buildAnimatedCard(
                        1,
                        _buildDashboardCard(
                          icon: Icons.pending,
                          label: "Pending Tasks",
                          value: "$pendingTasks",
                          onTap: () => _onCardTapped("Pending Tasks"),
                        )),
                    _buildAnimatedCard(
                        2,
                        _buildDashboardCard(
                          icon: Icons.production_quantity_limits,
                          label: "InProgress Tasks",
                          value: "$inProgress",
                          onTap: () => _onCardTapped("InProgress Tasks"),
                        )),
                    _buildAnimatedCard(
                        3,
                        _buildDashboardCard(
                          icon: Icons.task_alt,
                          label: "Completed Tasks",
                          value: "$totalTasks",
                          onTap: () => _onCardTapped("Completed Tasks"),
                        )),
                    _buildAnimatedCard(
                        4,
                        _buildDashboardCard(
                          icon: Icons.group,
                          label: "Team Members",
                          value: "$totalEmployees",
                          onTap: () => _onCardTapped("Team Members"),
                        )),
                    _buildAnimatedCard(
                        5,
                        _buildDashboardCard(
                          icon: Icons.thumb_up,
                          label: "Performance Rating",
                          value: "${performancePercentage.toStringAsFixed(1)}%",
                          onTap: () => _onCardTapped("Performance Rating"),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<DocumentSnapshot> getProfileStream(String uid) {
    return FirebaseFirestore.instance
        .collection('EmpProfile')
        .doc(uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
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
            child: user == null
                ? const Center(
              child: Text(
                "Not logged in",
                style: TextStyle(color: Colors.white),
              ),
            )
                : StreamBuilder<DocumentSnapshot>(
                stream: getProfileStream(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                        "No profile found",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final profileImageUrl = data['profileImage']?.toString() ?? '';
                  final fullName = data['fullName']?.toString() ??
                      'Techlead The Engineering Solution!';

                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 55,
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.grey)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              fullName,
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
                          Divider(
                            thickness: 1,
                            color: Colors.cyan,
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          _buildDrawerTile(
                            icon: Icons.calendar_today,
                            label: 'Calendar Screen',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Calendarscreen()),
                              );
                            },
                          ),
                          _buildDrawerTile(
                            icon: Icons.note_alt,
                            label: 'Leave Form',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Leavescreen()),
                              );
                            },
                          ),
                          _buildDrawerTile(
                            icon: Icons.report,
                            label: 'Daily Task Report',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => DailyTaskReport2()),
                              );
                            },
                          ),
                          _buildDrawerTile(
                            icon: Icons.announcement,
                            label: 'View Guildlines',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => UserViewGuideLines()),
                              );
                            },
                          ),
                          _buildDrawerTile(
                            icon: Icons.sunny_snowing,
                            label: 'Theme',
                            onTap: () {
                              final themeProvider =
                                  legacy_provider.Provider.of<ThemeProvider>(
                                      context,
                                      listen: false);
                              themeProvider.toggleTheme();

                              final isDarkMode = themeProvider.isDarkMode;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(
                                    isDarkMode
                                        ? 'Dark mode enabled!'
                                        : 'Light mode enabled!',
                                    style: const TextStyle(
                                      color: Colors.white, // ✅ White text
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }),
          ),
        ),
        body: Container(
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
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000F89),
                Color(0xFF0F52BA),
                Color(0xFF002147),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _buildBottomNavItem(
                icon: Icons.event_note,
                label: 'Attendance',
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              BottomNavItemWithBadge(
                icon: Icons.dashboard_customize,
                label: 'Category',
                badgeCount: _unreadNotifications,
                isActive: _currentIndex == 2,
                onTap: () async {
                  setState(() => _currentIndex = 2);
                },
              ),
              _buildBottomNavItem(
                icon: Icons.chat_bubble_outline,
                label: 'Support',
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
        Positioned(
          top: -30,
          left: MediaQuery.of(context).size.width / 2 - 30,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_currentIndex != profileIndex) {
                setState(() {
                  _currentIndex = profileIndex;
                });
              }
              // Else: already on profileIndex, do nothing
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                boxShadow: _currentIndex == profileIndex
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Transform.scale(
                scale: _currentIndex == profileIndex ? 1.2 : 1.0,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF005CFF),
                  elevation: 8,
                  onPressed: null, // GestureDetector handles tap
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: _currentIndex == profileIndex
                            ? Colors.amber
                            : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 10,
                          color: _currentIndex == profileIndex
                              ? Colors.amber
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        if (_isNavigating) return;
        setState(() => _isNavigating = true);
        onTap();
        setState(() => _isNavigating = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              transform: isActive
                  ? (Matrix4.identity()..scale(1.2))
                  : Matrix4.identity(),
              child: Icon(
                icon,
                color: isActive ? Colors.amber : Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.amber : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    // add this to prevent parent ListTileTheme overrides:
    selectedTileColor: Colors.transparent,
    tileColor: Colors.transparent,
  );
}
