import 'package:csam_mobile/screens/plant_management_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/cay_sam.dart';
import '../data/mock_data.dart';
import 'investor_plant_view_screen.dart';

class PlantsScreenNew extends StatefulWidget {
  final Function(String) onPlantSelected;

  const PlantsScreenNew({
    Key? key,
    required this.onPlantSelected,
  }) : super(key: key);

  @override
  State<PlantsScreenNew> createState() => _PlantsScreenNewState();
}

class _PlantsScreenNewState extends State<PlantsScreenNew> {
  String _searchTerm = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        // Logic kiểm tra role investor giống như trong React
        if (user?.htPhanQuyenTaiKhoans.any((r) => r.maVaiTro == "nft_invester") == true){
          return InvestorPlantViewScreen(
            plants: MockData.mockPlants,
            onPlantSelect: widget.onPlantSelected,
          );
        } else {
          // Giao diện quản lý thường cho các role khác
          return PlantManagementViewScreen(
            // plants: MockData.mockPlants,
            onPlantSelect: widget.onPlantSelected,
          );
        }
      },
    );
  }

  Widget _buildStandardPlantManagement() {
    final filteredPlants = _getFilteredPlants();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilter(),

          const SizedBox(height: 16),

          // Plants List
          Expanded(
            child: filteredPlants.isEmpty
                ? _buildEmptyState()
                : _buildPlantsList(filteredPlants),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        // Search Bar
        TextField(
          onChanged: (value) {
            setState(() {
              _searchTerm = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Tìm kiếm cây...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),

        const SizedBox(height: 12),

        // Status Filter
        Row(
          children: [
            const Icon(Icons.filter_list, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: _statusFilter,
                onChanged: (value) {
                  setState(() {
                    _statusFilter = value ?? 'all';
                  });
                },
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                  DropdownMenuItem(value: 'khoeManh', child: Text('Khỏe mạnh')),
                  DropdownMenuItem(value: 'yeu', child: Text('Yếu')),
                  DropdownMenuItem(value: 'benh', child: Text('Bệnh')),
                  DropdownMenuItem(value: 'chet', child: Text('Chết')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlantsList(List<CaySam> plants) {
    return ListView.builder(
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return _buildPlantCard(plant);
      },
    );
  }

  Widget _buildPlantCard(CaySam plant) {
    Color statusColor = (plant.trangThai ?? TrangThaiCay.chet).color;
    IconData statusIcon = (plant.trangThai ?? TrangThaiCay.chet).icon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onPlantSelected(plant.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.tenCay ?? 'Tên cây không có',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'ID: ${plant.id}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(plant.trangThai!),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (plant.viTri != null) ...[
                Text(
                  'Vị trí: ${plant.viTri}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              if (plant.ngayTrong != null) ...[
                Text(
                  'Ngày trồng: ${plant.ngayTrong}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy cây nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  List<CaySam> _getFilteredPlants() {
    return MockData.mockPlants.where((plant) {
      final matchesSearch = plant.tenCay?.toLowerCase().contains(_searchTerm.toLowerCase()) == true ||
          plant.id.toLowerCase().contains(_searchTerm.toLowerCase());
      final matchesStatus = _statusFilter == 'all' ||
          plant.trangThai?.name == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Color _getStatusColor(TrangThaiCay status) {
    return status.color;
  }

  IconData _getStatusIcon(TrangThaiCay status) {
    return status.icon;
  }

  String _getStatusText(TrangThaiCay status) {
    return status.displayName;
  }
}