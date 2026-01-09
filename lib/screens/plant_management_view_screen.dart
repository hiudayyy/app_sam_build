import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/api/api_caytrong.dart';
import 'package:nftsam/api/api_option.dart';
import 'package:nftsam/models/message_enum.dart';
import 'package:nftsam/models/vuontrong/losamcamera_model.dart';
import 'package:nftsam/screens/plant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../api/api.dart';
import '../core/constants/app_colors.dart';
import '../models/caysamuser_model.dart';
import '../models/farm_hierarchy.dart';
import '../data/mock_data.dart';
import '../models/kttoken.dart';
import '../models/option_model.dart';
import '../models/response_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamchitiet_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import 'package:file_picker/file_picker.dart';

import '../utils/app_dimensions.dart';
import '../widgets/camera.dart';
import 'add_farm_screen.dart';
import 'add_losam_screen.dart';
import 'add_plant_screen.dart';
import 'batch_plant_update_screen.dart';

class PlantManagementViewScreen extends StatefulWidget {
  const PlantManagementViewScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<PlantManagementViewScreen> createState() =>
      PlantManagementViewScreenState();
}

class PlantManagementViewScreenState extends State<PlantManagementViewScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  NavigationLevel currentLevel = NavigationLevel.farm;
  VuonTrongModel? selectedFarm;
  LoSamModel? selectedZone;
  String? selectedPlant;
  final ScrollController _scrollController = ScrollController();

  final List<String> gridColumns = ['A', 'B', 'C', 'D', 'E', 'F'];
  List<int> gridRows = [];
  List<LoSamChiTietModel>? losamchitiet = [];
  LoSamModel? loSam;

  bool isMultiSelectMode = false;
  bool _isLoading = false;
  Set<String> selectedEmptyCells = <String>{};

  // late PlantStats plantStats;
  List<VuonTrongModel>? farmsWithPlantsData = [];
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoSamTinhTrang = [];
  List<OptionModel> OptionLoSamDiemSucKhoe = [];

  // 🎨 Animation controllers
  late AnimationController _multiSelectAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _multiSelectAnimation;
  late Animation<double> _pulseAnimation;
  Future<LoSamModel?>? _futureLoSam;
  Kttoken? user;
  OptionModel? _selectedtuoicay;
  OptionModel? _selectedTinhTrang;
  OptionModel? _selectedDiemSucKhoe;
  String? _selectedFileName;
  File? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
  }

  @override
  void dispose() {
    _multiSelectAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }
  @override
  bool get wantKeepAlive => true;
  // ✅ HÀM LỌC TRUNG TÂM MỚI
  // void _applyFiltersAndSelectCells(List<CaySamModel> areaPlants) {
  //   // Bắt đầu với danh sách gốc
  //   List<CaySamModel> filteredList = List.from(areaPlants);
  //   final now = DateTime.now();
  //   if (_selectedtuoicay != null) {
  //     int? selectedAgeId = int.tryParse(_selectedtuoicay!.value);
  //     if (selectedAgeId != null) {
  //       filteredList = filteredList.where((plant) {
  //         if (plant.tuoiCayId != selectedAgeId) return false;
  //         if (plant.caySamNhatKys.isEmpty) return true;
  //       final hasThisMonthDiary = plant.caySamNhatKys.any((nk) {
  //         try {
  //           final ngayGhi = DateTime.parse(nk?.ngayGhi ?? "");
  //           return ngayGhi.month == now.month && ngayGhi.year == now.year;
  //         } catch (_) {
  //           return false;
  //         }
  //       });
  //       return !hasThisMonthDiary;
  //       //   return true;
  //     }).toList();
  //     }
  //   }
  //   // else {
  //   //   // Nếu chưa chọn tuổi, không lọc gì cả và không chọn ô nào
  //   //   _selectAllEmptyCells([]);
  //   //   return;
  //   // }
  //
  //   // 2. Lọc thêm theo Tình Trạng (nếu đã chọn)
  //   if (_selectedTinhTrang != null) {
  //     int? selectedStatusId = int.tryParse(_selectedTinhTrang!.value);
  //     if (selectedStatusId != null) {
  //       filteredList = filteredList.where((plant) =>
  //       plant.caySamNhatKys.firstOrNull?.tinhTrang == selectedStatusId
  //       ).toList();
  //     }
  //   }
  //
  //   // 3. Lọc thêm theo Sức Khỏe (nếu đã chọn)
  //   if (_selectedDiemSucKhoe != null) {
  //     int? selectedHealthId = int.tryParse(_selectedDiemSucKhoe!.value);
  //     if (selectedHealthId != null) {
  //       filteredList = filteredList.where((plant) =>
  //       plant.caySamNhatKys.firstOrNull?.diemSucKhoe == selectedHealthId
  //       ).toList();
  //     }
  //   }
  //
  //   // Cuối cùng, gọi hàm chọn các ô với danh sách đã được lọc hoàn chỉnh
  //   _selectAllEmptyCells(filteredList);
  // }
  void _applyFiltersAndSelectCells(List<CaySamModel> areaPlants) {
    // Bắt đầu với danh sách gốc
    List<CaySamModel> filteredList = List.from(areaPlants);
    final now = DateTime.now();
    bool checkHasThisMonthDiary(CaySamModel plant) {
      if (plant.caySamNhatKys.isEmpty) return false;

      return plant.caySamNhatKys.any((nk) {
        try {
          final ngayGhi = DateTime.parse(nk?.ngayGhi ?? "");
          return ngayGhi.month == now.month && ngayGhi.year == now.year;
        } catch (_) {
          return false;
        }
      });
    }
    if (_selectedtuoicay != null) {
      int? selectedAgeId = int.tryParse(_selectedtuoicay!.value);
      if (selectedAgeId != null) {
        filteredList = filteredList.where((plant) {
          if (plant.tuoiCayId != selectedAgeId) return false;
          bool hasDiary = checkHasThisMonthDiary(plant);
          return !hasDiary;
        }).toList();
      }
    }
    if (_selectedTinhTrang != null) {
      int? selectedStatusId = int.tryParse(_selectedTinhTrang!.value);
      if (selectedStatusId != null) {
        filteredList = filteredList.where((plant) {
          final lastStatus = plant.caySamNhatKys.firstOrNull?.tinhTrang;
          if (lastStatus != selectedStatusId) return false;
          bool hasDiary = checkHasThisMonthDiary(plant);
          return !hasDiary;
        }).toList();
      }
    }
    if (_selectedDiemSucKhoe != null) {
      int? selectedHealthId = int.tryParse(_selectedDiemSucKhoe!.value);
      if (selectedHealthId != null) {
        filteredList = filteredList.where((plant) {
          final lastHealth = plant.caySamNhatKys.firstOrNull?.diemSucKhoe;
          if (lastHealth != selectedHealthId) return false;
          bool hasDiary = checkHasThisMonthDiary(plant);
          return !hasDiary;
        }).toList();
      }
    }
    if(_selectedtuoicay != null || _selectedTinhTrang != null || _selectedDiemSucKhoe != null){
      _selectAllEmptyCells(filteredList);
    }else{
      _selectAllEmptyCells([]);
    }
  }
  void showLoadingDialog(BuildContext context, {String message = 'Đang xử lý...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // ✅ SỬ DỤNG AlertDialog ĐỂ CÓ GIAO DIỆN ĐẸP HƠN
        return AlertDialog(
          // Bo tròn các góc
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Giữ cho dialog có kích thước nhỏ nhất
            children: [
              // Vòng quay loading
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              // Text thông báo
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  void _setupAnimations() {
    _multiSelectAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _multiSelectAnimation = CurvedAnimation(
      parent: _multiSelectAnimationController,
      curve: Curves.easeInOut,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeData() async {
    // Calculate plant statistics

    final api = API();
    final apifarm = await api.listVuonTrong(status: 1, take: null, skip: 0);
    if (apifarm != null) {
      setState(() {
        farmsWithPlantsData = apifarm;
      });
    }
    final apiOptinlt = await api.OptionLoSamLoaiTuoi();
    if (apiOptinlt != null) {
      setState(() {
        OptionLoSamLoaiTuoi = apiOptinlt;
      });
    }
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
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
  }

  // Trong file plant_management_view_screen.dart

  // Trong file plant_management_view_screen.dart

  Future<void> _reloadData() async {
    if (selectedZone == null) return;
    final api = API();

    // 1. Bật trạng thái Loading đè lên UI cũ
    setState(() {
      _isLoading = true;
    });

    try {
      final newData = await api.getLoSamById(selectedZone!.loSamId);

      if (mounted) {
        setState(() {
          loSam = newData;
          // Cập nhật Future để đồng bộ, nhưng quan trọng là biến loSam đã có dữ liệu
          _futureLoSam = Future.value(newData);

          // 2. Tắt Loading khi dữ liệu đã về
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải lại dữ liệu: $e");
      if (mounted) {
        setState(() {
          _isLoading = false; // Tắt loading kể cả khi lỗi
        });
      }
    }
  }

  Future<void> buildLoSamChiTiets() async {
    final ageGroups = <int, int>{}; // key = idTuoiCaySam, value = count

    for (var plant in loSam?.caySams ?? []) {
      if (plant.tuoiCayId != null) {
        ageGroups.update(
          plant.tuoiCayId!,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final loSamChiTiets = ageGroups.entries.map((entry) {
      return {
        "LoSamLoaiTuoiId": entry.key,
        "SoLuong": entry.value,
      };
    }).toList();

    final result = {
      "LoSamChiTiets": loSamChiTiets,
    };

    final reposn = await API()
        .updateLoSamChiTietByLoSamId(id: loSam?.loSamId ?? 0, data: result);
    if (reposn?.message == "OK") {
      _reloadData();
    }
    print(result); // in ra
    // hoặc nếu cần gọi API thì truyền result vào body
  }

  void _toggleMultiSelectMode() {
    setState(() {
      isMultiSelectMode = !isMultiSelectMode;
      selectedEmptyCells.clear();
      selectedPlant = null;
      _clearSelection();
    });

    if (isMultiSelectMode) {
      _multiSelectAnimationController.forward();
    } else {
      _multiSelectAnimationController.reverse();
    }
  }

  int _calculatePlantAge(int plantingDate) {
    return plantingDate;
  }

  String _getPlantAgeGroup(int age) {
    if (age >= 1 && age <= 3) return '1-3 năm';
    if (age >= 4 && age <= 6) return '4-6 năm';
    if (age >= 7 && age <= 8) return '7-8 năm';
    if (age >= 9 && age <= 10) return '9-10 năm';
    return 'Chưa xác định';
  }

  String _getPlantAgeIconPath(int age) {
    switch (age) {
      case 1:
        return "assets/images/icon1t.png";
      case 2:
        return "assets/images/icon2xp.png";
      case 3:
        return "assets/images/icon3t.png";
      case 4:
        return "assets/images/icon4t.png";
      default:
        return "assets/images/icon1.png";
    }
  }




  Color _getPlantAgeIconColor(int age) {
    if (age == 1) return Colors.black54!;
    if (age == 2) return Colors.black54!;
    if (age == 3) return Colors.black54!;
    if (age == 4) return Colors.black54!;
    return Colors.grey[400]!;
  }

  void _handleNavigationBack() {
    setState(() {
      isMultiSelectMode = false;
      selectedEmptyCells.clear();
      _clearSelection();
      switch (currentLevel) {
        case NavigationLevel.grid:
          selectedFarm ??= VuonTrongModel(vuonTrongId: 0, tenVuon: '', diaChi: '', viTri: '', ghiChu: '', trangThai: 1); // hoặc kiểu tương ứng
          selectedFarm?.vuonTrongId = selectedZone?.vuonTrongId ?? 0;

          currentLevel = NavigationLevel.zone;
          selectedZone = null;
          break;
        case NavigationLevel.zone:
          currentLevel = NavigationLevel.farm;
          selectedFarm = null;
          break;
        case NavigationLevel.farm:
          break;
      }
    });
  }

  List<String> _getBreadcrumb() {
    final items = <String>[];
    if (selectedFarm != null) items.add(selectedFarm!.tenVuon);
    if (selectedZone != null) items.add(selectedZone?.tenLo ?? "");
    return items;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildHeader(),
      body: Column(
        children: [
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  AppBar? _buildHeader() {
    // Toàn bộ logic xác định trạng thái của bạn được giữ nguyên
    bool canShowMultiSelectButton = false;
    if (currentLevel == NavigationLevel.grid && user?.htTaiKhoan.htPhanQuyenTaiKhoans != null) {
      canShowMultiSelectButton = user!.htTaiKhoan.htPhanQuyenTaiKhoans.any(
            (pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin",
      );
    }
    final breadcrumb = _getBreadcrumb();
    if (currentLevel == NavigationLevel.farm) {
      return null;
    }
    final double scale = MediaQuery.of(context).size.width / 375.0;
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white, // Đảm bảo trắng hoàn toàn trên Android mới
      foregroundColor: Colors.black87,
      elevation: 0.5, // Giảm nhẹ độ dày đường kẻ cho hiện đại
      shadowColor: Colors.black.withOpacity(0.1),
      titleSpacing: 0,

      // Nút Back co giãn theo scale
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18 * scale),
        onPressed: _handleNavigationBack,
      ),

      title: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 14 * scale, color: Colors.grey.shade600),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Text(
              breadcrumb.join(' → '),
              style: TextStyle(
                fontSize: 13 * scale, // Responsive font size
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),

      actions: [
        if (canShowMultiSelectButton)
          Padding(
            padding: EdgeInsets.only(right: 12.0 * scale),
            child: SizedBox(
              // Khống chế chiều cao nút để trông nhỏ gọn và hiện đại hơn
              height: 34 * scale,
              child: ElevatedButton.icon(
                onPressed: _toggleMultiSelectMode,
                icon: Icon(
                  isMultiSelectMode ? Icons.close_rounded : Icons.checklist_rtl_rounded,
                  size: 16 * scale,
                ),
                label: Text(
                  isMultiSelectMode ? 'Thoát' : 'Nhật ký',
                  style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  // Màu sắc thay đổi theo trạng thái
                  backgroundColor: isMultiSelectMode
                      ? Colors.blueGrey.shade700
                      : Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0, // Phẳng hóa giao diện theo xu hướng hiện đại
                  padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCameraView(List<LoSamCameraModel> cameras, LoSamModel? losam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraViewWithGrid(
          cameras: cameras,
          losam: losam,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: user == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: _buildCurrentLevelContent(),
          ),
        ],
      ),
    );
  }
  Widget _buildAgeGroupStats(LoSamModel? lsmod) {
    // Lấy chiều rộng màn hình
    double screenWidth = MediaQuery.of(context).size.width;

    // Scale factor: Giữ nguyên logic responsive
    double scale = (screenWidth / 375).clamp(0.85, 1.3);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4 * scale), // Margin bên ngoài cực nhỏ
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 10 * scale), // Padding bên trong thắt chặt
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale), // Bo góc nhỏ hơn (12)
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06), // Bóng mờ hơn để trông nhẹ nhàng
            blurRadius: 6 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phân bố theo tuổi',
                style: TextStyle(
                    fontSize: 13 * scale, // Font tiêu đề nhỏ (13)
                    fontWeight: FontWeight.bold,
                    color: Colors.black87
                ),
              ),
              // Nút Refresh siêu nhỏ
              SizedBox(
                height: 24 * scale, // Giảm từ 30 xuống 24
                width: 24 * scale,
                child: IconButton(
                  onPressed: () {
                    if (_futureLoSam != null) {
                      _futureLoSam!.then((loSam) {
                        if (loSam != null) buildLoSamChiTiets();
                      });
                    }
                  },
                  icon: Icon(Icons.refresh_rounded, size: 16 * scale, color: Colors.blue),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Giúp nút nhận cảm ứng tốt dù nhỏ
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernStatItem(
                  "assets/images/icon1t.png", '3 năm', lsmod?.loSamChiTiets.sl(1), Colors.green, scale),
              _buildModernStatItem(
                  "assets/images/icon2xp.png", '6-7 năm', lsmod?.loSamChiTiets.sl(2), Colors.teal, scale),
              _buildModernStatItem(
                  "assets/images/icon3t.png", '8-9 năm', lsmod?.loSamChiTiets.sl(3), Colors.blue, scale),
              _buildModernStatItem(
                  "assets/images/icon4t.png", '>10 năm', lsmod?.loSamChiTiets.sl(4), Colors.purple, scale),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatItem(String iconPath, String label, dynamic count, Color color, double scale) {
    String displayCount = (count == null) ? '0' : count.toString();

    return Expanded(
      child: Column(
        children: [
          // 1. Icon Container: Size 34 (Rất gọn)
          Container(
            height: 34 * scale,
            width: 34 * scale,
            padding: EdgeInsets.all(7 * scale), // Padding bên trong icon cũng giảm
            decoration: BoxDecoration(
              color: color.withOpacity(0.4), // Độ đậm màu nền (bạn có thể chỉnh 0.4 hoặc 0.5 tùy mắt)
              shape: BoxShape.circle,
            ),
            child: Image.asset(iconPath, fit: BoxFit.contain),
          ),

          SizedBox(height: 4 * scale), // Khoảng cách cực gần

          // 2. Con số
          Text(
            displayCount,
            style: TextStyle(
              fontSize: 14 * scale, // Font số giảm xuống 14
              fontWeight: FontWeight.w800, // Vẫn rất đậm
              color: color,
              height: 1.1,
            ),
          ),

          // 3. Label
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10 * scale, // Font chữ text giảm xuống 10
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCurrentLevelContent() {
    switch (currentLevel) {
      case NavigationLevel.farm:
        return _buildFarmLevel();
      case NavigationLevel.zone:
        return _buildZoneLevel();
      case NavigationLevel.grid:
        return _buildGridLevel();
    }
  }

  Widget _buildFarmCard(VuonTrongModel? farm) {
    if (farm == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1), // Thêm viền
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            selectedFarm = farm;
            currentLevel = NavigationLevel.zone;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.green.shade50,
                    child: Icon(Icons.business_rounded, color: Colors.green.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      farm.tenVuon ?? "Chưa có tên",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddFarmScreen(
                            farmId: farm,
                            onSubmit: _edithandleFarmSubmit,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 20),
                    tooltip: 'Lưu',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      farm.viTri ?? "Chưa có vị trí",
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFarmLevel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý Trang trại',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hiện có ${farmsWithPlantsData?.length ?? 0} trang trại',
                      style: TextStyle(color: Colors.grey[600],fontSize: MediaQuery.of(context).size.width * 0.03),
                    ),
                  ],
                ),
              ),
              if(user!.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin"))
                ElevatedButton.icon(
                  onPressed: () => _showAddfarmDialog(),
                  icon:  Icon(Icons.add,size: MediaQuery.of(context).size.width * 0.035),
                  label: Text('Thêm vườn',style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 2, endIndent: 2),

        // Phần danh sách
        Expanded(
          child: farmsWithPlantsData == null
              ? const Center(child: CircularProgressIndicator())
              : farmsWithPlantsData!.isEmpty
              ? const Center(
            child: Text(
              'Chưa có trang trại nào.\nHãy nhấn "Thêm vườn" để bắt đầu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.only(top:16),
            itemCount: farmsWithPlantsData!.length,
            itemBuilder: (context, index) {
              final farm = farmsWithPlantsData![index];
              // Gọi hàm build card mới
              return _buildFarmCard(farm);
            },
          ),
        )
      ],
    );
  }

  Widget _buildZoneLevel() {
    if (selectedFarm?.vuonTrongId == null) return const SizedBox();
    final api = API();
    return FutureBuilder<List<LoSamModel>?>(
      future: api.listLoSam(
        status: "1",
        rowCount: null,
        skip: 0,
        searchBy: ["VuonTrong_ID equals '${selectedFarm?.vuonTrongId ?? 0}'"],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }

        final zonesWithPlantsData = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý Lô Sâm',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.05,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Các lô trong ${selectedFarm!.tenVuon}',
                          style: TextStyle(color: Colors.grey[600],fontSize: MediaQuery.of(context).size.width * 0.03),
                        ),
                      ],
                    ),
                  ),
                  if(user!.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>
                  pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin"))
                    ElevatedButton.icon(
                      onPressed: () => _showAddLoSamDialog(),
                      icon: Icon(Icons.add,size: MediaQuery.of(context).size.width * 0.035),
                      label: Text('Thêm lô',style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02, vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 2, endIndent: 2),
            Expanded(
              child: zonesWithPlantsData.isEmpty
                  ? const Center(
                child: Text(
                  'Chưa có lô sâm nào.\nHãy nhấn "Thêm lô" để bắt đầu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(top: 16),
                itemCount: zonesWithPlantsData.length,
                itemBuilder: (context, index) {
                  final zone = zonesWithPlantsData[index];
                  return _buildZoneCard(zone);
                },
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildZoneCard(LoSamModel zone) {
    final soCaySam = zone.soLuongCaySams ?? 0;
    final soHang = zone.soHang ?? 0;
    final soCot = zone.soCot ?? 0;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: Colors.black.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () { // Giữ nguyên logic onTap của bạn
          setState(() {
            selectedZone = zone;
            _reloadData();
            if (selectedZone != null) {
              setState(() {
                gridRows = List.generate(selectedZone!.soHang, (i) => i + 1);
              });
            }
            currentLevel = NavigationLevel.grid;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.map_rounded, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.tenLo ?? "Chưa có tên lô",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mã Lô: ${zone.maLo ?? "N/A"}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddLoSamScreen(
                            farmId: zone.vuonTrongId,
                            zoneid: zone.loSamId,
                            onSubmit: _edithandleLoSamSubmit,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit_outlined, color: Colors.blue.shade600, size: 20),
                    tooltip: 'Chỉnh sửa lô',
                    visualDensity: VisualDensity.compact,
                  ),
                  if (((zone.loSamCameras?.length ?? 0) == 1 && zone.soLuongCaySams > 0))
                    IconButton(
                      onPressed: () => _showCameraView(
                        zone.loSamCameras ?? [],
                        zone,
                      ),
                      icon: Icon(Icons.videocam_outlined, color: Colors.green.shade600, size: 22),
                      tooltip: 'Xem camera',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),

              const Divider(height: 20),
              Row(
                children: [
                  _buildStatChip(Icons.grid_on_outlined, '$soHang x $soCot'),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.eco_outlined, '$soCaySam Cây'),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

// Hàm hỗ trợ tạo chip thống kê (để ở đây cho đầy đủ)
  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Thay thế hàm _buildGridLevel cũ bằng hàm này:
  Widget _buildGridLevel() {
    if (_futureLoSam == null) return const SizedBox();

    return FutureBuilder<LoSamModel?>(
      future: _futureLoSam,
      builder: (context, snapshot) {
        // 1. Logic Loading cho lần đầu tiên vào màn hình (khi chưa có dữ liệu cũ)
        if (snapshot.connectionState == ConnectionState.waiting && loSam == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }

        // Lấy dữ liệu (Ưu tiên loSam mới nhất)
        if (loSam == null && snapshot.hasData) {
          loSam = snapshot.data;
        }
        if (loSam == null) {
          return const Center(child: Text("Không có dữ liệu"));
        }

        // ... (Các đoạn cập nhật biến phụ trợ giữ nguyên) ...
        final areaPlants = loSam?.caySams ?? [];
        losamchitiet = loSam?.loSamChiTiets;
        final allPlantPositions = areaPlants
            .map((plant) => plant.viTriTrongLo)
            .whereType<String>()
            .toSet();

        List<CaySamModel> displayPlants = areaPlants;
        // ... (Logic lọc user giữ nguyên) ...

        // 🔥 SỬ DỤNG STACK ĐỂ HIỆN LOADING MÀ KHÔNG MẤT SCROLL
        return Stack(
          children: [
            // Lớp dưới: Giao diện chính (Scroll View)
            // Nhờ Key và Controller, nó sẽ giữ nguyên vị trí
            SingleChildScrollView(
              key: const PageStorageKey("GridScrollKey"),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(), // Luôn cho phép cuộn
              child: Column(
                children: [
                  _buildLegend(loSam, displayPlants),
                  const SizedBox(height: 8),
                  if (isMultiSelectMode) ...[
                    _buildMultiSelectControls(displayPlants),
                    const SizedBox(height: 8),
                  ],
                  _buildAgeGroupStats(loSam),
                  const SizedBox(height: 8),
                  _buildPlantGrid(displayPlants, allPlantPositions),
                  // Thêm padding dưới cùng để không bị che bởi nút bấm nếu có
                  const SizedBox(height: 80),
                ],
              ),
            ),

            // Lớp trên: Loading Overlay (Chỉ hiện khi _isLoading = true)
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  // Màu nền bán trong suốt để làm mờ giao diện cũ
                  color: Colors.white.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMultiSelectControls(List<CaySamModel> areaPlants) {
    final selectedCount = selectedEmptyCells.length;
    final selectedPositions = selectedEmptyCells.take(5).join(', ');
    final moreText = selectedEmptyCells.length > 5
        ? ' và ${selectedEmptyCells.length - 5} vị trí khác'
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200, width: 1.5), // Viền rõ ràng hơn
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Hiện Đại ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chọn hàng loạt',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey.shade900,
                          letterSpacing: -0.5
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lọc nhanh & Thêm nhật ký',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text(
                        'Đã chọn: $selectedCount',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, thickness: 1),
            ),


            // 1. Dropdown Tuổi cây
            _buildModernDropdown(
              label: '1. Tuổi cây',
              icon: Icons.auto_awesome_motion_rounded,
              value: _selectedtuoicay,
              items: OptionLoSamLoaiTuoi,
              onChanged: (val) {
                setState(() => _selectedtuoicay = val);
                _applyFiltersAndSelectCells(areaPlants);
              },
              onClear: () {
                setState(() => _selectedtuoicay = null);
                _applyFiltersAndSelectCells(areaPlants);
              },
            ),

            const SizedBox(height: 12),

// 2. Dropdown Tình trạng
            _buildModernDropdown(
              label: '2. Tình trạng',
              icon: Icons.health_and_safety_rounded,
              value: _selectedTinhTrang,
              items: OptionLoSamTinhTrang,
              onChanged: (val) {
                setState(() => _selectedTinhTrang = val);
                _applyFiltersAndSelectCells(areaPlants);
              },
              onClear: () {
                setState(() => _selectedTinhTrang = null);
                _applyFiltersAndSelectCells(areaPlants);
              },
            ),

            const SizedBox(height: 12),

// 3. Dropdown Sức khỏe
            _buildModernDropdown(
              label: '3. Sức khỏe',
              icon: Icons.speed_rounded,
              value: _selectedDiemSucKhoe,
              items: OptionLoSamDiemSucKhoe.reversed.toList(),
              onChanged: (val) {
                setState(() => _selectedDiemSucKhoe = val);
                _applyFiltersAndSelectCells(areaPlants);
              },
              onClear: () {
                setState(() => _selectedDiemSucKhoe = null);
                _applyFiltersAndSelectCells(areaPlants);
              },
            ),

            const SizedBox(height: 20),

            // --- Hàng nút thao tác chính ---
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildSecondaryButton(
                    icon: Icons.refresh_rounded,
                    label: 'Bỏ chọn',
                    onPressed: _clearSelection,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildPrimaryButton(
                    icon: Icons.add_task_rounded,
                    label: 'Thêm nhật ký ($selectedCount)',
                    isActive: selectedCount > 0,
                    onPressed: () => _handleBatchAddPlants(areaPlants),
                  ),
                ),
              ],
            ),

            // --- Phần hiển thị vị trí đã chọn ---
            if (selectedCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vị trí: $selectedPositions$moreText',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // --- Phần File PDF ---
            _buildPdfSection(areaPlants),
          ],
        ),
      ),
    );
  }

// --- Các Widget thành phần hỗ trợ (Helper Widgets) ---

  Widget _buildModernDropdown({
    required String label,
    required IconData icon,
    required OptionModel? value,
    required List<OptionModel> items,
    required Function(OptionModel?) onChanged,
    required VoidCallback onClear, // ✨ Thêm hàm xóa
  }) {
    return DropdownButtonFormField<OptionModel>(
      value: value,
      hint: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey.shade600),
        // ✨ Thêm nút X ở cuối nếu đã có giá trị được chọn
        suffixIcon: value != null
            ? IconButton(
          icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
          onPressed: onClear,
        )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items.map((opt) => DropdownMenuItem(value: opt, child: Text(opt.text))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPrimaryButton({required IconData icon, required String label, required bool isActive, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isActive ? LinearGradient(colors: [Colors.green.shade600, Colors.green.shade700]) : null,
        boxShadow: isActive ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: ElevatedButton.icon(
        onPressed: isActive ? onPressed : null,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.blueGrey.shade600),
      label: Text(label, style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildPdfSection(List<CaySamModel> areaPlants) {
    if (_selectedFileName == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _pickPdfFile,
          icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 20),
          label: const Text('Đính kèm PDF báo cáo', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(color: Colors.red.shade100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            backgroundColor: Colors.red.shade50.withOpacity(0.3),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4), // Container bọc cả file và nút gửi
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_selectedFileName!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: _clearSelectedFile),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _uploadFileToServer(areaPlants),
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('GỬI DỮ LIỆU LÊN HỆ THỐNG', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _uploadFileToServer(List<CaySamModel> areaPlants) async {
    if (_selectedFileName == null) return; // Kiểm tra xem đã có data file chưa
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    Kttoken? user;
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    try {
      final updateData = {
        "CaySam_IDs": areaPlants
          .where((plant) => selectedEmptyCells.contains(plant.viTriTrongLo)) // Điều kiện lọc
          .map((plant) => plant.caySamId) // Lấy ID
          .toList(),
        "IdTaiKhoan": "${user?.htTaiKhoan.id}",
        "ThoiGian": DateTime.now().toIso8601String(),
        "TrangThai": true
      };
      final apiResponse = await API().addDinhKemFileCaySam(
        data: updateData,
        file: _selectedFilePath,
      );
      bool isSuccess = false;
      if (apiResponse?.messCode == MessCode.IsOK) isSuccess = true;
      if (isSuccess) {
        _showSnackBar("Tải file lên thành công!", isSuccess: true);
        _clearSelection();
        _clearSelectedFile();
      } else {
        _showSnackBar("Tải file thất bại.${apiResponse?.message} !", isSuccess: false);
      }
    } catch (e) {
      // Xử lý lỗi
      print("Lỗi: $e");
      _showSnackBar("Tải file thất bại.Vui lòng thử lại sau !", isSuccess: false);
    }
  }
  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;

        setState(() {
          _selectedFileName = file.name;
          _selectedFilePath = File(file.path!) ;
        });

        print("Đã chọn file: ${file.name}");
        print("Đường dẫn: ${file.path}");

        // TODO: Gọi API upload file ở đây nếu cần
      } else {
        // Người dùng hủy chọn
        print("Hủy chọn file");
      }
    } catch (e) {
      print("Lỗi chọn file: $e");
    }
  }

// 3. Hàm xóa file đã chọn (nếu muốn chọn lại)
  void _clearSelectedFile() {
    setState(() {
      _selectedFileName = null;
      _selectedFilePath = null;
    });
  }
  // Widget _buildAreaInfo() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         Text(
  //           selectedArea!.name,
  //           style: const TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         Container(
  //           width: double.infinity,
  //           height: 200,
  //           decoration: BoxDecoration(
  //             color: Colors.grey[100],
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.grey[300]!),
  //           ),
  //           child: const Center(
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(Icons.landscape, size: 40, color: Colors.grey),
  //                 SizedBox(height: 8),
  //                 Text('Layout khu vực'),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           'Kích thước ô: 40cm x 40cm | Lối đi: 50cm',
  //           style: TextStyle(
  //             fontSize: 10,
  //             color: Colors.grey[600],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  /*Widget _buildAreaStats(List<CaySamModel> areaPlants) {
    final healthyPlants = areaPlants
        .where((plant) => plant.trangThai == TrangThaiCay.khoeMauh)
        .length;
    final plantsWithInvestors = areaPlants
        .where((plant) => plant.loSamId != null)
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Cây trong khu',
            value: areaPlants.length.toString(),
            color: Colors.blue[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Có NĐT',
            value: plantsWithInvestors.toString(),
            color: Colors.green[600]!,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Khỏe mạnh',
            value: healthyPlants.toString(),
            color: Colors.teal[600]!,
          ),
        ),
      ],
    );
  }*/

  Widget _buildLegend(LoSamModel? losam,List<CaySamModel> caysam) {
    final isValid = user!.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) {
      if (pq.maVaiTro == "nft_invester") {
        return caysam.isNotEmpty && (losam?.loSamCameras?.length ?? 0) > 0;
      } else if (pq.maVaiTro == "nft_admin") {
        return (losam?.loSamCameras?.length ?? 0) > 0 && (selectedZone?.soLuongCaySams ?? 0) > 0;
      }
      return false;
    });
    final String? imageUrl = losam?.hinhAnh;
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // const Text(
          //   'Chú thích',
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w500,
          //   ),
          // ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8), // Giữ nguyên bo góc
              border: Border.all(color: Colors.grey.shade300), // Giữ nguyên viền
            ),
            // Clip.hardEdge cực kỳ quan trọng để cắt Shimmer/Ảnh theo góc bo của Container
            clipBehavior: Clip.hardEdge,
            child: hasImage
                ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,

              // === HIỆU ỨNG SHIMMER KHI ĐANG TẢI ===
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300, // Màu nền xám đậm hơn chút
                highlightColor: Colors.grey.shade100, // Màu vệt sáng lướt qua
                child: Container(
                  color: Colors.white, // Cần container màu trắng để hiệu ứng hiện lên
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // === HIỂN THỊ KHI LỖI TẢI ẢNH ===
              errorWidget: (context, url, error) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.grey),
                    SizedBox(height: 4),
                    Text("Lỗi tải ảnh", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
                : const Center(
              // === HIỂN THỊ KHI DỮ LIỆU RỖNG ===
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  Text("Chưa có ảnh"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Kích thước ô: 40cm x 40cm | Lối đi: 50cm',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
          const SizedBox(height: 12),

        if (isValid) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.camera_alt, size: 16),
                    const SizedBox(width: 8),
                    Text('Camera giám sát (${losam?.loSamCameras?.length})'),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showCameraView(
                    losam?.loSamCameras ?? [],
                    losam,
                  ),
                  icon: const Icon(Icons.videocam, size: 16),
                  label: const Text(
                    'Xem Camera',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ), // 👈 chỉnh padding ở đây
                    minimumSize:
                    const Size(0, 0), // 👈 bỏ giới hạn min mặc định
                    tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap, // 👈 giảm vùng chạm
                  ),
                )
              ],
            ),
          ),
        ],
            const SizedBox(height: 12),
            ...?losam?.loSamCameras
                ?.take(3)
                .map((camera) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: camera.trangThai == 1
                                      ? Colors.green
                                      : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(camera.loSamLoaiCamera?.ten ?? "",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                          Text(
                            camera.trangThai == 1 ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: camera.trangThai == 1
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              const Text('Nền:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              _buildLegendItem(AppColors.PRIMARY['lighter']!, 'Sống'),
              _buildLegendItem(Colors.blue[200]!, 'Ngủ đông'),
              _buildLegendItem(AppColors.ERROR['lighter']!, 'Chết'),
              _buildLegendItem(Colors.grey[300]!, 'Ô trống'),
              const SizedBox(width: double.infinity, height: 4), // Dòng ngăn cách
              const Text('Icon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              _buildIconColorLegendItem(AppColors.PRIMARY['darker']!, 'Rất tốt'), // case 5
              _buildIconColorLegendItem(AppColors.PRIMARY['main']!, 'Tốt'),      // case 4
              _buildIconColorLegendItem(AppColors.PRIMARY['light']!, 'Trung bình'),// case 3
              _buildIconColorLegendItem(AppColors.ERROR['light']!, 'Yếu'),       // case 2
              _buildIconColorLegendItem(AppColors.ERROR['main']!, 'Rất yếu'),    // case 1
              const SizedBox(width: double.infinity, height: 4),
              _buildLegendItemWithIcon(
                color: Colors.orange.shade500,
                icon: Icons.menu_book,
                label: 'Đã có nhật ký tháng này',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  Widget _buildIconColorLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle, // Hình tròn
            border: Border.all(color: Colors.black.withOpacity(0.1)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  Widget _buildLegendItemWithIcon({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(
            icon,
            size: 9,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
  Widget _buildPlantGrid(
      List<CaySamModel>? areaPlants, Set<String?> allPlantPositions) {

    if (gridColumns.isEmpty || gridRows.isEmpty) {
      return const SizedBox();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.grid_view_rounded,
                        size: 18, color: Colors.green[700]),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SƠ ĐỒ LUỐNG',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[500],
                              letterSpacing: 1)),
                      Text(selectedZone?.tenLo ?? 'Chưa chọn',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double availableWidth = constraints.maxWidth;
                const double gapSize = 3.0;
                const double walkwaySize = 12.0;
                int totalCols = gridColumns.length;
                bool hasWalkway = gridColumns.contains('C') && gridColumns.last != 'C';
                double totalSpacingWidth = 0;
                if (hasWalkway) {
                  totalSpacingWidth = ((totalCols - 2) * gapSize) + walkwaySize;
                } else {
                  totalSpacingWidth = (totalCols - 1) * gapSize;
                }
                double cellSize = ((availableWidth - totalSpacingWidth) / totalCols).floorToDouble();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: gridColumns.asMap().entries.map((entry) {
                          int index = entry.key;
                          String col = entry.value;
                          Widget headerCell = SizedBox(
                            width: cellSize,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(col,
                                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey[400], fontSize: 12)),
                              ),
                            ),
                          );
                          if (col == 'C') return Row(children: [headerCell, SizedBox(width: walkwaySize)]);
                          else if (index == gridColumns.length - 1) return headerCell;
                          else return Row(children: [headerCell, SizedBox(width: gapSize)]);
                        }).toList(),
                      ),
                    ),
                    ...gridRows.map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: gridColumns.asMap().entries.expand((entry) {
                          int index = entry.key;
                          String col = entry.value;
                          final position = '$col$row';

                          final plant = areaPlants?.firstWhere(
                                (p) => p.viTriTrongLo == position,
                            orElse: () => CaySamModel(caySamId: '', loSamId: 0, viTriTrongLo: '', tuoiCayId: 0, caySamNhatKys: [], caySam_DinhKems: []),
                          );
                          final hasPlant = plant?.caySamId.isNotEmpty ?? false;
                          final isSelected = plant?.caySamId == selectedPlant;
                          final isCellSelected = selectedEmptyCells.contains(position);
                          final ageIcon = _getPlantAgeIconPath(plant?.tuoiCayId ?? 0);
                          final diemSK = (plant?.caySamNhatKys.isNotEmpty ?? false) ? plant!.caySamNhatKys.first?.diemSucKhoe : 0;
                          final diemTT = (plant?.caySamNhatKys.isNotEmpty ?? false) ? plant!.caySamNhatKys.first?.tinhTrang : 0;

                          Color cellBgColor;
                          Color borderColor;
                          if (!hasPlant) {
                            cellBgColor = Colors.grey.shade200;
                            borderColor = Colors.white;
                          } else {
                            if (isMultiSelectMode && isCellSelected) {
                              cellBgColor = Colors.green[600]!;
                              borderColor = Colors.green[800]!;
                            } else {
                              cellBgColor = getTrangThaiColor(diemTT ?? 0).withOpacity(0.2);
                              borderColor = getTrangThaiColor(diemTT ?? 0).withOpacity(0.6);
                            }
                          }
                          final cell = GestureDetector(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              if (isMultiSelectMode) {
                                if (hasPlant && plant!.caySamNhatKys.isNotEmpty) {
                                  final ngayGhi = DateTime.parse(plant.caySamNhatKys.first?.ngayGhi ?? "");
                                  final now = DateTime.now();
                                  // if (ngayGhi.month == now.month && ngayGhi.year == now.year) {
                                  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã có nhật ký tháng này'), backgroundColor: Colors.orange));
                                  // } else {
                                    _handleEmptyCellToggle(position);
                                  // }
                                  // _handleEmptyCellToggle(position);
                                }
                                return;
                              }
                              if (!isMultiSelectMode) {
                                if (hasPlant) {
                                  final selected = areaPlants?.firstWhere((p) => p.caySamId == plant?.caySamId, orElse: () => CaySamModel(caySamId: '', loSamId: 0, viTriTrongLo: '', tuoiCayId: 0, caySamNhatKys: [], caySam_DinhKems: []));
                                  if (selected != null && selected.caySamId.isNotEmpty) {
                                    double savedPosition = 0;
                                    if (_scrollController.hasClients) {
                                      savedPosition = _scrollController.position.pixels;
                                    }
                                    CaySamModel? model = await API().getCaySamById(selected.caySamId);
                                    if(model != null){
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => PlantDetailScreen(
                                        plant: model,
                                        onBack: () {}, // Callback rỗng vì ta dùng await
                                      )));
                                    }
                                    await _reloadData();
                                    if (mounted) {
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (_scrollController.hasClients) {
                                          // Chỉ cuộn nếu khoảng cách lệch lớn (tránh giật nhẹ)
                                          if ((_scrollController.position.pixels - savedPosition).abs() > 5) {
                                            if (savedPosition <= _scrollController.position.maxScrollExtent) {
                                              _scrollController.jumpTo(savedPosition);
                                            } else {
                                              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                            }
                                          }
                                        }
                                      });
                                    }
                                  }
                                } else {
                                  // Logic thêm cây
                                  if(user!.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin")) _showAddPlantDialog(position);
                                }
                              }
                            },
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              decoration: BoxDecoration(
                                color: cellBgColor,
                                borderRadius: BorderRadius.circular(6),
                                border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : Border.all(color: borderColor, width: 1),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: hasPlant
                                        ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(child: ImageIcon(AssetImage(ageIcon), size: cellSize * 0.6, color: getDiemSKColor(diemSK ?? 0))),
                                        FittedBox(fit: BoxFit.scaleDown, child: Text(position, style: const TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.w800))),
                                      ],
                                    )
                                        : FittedBox(fit: BoxFit.scaleDown, child: Text(position, style: const TextStyle(color: Colors.black54, fontSize: 9, fontWeight: FontWeight.w600))),
                                  ),
                                  if (plant?.caySamNhatKys != null && plant!.caySamNhatKys.isNotEmpty)
                                        () {
                                      final ngayGhiStr = plant.caySamNhatKys.first?.ngayGhi;
                                      if (ngayGhiStr != null) {
                                        final ngayGhi = DateTime.tryParse(ngayGhiStr);
                                        final now = DateTime.now();
                                        if (ngayGhi != null && ngayGhi.month == now.month && ngayGhi.year == now.year) {
                                          return Positioned(top: 1, right: 1, child: Container(padding: const EdgeInsets.all(1), decoration: BoxDecoration(color: Colors.orange[800], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)), child: const Icon(Icons.edit, size: 6, color: Colors.white)));
                                        }
                                      }
                                      return const SizedBox();
                                    }(),
                                  if (isMultiSelectMode && isCellSelected) Center(child: Icon(Icons.check_circle, color: Colors.white, size: 16)),
                                ],
                              ),
                            ),
                          );

                          if (col == 'C') return [cell, SizedBox(width: walkwaySize)];
                          else if (index == gridColumns.length - 1) return [cell];
                          else return [cell, SizedBox(width: gapSize)];
                        }).toList(),
                      ),
                    )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlantDetails(List<CaySamModel>? areaPlants) {
    final plant = areaPlants?.firstWhere(
      (p) => p.caySamId == selectedPlant,
      orElse: () => CaySamModel(
        caySamId: '',
        loSamId: 0,
        viTriTrongLo: '',
        tuoiCayId: 0,
        caySamNhatKys: [], caySam_DinhKems: [],
      ),
    );

    // Nếu không tìm thấy cây
    if (plant == null || plant.caySamId.isEmpty) {
      return const SizedBox();
    }
    final age = _calculatePlantAge(plant.tuoiCayId ?? 0);
    final ageGroup = _getPlantAgeGroup(age);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin cây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlantDetailScreen(
                        plant: plant,
                        onBack: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Chi tiết'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
            children: [
              _buildDetailItem('Vị trí', plant.viTriTrongLo ?? 'N/A'),
              _buildDetailItem('Tuổi cây', '$ageGroup ($age năm)'),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailItem('Tên cây', plant.blockChain ?? ''),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _handleAddPlantSubmit(
      Map<String, dynamic> plantData,
      List<File?> images,
      String? caysamid
      ) async {
    showLoadingDialog(context, message: 'Đang lưu cây mới...');

    try {
      // ✅ BƯỚC 2: GỌI API VÀ CHỜ KẾT QUẢ
      final apiResponse = await API().addCaySam(
        data: plantData,
        files: images,
      );

      // ✅ BƯỚC 3: ĐÓNG DIALOG LOADING
      // Đóng dialog ngay sau khi có kết quả, trước khi xử lý tiếp.
      // Kiểm tra `mounted` để đảm bảo widget vẫn còn trên cây giao diện.
      if (mounted) {
        Navigator.of(context).pop(); // Dòng này để đóng dialog loading
      }

      // Kiểm tra lại lần nữa phòng trường hợp người dùng thoát ra trong lúc chờ
      if (!mounted) return;

      // ✅ BƯỚC 4: XỬ LÝ KẾT QUẢ API (như cũ)
      if (apiResponse != null && apiResponse.message == "OK") {
        // Thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🌱 Cây mới đã được thêm thành công!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _reloadData();
        });
        Navigator.of(context).pop();
      } else {
        // Lỗi từ server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thêm cây sâm. Lỗi: ${apiResponse?.message ?? "Không xác định"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ❌ XỬ LÝ KHI CÓ LỖI MẠNG HOẶC EXCEPTION

      // Đảm bảo dialog loading cũng được đóng khi có lỗi
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddLoSamDialog() {
    // Determine current zone info
    int zoneId = selectedZone?.vuonTrongId ?? 1;
    String zoneName = 'Vùng mặc định';

    if (selectedFarm?.vuonTrongId != null && selectedZone?.loSamId != null) {
      final farm = MockData.mockFarms
          .firstWhere((f) => f.id == selectedFarm?.vuonTrongId);
      final zone = farm.zones.firstWhere((z) => z.id == selectedZone?.loSamId);
      zoneName = zone.name;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddLoSamScreen(
          farmId: zoneId,
          onSubmit: _handleLoSamSubmit,
        ),
      ),
    );
  }
  void Selectlo(LoSamModel? zone){
    selectedZone = zone;
    _reloadData();
    if (selectedZone != null) {
      setState(() {
        gridRows = List.generate(selectedZone!.soHang, (i) => i + 1);
      });
    }
    currentLevel = NavigationLevel.grid;
  }
  void _showAddfarmDialog() {

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFarmScreen(
          farmId: null,
          onSubmit: _handleFarmSubmit,
        ),
      ),
    );
  }

  void _showAddPlantDialog(String cellId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPlantScreen(
          onSubmit: _handleAddPlantSubmit,
          onCancel: () {
            Navigator.of(context).pop();
          },
          gridPosition: cellId,
          losamId: selectedZone?.loSamId ?? 0,
          areaId: selectedZone?.maLo ?? "",
        ),
      ),
    );
  }

  void _handleLoSamSubmit(Map<String, dynamic> data,int id, {File? image}) async {
    print('LoSam data submitted: ${jsonEncode(data)}');

    List<int>? fileBytes;
    String? fileName;

    if (image != null) {
      fileBytes = await image.readAsBytes();
      fileName = image.path.split('/').last;
      print("📷 Ảnh được chọn: $fileName (${fileBytes.length} bytes)");
    }

    final response = await API().addLoSam(
      data: data,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    if (response != null) {
      if (response.message == "OK") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lô sâm đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        setState(() {
          _reloadData();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo lô sâm thất bại! ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
        print("⚠️ API trả về: ${response.message}");
      }
    } else {
      print("❌ API lỗi hoặc null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API lỗi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _handleFarmSubmit(VuonTrongModel model) async {
    final response = await API().addVuonTrong( model: model);
    if (response != null) {
      if (response.messCode == MessCode.IsOK) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vườn đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _initializeData();
        });
        Navigator.of(context).pop();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo Vườn thất bại! ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
        print("⚠️ API trả về: ${response.message}");
      }
    } else {
      print("❌ API lỗi hoặc null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API lỗi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _edithandleLoSamSubmit(Map<String, dynamic> data,int id, {File? image}) async {
    print('LoSam data submitted: ${jsonEncode(data)}');

    List<int>? fileBytes;
    String? fileName;

    if (image != null) {
      fileBytes = await image.readAsBytes();
      fileName = image.path.split('/').last;
      print("📷 Ảnh được chọn: $fileName (${fileBytes.length} bytes)");
    }

    final response = await API().editLoSam(
      id: id,
      data: data,
      fileBytes: fileBytes,
      fileName: fileName,
    );

    if (response != null) {
      if (response.messCode == MessCode.IsOK) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lô sâm đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        setState(() {
          _reloadData();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tạo lô sâm thất bại! ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
        print("⚠️ API trả về: ${response.message}");
      }
    } else {
      print("❌ API lỗi hoặc null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API lỗi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _edithandleFarmSubmit(VuonTrongModel model) async {

    final response = await API().editVuonTrong(model: model);
    if (response != null) {
      if (response.messCode == MessCode.IsOK) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉnh sửa thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        setState(() {
          _reloadData();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chỉnh sửa thất bại! ${response.message}'),
            backgroundColor: Colors.red,
          ),
        );
        print("⚠️ API trả về: ${response.messCode}");
      }
    } else {
      print("❌ API lỗi hoặc null");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API lỗi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleBatchAddPlants(List<CaySamModel> areaPlants) async {
    if (selectedEmptyCells.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Vui lòng chọn ít nhất một ô trống'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    List<String> selectedEmptyCellsList = selectedEmptyCells.toSet().toList();
    final updateData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchPlantUpdateScreen(
          selectedPositions: selectedEmptyCellsList,
          caysam: areaPlants,
          areaId: "",
          areaName: "",
        ),
      ),
    );

// 🔄 nếu updateData != null thì load lại
    if (updateData != null) {
      setState(() {
        _reloadData();
      });
    }

    // Reset selection
    setState(() {
      selectedEmptyCells.clear();
      isMultiSelectMode = false;
    });

    _multiSelectAnimationController.reverse();
    HapticFeedback.heavyImpact();
  }

  void _selectAllEmptyCells(List<CaySamModel> areaPlants) {
    if (!isMultiSelectMode) return;

    // Lấy toàn bộ vị trí có cây
    final occupied =
        areaPlants.map((p) => p.viTriTrongLo).whereType<String>().toSet();

    setState(() {
      selectedEmptyCells = occupied;
    });

    HapticFeedback.mediumImpact();
  }

  void _clearSelection() {
    setState(() {
      _selectedtuoicay = null;
      _selectedTinhTrang = null;
      _selectedDiemSucKhoe = null;
      selectedEmptyCells.clear();
    });
  }

  void _handleEmptyCellToggle(String position) {
    if (!isMultiSelectMode) return;
    setState(() {
      if (selectedEmptyCells.contains(position)) {
        selectedEmptyCells.remove(position);
      } else {
        selectedEmptyCells.add(position);
      }
    });

    // Haptic feedback
    HapticFeedback.lightImpact();
  }
}



extension LoSamChiTietExt on List<LoSamChiTietModel>? {
  int sl(int loaiTuoiId) =>
      this
          ?.firstWhere(
            (e) => e.loSamLoaiTuoiId == loaiTuoiId,
            orElse: () => LoSamChiTietModel(
              id: 0,
              loSamId: 0,
              loSamLoaiTuoiId: 0,
              soLuong: 0,
              trangThai: 0,
            ),
          )
          .soLuong ??
      0;
}
Color getDiemSKColor(int trangThaiId) {
  switch (trangThaiId) {
    case 5:
      return AppColors.PRIMARY['darker']!;
    case 4:
      return AppColors.PRIMARY['main']!;
    case 3:
      return AppColors.PRIMARY['light']!;
    case 2:
      return AppColors.ERROR['light']!;
    case 1:
      return AppColors.ERROR['main']!;
    default:
      return Colors.grey.shade50;
  }
}
Color getTrangThaiColor(int status) {
  switch (status) {
    case 1:
      return Colors.green[200]!; // 🌿 Sống
    case 2:
      return Colors.blue[200]!; // ❄️ Ngủ đông
    case 3:
      return AppColors.ERROR['light']!; // 💀 Chết
    default:
      return Colors.grey[50]!; // ⚪ Trạng thái không xác định
  }
}

