import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EmpShowData extends StatefulWidget {
  const EmpShowData({super.key});

  @override
  State<EmpShowData> createState() => _EmpShowDataState();
}

class _EmpShowDataState extends State<EmpShowData> {
  List<Map<String, dynamic>> profileList = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('EmpProfile').get();

      setState(() {
        profileList = snapshot.docs
            .map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'docId': doc.id,
        })
            .toList();
      });
    } catch (e) {
      print('Error loading profiles: $e');
    }
  }

  void _showEditProfileSheet(Map<String, dynamic> profileData) {
    final GlobalKey<FormState> _editFormKey = GlobalKey<FormState>();

    final fullNameController =
    TextEditingController(text: profileData['fullName']);
    final empIdController = TextEditingController(text: profileData['empId']);
    final dobController = TextEditingController(text: profileData['dob']);
    final qualificationController =
    TextEditingController(text: profileData['qualification']);
    final addressController =
    TextEditingController(text: profileData['address']);
    final mobileController = TextEditingController(text: profileData['mobile']);
    final emailController = TextEditingController(text: profileData['email']);
    final dateOfJoiningController =
    TextEditingController(text: profileData['dateOfJoining']);

    String imageUrl = profileData['profileImage'] ?? '';
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Form(
                key: _editFormKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.blueAccent),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : const AssetImage('assets/images/gallery.png')
                          as ImageProvider,
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt,
                              color: Colors.blueAccent),
                          onPressed: () async {
                            showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.camera),
                                        title: const Text('Take a photo'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final picked = await ImagePicker()
                                              .pickImage(
                                              source: ImageSource.camera);
                                          if (picked != null) {
                                            setModalState(() {
                                              selectedImage = File(picked.path);
                                            });
                                          }
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.folder),
                                        title: const Text('Choose from files'),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          final picked = await ImagePicker()
                                              .pickImage(
                                              source: ImageSource.gallery);
                                          if (picked != null) {
                                            setModalState(() {
                                              selectedImage = File(picked.path);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isUploading) const CircularProgressIndicator(),
                    _buildInput(fullNameController, 'Full Name',
                        validator: (val) =>
                        val!.isEmpty ? 'Enter name' : null),
                    _buildInput(empIdController, 'Employee ID',
                        validator: (val) =>
                        val!.isEmpty ? 'Enter Employee ID' : null),
                    _buildInput(dobController, 'DOB',
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(dobController.text) ??
                                DateTime.now(),
                            firstDate: DateTime(1950),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            dobController.text =
                            picked.toIso8601String().split('T')[0];
                          }
                        },
                        validator: (val) =>
                        val!.isEmpty ? 'Pick DOB' : null),
                    _buildInput(qualificationController, 'Qualification',
                        validator: (val) =>
                        val!.isEmpty ? 'Enter qualification' : null),
                    _buildInput(addressController, 'Address',
                        validator: (val) =>
                        val!.isEmpty ? 'Enter address' : null),
                    _buildInput(mobileController, 'Mobile',
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter mobile number';
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(val)) {
                            return 'Enter valid 10-digit number';
                          }
                          return null;
                        }),
                    _buildInput(emailController, 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter email';
                          }
                          if (!RegExp(r'^[\w-\.]+@gmail\.com$')
                              .hasMatch(val)) {
                            return 'Enter valid Gmail ID';
                          }
                          return null;
                        }),
                    _buildInput(dateOfJoiningController, 'Joining Date',
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.tryParse(
                                dateOfJoiningController.text) ??
                                DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            dateOfJoiningController.text =
                            picked.toIso8601String().split('T')[0];
                          }
                        },
                        validator: (val) =>
                        val!.isEmpty ? 'Pick joining date' : null),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_editFormKey.currentState!.validate()) {
                          setModalState(() => isUploading = true);

                          String? newImageUrl = imageUrl;
                          try {
                            if (selectedImage != null) {
                              final ref = FirebaseStorage.instance
                                  .ref()
                                  .child('profile_images')
                                  .child(
                                  '${DateTime.now().millisecondsSinceEpoch}.jpg');
                              await ref.putFile(selectedImage!);
                              newImageUrl = await ref.getDownloadURL();
                            }

                            final updatedData = {
                              'fullName': fullNameController.text.trim(),
                              'empId': empIdController.text.trim(),
                              'dob': dobController.text.trim(),
                              'qualification':
                              qualificationController.text.trim(),
                              'address': addressController.text.trim(),
                              'mobile': mobileController.text.trim(),
                              'email': emailController.text.trim(),
                              'dateOfJoining':
                              dateOfJoiningController.text.trim(),
                              'profileImage': newImageUrl ?? '',
                            };

                            await FirebaseFirestore.instance
                                .collection('EmpProfile')
                                .doc(profileData['docId'])
                                .update(updatedData);

                            _loadProfileData();
                            Navigator.pop(context);
                          } catch (e) {
                            print('Update error: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Update failed')));
                          } finally {
                            setModalState(() => isUploading = false);
                          }
                        }
                      },
                      icon: const Icon(Icons.update),
                      label: const Text('Update Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInput(TextEditingController controller, String label,
      {bool readOnly = false,
        TextInputType keyboardType = TextInputType.text,
        void Function()? onTap,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("All Employee Profiles",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: profileList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: profileList.length,
        itemBuilder: (context, index) {
          final profile = profileList[index];
          return Card(
            elevation: 6,
            margin: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _showEditProfileSheet(profile),
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profile['profileImage'] != null &&
                        profile['profileImage'].isNotEmpty
                        ? NetworkImage(profile['profileImage'])
                        : null,
                    child: (profile['profileImage'] == null ||
                        profile['profileImage'].isEmpty)
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow("Full Name", profile['fullName']),
                  _buildInfoRow("Employee ID", profile['empId']),
                  _buildInfoRow("DOB", profile['dob']),
                  _buildInfoRow(
                      "Qualification", profile['qualification']),
                  _buildInfoRow(
                    "Department",
                    profile['categories'] != null
                        ? (profile['categories'] as List<dynamic>)
                        .join(', ')
                        : "N/A",
                  ),
                  _buildInfoRow("Address", profile['address']),
                  _buildInfoRow("Mobile", profile['mobile']),
                  _buildInfoRow("Email", profile['email']),
                  _buildInfoRow("Joining Date", profile['dateOfJoining']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
