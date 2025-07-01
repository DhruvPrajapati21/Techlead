import 'package:flutter/material.dart';

class LoginController {
  static final Map<String, Map<String, String>> _validCredentials = {
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

  static Map<String, String>? verifyCredentials(String email, String password) {
    if (_validCredentials.containsKey(email) &&
        _validCredentials[email]!['password'] == password) {
      return _validCredentials[email];
    }
    return null;
  }

  static void completeLogin(BuildContext context, Map<String, String> userData) {
    // You can store this info using shared_preferences or navigate to a new page
    print("Admin logged in: ${userData['name']} (${userData['id']})");

    // Example: Navigate to home screen
    // Navigator.pushReplacementNamed(context, '/home');
  }

  static String? validateEmail(String? value) {
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@(gmail\.com|[a-zA-Z0-9.-]+\.(com|in))$",
    );
    if (value == null || value.isEmpty) return "Please enter your email";
    if (!emailRegex.hasMatch(value)) return "Please enter a valid email";
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Please enter your password";
    if (value.length < 8) return "Password must be at least 8 characters long";
    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+={};:<>|./?,-]).{8,}$',
    ).hasMatch(value)) {
      return "Password must contain upper, lower, number & special character";
    }
    return null;
  }
}
