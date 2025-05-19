import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:techlead/EmpHomescreen.dart';
import 'package:techlead/Enteredscreen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _moveUpAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _moveUpAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Darker Bluish Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF001B2D), Color(0xFF263A4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Dynamic Floating Particles with Neon Glow
          for (int i = 0; i < 5; i++) _buildDynamicFloatingParticle(i),

          // Center Content with Animations
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.5),
                      blurRadius: 25,
                      offset: const Offset(6, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with Neon Glow and Rotation (Gear or Engineering Icon)
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,

                        ),
                        child: Icon(
                          Icons.engineering,
                          size: 90,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        "Welcome to",
                        style: GoogleFonts.montserrat(
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              blurRadius: 25,
                              color: Colors.blueAccent.withOpacity(0.7),
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        "TechLead\nEngineering Solutions",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 35,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              blurRadius: 30,
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(4, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: ElevatedButton(
                        onPressed: () {
                         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Enteredscreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(35),
                          ),
                          elevation: 20,
                          shadowColor: Colors.blueAccent.withOpacity(0.7),
                          backgroundColor: Colors.black.withOpacity(0.6),
                        ).copyWith(
                          side: MaterialStateProperty.all(
                            BorderSide(color: Colors.white.withOpacity(0.7), width: 2),
                          ),
                        ),
                        child: Text(
                          "Start Your Journey",
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 15.0,
                                color: Colors.blueAccent.withOpacity(0.9),
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dynamic Floating Particle with Random Animation
  Widget _buildDynamicFloatingParticle(int index) {
    double randomTopPosition = (MediaQuery.of(context).size.height * 0.1 + (index * 50));
    double randomLeftPosition = (MediaQuery.of(context).size.width * 0.3 + (index * 40));

    return Positioned(
      top: randomTopPosition,
      left: randomLeftPosition,
      child: AnimatedContainer(
        duration: Duration(seconds: 3 + (index % 3)),
        width: 30 + (index % 3 * 10),
        height: 30 + (index % 3 * 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
