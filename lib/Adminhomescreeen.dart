import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class NewPieShowtest extends StatefulWidget {
  const NewPieShowtest({super.key});

  @override
  State<NewPieShowtest> createState() => _NewPieShowtestState();
}

class _NewPieShowtestState extends State<NewPieShowtest> with SingleTickerProviderStateMixin {
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
      duration: const Duration(seconds: 2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              elevation: 0,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.blue.shade900, // Background color matching the image
          child: Column(
            children: [
              // Top Avatar and Name Section
              Container(
                padding: const EdgeInsets.only(top: 40, bottom: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/images/logo.png',),
                      // Replace with your avatar image
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Tech Lead',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // List of items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.task,
                      text: 'Show Task',
                      onTap: () {}, // Add navigation functionality
                    ),
                    _buildDrawerItem(
                      icon: Icons.add,
                      text: 'Add Task',
                      onTap: () {},
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
                          icon: Icons.business_center,
                          text: 'Reception',
                          onTap: () {},
                        ),
                        _buildDrawerItem(
                          icon: Icons.settings_applications,
                          text: 'Installation',
                          onTap: () {},
                        ),
                        _buildDrawerItem(
                          icon: Icons.shopping_cart,
                          text: 'Sales',
                          onTap: () {},
                        ),
                        _buildDrawerItem(
                          icon: Icons.support_agent,
                          text: 'Service',
                          onTap: () {},
                        ),
                        _buildDrawerItem(
                          icon: Icons.meeting_room,
                          text: 'Meeting Management',
                          onTap: () {},
                        ),
                        _buildDrawerItem(
                          icon: Icons.cake,
                          text: 'Birthday Page',
                          onTap: () {},
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
                ]),
                const SizedBox(height: 16),
                _buildCard("Completed Projects", completedDataMap, [
                  Colors.teal,
                  Colors.cyan,
                  Colors.yellowAccent,
                  Colors.pink,
                  Colors.lightBlue,
                ]),
                const SizedBox(height: 16),
                _buildCard("Not Started Projects", notStartedDataMap, [
                  Colors.red,
                  Colors.orange,
                  Colors.amber,
                  Colors.purpleAccent,
                  Colors.green,
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, Map<String, double> dataMap, List<Color> colorList) {
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
                )
            ),
            const SizedBox(height: 16),
            dataMap.isEmpty
                ? const CircularProgressIndicator()
                : PieChart(
              dataMap: dataMap,
              chartRadius: MediaQuery.of(context).size.width / 1.6,
              colorList: _getColorListWithGlow(colorList),
              legendOptions:  LegendOptions(
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
