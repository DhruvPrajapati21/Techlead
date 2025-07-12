import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techlead/Employee/Authentication/EnLoginPage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Admin/Authentication/Admin_login_repository/Admin_login_Screen.dart';

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

  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _iconAnimations;

  final List<Map<String, String>> _socialButtons = [
    {
      'asset': 'assets/images/globe.png',
      'label': 'Website',
      'url': 'https://techleadsolution.in/',
    },
    {
      'asset': 'assets/images/facebook.png',
      'label': 'Facebook',
      'url': 'https://www.facebook.com/techleadtheengineeringsolution/',
    },
    {
      'asset': 'assets/images/instagram.png',
      'label': 'Instagram',
      'url': 'https://www.instagram.com/techleadhomeautomation/',
    },
    {
      'asset': 'assets/images/linkedin.png',
      'label': 'LinkedIn',
      'url': 'https://in.linkedin.com/company/techlead-the-engineering-solutions',
    },
    {
      'asset': 'assets/images/youtubem.png',
      'label': 'YouTube',
      'url': 'https://www.youtube.com/@techleadautomation2120',
    },
  ];

  @override
  void initState() {
    super.initState();

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

    Timer.periodic(Duration(seconds: 5), (timer) {
      if (_imageController.status == AnimationStatus.completed ||
          _imageController.status == AnimationStatus.dismissed) {
        _imageController.forward(from: 0.0);
      }
    });
    _iconControllers = List.generate(
      _socialButtons.length,
          (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 600),
      ),
    );

    _iconAnimations = _iconControllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    for (int i = 0; i < _iconControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        _iconControllers[i].forward();
      });
    }

  }

  @override
  void dispose() {
    _textController.dispose();
    _imageController.dispose();
    for (final controller in _iconControllers) {
      controller.dispose();
    }

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
            colors: [
              Color(0xFF000F89), // Royal Blue
              Color(0xFF0F52BA), // Cobalt Blue
              Color(0xFF002147), // Midnight Blue
            ],
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
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000F89), // Royal Blue
                Color(0xFF0F52BA), // Cobalt Blue
                Color(0xFF002147), // Midnight Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image with border and gradient background
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Center(
                      child: Image.asset(
                        "assets/images/enteredscreen.png",
                        height: 170,
                        width: 300,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),


                  const SizedBox(height: 30),

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
                                color: Colors.cyanAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AdminLoginScreen()),
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
                                color: Colors.cyanAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 70),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: List.generate(_socialButtons.length, (index) {
                        final item = _socialButtons[index];
                        return RotationTransition(
                          turns: _iconAnimations[index],
                          child: SocialButton(
                            assetPath: item['asset']!,
                            label: item['label']!,
                            url: item['url']!,
                          ),
                        );
                      }),
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
  final Animation<double>? rotationAnimation;

  const SocialButton({
    Key? key,
    required this.assetPath,
    required this.label,
    required this.url,
    this.rotationAnimation, // <-- Now nullable
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
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

            child: rotationAnimation != null
                ? RotationTransition(
              turns: rotationAnimation!,
              child: Image.asset(assetPath, fit: BoxFit.contain),
            )
                : Image.asset(assetPath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
