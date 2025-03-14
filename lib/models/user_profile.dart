import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'vcard_model.dart';

class UserProfile {
  String name;
  String company;
  String email;
  String phone;
  String website;
  String title;
  String address;

  UserProfile({
    required this.name,
    required this.company,
    this.email = '',
    this.phone = '',
    this.website = '',
    this.title = '',
    this.address = '',
  });

  // Convert to VCardModel
  VCardModel toVCardModel() {
    return VCardModel(
      name: name,
      company: company,
      email: email,
      phone: phone,
      website: website,
      title: title,
      address: address,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'company': company,
      'email': email,
      'phone': phone,
      'website': website,
      'title': title,
      'address': address,
    };
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      title: json['title'] ?? '',
      address: json['address'] ?? '',
    );
  }

  // Create empty profile
  factory UserProfile.empty() {
    return UserProfile(name: '', company: '');
  }

  // Save profile to SharedPreferences
  Future<bool> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(toJson());
      return await prefs.setString('user_profile', jsonString);
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }

  // Load profile from SharedPreferences
  static Future<UserProfile> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('user_profile');
      if (jsonString == null) {
        return UserProfile.empty();
      }
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return UserProfile.empty();
    }
  }
}
