import 'dart:convert';
import 'dart:io';

import 'package:csam_mobile/api/api_caysam.dart';
import 'package:csam_mobile/api/api_caytrong.dart';
import 'package:csam_mobile/api/api_option.dart';
import 'package:csam_mobile/models/vuontrong/losamcamera_model.dart';
import 'package:csam_mobile/screens/plant_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import '../models/camera.dart';
import '../models/cay_sam.dart';
import '../models/farm_hierarchy.dart';
import '../data/mock_data.dart';
import '../models/option_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamchitiet_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/camera.dart';
import 'add_losam_screen.dart';
import 'add_plant_screen.dart';
import 'batch_plant_update_screen.dart';

class PlantManagementViewScreen extends StatefulWidget {
  // final List<CaySam> plants;
  final Function(String) onPlantSelect;

  const PlantManagementViewScreen({
    Key? key,
    // required this.plants,
    required this.onPlantSelect,
  }) : super(key: key);

  @override
  State<PlantManagementViewScreen> createState() =>
      _PlantManagementViewScreenState();
}

class _PlantManagementViewScreenState extends State<PlantManagementViewScreen>
    with TickerProviderStateMixin {
  NavigationLevel currentLevel = NavigationLevel.farm;
  VuonTrongModel? selectedFarm;
  LoSamModel? selectedZone;
  // Area? selectedArea;
  String? selectedPlant;

  final List<String> gridColumns = ['A', 'B', 'C', 'D', 'E', 'F'];
  List<int> gridRows = [];
  List<LoSamChiTietModel>? losamchitiet = [];

  bool isMultiSelectMode = false;
  Set<String> selectedEmptyCells = <String>{};

  // late PlantStats plantStats;
  List<VuonTrongModel>? farmsWithPlantsData = [];
  List<OptionModel> OptionLoSamLoaiTuoi = [];

  // 🎨 Animation controllers
  late AnimationController _multiSelectAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _multiSelectAnimation;
  late Animation<double> _pulseAnimation;
  Future<LoSamModel?>? _futureLoSam;
  OptionModel? _selectedtuoicay;
  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupAnimations();
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
    // Calculate farms with plants data
    // farmsWithPlantsData = MockData.mockFarms
    //     .map((farm) => farm.copyWith(
    //   investorPlantCount: widget.plants
    //       .where((plant) => farm.zones.any((zone) =>
    //       zone.areas.any((area) => area.id == plant.areaId)))
    //       .length,
    // ))
    //     .where((farm) => farm.investorPlantCount! > 0)
    //     .toList();
    final apifarm = await api.listVuonTrong(status: 1, take: 10, skip: 0);
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
  }

  void _toggleMultiSelectMode() {
    setState(() {
      isMultiSelectMode = !isMultiSelectMode;
      selectedEmptyCells.clear();
      selectedPlant = null;
    });

    if (isMultiSelectMode) {
      _multiSelectAnimationController.forward();
    } else {
      _multiSelectAnimationController.reverse();
    }
  }

  PlantStats _calculatePlantStats(List<CaySamModel> plants) {
    final totalPlants = plants.length;
    final plantsWithInvestors =
        plants.where((plant) => plant.loSamId != null).length;
    final plantsWithoutInvestors = totalPlants - plantsWithInvestors;
    final ageGroups = <String, int>{
      '1-3': plants.where((plant) {
        final age = _calculatePlantAge(plant.tuoiCayId ?? 0);
        return age >= 1 && age <= 3;
      }).length,
      '4-6': plants.where((plant) {
        final age = _calculatePlantAge(plant.tuoiCayId ?? 0);
        return age >= 4 && age <= 6;
      }).length,
      '7-8': plants.where((plant) {
        final age = _calculatePlantAge(plant.tuoiCayId ?? 0);
        return age >= 7 && age <= 8;
      }).length,
      '9-10': plants.where((plant) {
        final age = _calculatePlantAge(plant.tuoiCayId ?? 0);
        return age >= 9 && age <= 10;
      }).length,
    };
    final healthyPlants =
        1 /*plants.where((p) => p.trangThai == TrangThaiCay.khoeMauh).length*/;
    return PlantStats(
      totalPlants: totalPlants,
      plantsWithInvestors: plantsWithInvestors,
      plantsWithoutInvestors: plantsWithoutInvestors,
      ageGroups: ageGroups,
      healthyPlants: healthyPlants,
    );
  }

  int _calculatePlantAge(int plantingDate) {
    // if (plantingDate.isEmpty) return 0;
    // try {
    //   final planted = DateTime.parse(plantingDate);
    //   final now = DateTime.now();
    //   return now.difference(planted).inDays ~/ 365;
    // } catch (e) {
    //   return 0;
    // }
    return plantingDate;
  }

  String _getPlantAgeGroup(int age) {
    if (age >= 1 && age <= 3) return '1-3 năm';
    if (age >= 4 && age <= 6) return '4-6 năm';
    if (age >= 7 && age <= 8) return '7-8 năm';
    if (age >= 9 && age <= 10) return '9-10 năm';
    return 'Chưa xác định';
  }

  IconData _getPlantAgeIcon(int age) {
    if (age == 1) return FontAwesomeIcons.seedling; // Young sprout
    if (age == 2) return FontAwesomeIcons.leaf; // Growing plant
    if (age == 3) return Icons.park; // Mature tree
    if (age == 4) return Icons.forest; // Old tree
    return FontAwesomeIcons.seedling;
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
      switch (currentLevel) {
        case NavigationLevel.grid:
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final breadcrumb = _getBreadcrumb();
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (breadcrumb.isNotEmpty)
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentLevel != NavigationLevel.farm)
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _handleNavigationBack,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),

                      // Breadcrumb chiếm phần còn lại
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  breadcrumb.join(' → '),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              if (currentLevel == NavigationLevel.grid)
                                AnimatedBuilder(
                                  animation: _multiSelectAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: 1.0 +
                                          (_multiSelectAnimation.value *
                                              0.05),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          gradient: isMultiSelectMode
                                              ? LinearGradient(
                                                  colors: [
                                                    Colors.red[400]!,
                                                    Colors.red[600]!
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    Colors.blue[400]!,
                                                    Colors.blue[600]!
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isMultiSelectMode
                                                      ? Colors.red
                                                      : Colors.blue)
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: _toggleMultiSelectMode,
                                          icon: Icon(
                                            isMultiSelectMode
                                                ? Icons.close
                                                : Icons.check_box_outlined,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            isMultiSelectMode
                                                ? 'Thoát'
                                                : 'Nhật ký',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )),
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
          ],
        ),
      ),
    );
  }

  void _showCameraView(List<LoSamCameraModel> cameras, String areaName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraView(
          cameras: cameras,
          areaName: areaName,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // if(currentLevel == NavigationLevel.grid)
          // _buildAgeGroupStats(),

          /*_buildOverallStats(),
          const SizedBox(height: 16),*/
          Expanded(
            child: _buildCurrentLevelContent(),
          ),
        ],
      ),
    );
  }

  /*Widget _buildOverallStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Tổng số cây',
            value: selectedZone?.dienTich.toString() ?? "",
            color: Colors.green[600]!,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Có nhà đầu tư',
            value: plantStats.plantsWithInvestors.toString(),
            color: Colors.blue[600]!,
          ),
        ),
      ],
    );
  }*/

  Widget _buildAgeGroupStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        // borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phân bố theo tuổi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildAgeGroupItem(FontAwesomeIcons.seedling, '1-3(N)',
                    losamchitiet.sl(1), Colors.green[400]!),
              ),
              Expanded(
                child: _buildAgeGroupItem(FontAwesomeIcons.leaf, '4-6(N)',
                    losamchitiet.sl(2), Colors.green[600]!),
              ),
              Expanded(
                child: _buildAgeGroupItem(Icons.park, '7-8(N)',
                    losamchitiet.sl(3), Colors.green[700]!),
              ),
              Expanded(
                child: _buildAgeGroupItem(Icons.forest, '9-10(N)',
                    losamchitiet.sl(4), Colors.green[800]!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupItem(
      IconData icon, String label, int? count, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        // borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: MediaQuery.of(context).size.width * 0.03, color: color),
          SizedBox(width: MediaQuery.of(context).size.width * 0.01),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.025),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.006,
                vertical: MediaQuery.of(context).size.width * 0.002),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString() ?? "0",
              style:
                  TextStyle(fontSize: MediaQuery.of(context).size.width * 0.02),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
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
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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

  Widget _buildFarmLevel() {
    return Column(
      children: [
        const Text(
          'Quản lý Trang trại',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          //{plantStats.totalPlants}
          'Quản lý ${farmsWithPlantsData?.length} trang trại với tổng cộng  cây sâm',
          style: TextStyle(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: farmsWithPlantsData?.length,
            itemBuilder: (context, index) {
              final farm = farmsWithPlantsData?[index];
              return _buildFarmCard(farm);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFarmCard(VuonTrongModel? farm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              selectedFarm = farm;
              currentLevel = NavigationLevel.zone;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm?.tenVuon ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        farm?.viTri ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        farm?.ghiChu ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 8,
                    //     vertical: 4,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blue[100],
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Text(
                    //     '${farm.investorPlantCount} cây',
                    //     style: TextStyle(
                    //       fontSize: 10,
                    //       fontWeight: FontWeight.w500,
                    //       color: Colors.blue[700],
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneLevel() {
    if (selectedFarm == null) return const SizedBox();

    final api = API();

    return FutureBuilder<List<LoSamModel>?>(
      future: api.listLoSam(
        status: "1",
        rowCount: 10,
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

        if (zonesWithPlantsData.isEmpty) {
          return const Center(child: Text("Không có dữ liệu"));
        }

        // 👉 render dữ liệu zone
        return Column(
          children: [
            const Text(
              'Quản lý Vùng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Vùng trong ${selectedFarm!.tenVuon}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddLoSamDialog(),
                  icon: const Icon(Icons.forest, size: 16),
                  label: const Text('Thêm lô sâm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              selectedZone = zone;
              _futureLoSam = API().getLoSamById(selectedZone!.loSamId);
              if (selectedZone != null) {
                setState(() {
                  gridRows = List.generate(selectedZone!.soHang, (i) => i + 1);
                });
              }
              currentLevel = NavigationLevel.grid;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.map,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.tenLo ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Mã Lô: ${zone.maLo}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        "Loại: ${zone.loai}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        zone.ghiChu ?? "",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 8,
                    //     vertical: 4,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: Colors.blue[100],
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Text(
                    //     '${zone.investorPlantCount} cây',
                    //     style: TextStyle(
                    //       fontSize: 10,
                    //       fontWeight: FontWeight.w500,
                    //       color: Colors.blue[700],
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridLevel() {
    if (_futureLoSam == null) return const SizedBox();

    return FutureBuilder<LoSamModel?>(
      future: _futureLoSam,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}"));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text("Không có dữ liệu"));
        }

        final listcaysam = snapshot.data!;
        final areaPlants = listcaysam.caySams ?? [];
        losamchitiet = listcaysam.loSamChiTiets;

        final allPlantPositions = areaPlants
            .map((plant) => plant.viTriTrongLo)
            .whereType<String>()
            .toSet();

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildAgeGroupStats(),
              const SizedBox(height: 16),
              Text(
                "Tên lô: ${listcaysam.tenLo ?? 'Chưa có'}",
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildLegend(listcaysam),
              const SizedBox(height: 16),
              if (isMultiSelectMode) ...[
                _buildMultiSelectControls(areaPlants),
                const SizedBox(height: 16),
              ],
              _buildPlantGrid(areaPlants, allPlantPositions),
            ],
          ),
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

    return AnimatedBuilder(
      animation: _multiSelectAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_multiSelectAnimation.value * 0.02),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.indigo[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
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
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Icon(Icons.touch_app,
                                  color: Colors.blue[800], size: 20),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nhật ký',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Text(
                        '✅ $selectedCount đã chọn',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // ElevatedButton.icon(
                    //   onPressed: () => _selectAllEmptyCells(areaPlants),
                    //   icon: const Icon(Icons.select_all, size: 16),
                    //   label: const Text('Chọn tất cả ô trống'),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: Colors.white,
                    //     foregroundColor: Colors.blue[600],
                    //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    //     textStyle: const TextStyle(fontSize: 12),
                    //     side: BorderSide(color: Colors.blue[300]!),
                    //   ),
                    // ),
                    DropdownButton<OptionModel>(
                      value: _selectedtuoicay,
                      hint: const Text('Chọn loại tuổi cây'),
                      icon: const Icon(Icons.arrow_drop_down),
                      isExpanded: true, // cho rộng toàn bộ chiều ngang
                      items: OptionLoSamLoaiTuoi.map((opt) {
                        return DropdownMenuItem<OptionModel>(
                          value: opt,
                          child: Text(opt.text), // hiển thị text ra UI
                        );
                      }).toList(),
                      onChanged: (OptionModel? newValue) {
                        if (newValue == null) return;
                        setState(() {
                          _selectedtuoicay = newValue;
                        });

                        final strVal = newValue.value;
                        int? selectedValue = int.tryParse(strVal);

                        // Lọc danh sách areaPlants theo selectedValue
                        final filtered = areaPlants
                            .where((plant) => plant.tuoiCayId == selectedValue && plant.caySamNhatKys.isEmpty)
                            .toList();

                        // Gọi hàm của bạn với danh sách đã lọc
                        _selectAllEmptyCells(filtered);
                      },
                    ),
                    ElevatedButton.icon(
                      onPressed: _clearSelection,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Bỏ chọn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                        side: BorderSide(color: Colors.blue[300]!),
                      ),
                    ),
                    if (selectedCount > 0)
                      ElevatedButton.icon(
                        onPressed: () {
                          _handleBatchAddPlants(areaPlants);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: Text('Thêm nhật ký ($selectedCount)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                          elevation: 4,
                        ),
                      ),
                  ],
                ),

                // Selected positions preview
                if (selectedCount > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[100]!, Colors.indigo[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📍 Đã chọn $selectedCount vị trí:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$selectedPositions$moreText',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Help text with animation
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      '💡 Tap vào các ô trống (màu xám) để chọn/bỏ chọn',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Widget _buildLegend(LoSamModel? losam) {
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
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            clipBehavior: Clip.hardEdge, // để bo góc ảnh theo borderRadius
            child: Image.network(
              "https://10.0.2.2:7261/Images/lo_sam/Lo_001_L001_180925091112.png",
              fit: BoxFit.cover, // có thể đổi: contain, fill, cover
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text("Không tải được ảnh"));
              },
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
          if (/*selectedZone!.loSamCameras.isNotEmpty*/ true) ...[
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
                      losam?.tenLo ?? "",
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
            const SizedBox(height: 12),

            // Camera Status List
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
                                  color: camera.trangThai == 0
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
                            camera.trangThai == 0 ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: camera.trangThai == 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),

            const SizedBox(height: 16),
          ],

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(Colors.green, 'Khỏe mạnh'),
              _buildLegendItem(Colors.yellow[700]!, 'Yếu'),
              _buildLegendItem(Colors.orange, 'Bệnh'),
              _buildLegendItem(Colors.red, 'Chết'),
              _buildLegendItem(Colors.grey[300]!, 'Ô trống'),
              _buildLegendItem(Colors.blue[500]!, 'Có nhà đầu tư'),
              _buildLegendItemWithIcon(
                color: Colors.orange.shade500,
                icon: Icons.menu_book,
                label: 'Đã có nhật ký tháng này',
              ),
            ],
          ),
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
        children: [
          Text(
            'Bản đồ Cây trồng - ${selectedZone!.tenLo}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          // Scroll ngang toàn bộ grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Grid Rows
                  ...gridRows.map((row) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            ...gridColumns.expand((col) {
                              final position = '$col$row';
                              final plant = areaPlants?.firstWhere(
                                (p) => p.viTriTrongLo == position,
                                orElse: () => CaySamModel(
                                    loSam: '',
                                    caySamId: '',
                                    loSamId: 0,
                                    viTriTrongLo: '',
                                    tuoiCayId: 0, caySamNhatKys: []),
                              );

                              final hasPlant =
                                  plant?.caySamId.isNotEmpty ?? false;
                              final hasInvestor = plant?.loSamId != null;
                              final isSelected =
                                  plant?.caySamId == selectedPlant;
                              final isCellSelected =
                                  selectedEmptyCells.contains(position);

                              // Tuổi cây
                              // Chờ trạng thái cây
                              final age = hasPlant
                                  ? _calculatePlantAge(plant?.tuoiCayId ?? 0)
                                  : 0;
                              final ageIcon =
                                  _getPlantAgeIcon(plant?.tuoiCayId ?? 0);
                              final ageColor =
                                  _getPlantAgeIconColor(plant?.tuoiCayId ?? 0);

                              final cell = Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();

                                      // Multi-select mode
                                      if (isMultiSelectMode) {
                                        if (hasPlant) {
                                          if(plant!.caySamNhatKys.isNotEmpty){
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Cây ở vị trí ${plant.viTriTrongLo} đã có nhật ký'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }else{
                                            _handleEmptyCellToggle(position);
                                          }
                                        }
                                        return;
                                      }
                                      // Normal mode
                                      if (!isMultiSelectMode) {
                                        if (hasPlant) {
                                          final selected =
                                              areaPlants?.firstWhere(
                                            (p) =>
                                                p.caySamId == plant?.caySamId,
                                            orElse: () => CaySamModel(
                                              caySamId: '',
                                              loSamId: 0,
                                              viTriTrongLo: '',
                                              tuoiCayId: 0, caySamNhatKys: [],
                                            ),
                                          );

                                          if (selected != null &&
                                              selected.caySamId.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    PlantDetailScreen(
                                                  plant: selected,
                                                  onBack: () {
                                                    Navigator.pop(context);
                                                  },
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          _showAddPlantDialog(position);
                                        }
                                      }
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 2),
                                      decoration: BoxDecoration(
                                        color: (!hasPlant)
                                            ? Colors.grey[100]
                                            : (isMultiSelectMode
                                                ? (isCellSelected
                                                    ? Colors.green[400]
                                                    : Colors.grey[200])
                                                : Colors.green[400]),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.blue
                                              : hasPlant
                                                  ? Colors.transparent
                                                  : Colors.grey[100]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: hasPlant
                                                ? Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(ageIcon,
                                                          color: ageColor,
                                                          size: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.05),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        position,
                                                        style: TextStyle(
                                                          color: (isMultiSelectMode
                                                              ? (isCellSelected
                                                                  ? Colors.white
                                                                  : Colors.grey[
                                                                      600])
                                                              : Colors.white),
                                                          fontSize: 8,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    position,
                                                    style: TextStyle(
                                                      color: Colors.grey[400],
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                          ),
                                          if (plant?.caySamNhatKys != null && plant!.caySamNhatKys.isNotEmpty)
                                            Positioned(
                                              bottom: 2,
                                              right: 2,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade500,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 1),
                                                ),
                                                child: Icon(
                                                  Icons.menu_book,
                                                  size: 8,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          // if (hasPlant && hasInvestor)
                                          //   Positioned(
                                          //     top: 2,
                                          //     right: 2,
                                          //     child: Container(
                                          //       width: 8,
                                          //       height: 8,
                                          //       decoration: BoxDecoration(
                                          //         color: Colors.blue[500],
                                          //         shape: BoxShape.circle,
                                          //         border: Border.all(color: Colors.white, width: 1),
                                          //       ),
                                          //     ),
                                          //   ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );

                              // 👉 Nếu col == 'C' thì thêm đường đi (SizedBox)
                              if (col == 'C') {
                                return [cell, const SizedBox(width: 16)];
                              } else {
                                return [cell];
                              }
                            }),
                          ],
                        ),
                      )),
                ],
              ),
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
        tuoiCayId: 0, caySamNhatKys: [],
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
  ) async {
    try {
      // 🔹 Gọi API
      final apiResponse = await API().addCaySam(
        data: plantData,
        files: images,
      );

      if (apiResponse != null && apiResponse.message == "OK") {
        // ✅ Thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🌱 Cây mới đã được thêm vào vị trí ${plantData['gridPosition']}!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
        setState(() {
          _futureLoSam = API().getLoSamById(selectedZone!.loSamId);
        }); // refresh UI nếu cần
      } else {
        // ❌ Lỗi từ server
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể thêm cây sâm.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ❌ Lỗi mạng hoặc exception khác
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
    int zoneId = selectedZone?.loSamId ?? 1;
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
          zoneId: zoneId,
          zoneName: zoneName,
          onSubmit: _handleLoSamSubmit,
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

  void _handleLoSamSubmit(Map<String, dynamic> data, {File? image}) async {
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
          _futureLoSam = API().getLoSamById(selectedZone!.loSamId);
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

  void _handleBatchAddPlants(List<CaySamModel> areaPlants) {
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
    List<String> selectedEmptyCellsList =
    selectedEmptyCells.toSet().toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchPlantUpdateScreen( selectedPositions: selectedEmptyCellsList,caysam: areaPlants, areaId: "1", areaName: "L001",),
      ),
    );

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

class PlantStats {
  final int totalPlants;
  final int plantsWithInvestors;
  final int plantsWithoutInvestors;
  final Map<String, int> ageGroups;
  final int healthyPlants;

  PlantStats({
    required this.totalPlants,
    required this.plantsWithInvestors,
    required this.plantsWithoutInvestors,
    required this.ageGroups,
    required this.healthyPlants,
  });
}

class _AreaWithStats {
  final Area area;
  final int plantCount;
  final int plantsWithInvestors;

  _AreaWithStats({
    required this.area,
    required this.plantCount,
    required this.plantsWithInvestors,
  });
}

extension LoSamChiTietExt on List<LoSamChiTietModel>? {
  int sl(int id) =>
      this
          ?.firstWhere(
            (e) => e.id == id,
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
