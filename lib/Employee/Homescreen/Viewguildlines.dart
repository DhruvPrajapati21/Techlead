import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Guildlinesmodel.dart';

class Viewguildlines extends StatefulWidget {
  const Viewguildlines({super.key});

  @override
  State<Viewguildlines> createState() => _ViewguildlinesState();
}

class _ViewguildlinesState extends State<Viewguildlines> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Guidelines",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF000F89), // Royal Blue
                Color(0xFF0F52BA), // Cobalt Blue
                Color(0xFF002147), // Deep Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Guidelines')
            .orderBy('reportedDateTime', descending: false)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No Guildlines data available!'));
          }
          List<GuidelinesModel> Guidelines = snapshot.data!.docs.map((doc) => GuidelinesModel.fromSnapshot(doc)).toList();
          List<GuidelinesModel> Guide = [];
          snapshot.data!.docs.forEach((doc) {
            GuidelinesModel headlines = GuidelinesModel.fromSnapshot(doc);
            GuidelinesModel guidelines = GuidelinesModel.fromSnapshot(doc);
            GuidelinesModel contactus = GuidelinesModel.fromSnapshot(doc);

            Guide.add(headlines);
            Guide.add(guidelines);
            Guide.add(contactus);
          });

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var GuidelinesModel = Guidelines[index];
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  margin: EdgeInsets.all(11.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF000F89), // Royal Blue
                          Color(0xFF0F52BA), // Cobalt Blue
                          Color(0xFF002147), // Deep Blue
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // HEADLINES
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.title, color: Colors.cyanAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Headlines: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.cyanAccent),
                                    ),
                                    TextSpan(
                                      text: '${GuidelinesModel.headlines}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // GUIDELINES
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.rule, color: Colors.cyanAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Guidelines: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.cyanAccent),
                                    ),
                                    TextSpan(
                                      text: '${GuidelinesModel.guidelines}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // CONTACT US
                        // CONTACT US
                        // CONTACT US
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.email, color: Colors.cyanAccent, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _launchEmail('${GuidelinesModel.contactus}');
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'Contact Us (Email-id): ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.cyanAccent,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${GuidelinesModel.contactus}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              decoration: TextDecoration.underline, // underline only email
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Note: Click the email ID to contact the admin.',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),



                        SizedBox(height: 10),

                        // DATE & TIME
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.cyanAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Reported Date & Time: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                  fontSize: 11),
                            ),
                            Expanded(
                              child: Text(
                                GuidelinesModel.reportedDateTime != null
                                    ? DateFormat('dd/MM/yyyy HH:mm:ss').format(
                                    GuidelinesModel.reportedDateTime.toDate())
                                    : 'N/A',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );


        },
      ),
    );
  }
}
_launchEmail(String emailAddress) async {
  final Uri emailUri = Uri(
    scheme: 'mailto',
    path: emailAddress,
    queryParameters: {
      'subject': 'Your subject here',
      'body': 'Your message here',
    },
  );

  if (await canLaunchUrl(emailUri)) {
    await launchUrl(emailUri);
  } else {
    Fluttertoast.showToast(
      msg: "No email app found. Please install an email client.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
    );
  }
}