import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Employee/Authentication/EnLoginPage.dart';
import '../../Loginui/beizercontainer.dart';
import '../../Loginui/beizercontainerbottom.dart';
import '../../Loginui/beizercontainerleft.dart';
import '../Adminhomescreen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your username';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must be at least 8 characters,\ninclude upper and lower case letters,\n1 number and 1 special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

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

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('Empauth').doc(credential.user!.uid).set({
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'uid': credential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showToast("Registration successful!", Colors.green);

      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const NewPieShow()),
      );
    } on FirebaseAuthException catch (e) {
      _showToast(e.message ?? "Registration failed", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _backButton() {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(left: 0, top: 10, bottom: 10),
              child: const Icon(Icons.keyboard_arrow_left, color: Colors.white),
            ),
            const Text('Back',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white))
          ],
        ),
      ),
    );
  }

  Widget _entryField(String title,
      {bool isPassword = false,
        TextEditingController? controller,
        Widget? prefixIcon,
        String? Function(String?)? validator,
        bool isConfirmPassword = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          TextFormField(
            controller: controller,
            textInputAction: TextInputAction.next,
            onEditingComplete: () => FocusScope.of(context).nextFocus(),
            obscureText: isPassword
                ? (isConfirmPassword ? !_confirmPasswordVisible : !_passwordVisible)
                : false,
            validator: validator,
            style: const TextStyle(color: Colors.blueAccent),
              decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  prefixIcon: prefixIcon,
                  suffixIcon: isPassword
                      ? IconButton(
                    icon: Icon(
                      isConfirmPassword
                          ? (_confirmPasswordVisible ? Icons.visibility : Icons.visibility_off)
                          : (_passwordVisible ? Icons.visibility : Icons.visibility_off),
                      color: Colors.blueAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          _confirmPasswordVisible = !_confirmPasswordVisible;
                        } else {
                          _passwordVisible = !_passwordVisible;
                        }
                      });
                    },
                  )
                      : null,
                  hintText: 'Enter $title',
                  hintStyle: TextStyle(color: Colors.blue.shade900),
                errorStyle: TextStyle(color: Colors.cyanAccent,fontWeight: FontWeight.bold,fontSize: 12),

              ),

    ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(vertical: 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey, // dark blue
            Color(0xFF1976D2), // medium blue
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            offset:  Offset(2, 4),
            blurRadius: 5,
            spreadRadius: 2,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent, // needed for gradient to show
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: _handleSignUp,
          splashColor: Colors.white.withOpacity(0.3),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Register Now',
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }


  Widget _emailPasswordWidget() {
    return Column(
      children: <Widget>[
        _entryField("Username",
            controller: _usernameController,
            prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
            validator: _validateUsername),
        _entryField("Email id",
            controller: _emailController,
            prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
            validator: _validateEmail),
        _entryField("Password",
            isPassword: true,
            controller: _passwordController,
            prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
            validator: _validatePassword),
        _entryField("Confirm Password",
            isPassword: true,
            isConfirmPassword: true,
            controller: _confirmPasswordController,
            prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
            validator: _validateConfirmPassword),
      ],
    );
  }

  // Widget _loginAccountLabel() {
  //   return InkWell(
  //     onTap: () {
  //       Navigator.push(
  //           context, MaterialPageRoute(builder: (context) => const LoginPage()));
  //     },
  //     child: Container(
  //       margin: const EdgeInsets.symmetric(vertical: 20),
  //       padding: const EdgeInsets.all(15),
  //       alignment: Alignment.bottomCenter,
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: const <Widget>[
  //           Text(
  //             'Already have an account ?',
  //             style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  //           ),
  //           SizedBox(
  //             width: 10,
  //           ),
  //           Text(
  //             'Login',
  //             style: TextStyle(
  //                 color: Color(0xfff79c4f),
  //                 fontSize: 13,
  //                 fontWeight: FontWeight.w600),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _title() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        text: 'S',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
        children: [
          TextSpan(text: 'ig', style: TextStyle(color: Colors.white, fontSize: 30)),
          TextSpan(text: 'n Up', style: TextStyle(color: Colors.white, fontSize: 30)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.blue.shade900,
      body: Stack(
        children: <Widget>[

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(height: height * .2),
                _title(),
                const SizedBox(height: 30),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: _emailPasswordWidget(),
                        ),
                        const SizedBox(height: 35),
                        _submitButton(),
                        // const SizedBox(height: 20),
                        // _loginAccountLabel(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(top: 40, left: 0, child: _backButton()),
        ],
      ),
    );
  }
}
