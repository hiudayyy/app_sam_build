import 'package:csam_mobile/api/api_option.dart';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/option_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../api/api_caysam.dart';
import '../screens/plant_detail_screen.dart'; // import nơi có hàm listCaySam

class DanhSachCaySamPage extends StatefulWidget {
  const DanhSachCaySamPage({super.key});

  @override
  State<DanhSachCaySamPage> createState() => _DanhSachCaySamPageState();
}

class _DanhSachCaySamPageState extends State<DanhSachCaySamPage> {
  final List<CaySamModel> _items = [];
  List<OptionModel> OptionLoSamTinhTrang = [];
  List<OptionModel> OptionLoSamDiemSucKhoe = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _skip = 0;
  final int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchCaySam();

    // khi scroll gần cuối danh sách → load thêm
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchCaySam();
      }
    });
  }

  Future<void> _fetchCaySam() async {
    setState(() => _isLoading = true);

    final res = await API().listCaySam(status: "1",skip: _skip, top: _pageSize);
    final newItems = res?.items ?? [];

    setState(() {
      _items.addAll(newItems);
      _isLoading = false;
      _skip += _pageSize;
      if (newItems.length < _pageSize) _hasMore = false;
    });
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách cây sâm")),
      body: _items.isEmpty && !_isLoading
          ? const Center(child: Text("Không có dữ liệu"))
          : ListView.builder(
        controller: _scrollController,
        itemCount: _items.length + 1,
        itemBuilder: (context, index) {
          if (index < _items.length) {
            final cay = _items[index];
            final tinhTrang = _items[index].caySamNhatKys.isNotEmpty
                ? OptionLoSamTinhTrang
                .firstWhere(
                  (opt) =>
              opt.value ==
                  _items[index].caySamNhatKys.first?.tinhTrang.toString(),
              orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
            )
                .text
                : "Chưa xác địnhknk";
            final diemsk = _items[index].caySamNhatKys.isNotEmpty
                ? OptionLoSamDiemSucKhoe
                .firstWhere(
                  (opt) =>
              opt.value ==
                  _items[index].caySamNhatKys.first?.diemSucKhoe.toString(),
              orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
            )
                .text
                : "Chưa xác địnhknk";
            // final diemsk =
            //     cay.caySamNhatKys.firstOrNull?.diemSucKhoe ?? 'N/A';

            return ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: Text(cay.maCaySam ?? 'Chưa có mã'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tình trạng: $tinhTrang'),
                  Text('Sức khỏe: $diemsk'),
                ],
              ),
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
            );
          } else {
            return _hasMore
                ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
                : const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
