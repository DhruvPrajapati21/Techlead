import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:techlead/newpie.dart';

import 'cusmedezeui/beizercontainer.dart';
import 'cusmedezeui/beizercontainerbottom.dart';
import 'cusmedezeui/beizercontainerleft.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  void _showToast(String message, Color bgColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: bgColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Empauth')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() => _isVerified = true);
        _showToast("Email verified! Please enter a new password.", Colors.green);
      } else {
        _showToast("Email not found in Empauth collection. Please try again.", Colors.red);
      }
    } catch (e) {
      _showToast("Error: ${e.toString()}", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Empauth')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();

      if (snapshot.docs.isEmpty) {
        _showToast("Email not found in Empauth collection.", Colors.red);
        return;
      }

      await FirebaseFirestore.instance
          .collection('Empauth')
          .doc(snapshot.docs.first.id)
          .update({'password': _newPasswordController.text.trim()});

      _showToast("Password reset successfully!", Colors.green);

      _formKey.currentState!.reset();
      _emailController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => NewPieShow()));
    } catch (e) {
      _showToast("Error: ${e.toString()}", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            label == 'Email' ? Icons.email : Icons.lock,
            color: Colors.pink,
          ),
          suffixIcon: (label == 'New Password' || label == 'Confirm Password')
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility : Icons.visibility_off,
              color: Colors.pink,
            ),
            onPressed: toggleVisibility,
          )
              : null,
          border: OutlineInputBorder(borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.pink.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.blueAccent, Colors.deepPurpleAccent],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade200,
              blurRadius: 5,
              offset: const Offset(2, 4),
              spreadRadius: 2,
            ),
          ],
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
          label,
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _backButton() {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: const [
            Padding(
              padding: EdgeInsets.only(left: 0, top: 10, bottom: 10),
              child: Icon(Icons.keyboard_arrow_left, color: Colors.white),
            ),
            Text('Back',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: BezierContainer()),
          const Positioned(bottom: 0, left: 0, right: 0, child: BezierContainerBottom()),
          const Positioned(left: 0, bottom: 0, child: BezierContainerLeft()),
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Forgot Password',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: 'Email',
                            controller: _emailController,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Email is required';
                              if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                            readOnly: _isVerified,
                          ),
                          if (_isVerified) ...[
                            _buildTextField(
                              label: 'New Password',
                              controller: _newPasswordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Password is required';
                                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$')
                                    .hasMatch(value)) {
                                  return 'Password must contain letters, numbers, and symbols';
                                }
                                return null;
                              },
                              obscureText: !_showNewPassword,
                              toggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                            ),
                            _buildTextField(
                              label: 'Confirm Password',
                              controller: _confirmPasswordController,
                              validator: (value) {
                                if (value != _newPasswordController.text) return 'Passwords do not match';
                                return null;
                              },
                              obscureText: !_showConfirmPassword,
                              toggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                          ],
                          const SizedBox(height: 30),
                          _buildButton(
                            label: _isVerified ? 'Reset Password' : 'Verify Email',
                            onTap: _isVerified ? _resetPassword : _verifyEmail,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(top: 40, left: 0, child: _backButton()),
        ],
      ),
    );
  }
}
