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
        backgroundColor: Colors.blue,
        title: Text(
          "View Guidelines",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
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
                  color: Colors.white60,
                  margin: EdgeInsets.all(11.0),
                  child: ListTile(
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Headlines: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                TextSpan(
                                  text: '${GuidelinesModel.headlines}',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Guildlines: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black),
                                ),
                                TextSpan(
                                  text: '${GuidelinesModel.guidelines}',
                                  style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30),
                          TextButton(
                            onPressed: () {
                              _launchEmail('${GuidelinesModel.contactus}');
                            },
                            child:RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Contactus: ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  TextSpan(
                                    text: '${GuidelinesModel.contactus}',
                                    style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 10,),
                          Row(
                            children: [
                              SizedBox(width: 5,),
                              Text(
                                'Reported Date & Time: ',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 11),
                              ),
                              Text(
                                GuidelinesModel.reportedDateTime != null
                                    ? DateFormat('dd/MM/yyyy HH:mm:ss').format(
                                    GuidelinesModel.reportedDateTime.toDate())
                                    : 'N/A',
                                style: TextStyle(fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
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
  final Uri _emailLaunchUri = Uri(
    scheme: 'mailto',
    path: emailAddress,
    queryParameters: {
      'subject': 'Your subject here',
      'body': 'Your message here',
    },
  );
  if (await canLaunch(_emailLaunchUri.toString())) {
    await launch(_emailLaunchUri.toString());
  } else {
    throw 'Could not launch $_emailLaunchUri';
  }
}
