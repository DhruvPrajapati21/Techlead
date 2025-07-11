import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import 'package:techlead/Admin/Installation/Showinstallationdata.dart';

import 'package:techlead/Admin/Leavescreen/leaveinfo.dart';
import 'package:techlead/Admin/Meetingmanagement/reception.dart';
import 'package:techlead/Admin/Taskdetails/reportsendtoadminside.dart';

import 'package:techlead/Admin/Meetingsection/showreceptiondata.dart';
import 'package:techlead/Admin/Taskdetails/taskassignpage.dart';
import '../Employee/Categoryscreen/Installation/serviceinstallationpage.dart';
import '../Employee/Categoryscreen/Sales/salespage.dart';
import 'Employeedetails/Empshowdata.dart';
import 'Employeedetails/EnSignUpPage.dart';
import 'Employeedetails/Showemployees.dart';
import 'Employeedetails/forgotpassword.dart';
import 'Guildlines/Adminviewguildlines.dart';
import 'Guildlines/Guildlinesassign.dart';
import 'Installation/fetchedshortagereport.dart';
import 'Piechart/Addpiegraph.dart';
import '../Employee/Authentication/Enteredscreen.dart';
import 'Attendance/Showattendancedata.dart';
import 'Sales/Showsalesdata.dart';
import '../Default/Themeprovider.dart';
import '../Employee/Categoryscreen/Services/Servicepage.dart';
import 'Birthdaydetails/empwishform.dart';

class NewPieShow extends StatefulWidget {
  const NewPieShow({super.key});

  @override
  State<NewPieShow> createState() => _NewPieShowState();
}

