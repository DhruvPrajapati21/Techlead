import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techlead/taskreportpage.dart';
import 'Attendacescreen.dart';
import 'Categoryscreen.dart';
import 'Leavescreen.dart';
import 'Profilescreen.dart';
import 'Supportscreen.dart';
import 'inhome.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalTasks = 0;
  int inProgress = 0;
  int pendingTasks = 0;
  double totalWorkingHours = 0;
  double performancePercentage = 0;
  int totalEmployees = 1;
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  int _unreadNotifications = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchOverallStats();
    _fetchUnreadNotifications();
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

  Future<void> _fetchOverallStats() async {
    try {
      QuerySnapshot attendanceSnapshot = await _firestore.collection('Attendance').get();
      QuerySnapshot empSnapshot = await _firestore.collection('EmpProfile').get();

      Set<String> availableCategories = {};

      for (var doc in empSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('categories')) {
          List<dynamic> categories = data['categories'];
          availableCategories.addAll(categories.map((e) => e.toString()));
        }
      }

      int employeeCount = availableCategories.isEmpty ? 0 : empSnapshot.docs.length;
      int completedTasks = 0, pendingTasksCount = 0, inProgressCount = 0;

      var statuses = {
        'Completed': (int count) => completedTasks = count,
        'Pending': (int count) => pendingTasksCount = count,
        'In Progress': (int count) => inProgressCount = count,
      };

      for (var status in statuses.keys) {
        QuerySnapshot snapshot = await _firestore
            .collection('DailyTaskReport')
            .where('service_status', isEqualTo: status)
            .get();

        int count = 0;
        for (var doc in snapshot.docs) {
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          if (data != null && availableCategories.contains(data['category'].toString())) {
            count++;
          }
        }
        statuses[status]!(count);
      }

      int totalDays = 0, fullDays = 0, halfDays = 0;
      double totalHours = 0;

      for (var doc in attendanceSnapshot.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          if (data.containsKey('record')) {
            List<String> parts = data['record'].split(' ');
            int hours = int.tryParse(parts[0]) ?? 0;
            int minutes = int.tryParse(parts[2]) ?? 0;
            totalHours += hours + (minutes / 60);
          }

          if (data.containsKey('status')) {
            if (data['status'] == 'Full Day') fullDays++;
            else if (data['status'] == 'Half Day') halfDays++;
            totalDays++;
          }
        }
      }

      double avgWorkingHours = totalHours / (employeeCount > 0 ? employeeCount : 1);
      double fullDayPercentage = (fullDays / (totalDays > 0 ? totalDays : 1)) * 100;
      double halfDayPercentage = (halfDays / (totalDays > 0 ? totalDays : 1)) * 50;
      double overallPerformance = (fullDayPercentage + halfDayPercentage + (completedTasks * 2)) / 3;

      setState(() {
        totalWorkingHours = avgWorkingHours;
        totalTasks = completedTasks;
        performancePercentage = overallPerformance;
        totalEmployees = employeeCount;
        pendingTasks = pendingTasksCount;
        inProgress = inProgressCount;
      });
    } catch (e) {
      print('Error fetching overall stats: $e');
    }
  }

  void _onCardTapped(String label) async {
    List<Widget> content = [];

    try {
      if (label == "Working Hours") {
        QuerySnapshot snapshot = await _firestore
            .collection('Attendance')
            .where('userId', isEqualTo: currentUserId)
            .get();

        int index = 1;
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          content.add(
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('$index', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(data['employeeName'] ?? 'Unknown'),
              subtitle: Text("Working time: ${data['record'] ?? 'N/A'}"),
            ),
          );
          index++;
        }
      } else if (label == "Pending Tasks" || label == "InProgress Tasks" || label == "Completed Tasks") {
        String status = label == "Pending Tasks"
            ? "Pending"
            : label == "InProgress Tasks"
            ? "In Progress"
            : "Completed";

        QuerySnapshot snapshot = await _firestore
            .collection('DailyTaskReport')
            .where('service_status', isEqualTo: status)
            .get();

        int index = 1;
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          content.add(
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('$index', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(data['taskTitle'] ?? 'Task'),
              subtitle: Text(
                "Category: ${data['Service_department'] ?? 'N/A'}, Assigned to: ${data['employeeName'] ?? 'N/A'}",
              ),
            ),
          );
          index++;
        }
      } else if (label == "Team Members") {
        QuerySnapshot snapshot = await _firestore.collection('EmpProfile').get();
        int index = 1;
        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          content.add(
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text('$index', style: const TextStyle(color: Colors.white)),
              ),
              title: Text(data['fullName'] ?? 'Unknown'),
              subtitle: Text(
                "Address: ${data['address'] ?? 'N/A'}, Phone: ${data['mobile'] ?? 'N/A'}, Email: ${data['email'] ?? 'N/A'}",
              ),
            ),
          );
          index++;
        }
      } else if (label == "Performance Rating") {
        content.add(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Performance is calculated as:\n"
                  "• Full Day = 100%\n"
                  "• Half Day = 50%\n"
                  "• Completed Task = 2 Points\n\n"
                  "Combined Score = Avg of all.",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: content.isNotEmpty
                ? ListView(children: content)
                : const Center(child: Text("No data found")),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            )
          ],
        ),
      );
    } catch (e) {
      print("Error loading dialog data for $label: $e");
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
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
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
              SizedBox(height: 5,),
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
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child:
                  Text(
                    'Techlead',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
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
                  style: TextStyle(fontSize: 20,
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
                  _buildDashboardCard(
                    icon: Icons.access_time,
                    label: "Working Hours",
                    value: "${totalWorkingHours.toStringAsFixed(1)} hrs",
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
                  if (ModalRoute
                      .of(context)
                      ?.settings
                      .name != 'HomeScreen') {
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
                  if (ModalRoute
                      .of(context)
                      ?.settings
                      .name != 'Attendancescreen') {
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
                  if (ModalRoute
                      .of(context)
                      ?.settings
                      .name != 'CategoryScreen') {
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
                  if (ModalRoute
                      .of(context)
                      ?.settings
                      .name != 'ContactUs') {
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
          left: MediaQuery
              .of(context)
              .size
              .width / 2 - 35,
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
          Icon(icon, color: Colors.deepPurple), // 👈 Set icon color to white
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.deepPurple, // 👈 Set text color to white
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


