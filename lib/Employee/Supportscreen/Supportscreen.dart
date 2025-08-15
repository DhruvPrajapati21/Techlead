import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _responsiveFontSize(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return base * 1.6; // Large tablet
    if (width > 600) return base * 1.3; // Small tablet
    return base; // Phone
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return const EdgeInsets.all(32.0);
    if (width > 600) return const EdgeInsets.all(20.0);
    return const EdgeInsets.all(16.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_in_talk_rounded,
                color: Colors.white, size: _responsiveFontSize(context, 22)),
            const SizedBox(width: 8.0),
            Text(
              "Contact Us",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: _responsiveFontSize(context, 20),
                shadows: const [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2.0,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        flexibleSpace: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF144E8C), Color(0xFF0A2540)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: screenWidth > 600 ? 140 : 115,
              left: MediaQuery.of(context).size.width / 2 - 50,
              child: Image.asset(
                'assets/images/enteredscreen.png',
                width: screenWidth > 600 ? 120 : 100,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(150.0),
          child: Column(
            children: [
              const Divider(
                  color: Colors.white54, thickness: 1.0, indent: 20.0, endIndent: 20.0),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "We’re here to assist you with all your inquiries",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: _responsiveFontSize(context, 14),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF144E8C), Color(0xFF0A2540)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: _responsivePadding(context),
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenWidth > 600 ? 350 : 300),
                    Text(
                      "Reach out to us for expert advice on Home automation solutions!",
                      style: GoogleFonts.lato(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: _responsiveFontSize(context, 22),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    ContactDetail(
                      icon: Icons.location_on,
                      title: "Address",
                      detail:
                      "A-303, S.G.Business Hub, Sarkhej - Gandhinagar Highway, Gota, Ahmedabad, Gujarat 380060",
                      actionUrl:
                      "https://www.google.com/maps/search/?api=1&query=A-303,+S.G.Business+Hub,+Sarkhej+-+Gandhinagar+Highway,+Gota,+Ahmedabad,+Gujarat+380060",
                      fontSize: _responsiveFontSize(context, 15),
                    ),
                    const SizedBox(height: 16.0),
                    ContactDetail(
                      icon: Icons.email,
                      title: "Email",
                      detail: "info@techleadsolution.in",
                      actionUrl: "mailto:info@techleadsolution.in",
                      fontSize: _responsiveFontSize(context, 15),
                    ),
                    const SizedBox(height: 16.0),
                    ContactDetail(
                      icon: Icons.phone,
                      title: "Phone",
                      detail: "+91 9586 889988",
                      actionUrl: "tel:+919586889988",
                      fontSize: _responsiveFontSize(context, 15),
                    ),
                    const SizedBox(height: 16.0),
                    ContactDetail(
                      icon: Icons.language,
                      title: "Website",
                      detail: "https://techleadsolution.in",
                      actionUrl: "https://techleadsolution.in",
                      fontSize: _responsiveFontSize(context, 15),
                    ),
                    const Divider(color: Colors.white54, thickness: 1.0),
                    const SizedBox(height: 16.0),
                    Text(
                      "Ride the wave of the future with our trendsetting home automation services. Seamlessly integrate smart technology, stay ahead.",
                      style: GoogleFonts.openSans(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: _responsiveFontSize(context, 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      "Follow Us on Social",
                      style: GoogleFonts.roboto(
                        textStyle: TextStyle(
                          color: Colors.white,
                          fontSize: _responsiveFontSize(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16.0,
                      runSpacing: 16.0,
                      children: const [
                        SocialButton(
                          assetPath: 'assets/images/facebook.png',
                          label: "Facebook",
                          url:
                          "https://www.facebook.com/techleadtheengineeringsolution/",
                        ),
                        SocialButton(
                          assetPath: 'assets/images/instagram.png',
                          label: "Instagram",
                          url:
                          "https://www.instagram.com/techleadhomeautomation/",
                        ),
                        SocialButton(
                          assetPath: 'assets/images/linkedin.png',
                          label: "LinkedIn",
                          url:
                          "https://in.linkedin.com/company/techlead-the-engineering-solutions",
                        ),
                        SocialButton(
                          assetPath: 'assets/images/youtubem.png',
                          label: "YouTube",
                          url:
                          "https://www.youtube.com/@techleadautomation2120",
                        ),
                      ],
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
}

class ContactDetail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;
  final String? actionUrl;
  final double fontSize;

  const ContactDetail({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.actionUrl,
    required this.fontSize,
  });

  Future<void> _handleTap(BuildContext context) async {
    if (actionUrl != null) {
      final Uri uri = Uri.parse(actionUrl!);
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $title')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Card(
        color: Colors.blue.shade900,
        elevation: 5.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF144E8C), Color(0xFF0A2540)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(icon, color: Colors.white, size: fontSize + 8),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                    const SizedBox(height: 4.0),
                    Text(
                      detail,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize - 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    super.key,
    required this.assetPath,
    required this.label,
    required this.url,
  });

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
    final double size =
    MediaQuery.of(context).size.width > 600 ? 36 : 28; // Responsive icon size

    return Column(
      children: [
        GestureDetector(
          onTap: () => _launchURL(context),
          child: CircleAvatar(
            radius: size,
            backgroundColor: Colors.white.withOpacity(0.85),
            backgroundImage: AssetImage(assetPath),
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize:
            MediaQuery.of(context).size.width > 600 ? 15 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
