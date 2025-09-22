import 'package:csam_mobile/api/api_caytrong.dart';
import 'package:csam_mobile/models/vuontrong/losamcamera_model.dart';
import 'package:csam_mobile/screens/plant_detail_screen.dart';
import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/camera.dart';
import '../models/cay_sam.dart';
import '../models/farm_hierarchy.dart';
import '../data/mock_data.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamchitiet_model.dart';
import '../models/vuontrong/vuontrong_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/camera.dart';

class PlantManagementViewScreen extends StatefulWidget {
  // final List<CaySam> plants;
  final Function(String) onPlantSelect;

  const PlantManagementViewScreen({
    Key? key,
    // required this.plants,
    required this.onPlantSelect,
  }) : super(key: key);

  @override
  State<PlantManagementViewScreen> createState() => _PlantManagementViewScreenState();
}

class _PlantManagementViewScreenState extends State<PlantManagementViewScreen> {
  NavigationLevel currentLevel = NavigationLevel.farm;
  VuonTrongModel? selectedFarm;
  LoSamModel? selectedZone;
  // Area? selectedArea;
  String? selectedPlant;

  final List<String> gridColumns = ['A', 'B', 'C', 'D', 'E', 'F'];
  List<int> gridRows = [];
  List<LoSamChiTietModel>? losamchitiet =[];

  // late PlantStats plantStats;
  List<VuonTrongModel>? farmsWithPlantsData = [];

  @override
  void initState() {
    super.initState();
    _initializeData();

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
    final apifarm = await api.listVuonTrong( status: 1,take: 10,skip: 0);
    if(apifarm !=null){
      setState(() {
        farmsWithPlantsData = apifarm;
      });
    }
  }

  PlantStats _calculatePlantStats(List<CaySamModel> plants) {
    final totalPlants = plants.length;
    final plantsWithInvestors = plants.where((plant) => plant.loSamId != null).length;
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
    final healthyPlants =1/*plants.where((p) => p.trangThai == TrangThaiCay.khoeMauh).length*/ ;
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
    if (age == 1) return Colors.green[400]!;
    if (age == 2) return Colors.green[600]!;
    if (age == 3) return Colors.green[700]!;
    if (age == 4) return Colors.green[800]!;
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
                      ],
                    ),
                  ),
                ),
              ],
            )
        ),

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
                child: _buildAgeGroupItem(FontAwesomeIcons.seedling, '1-3(N)', losamchitiet.sl(1), Colors.green[400]!),
              ),
              Expanded(
                child: _buildAgeGroupItem(FontAwesomeIcons.leaf, '4-6(N)', losamchitiet.sl(2), Colors.green[600]!),
              ),
              Expanded(
                child: _buildAgeGroupItem(Icons.park, '7-8(N)', losamchitiet.sl(3), Colors.green[700]!),
              ),
              Expanded(
                child: _buildAgeGroupItem(Icons.forest, '9-10(N)', losamchitiet.sl(4), Colors.green[800]!),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupItem(IconData icon, String label, int? count, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        // borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString() ?? "0",
              style: const TextStyle(fontSize: 10),
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
        searchBy: [
          "VuonTrong_ID equals '${selectedFarm?.vuonTrongId ?? 0}'"
        ],
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
            Text(
              ' vùng trong ${selectedFarm!.tenVuon}',
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
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
    final api = API();
    if (selectedZone == null) return const SizedBox();
    return FutureBuilder<LoSamModel?>(
      future: api.getLoSamById(selectedZone!.loSamId), // lấy theo id của zone
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

        final listcaysam = snapshot.data;

        losamchitiet = listcaysam?.loSamChiTiets;

        final areaPlants = listcaysam?.caySams ?? [];

        final allPlantPositions = areaPlants
            .map((plant) => plant.viTriTrongLo)
            .whereType<String>() // loại bỏ null
            .toSet();

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildAgeGroupStats(),
              const SizedBox(height: 16),
              Text("Tên lô: ${listcaysam?.tenLo ?? 'Chưa có'}",style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16),),
              const SizedBox(height: 16),
              _buildLegend(listcaysam),
              const SizedBox(height: 16),
              _buildPlantGrid(areaPlants, allPlantPositions),
              const SizedBox(height: 16),
              if (selectedPlant != null) ...[
                _buildSelectedPlantDetails(areaPlants),
              ],
            ],
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (/*selectedZone!.loSamCameras.isNotEmpty*/true) ...[
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
                      losam?.tenLo?? "",
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
                      minimumSize: const Size(0, 0), // 👈 bỏ giới hạn min mặc định
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 👈 giảm vùng chạm
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Camera Status List
            ...?losam?.loSamCameras?.take(3).map((camera) => Container(
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
                          color: camera.trangThai == 0 ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(camera.loSamLoaiCamera?.ten ?? "", style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Text(
                    camera.trangThai == 0 ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: camera.trangThai == 0 ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            )).toList(),

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

  Widget _buildPlantGrid(List<CaySamModel>? areaPlants, Set<String?> allPlantPositions) {
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
                            orElse: () => CaySamModel(loSam: '', caySamId: '', loSamId: 0, viTriTrongLo: '', tuoiCayId: 0),
                          );

                          final hasPlant = plant?.caySamId.isNotEmpty ?? false;
                          final hasInvestor = plant?.loSamId != null;
                          final isSelected = plant?.caySamId == selectedPlant;

                          // Tuổi cây
                          // Chờ trạng thái cây
                          final age = hasPlant ? _calculatePlantAge(plant?.tuoiCayId ?? 0 ) : 0;
                          final ageIcon = _getPlantAgeIcon(plant?.tuoiCayId ?? 0);
                          final ageColor = _getPlantAgeIconColor(plant?.tuoiCayId ?? 0);

                          final cell = Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: GestureDetector(
                                onTap: hasPlant
                                    ? () {
                                  final selected = areaPlants?.firstWhere(
                                        (p) => p.caySamId == plant?.caySamId,
                                    orElse: () => CaySamModel(
                                      caySamId: '',
                                      loSamId: 0,
                                      viTriTrongLo: '',
                                      tuoiCayId: 0,
                                    ),
                                  );

                                  if (selected != null && selected.caySamId.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlantDetailScreen(
                                          plant: selected,
                                          onBack: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                    );
                                  }
                                }
                                    : null,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: hasPlant
                                      ? Colors.green
                                      : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : hasPlant
                                          ? Colors.transparent
                                          : Colors.grey[400]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: hasPlant
                                            ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(ageIcon, color: ageColor, size: MediaQuery.of(context).size.width * 0.05),
                                            const SizedBox(height: 2),
                                            Text(
                                              position,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                            : Text(
                                          position,
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 8,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      if (hasPlant && hasInvestor)
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.blue[500],
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1),
                                            ),
                                          ),
                                        ),
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
        tuoiCayId: 0,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      this?.firstWhere(
            (e) => e.id == id,
        orElse: () => LoSamChiTietModel(
          id: 0,
          loSamId: 0,
          loSamLoaiTuoiId: 0,
          soLuong: 0,
          trangThai: 0,
        ),
      ).soLuong ?? 0;
}
