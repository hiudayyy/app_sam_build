import 'package:flutter/material.dart';

import '../models/vuontrong/caysam_model.dart';

class DanhSachCayYeuPage extends StatelessWidget {
  final List<CaySamModel> cayYeuList;
  const DanhSachCayYeuPage({super.key, required this.cayYeuList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách cây yếu')),
      body: ListView.builder(
        itemCount: cayYeuList.length,
        itemBuilder: (context, index) {
          final cay = cayYeuList[index];
          return ListTile(
            leading: const Icon(Icons.local_florist, color: Colors.redAccent),
            title: Text(cay.maCaySam ?? 'Chưa có tên'),
            subtitle: Text('Tình trạng: ${cay.caySamNhatKys.first?.tinhTrang ?? 'Không rõ'}'),
          );
        },
      ),
    );
  }
}
