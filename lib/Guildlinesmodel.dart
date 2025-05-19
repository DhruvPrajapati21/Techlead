import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GuidelinesModel {
  final String headlines;
  final String guidelines;
  final String contactus;
  final Timestamp reportedDateTime;


  GuidelinesModel(
      {required this.headlines,required this.guidelines ,required this.contactus,required this.reportedDateTime,});

  factory GuidelinesModel.fromSnapshot(DocumentSnapshot snapshot) {
    return GuidelinesModel(
      // Assign the document ID to the id field
      headlines: snapshot['headlines'],
      guidelines: snapshot['guidelines'],
      contactus: snapshot['contactus'],
      reportedDateTime: snapshot['reportedDateTime'],
    );
  }
}
