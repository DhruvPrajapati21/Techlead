import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Adminhomescreeen.dart';
import 'Adminloginuipart.dart';
import 'Enteredscreen.dart';
import 'newpie.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController adminNameController = TextEditingController();
  TextEditingController adminIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoginAttempted = false;
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body:CustomPaint(
          painter: CombinedBackgroundPainter(),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Image.asset(
                        'assets/images/profile.png',
                        width: 280,
                        height: 150,
                      ),
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Arial',
                        ),
                      ),
                      const SizedBox(height: 40),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: _isLoginAttempted
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          child: Column(
                            children: [
                              _buildTextField(
                                label: 'Username',
                                hint: 'Enter Your Email Address',
                                controller: _emailController,
                                icon: Icons.person_outline,
                                validator: (value) {
                                  final emailRegex = RegExp(
                                    r"^[a-zA-Z0-9._%+-]+@(gmail\.com|[a-zA-Z0-9.-]+\.(com|in))$",
                                  );
                                  if (value == null || value.isEmpty) {
                                    return "Please enter your email";
                                  } else if (!emailRegex.hasMatch(value)) {
                                    return "Please enter a valid email";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                label: 'Password',
                                hint: 'Enter Password',
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                obscureText: !_passwordVisible,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter your Password";
                                  } else if (value.length < 8) {
                                    return "Password must be at least 8 characters long";
                                  } else if (!RegExp(
                                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={};:<>|./?,-]).{8,}$')
                                      .hasMatch(value)) {
                                    return "Password must contain upper, lower, number & special character";
                                  }
                                  return null;
                                },
                              ),


                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            setState(() => _isLoginAttempted = true);
                            if (_formKey.currentState!.validate()) {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();

                              Map<String, Map<String, String>> validCredentials = {
                                'techlead@gmail.com': {
                                  'password': 'Techlead@2020',
                                  'name': 'Techlead Team',
                                  'id': 'Techlead12',
                                },
                                'Pratik.techlead@gmail.com': {
                                  'password': 'Prateek@123',
                                  'name': 'Pratik Patel',
                                  'id': 'Techlead13',
                                },
                                'Vivek9.techlead@gmail.com': {
                                  'password': 'Vivek@123',
                                  'name': 'Vivek Sharma',
                                  'id': 'Techlead14',
                                },
                                'ankit29.techlead@gmail.com': {
                                  'password': 'Ankit@123',
                                  'name': 'Ankit Parekh',
                                  'id': 'Techlead15',
                                },
                                'krutarth23.techlead@gmail.com': {
                                  'password': 'Krutarth@123',
                                  'name': 'Krutarth Patel',
                                  'id': 'Techlead16',
                                },
                                'Deep6.techlead@gmail.com': {
                                  'password': 'Deep@123',
                                  'name': 'Deep Akhani',
                                  'id': 'Techlead17',
                                },
                              };

                              if (validCredentials.containsKey(email) &&
                                  validCredentials[email]!['password'] == password) {
                                adminNameController.text =
                                validCredentials[email]!['name']!;
                                adminIdController.text = validCredentials[email]!['id']!;

                                Fluttertoast.showToast(
                                  msg: "Login successful",
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );

                                loginUser();
                              } else {
                                Fluttertoast.showToast(
                                  msg: "Invalid email or password",
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF003366), Color(0xFF0F52BA)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "LogIn",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    Widget? suffixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            inputDecorationTheme: const InputDecorationTheme(
              errorStyle: TextStyle(
                color: Color(0xFF02FAFA), // Dark cyan accent
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            validator: validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white12,
              prefixIcon: Icon(icon, color: Colors.white),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(String assetPath) {
    return CircleAvatar(
      backgroundColor: Colors.white12,
      radius: 22,
      child: Image.asset(assetPath, height: 24),
    );
  }

  Future<void> loginUser() async {
    setState(() {
      _isLoginAttempted = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);

    // 👇 Save Admin Name and ID to SharedPreferences
    prefs.setString('name', adminNameController.text);
    prefs.setString('id', adminIdController.text);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NewPieShow()),
    );
  }
}
class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Start from the top-left corner
    path.lineTo(0, 0);

    // Draw a curve from top-left to top-right
    path.quadraticBezierTo(size.width * 0.5, -40, size.width, 0);

    // Draw a line to the bottom-right corner
    path.lineTo(size.width, size.height);

    // Draw a line to the bottom-left corner
    path.lineTo(0, size.height);

    // Close the path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}