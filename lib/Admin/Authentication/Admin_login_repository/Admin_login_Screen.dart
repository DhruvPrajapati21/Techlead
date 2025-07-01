import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Adminhomescreen.dart';
import 'Adminloginuipart.dart';
import 'login_button.dart';
import 'login_controller.dart';
import 'login_form.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}



class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoginAttempted = false;
  bool _passwordVisible = false;


  Future<void> loginUser(Map<String, String> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isAdmin', true);

    // Store actual admin name and ID instead of email/password
    await prefs.setString('name', userData['name'] ?? '');
    await prefs.setString('id', userData['id'] ?? '');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const NewPieShow()),
    );
  }

  void _handleLogin() {
    setState(() {
      _isLoginAttempted = true;
    });

    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userData = LoginController.verifyCredentials(email, password);
      if (userData != null) {
        loginUser(userData); // Pass correct name/id
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid email or password"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: CombinedBackgroundPainter(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Image.asset(
                          'assets/images/profile.png',
                          width: 280,
                          height: 150,
                        ),
                        const Text(
                          "Admin Login",
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30),
                          child: LoginForm(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            isLoginAttempted: _isLoginAttempted,
                            passwordVisible: _passwordVisible,
                            onTogglePasswordVisibility: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                        const Spacer(),
                        LoginButton(onTap: _handleLogin),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
