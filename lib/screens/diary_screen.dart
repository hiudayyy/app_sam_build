import 'package:flutter/material.dart';

class DiaryScreen extends StatelessWidget {
  final Function([List<String>?]) onBatchDiaryUpdate;

  const DiaryScreen({
    Key? key,
    required this.onBatchDiaryUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Quản lý Nhật ký',
              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.05, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Tính năng đang được phát triển',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => onBatchDiaryUpdate(),
              child: Text('Cập nhật hàng loạt'),
            ),
          ],
        ),
      ),
    );
  }
}