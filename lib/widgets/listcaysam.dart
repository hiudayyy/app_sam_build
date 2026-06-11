import 'dart:async';

import 'package:nftsam/api/api_option.dart';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/option_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../api/api_caysam.dart';
import '../screens/plant_detail_screen.dart'; // import nơi có hàm listCaySam

import '/app_config.dart';

class DanhSachCaySamPage extends StatefulWidget {
  final int? initialHealth;
  const DanhSachCaySamPage({super.key, this.initialHealth});

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
  int? _selectedHealth;
  int? _selectedStatus;
  final Map<int, String> _healthOptions = {
    5: 'Rất tốt',
    4: 'Tốt',
    3: 'Trung bình',
    2: 'Yếu',
    1: 'Rất yếu',
  };

  final Map<int, String> _statusOptions = {
    1: 'Đang phát triển',
    2: 'Ngủ đông',
    3: 'Đã chết',
  };
  final int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedHealth = widget.initialHealth;
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

  Future<void> _fetchCaySam() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    List<String> searchParams = [];
    if (_searchQuery.isNotEmpty) {
      searchParams.add("MaCaySam contains '${_searchQuery}'");
    }
    if (_selectedHealth != null) {
      searchParams.add("DiemSucKhoe contains ${_selectedHealth}");
    }
    if (_selectedStatus != null) {
      searchParams.add("TinhTrang contains ${_selectedStatus}");
    }
    try {
      final res = await API().listCaySam(
        status: "1",
        skip: _skip,
        top: _pageSize,
        searchBy: searchParams,
      );

      final newItems = res?.items ?? [];

      if (mounted) {
        setState(() {
          if (_skip == 0) {
            _items
                .clear(); // Clear list nếu là trang đầu tiên (do search/filter)
          }
          _items.addAll(newItems);
          _isLoading = false;
          _skip += _pageSize;
          // Nếu số lượng trả về ít hơn pageSize -> Đã hết dữ liệu
          if (newItems.length < _pageSize) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      AppConfig.printEx("Lỗi tải danh sách: $e");
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
      case '1':
        return Colors.green.shade600;
      case '2':
        return Colors.blue.shade600;
      case '3':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  Color _getHealthColor(String? healthValue) {
    switch (healthValue) {
      case '5':
        return Colors.green.shade600;
      case '4':
        return Colors.teal.shade500;
      case '3':
        return Colors.orange.shade600;
      case '2':
        return Colors.deepOrange.shade500;
      case '1':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: Column(
        children: [
          // --- Text Search ---
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm theo mã sâm...', // Sửa hint cho đúng logic
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        // Reset search query
                        _searchQuery = "";
                        setState(() {
                          _items.clear();
                          _skip = 0;
                          _hasMore = true;
                        });
                        _fetchCaySam();
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
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Dropdown Sức Khỏe
              Expanded(
                child: _buildDropdown(
                  label: "Sức khỏe",
                  value: _selectedHealth,
                  items: _healthOptions,
                  onChanged: (val) {
                    setState(() {
                      _selectedHealth = val;
                      _items.clear();
                      _skip = 0;
                      _hasMore = true;
                    });
                    _fetchCaySam();
                  },
                  icon: Icons.favorite_border,
                  iconColor: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: "Trạng thái",
                  value: _selectedStatus,
                  items: _statusOptions,
                  onChanged: (val) {
                    setState(() {
                      _selectedStatus = val;
                      _items.clear();
                      _skip = 0;
                      _hasMore = true;
                    });
                    _fetchCaySam();
                  },
                  icon: Icons.spa_outlined,
                  iconColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required Map<int, String> items,
    required Function(dynamic) onChanged,
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          isExpanded: true,
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          borderRadius: BorderRadius.circular(12),
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) {
            return [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                  //  Icon(icon, size: 18, color: iconColor ?? Colors.grey),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              ...items.entries.map((entry) {
                return Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ];
          },
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text("Tất cả", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...items.entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
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
                ? const Center(
                    child: Text("Không có dữ liệu hoặc không tìm thấy kết quả"))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _items.length) {
                        final cay = _items[index];
                        final tinhTrangOption = OptionLoSamTinhTrang.firstWhere(
                          (opt) =>
                              opt.value ==
                              cay.caySamNhatKys.firstOrNull?.tinhTrang
                                  .toString(),
                          orElse: () =>
                              OptionModel(value: "-1", text: "Chưa xác định"),
                        );
                        final diemSucKhoeOption =
                            OptionLoSamDiemSucKhoe.firstWhere(
                          (opt) =>
                              opt.value ==
                              cay.caySamNhatKys.firstOrNull?.diemSucKhoe
                                  .toString(),
                          orElse: () =>
                              OptionModel(value: "-1", text: "Chưa xác định"),
                        );
                        final statusColor =
                            _getStatusColor(tinhTrangOption.value);
                        final healthColor =
                            _getHealthColor(diemSucKhoeOption.value);

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                              padding: EdgeInsets.all(
                                  (screenWidth * 0.035).clamp(10.0, 24.0)),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        statusColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.eco,
                                      color: statusColor,
                                      size: (screenWidth * 0.06),
                                    ),
                                  ),
                                  SizedBox(
                                      width: (screenWidth * 0.035)
                                          .clamp(10.0, 24.0)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cay.maCaySam ?? 'Chưa có mã',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                                color: healthColor,
                                                shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Sức khỏe: ${diemSucKhoeOption.text}',
                                            style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: (screenWidth * 0.035)
                                                    .clamp(12.0, 15.0)),
                                          ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Vị trí: ${cay.viTriTrongLo ?? "Chưa có"}',
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: (screenWidth * 0.035)
                                                  .clamp(12.0, 15.0)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tinhTrangOption.text,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: (screenWidth * 0.03)
                                              .clamp(10.0, 15.0)),
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
