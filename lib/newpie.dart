import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Guildlinesassign.dart';
import 'package:techlead/Showemployees.dart';
import 'package:techlead/Showinstallationdata.dart';
import 'package:techlead/forgotpassword.dart';
import 'package:techlead/leaveinfo.dart';
import 'package:techlead/reception.dart';
import 'package:techlead/reportsendtoadminside.dart';
import 'package:techlead/shortageofdata.dart';
import 'package:techlead/showreceptiondata.dart';
import 'package:techlead/taskassignpage.dart';
import 'Addpiegraph.dart';
import 'Employeeprofiledata.dart';
import 'EnSignUpPage.dart';
import 'Enteredscreen.dart';
import 'Showattendancedata.dart';
import 'Showsalesdata.dart';
import 'Themeprovider.dart';
import 'alldepartmentsfetchpages/Servicepage.dart';
import 'empwishform.dart';

class NewPieShow extends StatefulWidget {
  const NewPieShow({super.key});

  @override
  State<NewPieShow> createState() => _NewPieShowState();
}

class _NewPieShowState extends State<NewPieShow> with SingleTickerProviderStateMixin {
  Map<String, double> pendingDataMap = {};
  Map<String, double> completedDataMap = {};
  Map<String, double> notStartedDataMap = {};

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
    final snapshot = await FirebaseFirestore.instance.collection('projects').get();
    final pendingCategoryMap = <String, double>{};
    final completedCategoryMap = <String, double>{};
    final notStartedCategoryMap = <String, double>{};

    for (var doc in snapshot.docs) {
      final category = doc['category'] as String?;
      final completionPercentage = doc['completionPercentage'] as int?;
      final status = doc['status'] as String?;

      if (category != null && completionPercentage != null && status != null) {
        if (status == 'In Progress') {
          pendingCategoryMap[category] = (pendingCategoryMap[category] ?? 0) + completionPercentage;
        } else if (status == 'Completed') {
          completedCategoryMap[category] = (completedCategoryMap[category] ?? 0) + completionPercentage;
        } else if (status == 'Not Started') {
          notStartedCategoryMap[category] = (notStartedCategoryMap[category] ?? 0) + completionPercentage;
        }
      }
    }

    setState(() {
      pendingDataMap = _prepareDataForPieChart(pendingCategoryMap);
      completedDataMap = _prepareDataForPieChart(completedCategoryMap);
      notStartedDataMap = _prepareDataForPieChart(notStartedCategoryMap);
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
  bool _isDialogShowing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> _onWillPop() async {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.openEndDrawer();
      return false;
    } else if (!_isDialogShowing) {
      _isDialogShowing = true;
      bool? confirmExit = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text(
            'Exit Techlead App?',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          ),
          content: const Text(
            'Are you sure you want to exit?',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isDialogShowing =
                false;
                Navigator.of(context).pop(false);
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                _isDialogShowing =
                false;
                Navigator.of(context).pop(true);
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      return confirmExit ?? false;
    } else {
      return false;
    }
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
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Logout Techlead App?",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
          ),
          content: const Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
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
              child: Container(
              ),
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
              color: Colors.blue.shade900,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 60, bottom: 20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundImage: AssetImage('assets/images/ios.jpg'),
                          backgroundColor: Colors.white,
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
              Divider(color: Colors.white,thickness: 2,),
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      icon: Icons.task,
                      text: 'Show Task',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>ReportSendToAdminSide()));
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.add,
                      text: 'Add Task',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>TaskAssignPageDE()));
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
                            Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.people_alt,
                          text: 'Employee Auth',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => Showemployees()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.people_alt,
                          text: 'Employee Profile',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EmpShowData()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.lock_reset,
                          text: 'Forgot Password',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPasswordPage()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.note_alt_sharp,
                          text: 'Add Guildlines',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>AddGuidelines()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.meeting_room,
                          text: 'Meeting Section',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Showreceptiondata()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.settings_applications,
                          text: 'Installation',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Showinstallationdata()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.report_problem,
                          text: 'Installation Shortage Report',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>ShortageOfProduct()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.shopping_cart,
                          text: 'Sales',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>SalesInfoPage()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.support_agent,
                          text: 'Service',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>ServicePageList()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.meeting_room,
                          text: 'Meeting Management',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>ReceptionPage()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.cake,
                          text: 'Birthday Page',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>EmpWishForm()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.show_chart,
                          text: 'Attendancedata',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>Attendance()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.show_chart,
                          text: 'Leavedata',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>LeaveInfo()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.add_box,
                          text: 'Addprojectgraph',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>AdminFetchDataPiePage()));
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.sunny_snowing,
                          text: 'Theme',
                          onTap: () {
                            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
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
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCard("Pending Projects", pendingDataMap, [
                  Colors.blue,
                  Colors.orange,
                  Colors.greenAccent,
                  Colors.deepPurpleAccent,
                  Colors.redAccent,
                ], context),
                const SizedBox(height: 16),
                _buildCard("Completed Projects", completedDataMap, [
                  Colors.teal,
                  Colors.cyan,
                  Colors.yellowAccent,
                  Colors.pink,
                  Colors.lightBlue,
                ], context),
                const SizedBox(height: 16),
                // _buildCard("Not Started Projects", notStartedDataMap, [
                //   Colors.red,
                //   Colors.orange,
                //   Colors.amber,
                //   Colors.purpleAccent,
                //   Colors.green,
                // ]),
              ],
            ),
          ),
        ),
      ),
        ),
    );
  }


  Widget _buildCard(String title, Map<String, double> dataMap, List<Color> colorList, BuildContext context) {
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
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            dataMap.isEmpty
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
            ),
          ],
        ),
      ),
    );
  }


  List<Color> _getColorListWithGlow(List<Color> colorList) {
    final glowingSliceOpacity = _animationController.value;
    if (_glowingIndex != -1) {
      colorList[_glowingIndex] = colorList[_glowingIndex].withOpacity(0.5 + glowingSliceOpacity * 0.5);
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
      style: TextStyle(
        fontSize: 16,
        color: Colors.white,
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
