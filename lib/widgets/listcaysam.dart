import 'dart:async';

import 'package:nftsam/api/api_option.dart';
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

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchCaySam();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchCaySam();
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != _searchController.text) {
        _searchQuery = _searchController.text;
        setState(() {
          _items.clear();
          _skip = 0;
          _hasMore = true;
        });
        _fetchCaySam();
      }
    });
  }

  // ================================================================
  // ✅ HÀM MỚI: CHUYỂN ĐỔI TUỔI NGƯỜI DÙNG NHẬP SANG ID
  // ================================================================
  /// Chuyển đổi một chuỗi số (tuổi) thành TuoiCay_ID tương ứng.
  /// Trả về null nếu chuỗi không phải là số hoặc không thuộc khoảng nào.
  String? _mapAgeToTuoiCayId(String query) {
    // Thử chuyển đổi chuỗi nhập vào thành số nguyên
    final age = int.tryParse(query);
    if (age == null) {
      // Nếu không phải là số, không thể là tuổi -> trả về null
      return null;
    }

    // Áp dụng logic ánh xạ
    if (age >= 3 && age <= 5) return '1';
    if (age >= 6 && age <= 7) return '2';
    if (age >= 8 && age <= 9) return '3';
    if (age > 9) return '4';

    // Nếu số tuổi không nằm trong bất kỳ khoảng nào
    return null;
  }
  // ================================================================

  // ✅ CẬP NHẬT: HÀM NÀY GIỜ SẼ XÂY DỰNG MỘT DANH SÁCH ĐIỀU KIỆN TÌM KIẾM
  Future<void> _fetchCaySam() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    // ================================================================
    // ✅ LOGIC MỚI: XÂY DỰNG DANH SÁCH `searchBy`
    // ================================================================
    List<String>? searchParams;
    if (_searchQuery.isNotEmpty) {
      searchParams = [];
      searchParams.add("MaCaySam contains '${_searchQuery}'");
      searchParams.add("ViTriTrongLo contains '${_searchQuery}'");
    }
    // ================================================================

    final res = await API().listCaySam(
      status: "1",
      skip: _skip,
      top: _pageSize,
      searchBy: searchParams,
    );
    final newItems = res?.items ?? [];

    if (mounted) {
      setState(() {
        _items.addAll(newItems);
        _isLoading = false;
        _skip += _pageSize;
        if (newItems.length < _pageSize) _hasMore = false;
      });
    }
  }

  Future<void> _initializeData() async {
    final api = API();
    final apiOptintt = await api.OptionLoSamTinhTrang();
    if (mounted && apiOptintt != null) {
      setState(() {
        OptionLoSamTinhTrang = apiOptintt;
      });
    }
    final apiOptindsk = await api.OptionLoSamDiemSucKhoe();
    if (mounted && apiOptindsk != null) {
      setState(() {
        OptionLoSamDiemSucKhoe = apiOptindsk;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Color _getStatusColor(String? statusValue) {
    switch (statusValue) {
      case '1': return Colors.green.shade600;
      case '2': return Colors.blue.shade600;
      case '3': return Colors.red.shade600;
      default: return Colors.grey.shade500;
    }
  }

  Color _getHealthColor(String? healthValue) {
    switch (healthValue) {
      case '5': return Colors.green.shade600;
      case '4': return Colors.teal.shade500;
      case '3': return Colors.orange.shade600;
      case '2': return Colors.deepOrange.shade500;
      case '1': return Colors.red.shade700;
      default: return Colors.grey.shade500;
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm theo mã, vị trí...', // Cập nhật hint text
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách cây sâm"),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _items.isEmpty && !_isLoading
                ? const Center(child: Text("Không có dữ liệu hoặc không tìm thấy kết quả"))
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _items.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _items.length) {
                  final cay = _items[index];
                  final tinhTrangOption = OptionLoSamTinhTrang.firstWhere(
                        (opt) => opt.value == cay.caySamNhatKys.firstOrNull?.tinhTrang.toString(),
                    orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
                  );
                  final diemSucKhoeOption = OptionLoSamDiemSucKhoe.firstWhere(
                        (opt) => opt.value == cay.caySamNhatKys.firstOrNull?.diemSucKhoe.toString(),
                    orElse: () => OptionModel(value: "-1", text: "Chưa xác định"),
                  );
                  final statusColor = _getStatusColor(tinhTrangOption.value);
                  final healthColor = _getHealthColor(diemSucKhoeOption.value);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(Icons.eco, color: statusColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cay.maCaySam ?? 'Chưa có mã',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(color: healthColor, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sức khỏe: ${diemSucKhoeOption.text}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vị trí: ${cay.viTriTrongLo ?? "Chưa có"}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                tinhTrangOption.text,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
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
            ),
          ),
        ],
      ),
    );
  }
}
