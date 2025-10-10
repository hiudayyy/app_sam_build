import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

class LoginModel {
  late String uname;
  late String pass;
  late String apiDate;
  late String hashCode256;
  late String deviceToken;

  LoginModel({
    required this.uname,
    required this.pass,
    required this.deviceToken,
  }) : apiDate = getDate() {
    hashCode256 = shaCode256();
  }

  static String getDate() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMddHHmmss');
    return formatter.format(now);
  }

  String shaCode256() {
    final rawData = '$apiDate|$uname|$pass|$apiDate|0988|$apiDate';
    final bytes = utf8.encode(rawData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Map<String, dynamic> toJsonGet() {
    return {
      'uname': uname,
      'pass': pass,
      'apiDate': apiDate,
      'hashCode': hashCode256,
      'deviceToken':deviceToken,
    };
  }
}
