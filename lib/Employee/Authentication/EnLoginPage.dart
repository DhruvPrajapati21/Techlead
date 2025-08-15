import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techlead/Employee/Homescreen/EmpHomescreen.dart';
import '../../Loginui/beizercontainer.dart';
import '../../Loginui/beizercontainerbottom.dart';
import '../../Loginui/beizercontainerleft.dart';

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

  Widget _entryField(
      String title, {
        bool isPassword = false,
        TextEditingController? controller,
        String? Function(String?)? validator,
        bool isInvalid = false,
        String? hintText,
        Color hintTextColor = Colors.white,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [ Color(0xFF000F89), // Royal Blue
                    Color(0xFF0F52BA), // Cobalt Blue (replacing Indigo)
                    Color(0xFF002147),],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: controller,
                textInputAction: TextInputAction.next,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
                obscureText: isPassword && !_isPasswordVisible,
                validator: validator,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    isPassword ? Icons.lock_outline : Icons.email_outlined,
                    color: Colors.white,
                  ),
                  suffixIcon: isPassword
                      ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                      : null,
                  hintText: hintText,
                  hintStyle: GoogleFonts.poppins(color: hintTextColor),
                  errorStyle: GoogleFonts.poppins(
                    color: Colors.cyanAccent, // 👈 set error text color here
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF000F89), // Royal Blue
              Color(0xFF0F52BA), // Cobalt Blue
              Color(0xFF002147), // Deep Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
          color: Colors.white,
        )
            : Text(
          'Login',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1,
          ),
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
                top: -height * 0.15,
                left: MediaQuery.of(context).size.width * 0.25,
                right: MediaQuery.of(context).size.width * 0.25,
                child: const BezierContainer(),  // adjust size inside container
              ),

              // Left Center
              Positioned(
                top: height * 0.25,
                left: -MediaQuery.of(context).size.width * 0.3,
                child: const BezierContainerLeft(),
              ),

              // Right Center
              Positioned(
                top: height * 0.25,
                right: -MediaQuery.of(context).size.width * 0.3,
                child: const BezierContainer(), // You'll need to create this if not existing
              ),

              // Bottom Center
              Positioned(
                bottom: -height * 0.15,
                left: MediaQuery.of(context).size.width * 0.25,
                right: MediaQuery.of(context).size.width * 0.25,
                child: const BezierContainerBottom(),
              ),

              // Center (optional, or can be your main content)
              Positioned(
                top: height * 0.4,
                left: MediaQuery.of(context).size.width * 0.3,
                right: MediaQuery.of(context).size.width * 0.3,
                child: const BezierContainerBottom(),  // Optional, create if needed
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start, // <-- changed here
                    children: <Widget>[
                      SizedBox(height: height * .1),  // You can adjust this space if needed
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
    return Column(
      children: [
        const Icon(
          Icons.lock_outline, // You can change this to any icon you like
          size: 60,
          color: Colors.white,
        ),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            text: 'L',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
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
        ),
      ],
    );
  }

}