class _NewPieShowState extends State<NewPieShow>
    with SingleTickerProviderStateMixin {
  Map<String, double> pendingDataMap = {};
  Map<String, double> completedDataMap = {};
  bool isLoading = true;

  late AnimationController _animationController;
  int _glowingIndex = -1;

  @override
  void initState() {
    super.initState();
    fetchPieChartData();
    _animationController = AnimationController(
      duration: const Duration(seconds: 0),
      vsync: this,
    )..addListener(() {
        if (_animationController.isCompleted) {
          setState(() {
            _glowingIndex = (_glowingIndex + 1) % 5;
            _animationController.reset();
            _animationController.forward();
          });
        }
      });
    _animationController.forward();
  }

  Future<void> fetchPieChartData() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance.collection('projects').get();
    final pendingCategoryMap = <String, double>{};
    final completedCategoryMap = <String, double>{};

    for (var doc in snapshot.docs) {
      final category = doc['category'] as String?;
      final completionPercentage = doc['completionPercentage'] as int?;
      final status = doc['status'] as String?;

      if (category != null && completionPercentage != null && status != null) {
        if (status == 'In Progress') {
          pendingCategoryMap[category] =
              (pendingCategoryMap[category] ?? 0) + completionPercentage;
        } else if (status == 'Completed') {
          completedCategoryMap[category] =
              (completedCategoryMap[category] ?? 0) + completionPercentage;
        }
      }
    }

    setState(() {
      pendingDataMap = _prepareDataForPieChart(pendingCategoryMap);
      completedDataMap = _prepareDataForPieChart(completedCategoryMap);
      isLoading = false;
    });
  }


  Map<String, double> _prepareDataForPieChart(Map<String, double> categoryMap) {
    return categoryMap.map((key, value) => MapEntry(key, value.toDouble()));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
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
            actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
    return shouldExit ?? false;
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Enteredscreen()),
    );
  }

  void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.logout, color: Colors.blueAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logout Techlead App?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Times New Roman',
                    ),
                  ),
                ),
              ],
            ),
            content: const Text('Are you sure you want to logout?',
                style: TextStyle(fontSize: 16)),
            actionsPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout(context);
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Container(),
              ),
              AppBar(
                title: Text(
                  "Project Overview",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.white24,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                iconTheme: IconThemeData(color: Colors.white),
                elevation: 0,
              ),
            ],
          ),
        ),
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A2A5A), // Deep navy blue
                  Color(0xFF15489C), // Strong steel blue
                  Color(0xFF1E64D8), // Vivid rich blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 60, bottom: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1E64D8),
                              Color(0xFF1E64D8),
                              Color(0xFF1E64D8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF005F73), // Deep Teal Cyan
                                Color(0xFF0A9396), // Rich Cyan Blue
                              ]
                              ,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/ios.jpg',
                              width: 100, // You can customize this
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'TechLead The Engineering Solutions!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Times New Roman",
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.white,
                  thickness: 2,
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildDrawerItem(
                        icon: Icons.task,
                        text: 'Show Employee Tasks',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      ReportSendToAdminSide()));
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.add,
                        text: 'Task Assign',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TaskAssignPageDE()));
                        },
                      ),
                      const Divider(
                        color: Colors.white54,
                      ),
                      ExpansionTile(
                        iconColor: Colors.tealAccent,
                        collapsedIconColor: Colors.tealAccent,
                        title: Text(
                          'Project Categories',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: [
                          _buildDrawerItem(
                            icon: Icons.person_add_alt_1,
                            text: 'Employee Registration',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SignUpPage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.people_alt,
                            text: 'Employee Authentication',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Showemployees()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.people_outline_outlined,
                            text: 'Employee Profiles',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EmpShowData()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.lock_reset,
                            text: 'Employee Forgot Password',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          ForgotPasswordPage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.note_alt_sharp,
                            text: 'Add Guildlines',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AddGuidelines()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.view_agenda,
                            text: 'View Guildlines',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AdminGuideLines()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.install_desktop,
                            text: 'Site Installation',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          InstallationPage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.settings_applications,
                            text: 'Installation Reports',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Showinstallationdata()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.report_problem,
                            text: 'Installation Shortage Reports',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          FetchedProductPage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.generating_tokens_rounded,
                            text: 'Sales Lead',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SalesPage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.shopping_cart,
                            text: 'Sales Reports',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SalesInfoPage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.meeting_room,
                            text: 'Meeting Assign',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ReceptionPage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.meeting_room,
                            text: 'Meeting Reports',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          Showreceptiondata()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.cake,
                            text: 'Birthday Page',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EmpWishForm()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.show_chart,
                            text: 'Attendance Reports',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => Attendance()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.leave_bags_at_home,
                            text: 'Leave Reports',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LeaveInfo()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.add_box,
                            text: 'Addprojectgraph',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          AdminFetchDataPiePage()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.support_agent,
                            text: 'Services',
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ServicePageList()));
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.sunny_snowing,
                            text: 'Theme',
                            onTap: () {
                              final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                              themeProvider.toggleTheme();

                              final isDarkMode = themeProvider.isDarkMode; // make sure ThemeProvider exposes this bool

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(
                                    isDarkMode ? 'Dark mode enabled!' : 'Light mode enabled!',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // ✅ White text
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                          _buildDrawerItem(
                            icon: Icons.logout,
                            text: 'Logout',
                            onTap: () {
                              showLogoutConfirmationDialog(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0A2A5A), // Deep navy blue
                Color(0xFF15489C), // Strong steel blue
                Color(0xFF1E64D8), // Vivid rich blue
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildCard(
                      "Pending Projects",
                      pendingDataMap,
                      [
                        Colors.blue,
                        Colors.orange,
                        Colors.greenAccent,
                        Colors.deepPurpleAccent,
                        Colors.redAccent,
                      ],
                      context),
                  const SizedBox(height: 16),
                  _buildCard(
                      "Completed Projects",
                      completedDataMap,
                      [
                        Colors.teal,
                        Colors.cyan,
                        Colors.yellowAccent,
                        Colors.pink,
                        Colors.lightBlue,
                      ],
                      context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, Map<String, double> dataMap,
      List<Color> colorList, BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.blue.shade400.withOpacity(0.5),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A2A5A),
              ),
            ),
            const SizedBox(height: 16),
            isLoading
                ? _buildShimmerPlaceholder()
                : dataMap.isEmpty
                ? Text(
              'No data available.\nTip: Start by adding project data.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            )
                : PieChart(
              dataMap: dataMap,
              chartRadius: MediaQuery.of(context).size.width / 1.6,
              colorList: _getColorListWithGlow(colorList),
              legendOptions: LegendOptions(
                legendPosition: LegendPosition.bottom,
                legendTextStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.blue.shade900,
                ),
              ),
              chartValuesOptions: const ChartValuesOptions(
                showChartValuesInPercentage: true,
              ),
            )

          ],
        ),
      ),
    );
  }

  List<Color> _getColorListWithGlow(List<Color> colorList) {
    final glowingSliceOpacity = _animationController.value;
    if (_glowingIndex != -1) {
      colorList[_glowingIndex] =
          colorList[_glowingIndex].withOpacity(0.5 + glowingSliceOpacity * 0.5);
    }
    return colorList;
  }
}

Widget _buildDrawerItem({
  required IconData icon,
  required String text,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(
      icon,
      color: Colors.tealAccent,
    ),
    title: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto', // Make sure it's available or added
      ),
    ),
    trailing: Icon(
      Icons.arrow_forward_ios,
      color: Colors.tealAccent,
      size: 16,
    ),
    onTap: onTap,
  );
}
Widget _buildShimmerPlaceholder() {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 150,
          height: 20,
          color: Colors.white,
        ),
        const SizedBox(height: 8),
        Container(
          width: 100,
          height: 20,
          color: Colors.white,
        ),
      ],
    ),
  );
}
