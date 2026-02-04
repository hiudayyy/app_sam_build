import 'package:nftsam/screens/plant_management_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/cay_sam.dart';
import '../data/mock_data.dart';

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
          // return InvestorPlantViewScreen(
          //   plants: MockData.mockPlants,
          //   onPlantSelect: widget.onPlantSelected,
          // );
          return PlantManagementViewScreen();
        } else {
          // Giao diện quản lý thường cho các role khác
          return PlantManagementViewScreen();
        }
      },
    );
  }

}