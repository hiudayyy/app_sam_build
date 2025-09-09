import 'package:flutter/material.dart';

class EnvironmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thermostat, size: 64, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Giám sát Môi trường',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Tính năng đang được phát triển',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}