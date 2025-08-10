import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:techlead/Admin/Installation/Showinstallationdata.dart';

import 'package:techlead/Admin/Leavescreen/leaveinfo.dart';
import 'package:techlead/Admin/Meetingmanagement/reception.dart';
import 'package:techlead/Admin/Sales/salespage.dart';
import 'package:techlead/Admin/Taskdetails/Admintaskassigneddata.dart';
import 'package:techlead/Admin/Taskdetails/reportsendtoadminside.dart';

import 'package:techlead/Admin/Meetingsection/showreceptiondata.dart';
import 'package:techlead/Admin/Taskdetails/taskassignpage.dart';
import '../Calendar_Ui/Task_Report_Model/SyncFunction_Task.dart';
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
  bool isLoading = true;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override


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
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        actionsPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.amberAccent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () => _onWillPop(context),
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
                    Color(0xFF0A2A5A),
                    Color(0xFF15489C),
                    Color(0xFF1E64D8),
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
                          width: 100,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E64D8), Color(0xFF1E64D8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4)),
                            ],
                          ),
                          child: Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF005F73), Color(0xFF0A9396)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/enteredscreen.png',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'TechLead The Engineering Solutions!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Times New Roman",
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: Colors.white, thickness: 2),

                  Expanded(
                    child: ListView(
                      children: [
                        _buildSectionHeader('Project Information'),
                        _buildDrawerItem(
                            icon: Icons.task,
                            text: 'Show Employee Tasks',
                            onTap: () =>
                                _navigate(context, ReportSendToAdminSide())),
                        _buildDrawerItem(
                            icon: Icons.add,
                            text: 'Task Assign',
                            onTap: () => _navigate(context, TaskAssignPageDE())),
                        _buildDrawerItem(
                            icon: Icons.report,
                            text: 'Task Report',
                            onTap: () =>
                                _navigate(context, Admintaskassigneddata())),

                        Divider(color: Colors.white54),

                        _buildSectionHeader('Employees Project Data'),

                        _buildDrawerItem(
                            icon: Icons.person_add_alt_1,
                            text: 'Employee Registration',
                            onTap: () => _navigate(context, SignUpPage())),
                        _buildDrawerItem(
                            icon: Icons.people_alt,
                            text: 'Employee Authentication',
                            onTap: () => _navigate(context, Showemployees())),
                        _buildDrawerItem(
                            icon: Icons.people_outline,
                            text: 'Employee Profiles',
                            onTap: () => _navigate(context, EmpShowData())),
                        _buildDrawerItem(
                            icon: Icons.lock_reset,
                            text: 'Employee Forgot Password',
                            onTap: () =>
                                _navigate(context, ForgotPasswordPage())),
                        _buildDrawerItem(
                            icon: Icons.note_alt_sharp,
                            text: 'Add Guidelines',
                            onTap: () => _navigate(context, AddGuidelines())),
                        _buildDrawerItem(
                            icon: Icons.view_agenda,
                            text: 'View Guidelines',
                            onTap: () => _navigate(context, AdminGuideLines())),
                        Divider(color: Colors.white54),

                        _buildSectionHeader('Installation'),
                        _buildDrawerItem(
                            icon: Icons.install_desktop,
                            text: 'Site Installation',
                            onTap: () => _navigate(context, InstallationPage())),
                        _buildDrawerItem(
                            icon: Icons.settings_applications,
                            text: 'Installation Reports',
                            onTap: () =>
                                _navigate(context, Showinstallationdata())),
                        _buildDrawerItem(
                            icon: Icons.report_problem,
                            text: 'Installation Shortage Reports',
                            onTap: () =>
                                _navigate(context, FetchedProductPage())),
                        Divider(color: Colors.white54),

                        _buildSectionHeader('Sales'),
                        _buildDrawerItem(
                            icon: Icons.generating_tokens_rounded,
                            text: 'Sales Lead',
                            onTap: () => _navigate(context, AdminSalesPage())),
                        _buildDrawerItem(
                            icon: Icons.shopping_cart,
                            text: 'Sales Reports',
                            onTap: () => _navigate(context, SalesInfoPage())),
                        Divider(color: Colors.white54),

                        _buildSectionHeader('Meetings'),
                        _buildDrawerItem(
                            icon: Icons.meeting_room,
                            text: 'Meeting Assign',
                            onTap: () => _navigate(context, ReceptionPage())),
                        _buildDrawerItem(
                            icon: Icons.meeting_room_outlined,
                            text: 'Meeting Reports',
                            onTap: () => _navigate(context, Showreceptiondata())),
                        Divider(color: Colors.white54),

                        _buildSectionHeader('HR & Admin'),
                        _buildDrawerItem(
                            icon: Icons.cake,
                            text: 'Birthday Page',
                            onTap: () => _navigate(context, EmpWishForm())),
                        _buildDrawerItem(
                            icon: Icons.show_chart,
                            text: 'Attendance Reports',
                            onTap: () => _navigate(context, Attendance())),
                        _buildDrawerItem(
                            icon: Icons.leave_bags_at_home,
                            text: 'Leave Reports',
                            onTap: () => _navigate(context, LeaveInfo())),
                        // _buildDrawerItem(
                        //     icon: Icons.add_box,
                        //     text: 'Add Project Graph',
                        //     onTap: () =>
                        //         _navigate(context, AdminFetchDataPiePage())),
                        _buildDrawerItem(
                            icon: Icons.support_agent,
                            text: 'Services',
                            onTap: () => _navigate(context, ServicePageList())),

                        _buildDrawerItem(
                          icon: Icons.sunny_snowing,
                          text: 'Theme',
                          onTap: () {
                            final themeProvider = Provider.of<ThemeProvider>(
                                context,
                                listen: false);
                            themeProvider.toggleTheme();

                            final isDarkMode = themeProvider
                                .isDarkMode;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.green,
                                content: Text(
                                  isDarkMode
                                      ? 'Dark mode enabled!'
                                      : 'Light mode enabled!',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold), // ✅ White text
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        _buildDrawerItem(
                            icon: Icons.logout,
                            text: 'Logout',
                            onTap: () => showLogoutConfirmationDialog(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: isLoading
              ? Center(
            child: Shimmer.fromColors(
              baseColor: Colors.blue.shade300,
              highlightColor: Colors.blue.shade100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 150,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          )
              : const TaskCalendarPage(),
        )
    );
  }
}