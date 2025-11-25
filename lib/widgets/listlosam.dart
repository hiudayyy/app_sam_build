import 'package:nftsam/api/api_caytrong.dart';
import 'package:nftsam/api/api_option.dart';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/option_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../screens/home_screen.dart';

class DanhSachLoSamPage extends StatefulWidget {
  const DanhSachLoSamPage({super.key});

  @override
  State<DanhSachLoSamPage> createState() => _DanhSachLoSamPageState();
}

class _DanhSachLoSamPageState extends State<DanhSachLoSamPage> {
  final List<LoSamModel> _items = [];
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

    final res = await API().listLoSam(status: "1",skip: _skip, top: _pageSize);
    final newItems = res ?? [];

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
  Widget _buildLoSamList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _items.length) {
          final   loSam = _items[index];
          return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      tabcurrent: 2,
                      shouldShowDialog: true,
                      zone: loSam,
                    ),
                  ),
                );
              },
             child: Card(
               margin: const EdgeInsets.only(bottom: 12),
               child: Container(
                 decoration: BoxDecoration(
                   border: const Border(
                     left: BorderSide(color: Colors.green, width: 4),
                   ),
                   borderRadius: BorderRadius.circular(12),
                 ),
                 child: Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Row(
                     children: [
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.green.shade100,
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Icon(Icons.eco, size: 20, color: Colors.green.shade600),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Expanded(
                                   child: Text(
                                     loSam.tenLo ?? 'Chưa có tên lô',
                                     style: const TextStyle(fontWeight: FontWeight.w600),
                                   ),
                                 ),
                                 Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: Colors.grey.shade200,
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: Text(
                                     loSam.maLo ?? 'Mã trống',
                                     style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                   ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 12),
                             Row(
                               children: [
                                 Expanded(child: _buildZoneInfo('Ghi chú:', loSam.ghiChu ?? 'Không có')),
                                 Expanded(child: _buildZoneInfo('Số cây:', '${loSam.soLuongCaySams ?? 0}')),
                               ],
                             ),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                 Expanded(child: _buildZoneInfo('Số hàng:', '${loSam.soHang ?? '-'}')),
                                 Expanded(child: _buildZoneInfo('Số cột:', '${loSam.soCot ?? '-'}')),
                               ],
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
          );

        } else {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
  Widget _buildZoneInfo(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Colors.black),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: value),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Danh sách lô sâm",style: TextStyle(color: Colors.white),),backgroundColor: Colors.green.shade700,foregroundColor: Colors.white ),
      body: _items.isEmpty && !_isLoading
          ? const Center(child: Text("Không có dữ liệu"))
          : _buildLoSamList(),
    );
  }
}
