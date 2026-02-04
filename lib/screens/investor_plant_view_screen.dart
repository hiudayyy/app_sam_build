import 'package:flutter/material.dart';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/farm_hierarchy.dart';
import '../data/mock_data.dart';

class InvestorPlantViewScreen extends StatefulWidget {
  final List<CaySam> plants;
  final Function(String) onPlantSelect;

  const InvestorPlantViewScreen({
    Key? key,
    required this.plants,
    required this.onPlantSelect,
  }) : super(key: key);

  @override
  State<InvestorPlantViewScreen> createState() => _InvestorPlantViewScreenState();
}

class _InvestorPlantViewScreenState extends State<InvestorPlantViewScreen> {
  NavigationLevel currentLevel = NavigationLevel.farm;
  Farm? selectedFarm;
  Zone? selectedZone;
  Area? selectedArea;
  String? selectedPlant;
  final api = API();

  static const List<String> gridColumns = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const List<int> gridRows = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  @override
  Widget build(BuildContext context) {
    final investorPlants = widget.plants.where((plant) => plant.investorId == "5").toList();

    // Tính toán thống kê tổng quan
    final totalPlants = investorPlants.length;
    final healthyPlants = investorPlants.where((p) => p.trangThai == TrangThaiCay.khoeMauh).length;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    // Breadcrumb
                    if (_getBreadcrumb().isNotEmpty) ...[
                      Row(
                        children: [
                          if (currentLevel != NavigationLevel.farm)
                            IconButton(
                              onPressed: _handleNavigationBack,
                              icon: const Icon(Icons.arrow_back),
                              iconSize: 20,
                            ),
                          Icon(Icons.location_pin, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getBreadcrumb().join(' → '),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Overall Stats - Always visible
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '$totalPlants',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                Text(
                                  'Tổng số cây',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '$healthyPlants',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                                Text(
                                  'Cây khỏe mạnh',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Navigation Content
                  Expanded(
                    child: _buildCurrentLevelView(investorPlants),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        default:
          break;
      }
    });
  }

  List<String> _getBreadcrumb() {
    final items = <String>[];
    if (selectedFarm != null) items.add(selectedFarm!.name);
    if (selectedZone != null) items.add(selectedZone!.name);
    if (selectedArea != null) items.add(selectedArea!.name);
    return items;
  }

  Widget _buildCurrentLevelView(List<CaySam> investorPlants) {
    switch (currentLevel) {
      case NavigationLevel.farm:
        return _buildFarmLevel(investorPlants);
      case NavigationLevel.zone:
        return _buildZoneLevel(investorPlants);
      // case NavigationLevel.area:
      //   return _buildAreaLevel(investorPlants);
      case NavigationLevel.grid:
        return _buildGridLevel(investorPlants);
    }
  }

  Widget _buildFarmLevel(List<CaySam> investorPlants) {
      // Group plants by farms and calculate investor plant count per location

    final farmsWithInvestorData = MockData.mockFarms.map((farm) {
      final count = investorPlants.where((plant) =>
          farm.zones.any((zone) =>
              zone.areas.any((area) => area.id == plant.areaId))).length;
      return farm.copyWith(investorPlantCount: count);
    }).where((farm) => farm.investorPlantCount! > 0).toList();
    return Column(
      children: [
        Column(
          children: [
            const Text(
              'Chọn Trang trại',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có cây trồng tại ${farmsWithInvestorData.length} trang trại',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: ListView.builder(
            itemCount: farmsWithInvestorData.length,
            itemBuilder: (context, index) {
              final farm = farmsWithInvestorData[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedFarm = farm;
                      currentLevel = NavigationLevel.zone;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.business, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farm.name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    farm.location,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${farm.investorPlantCount} cây',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          farm.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoneLevel(List<CaySam> investorPlants) {
    if (selectedFarm == null) return const SizedBox.shrink();

    final zonesWithInvestorData = selectedFarm!.zones.map((zone) {
      final count = investorPlants.where((plant) =>
          zone.areas.any((area) => area.id == plant.areaId)).length;
      return zone.copyWith(investorPlantCount: count);
    }).where((zone) => zone.investorPlantCount! > 0).toList();

    return Column(
      children: [
        Column(
          children: [
            const Text(
              'Chọn Vùng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn có cây trồng tại ${zonesWithInvestorData.length} vùng trong ${selectedFarm!.name}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: ListView.builder(
            itemCount: zonesWithInvestorData.length,
            itemBuilder: (context, index) {
              final zone = zonesWithInvestorData[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedZone = zone;
                      currentLevel = NavigationLevel.grid;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.map, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zone.name,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                zone.description,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${zone.investorPlantCount} cây',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridLevel(List<CaySam> investorPlants) {
    if (selectedArea == null) return const SizedBox.shrink();

    final areaPlants = investorPlants.where((plant) => plant.areaId == selectedArea!.id).toList();
    final investorPlantPositions = areaPlants.map((plant) => plant.gridPosition).toSet();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Area Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    selectedArea!.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Center(
                      child: Text('Layout khu vực (Example Image)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kích thước ô: 40cm x 40cm | Lối đi: 50cm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats for this area
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${areaPlants.length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                        Text(
                          'Cây trong khu này',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          '${areaPlants.where((p) => p.trangThai == TrangThaiCay.khoeMauh).length}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        Text(
                          'Cây khỏe mạnh',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Legend
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chú thích',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 34,
                    runSpacing: 0,
                    children: [
                      _buildLegendItem(Colors.green.shade500, 'Cây của bạn'),
                      _buildLegendItem(Colors.yellow.shade500, 'Cây yếu'),
                      _buildLegendItem(Colors.grey.shade200, 'Ô trống', isDashed: true),
                      _buildLegendItem(Colors.grey.shade300, 'Cây khác'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Grid Layout
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Text(
                    'Bản đồ Cây trồng - ${selectedArea!.name}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Column(
                        children: [
                          // Grid Headers
                          // Row(
                          //   children: [
                          //     const SizedBox(width: 15), // Empty corner
                          //     ...gridColumns.map((col) => Expanded(
                          //       child: Center(
                          //         child: Text(
                          //           col,
                          //           style: const TextStyle(fontWeight: FontWeight.w500),
                          //         ),
                          //       ),
                          //     )),
                          //   ],
                          // ),

                          const SizedBox(height: 8),

                          // Grid Rows
                          ...gridRows.map((row) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                ...gridColumns.expand((col) {
                                  final position = '$col$row';
                                  final plant = areaPlants.where((p) => p.gridPosition == position).firstOrNull;
                                  final isOwned = investorPlantPositions.contains(position);
                                  final isEmpty = plant == null;
                                  final isSelected = plant?.id == selectedPlant;

                                  final cell = Expanded(
                                    child: AspectRatio(
                                      aspectRatio: 1,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        child: InkWell(
                                          onTap: () {
                                            if (!isEmpty) {
                                              setState(() {
                                                //selectedPlant = selectedPlant == plant.id ? null : plant?.id;
                                                widget.onPlantSelect(plant.id);
                                              });
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(4),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _getPlantStatusColor(
                                                isOwned,
                                                isEmpty,
                                                plant?.trangThai?.name,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.grey.shade400,
                                                width: isSelected ? 2 : 1,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                BoxShadow(
                                                  color: Colors.blue.shade200,
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                                  : null,
                                            ),
                                            child: Center(
                                              child: isOwned
                                                  ? Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.eco, color: Colors.white, size: 8),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    position,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              )
                                                  : isEmpty
                                                  ? Text(
                                                position,
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                                  : Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.7),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  // 👉 Nếu col == 'C' thì trả về cell + SizedBox
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
            ),
          ),

          // Selected Plant Details
          if (selectedPlant != null && selectedPlant!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSelectedPlantDetails(areaPlants),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isDashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: isDashed ? Border.all(
              color: Colors.grey.shade400,
              style: BorderStyle.solid,
            ) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getPlantStatusColor(bool isOwned, bool isEmpty, String? status) {
    if (isEmpty) return Colors.grey.shade100;
    if (!isOwned) return Colors.grey.shade300;

    switch (status) {
      case 'khoeMauh':
        return Colors.green.shade500;
      case 'yeu':
        return Colors.yellow.shade500;
      case 'benh':
        return Colors.orange.shade500;
      case 'chet':
        return Colors.red.shade500;
      default:
        return Colors.grey.shade400;
    }
  }

  String _getPlantStatusText(String? status) {
    switch (status) {
      case 'khoeMauh':
        return 'Khỏe mạnh';
      case 'yeu':
        return 'Yếu';
      case 'benh':
        return 'Bệnh';
      case 'chet':
        return 'Chết';
      default:
        return 'Chưa xác định';
    }
  }

  Widget _buildSelectedPlantDetails(List<CaySam> areaPlants) {
    final plant = areaPlants.firstWhere((p) => p.id == selectedPlant);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thông tin cây',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                ElevatedButton.icon(
                  onPressed: () => widget.onPlantSelect(plant.id),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Xem chi tiết'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vị trí',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            plant.gridPosition ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trạng thái',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPlantStatusColor(true, false, plant.trangThai?.name),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getPlantStatusText(plant.trangThai?.name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tên cây',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      plant.tenCay ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ngày trồng',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      plant.ngayTrong != null && plant.ngayTrong!.isNotEmpty
                          ? DateTime.parse(plant.ngayTrong!).toString().split(' ')[0]
                          : 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}