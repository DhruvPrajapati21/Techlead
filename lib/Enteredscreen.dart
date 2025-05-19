import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/EnLoginPage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Alogin.dart';

class Enteredscreen extends StatefulWidget {
  const Enteredscreen({super.key});

  @override
  State<Enteredscreen> createState() => _EnteredscreenState();
}

class _EnteredscreenState extends State<Enteredscreen> with TickerProviderStateMixin {


  late AnimationController _textController;
  late AnimationController _imageController;

  late Animation<double> _techleadAnimation;
  late Animation<double> _theAnimation;
  late Animation<double> _engineeringAnimation;
  late Animation<double> _solutionAnimation;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();

    // Text Animation Controller (one-time)
    _textController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..forward();

    // Text Animations
    _techleadAnimation = Tween(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _theAnimation = Tween(begin: 200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _engineeringAnimation = Tween(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _solutionAnimation = Tween(begin: 200.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Flip Image Controller (repeats every 5 seconds)
    _imageController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1), // 1 sec flip duration
    );

    _flipAnimation = Tween<double>(begin: 0.0, end: 3.1416).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeInOut),
    );

    // Repeating flip every 5 seconds
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (_imageController.status == AnimationStatus.completed ||
          _imageController.status == AnimationStatus.dismissed) {
        _imageController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Widget _buildCard(Widget content, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        width: 160,
        margin: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.0),
          border: Border.all(
            color: Colors.white,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.9),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 0), // Shadow all around
            ),
          ],
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand( // Ensures background fills entire screen
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD4E9FB), // deeper bluish-white
                Color(0xFFBBDDFD), // cool light blue
                Color(0xFFD9EBF8), // muted steel blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image with border and gradient background
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            "assets/images/ppo.jpg",
                            height: 170,
                            width: 350,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Animated App name row with animation from different directions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Techlead animation from the left
                          AnimatedBuilder(
                            animation: _techleadAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_techleadAnimation.value, 0),
                                child: child,
                              );
                            },
                            child: Text(
                              "Techlead",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 1.5,
                                color: Colors.blue.shade900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 6),

                          // "The" animation from the right
                          AnimatedBuilder(
                            animation: _theAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_theAnimation.value, 0),
                                child: child,
                              );
                            },
                            child: Text(
                              "The",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 1.5,
                                color: Colors.blue.shade900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 6),

                          // Engineering animation from the top
                          AnimatedBuilder(
                            animation: _engineeringAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _engineeringAnimation.value),
                                child: child,
                              );
                            },
                            child: Text(
                              "Engineering",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                letterSpacing: 1.5,
                                color: Colors.blue.shade900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Solution animation from the bottom
                          AnimatedBuilder(
                            animation: _solutionAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _solutionAnimation.value),
                                child: child,
                              );
                            },
                            child: Text(
                              "Solution",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                letterSpacing: 1.5,
                                color: Colors.blue.shade900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.1),
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Login option cards
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildCard(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/al.jpg",
                              height: 100,
                              width: 150,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Admin Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
                        },
                      ),
                      _buildCard(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              "assets/images/ul.jpg",
                              height: 100,
                              width: 150,
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Employee Login",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: const [
                        SocialButton(
                          assetPath: 'assets/images/globe.png',
                          label: 'Website',
                          url: 'https://techleadsolution.in/',
                        ),
                        SocialButton(
                          assetPath: 'assets/images/facebook.png',
                          label: 'Facebook',
                          url: 'https://www.facebook.com/techleadtheengineeringsolution/',
                        ),
                        SocialButton(
                          assetPath: 'assets/images/instagram.png',
                          label: 'Instagram',
                          url: 'https://www.instagram.com/techleadhomeautomation/',
                        ),
                        SocialButton(
                          assetPath: 'assets/images/linkedin.png',
                          label: 'LinkedIn',
                          url: 'https://in.linkedin.com/company/techlead-the-engineering-solutions',
                        ),
                        SocialButton(
                          assetPath: 'assets/images/youtubem.png',
                          label: 'YouTube',
                          url: 'https://www.youtube.com/@techleadautomation2120',
                        ),
                      ],
                    ),
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SocialButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final String url;

  const SocialButton({
    Key? key,
    required this.assetPath,
    required this.label,
    required this.url,
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Falling back to platformDefault');
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('launchUrl error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $label')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchURL(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 50,
            width: 50,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
