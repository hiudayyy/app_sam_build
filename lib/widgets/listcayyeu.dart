import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/api/api_option.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../api/api.dart';
import '../models/option_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../screens/plant_detail_screen.dart';

class DanhSachCayYeuPage extends StatefulWidget {
  const DanhSachCayYeuPage({super.key});

  @override
  State<DanhSachCayYeuPage> createState() => _DanhSachCayYeuPageState();
}

class _DanhSachCayYeuPageState extends State<DanhSachCayYeuPage> {
  late Future<List<CaySamModel>?> _futureCayYeu;
  List<OptionModel> OptionLoSamTinhTrang = [];
  List<OptionModel> OptionLoSamDiemSucKhoe = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _futureCayYeu = _fetchCayYeu();

  }
  Future<List<CaySamModel>?> _fetchCayYeu() async {
    try {
      final allCay = await API().ListCaySamRatYeu();
      return allCay?.items;
    } catch (e) {
      debugPrint('❌ Lỗi lấy cây yếu: $e');
      return [];
    }
  }
  Future<void> _initializeData() async {
    final api = API();
    final apiOptintt = await api.OptionLoSamTinhTrang();
    if (apiOptintt != null) {
      setState(() {
        OptionLoSamTinhTrang = apiOptintt;
      });
    }
    final apiOptindsk = await api.OptionLoSamDiemSucKhoe();
    if (apiOptindsk != null) {
      setState(() {
        OptionLoSamDiemSucKhoe = apiOptindsk;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách cây yếu'),backgroundColor: Colors.orange.shade400,foregroundColor: Colors.white,),
      body: FutureBuilder<List<CaySamModel>?>(
        future: _futureCayYeu,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có cây yếu nào.'));
          }

          final cayYeuList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cayYeuList.length,
            itemBuilder: (context, index) {
              final cay = cayYeuList[index];
              final tinhTrang = OptionLoSamTinhTrang.firstWhere(
                    (opt) => opt.value == cay.caySamNhatKys.first?.tinhTrang.toString(),
                orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
              ).text;
              final diemsk = OptionLoSamDiemSucKhoe.firstWhere(
                    (opt) => opt.value == cay.caySamNhatKys.first?.diemSucKhoe.toString(),
                orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
              ).text;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlantDetailScreen(
                        plant: cay,
                        onBack: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.orange, width: 3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cay.maCaySam ?? 'Chưa có mã',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Chip(
                                        label: const Text(
                                          '⚠️ Yếu',
                                          style: TextStyle(fontSize: 12, color: Colors.orange),
                                        ),
                                        backgroundColor: Colors.orange.withOpacity(0.1),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tình trạng: $tinhTrang',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sức khỏe: $diemsk',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vị trí: ${cay.viTriTrongLo ?? "Không rõ"}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb_outline, color: Colors.orange.shade800, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Khuyến nghị: Cần theo dõi và chăm sóc đặc biệt',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
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
            },
          );
        },
      ),
    );
  }
}
