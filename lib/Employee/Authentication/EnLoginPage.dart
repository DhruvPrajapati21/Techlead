import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:techlead/EmpHomescreen.dart';
import '../cusmedezeui/beizercontainer.dart';
import '../cusmedezeui/beizercontainerbottom.dart';
import '../cusmedezeui/beizercontainerleft.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isInvalidEmail = false;
  bool _isInvalidPassword = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid Gmail address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must be at least 8 characters,\ninclude upper and lower case letters,\nand at least 1 number';
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isInvalidEmail = false;
      _isInvalidPassword = false;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _showToast("Login successful!", Colors.green);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isInvalidEmail = true;
        _isInvalidPassword = true;

        if (e.code == 'user-not-found') {
          _errorMessage = "No user found for that email.";
        } else if (e.code == 'wrong-password') {
          _errorMessage = "Incorrect password. Please try again!";
        } else {
          _errorMessage = "Username and Password do not match. Please try again!";
        }
      });

      _showToast(_errorMessage!, Colors.red);
    } catch (e) {
      setState(() {
        _errorMessage = "An unexpected error occurred. Please try again.";
      });

      _showToast(_errorMessage!, Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _entryField(String title,
      {bool isPassword = false,
        TextEditingController? controller,
        String? Function(String?)? validator,
        bool isInvalid = false,
        String? hintText,
        Color hintTextColor = Colors.white,
        List<Color> gradientColors = const [Color(0xFF0062BA), Color(0xFF176CEF)]}) { // Added gradientColors parameter
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: isPassword && !_isPasswordVisible,
              validator: validator,
              style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: hintTextColor),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                suffixIcon: isPassword
                    ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blueAccent,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailPasswordWidget() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          _entryField(
            "Email id",
            controller: _emailController,
            validator: _validateEmail,
            isInvalid: _isInvalidEmail,
            hintText: "Enter your email address",
            hintTextColor: Colors.white,
          ),
          _entryField(
            "Password",
            isPassword: true,
            controller: _passwordController,
            validator: _validatePassword,
            isInvalid: _isInvalidPassword,
            hintText: "Enter your password",
            hintTextColor: Colors.white,
          ),
        ],
      ),
    );
  }


  Widget _submitButton() {
    return GestureDetector(
      onTap: _handleLogin,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          boxShadow: <BoxShadow>[
            BoxShadow(

              offset: const Offset(2, 4),
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF002A55), Color(0xFF2F7DF3)],
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
          'Login',
          style: TextStyle(fontSize: 20, color: Colors.white,fontWeight: FontWeight.bold),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF003366), Color(0xFF0F52BA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SizedBox(
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned(
                top: -height * .15,
                right: -MediaQuery.of(context).size.width * .25,
                child: const BezierContainer(),
              ),
              Positioned(
                top: -height * .05,
                right: -MediaQuery.of(context).size.width * -.6,
                child: const BezierContainerLeft(),
              ),
              Positioned(
                top: height * 0.7,
                right: -MediaQuery.of(context).size.width * -.4,
                child: const BezierContainerBottom(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: height * .2),
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      _title(),
                      const SizedBox(height: 50),
                      _emailPasswordWidget(),
                      const SizedBox(height: 40),
                      _submitButton(),
                      // Container(
                      //   padding: const EdgeInsets.symmetric(vertical: 10),
                      //   alignment: Alignment.centerRight,
                      //   child: GestureDetector(
                      //     onTap: () {
                      //       Navigator.push(
                      //         context,
                      //         MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      //       );
                      //     },
                      //     child: const Text(
                      //       'Forgot Password ?',
                      //       style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.blue),
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(height: 20),
                      // _createAccountLabel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        text: 'L',
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
        children: [
          TextSpan(
            text: 'og',
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
          TextSpan(
            text: 'in',
            style: TextStyle(color: Colors.white, fontSize: 30),
          ),
        ],
      ),
    );
  }

//   Widget _createAccountLabel() {
//     return InkWell(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
//       },
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 20),
//         padding: const EdgeInsets.all(15),
//         alignment: Alignment.bottomCenter,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const <Widget>[
//             Text(
//               'Don\'t have an account ?',
//               style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
//             ),
//             SizedBox(width: 10),
//             Text(
//               'SignUp',
//               style: TextStyle(color: Color(0xfff79c4f), fontSize: 13, fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
}
