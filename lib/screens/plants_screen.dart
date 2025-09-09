import 'package:flutter/material.dart';
import '../models/cay_sam.dart';
import '../data/mock_data.dart';
import '../widgets/plant_card.dart';
import '../widgets/protected_route.dart';
import '../models/user.dart';

class PlantsScreenNew extends StatefulWidget {
  final Function(String) onPlantSelected;

  const PlantsScreenNew({
    Key? key,
    required this.onPlantSelected,
  }) : super(key: key);

  @override
  _PlantsScreenNewState createState() => _PlantsScreenNewState();
}

class _PlantsScreenNewState extends State<PlantsScreenNew> {
  String _searchTerm = '';
  String _statusFilter = 'all';
  List<String> _selectedPlantsForDiary = [];

  List<CaySam> get _filteredPlants {
    return MockData.mockPlants.where((plant) {
      final matchesSearch = (plant.tenCay?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          plant.id.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesStatus = _statusFilter == 'all' || plant.trangThai?.name == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      requiredPermission: Permission.managePlants,
      fallback: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Bạn không có quyền truy cập Cây trồng',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Filter Section
            Column(
              children: [
                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm cây...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchTerm = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    // Grid/List toggle button (always show grid for simplicity)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.grid_view),
                        onPressed: () {
                          // Toggle between grid/list view
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Filter Row
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.grey.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        value: _statusFilter,
                        items: [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                          DropdownMenuItem(value: 'khoeMauh', child: Text('Khỏe mạnh')),
                          DropdownMenuItem(value: 'yeu', child: Text('Yếu')),
                          DropdownMenuItem(value: 'benh', child: Text('Bệnh')),
                          DropdownMenuItem(value: 'chet', child: Text('Chết')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value ?? 'all';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            // Plants Grid - Single column like React mobile layout
            Expanded(
              child: _filteredPlants.isEmpty
                  ? Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Không tìm thấy cây nào phù hợp',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredPlants.length,
                itemBuilder: (context, index) {
                  final plant = _filteredPlants[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: PlantCard(
                      plant: plant,
                      onTap: () => widget.onPlantSelected(plant.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}