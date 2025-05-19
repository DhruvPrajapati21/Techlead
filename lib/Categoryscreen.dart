import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:techlead/Accounthomescreen.dart';
import 'package:techlead/Digitalmarketinghomescreen.dart';
import 'package:techlead/Financeshomescreen.dart';
import 'package:techlead/Hrhomescreen.dart';
import 'package:techlead/Managementhomescreen.dart';
import 'package:techlead/SmHomescreen.dart';
import 'package:techlead/alldepartmentsfetchpages/Socialmediamarketingshowdata.dart';
import 'package:techlead/alldepartmentsfetchpages/hrreceivedscreen.dart';
import 'alldepartmentsfetchpages/Accountshowdata.dart';
import 'alldepartmentsfetchpages/Digitlmarketingshowdata.dart';
import 'alldepartmentsfetchpages/Financeshowdata.dart';
import 'alldepartmentsfetchpages/Managementshowdata.dart';
import 'alldepartmentsfetchpages/Receptionhomescreen.dart';
import 'alldepartmentsfetchpages/Saleshomescreen.dart';
import 'alldepartmentsfetchpages/Servicepage.dart';
import 'inhome.dart';

class Categoryscreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  Categoryscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          "Category Screen",
          style: TextStyle(
            fontFamily: "Times New Roman",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('EmpProfile')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('An error occurred. Please try again.'));
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(
                child: Text(
                  'No profile data available!',
                  style: TextStyle(
                      fontFamily: "Times New Roman", fontWeight: FontWeight.bold),
                ));
          }

          final profileData = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> userDepartments =
          List<String>.from(profileData['categories'] ?? []);
          return CategoryGrid(userDepartments: userDepartments);
        },
      ),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<String> userDepartments;

  const CategoryGrid({super.key, required this.userDepartments});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allCategories = [
      {'label': 'Human Resources', 'icon': Icons.work, 'color': Colors.indigo, 'screen': Hrhomescreen()},
      {'label': 'Finance', 'icon': Icons.account_balance_wallet, 'color': Colors.teal, 'screen': Financeshomescreen()},
      {'label': 'Management', 'icon': Icons.business, 'color': Colors.cyan, 'screen': Managementhomescreen()},
      {'label': 'Installation', 'icon': Icons.build, 'color': Colors.green, 'screen': Inhomescreen()},
      {'label': 'Sales', 'icon': Icons.shopping_cart, 'color': Colors.purple, 'screen': Saleshomescreen()},
      {'label': 'Reception', 'icon': Icons.phone_in_talk, 'color': Colors.orange, 'screen': Receptionhomescreen()},
      {'label': 'Account', 'icon': Icons.attach_money, 'color': Colors.red, 'screen': Accounthomescreen()},
      {'label': 'Services', 'icon': Icons.miscellaneous_services, 'color': Colors.teal, 'screen': ServicePageList()},
      {'label': 'Social Media', 'icon': Icons.public, 'color': Colors.cyan, 'screen': Smhomescreen()},
      {'label': 'Digital Marketing', 'icon': Icons.trending_up, 'color': Colors.amber, 'screen': Digitalmarketinghomescreen()},
    ];

    final filteredCategories = allCategories
        .where((category) => userDepartments.contains(category['label']))
        .toList();

    if (filteredCategories.isEmpty) {
      return const Center(
        child: Text(
          'No department cards assigned for your profile.',
          style: TextStyle(fontWeight: FontWeight.bold,fontFamily: "Times New Roman"),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: filteredCategories.length,
        itemBuilder: (context, index) {
          final category = filteredCategories[index];
          return GestureDetector(
            onTap: () {
              if (category.containsKey('screen')) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => category['screen']),
                );
              } else {
                Fluttertoast.showToast(
                  msg: "Service not available currently!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.green,
                  textColor: Colors.white,
                  fontSize: 16.0,
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: category['color'],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'],
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    category['label'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
