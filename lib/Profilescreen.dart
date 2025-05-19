import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/EnLoginPage.dart';
import 'package:techlead/Enteredscreen.dart';
import 'addinforemployee.dart';

class ProfileScreen extends StatefulWidget {
  final String category;
  const ProfileScreen({Key? key, required this.category, required String userId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _hasProfile = false;
  final Set<String> _shownTaskIds = {};
  late AnimationController _animationController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _empIdController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateOfJoiningController = TextEditingController();

  final List<String> _categories = [
    'Digital Marketing', 'Sales', 'Installation', 'Human Resource Dev',
    'Receptionist', 'Accountant', 'Services', 'Social Media Marketing'
  ];

  final Map<String, bool> _selectedCategories = {};
  bool _isSubmitting = false;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    _initializeCategories();
    _checkProfile();
    initNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _empIdController.dispose();
    _dobController.dispose();
    _qualificationController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dateOfJoiningController.dispose();
    super.dispose();
  }

  void _initializeCategories() {
    for (var category in _categories) {
      _selectedCategories[category] = false;
    }
  }

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          navigatorKey.currentState?.pushNamed('/Categoryscreen', arguments: response.payload);
        }
      },
    );

    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

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
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'Task Assign Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      "Click to view details",
      platformChannelSpecifics,
      payload: category,
    );
  }

  void checkTaskAssignment(List<String> categories) async {
    QuerySnapshot taskSnapshot = await FirebaseFirestore.instance.collection('TaskAssign').get();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var doc in taskSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String docId = doc.id;

      if (prefs.getBool('task_$docId') == true) continue;
      if (!data.containsKey('department')) continue;

      if (categories.contains(data['department'])) {
        _showNotification("New Task Assigned", "You have a new assigned task!");
        prefs.setBool('task_$docId', true);
        break;
      }
    }
  }



  void checkTaskAssignment2(String empId) async {
    QuerySnapshot taskSnapshot = await FirebaseFirestore.instance.collection('TaskAssign').get();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    for (var doc in taskSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      String docId = doc.id;

      if (prefs.getBool('task_$docId') == true) continue;
      if (!data.containsKey('empIds')) continue;

      if ((data['empIds'] as List).contains(empId)) {
        _showNotification("New Task Assigned", "You have a new assigned task!");
        prefs.setBool('task_$docId', true);
        break;
      }
    }
  }


  Future<void> _checkProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('EmpProfile') .doc(userId).get();
    setState(() {
      _hasProfile = doc.exists;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      setState(() {
        _imageFile = pickedFile;
      });
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error picking image: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Pick from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String userId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _updateProfile(Map<String, dynamic> updatedData) async {
    try {
      await FirebaseFirestore.instance
          .collection('EmpProfile')
          .doc(userId)
          .update(updatedData);

      Fluttertoast.showToast(
        msg: "Profile updated successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error updating profile: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Employee Profile',
          style: TextStyle(
            fontFamily: "Times New Roman",
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _hasProfile
            ? null
            : [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProfilePage()),
              ).then((_) => _checkProfile());
            },
          ),
        ],
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
          String empId = profileData['empId'];
          List<String> categories =
          List<String>.from(profileData['categories'] ?? []);

          checkTaskAssignment2(empId);
          checkTaskAssignment(categories);

          return _buildProfileContent(profileData);
        },
      ),
    );
  }
  Widget _buildProfileContent(Map<String, dynamic> profileData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildProfileCard(profileData),
          const SizedBox(height: 20),
          _buildInfoCards(profileData),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profileData) {
    return Container(
      width: 330,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (profileData['profileImage'] != null && profileData['profileImage'].toString().isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageView(imageUrl: profileData['profileImage']),
                  ),
                );
              }
            },
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              backgroundImage: profileData['profileImage'] != null && profileData['profileImage'].toString().isNotEmpty
                  ? NetworkImage(profileData['profileImage'])
                  : null,
              child: profileData['profileImage'] == null || profileData['profileImage'].toString().isEmpty
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profileData['fullName'] ?? 'N/A',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // IconButton(
              //   icon: const Icon(Icons.edit, color: Colors.white),
              //   onPressed: () => _showEditProfileSheet(profileData),
              // ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards(Map<String, dynamic> profileData) {
    return Column(
      children: [
        _buildInfoCard(
          title: 'Personal Information',
          icon: Icons.person,
          fields: [
            _buildInfoRow('Employee ID', profileData['empId']),
            _buildInfoRow('Email', profileData['email']),
            _buildInfoRow('Contact', profileData['mobile']),
            _buildInfoRow('Department', (profileData['categories'] as List<dynamic>).join(', ')),
            _buildInfoRow('Address', profileData['address']),
            _buildInfoRow('Date of Birth', profileData['dob']),
          ],
        ),
        const SizedBox(height: 20),
        _buildInfoCard(
          title: 'Work Experience',
          icon: Icons.work,
          fields: [
            _buildInfoRow('Qualification', profileData['qualification']),
            _buildInfoRow('Date of Joining', profileData['dateOfJoining']),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> fields}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 4,
        color: const Color(0xFFFDFEFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...fields,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // void _showEditProfileSheet(Map<String, dynamic> profileData) {
  //   final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();
  //
  //   final TextEditingController fullNameController = TextEditingController(text: profileData['fullName']);
  //   final TextEditingController empIdController = TextEditingController(text: profileData['empId']);
  //   final TextEditingController dobController = TextEditingController(text: profileData['dob']);
  //   final TextEditingController qualificationController = TextEditingController(text: profileData['qualification']);
  //   final TextEditingController addressController = TextEditingController(text: profileData['address']);
  //   final TextEditingController mobileController = TextEditingController(text: profileData['mobile']);
  //   final TextEditingController emailController = TextEditingController(text: profileData['email']);
  //   final TextEditingController dateOfJoiningController = TextEditingController(text: profileData['dateOfJoining']);
  //
  //   String imageUrl = profileData['profileImage'] ?? '';
  //   File? selectedImage;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           top: 20,
  //           left: 16,
  //           right: 16,
  //           bottom: MediaQuery.of(context).viewInsets.bottom + 20,
  //         ),
  //         child: StatefulBuilder(builder: (context, setState) {
  //           return SingleChildScrollView(
  //             child: Form(
  //               key: _editFormKey,
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   // Top blue back button
  //                   Row(
  //                     children: [
  //                       IconButton(
  //                         icon: Icon(Icons.arrow_back, color: Colors.blueAccent),
  //                         onPressed: () => Navigator.pop(context),
  //                       ),
  //                       const Spacer(),
  //                       const Text(
  //                         'Edit Profile',
  //                         style: TextStyle(
  //                           fontSize: 22,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.blueAccent,
  //                         ),
  //                       ),
  //                       const Spacer(flex: 2),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 20),
  //                   Stack(
  //                     alignment: Alignment.bottomRight,
  //                     children: [
  //                       CircleAvatar(
  //                         radius: 50,
  //                         backgroundImage: selectedImage != null
  //                             ? FileImage(selectedImage!)
  //                             : imageUrl.isNotEmpty
  //                             ? NetworkImage(imageUrl)
  //                             : const AssetImage('assets/images/gallery.png') as ImageProvider,
  //                       ),
  //                       IconButton(
  //                         icon: const Icon(Icons.edit, color: Colors.blueAccent),
  //                         onPressed: () async {
  //                           final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  //                           if (picked != null) {
  //                             setState(() {
  //                               selectedImage = File(picked.path);
  //                             });
  //                           }
  //                         },
  //                       ),
  //                     ],
  //                   ),
  //                   const SizedBox(height: 20),
  //                   _buildInput(fullNameController, 'Full Name', validator: (val) => val!.isEmpty ? 'Enter name' : null),
  //                   _buildInput(empIdController, 'Employee ID', validator: (val) => val!.isEmpty ? 'Enter Employee ID' : null),
  //                   _buildInput(dobController, 'Date of Birth',
  //                       readOnly: true,
  //                       onTap: () async {
  //                         final pickedDate = await showDatePicker(
  //                           context: context,
  //                           initialDate: DateTime.tryParse(dobController.text) ?? DateTime.now(),
  //                           firstDate: DateTime(1950),
  //                           lastDate: DateTime.now(),
  //                         );
  //                         if (pickedDate != null) {
  //                           dobController.text = pickedDate.toString().split(' ')[0];
  //                         }
  //                       },
  //                       validator: (val) => val!.isEmpty ? 'Pick DOB' : null),
  //                   _buildInput(qualificationController, 'Qualification',
  //                       validator: (val) => val!.isEmpty ? 'Enter qualification' : null),
  //                   _buildInput(addressController, 'Address', validator: (val) => val!.isEmpty ? 'Enter address' : null),
  //                   _buildInput(mobileController, 'Mobile',
  //                       keyboardType: TextInputType.phone,
  //                       validator: (val) {
  //                         if (val == null || val.isEmpty) return 'Enter mobile number';
  //                         if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) return 'Enter valid 10-digit number';
  //                         return null;
  //                       }),
  //                   _buildInput(emailController, 'Email',
  //                       keyboardType: TextInputType.emailAddress,
  //                       validator: (val) {
  //                         if (val == null || val.isEmpty) return 'Enter email';
  //                         if (!RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(val)) return 'Enter valid Gmail ID';
  //                         return null;
  //                       }),
  //                   _buildInput(dateOfJoiningController, 'Date of Joining',
  //                       readOnly: true,
  //                       onTap: () async {
  //                         final pickedDate = await showDatePicker(
  //                           context: context,
  //                           initialDate: DateTime.tryParse(dateOfJoiningController.text) ?? DateTime.now(),
  //                           firstDate: DateTime(2000),
  //                           lastDate: DateTime.now(),
  //                         );
  //                         if (pickedDate != null) {
  //                           dateOfJoiningController.text = pickedDate.toString().split(' ')[0];
  //                         }
  //                       },
  //                       validator: (val) => val!.isEmpty ? 'Pick joining date' : null),
  //                   const SizedBox(height: 20),
  //                   ElevatedButton.icon(
  //                     icon: const Icon(Icons.update),
  //                     label: const Text('Update Profile'),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blueAccent,
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  //                       textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                     ),
  //                     onPressed: () async {
  //                       if (_editFormKey.currentState!.validate()) {
  //                         String? newImageUrl;
  //
  //                         if (selectedImage != null) {
  //                           final storageRef = FirebaseStorage.instance
  //                               .ref('profile_images/${DateTime.now().millisecondsSinceEpoch}');
  //                           await storageRef.putFile(selectedImage!);
  //                           newImageUrl = await storageRef.getDownloadURL();
  //                         }
  //
  //                         final updatedData = {
  //                           'fullName': fullNameController.text,
  //                           'empId': empIdController.text,
  //                           'dob': dobController.text,
  //                           'qualification': qualificationController.text,
  //                           'address': addressController.text,
  //                           'mobile': mobileController.text,
  //                           'email': emailController.text,
  //                           'dateOfJoining': dateOfJoiningController.text,
  //                           'logoUrl': newImageUrl ?? imageUrl,
  //                         };
  //
  //                         await _updateProfile(updatedData);
  //                         Navigator.pop(context);
  //                       }
  //                     },
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         }),
  //       );
  //     },
  //   );
  // }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout Techlead APP?", style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
          content: const Text("Are you sure you want to logout?"),
          actions: <Widget>[
            TextButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Yes"),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => Enteredscreen()),
                      (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

Widget _buildInput(TextEditingController controller, String label,
    {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false,
      VoidCallback? onTap,
      String? Function(String?)? validator}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
