import 'package:csam_mobile/api/api_dashboard.dart';
import 'package:csam_mobile/screens/plant_management_view_screen.dart';
import 'package:csam_mobile/screens/plants_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/dashboard/dashboard_model.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/listcaysam.dart';
import '../widgets/listcayyeu.dart';
import '../widgets/listlosam.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  // final List<CaySam> plants;
  final List<CaySam> plants;

  const DashboardScreen({
    Key? key,
    // required this.plants,
    required this.plants
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
  with TickerProviderStateMixin {
  DashBoardtotal? numbertotal ;
  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  Future<void> _initializeData() async {
    // Calculate plant statistics

    final api = API();
    final apifarm = await api.getDashBoardSam();
    if (!mounted) return;
    if(apifarm?.oneItem != null){
      setState(() {
        numbertotal = apifarm?.oneItem;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final totalPlants = widget.plants.length;
    final healthyPlants = widget.plants.where((p) => p.trangThai == TrangThaiCay.khoeMauh).length;
    final weakPlants = widget.plants.where((p) => p.trangThai == TrangThaiCay.yeu).length;
    final sickPlants = widget.plants.where((p) => p.trangThai == TrangThaiCay.benh).length;
    final deadPlants = widget.plants.where((p) => p.trangThai == TrangThaiCay.chet).length;

    final healthPercentage = totalPlants > 0 ? (healthyPlants / totalPlants) * 100 : 0.0;

    // Mock environment status to match React
    final environmentStatus = {
      'temperature': {'value': 22, 'status': 'good', 'min': 20, 'max': 24},
      'humidity': {'value': 75, 'status': 'good', 'min': 70, 'max': 80},
      'soilMoisture': {'value': 68, 'status': 'warning', 'min': 60, 'max': 75},
    };

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Stats - 2x2 grid như React
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.business,
                    title: 'Tổng số vườn',
                    value: numbertotal?.totalVuonTrong.toString() ?? "",
                    color: Colors.green,
                    backgroundColor: Colors.green.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeScreen(tabcurrent: 2,),
                        ),
                      );
                    },
                  ),
                  _buildStatCard(
                    context,
                    icon: Icons.map,
                    title: 'Tổng số lô',
                    value: numbertotal?.totalLoSam.toString() ?? "",
                    color: Colors.green.shade600,
                    backgroundColor: Colors.green.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DanhSachLoSamPage(),
                        ),
                      );
                    },
                  ),
                  _buildStatCard(
                    context,
                    icon: Icons.eco,
                    title: 'Tổng số cây',
                    value: numbertotal?.totalCaySam.toString() ?? "",
                    color: Colors.green,
                    backgroundColor: Colors.green.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DanhSachCaySamPage(),
                        ),
                      );
                    },
                  ),
                  _buildStatCard(
                    context,
                    icon: Icons.warning,
                    title: 'Cây yếu',
                    value: numbertotal?.totalSuckhoeYeu.toString() ?? "",
                    color: Colors.yellow.shade700,
                    backgroundColor: Colors.yellow.shade100,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DanhSachCayYeuPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Health Overview - Match React design
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng quan sức khỏe vườn sâm',
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 16),

                      // Progress bar với percentage
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tình trạng tổng thể',
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                              ),
                              Text(
                                '${healthPercentage.round()}%',
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.035),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: healthPercentage / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              healthPercentage >= 80 ? Colors.green :
                              healthPercentage >= 60 ? Colors.orange : Colors.red,
                            ),
                            minHeight: 8,
                          ),
                        ],
                      ),

                      SizedBox(height: MediaQuery.of(context).size.width * 0.035),

                      // Detailed breakdown grid - match React
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: MediaQuery.of(context).size.width * 0.03,
                        mainAxisSpacing: MediaQuery.of(context).size.width * 0.03,
                        childAspectRatio: MediaQuery.of(context).size.width * 0.0055,
                        children: [
                          _buildHealthIndicator(context,'Khỏe mạnh', healthyPlants, Colors.green),
                          _buildHealthIndicator(context,'Yếu', weakPlants, Colors.yellow.shade600),
                          _buildHealthIndicator(context,'Bệnh', sickPlants, Colors.orange),
                          _buildHealthIndicator(context,'Chết', deadPlants, Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Environmental Status - Match React
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tình trạng môi trường',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Dữ liệu từ cảm biến thời gian thực',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                      SizedBox(height: 16),

                      Column(
                        children: [
                          _buildEnvironmentItem(
                            icon: Icons.thermostat,
                            iconColor: Colors.red.shade500,
                            label: 'Nhiệt độ',
                            value: '${environmentStatus['temperature']!['value']}°C',
                            status: environmentStatus['temperature']!['status'] as String,
                            range: '${environmentStatus['temperature']!['min']}-${environmentStatus['temperature']!['max']}°C',
                          ),
                          SizedBox(height: 16),
                          _buildEnvironmentItem(
                            icon: Icons.opacity,
                            iconColor: Colors.blue.shade500,
                            label: 'Độ ẩm KK',
                            value: '${environmentStatus['humidity']!['value']}%',
                            status: environmentStatus['humidity']!['status'] as String,
                            range: '${environmentStatus['humidity']!['min']}-${environmentStatus['humidity']!['max']}%',
                          ),
                          SizedBox(height: 16),
                          _buildEnvironmentItem(
                            icon: Icons.opacity,
                            iconColor: Colors.amber.shade600,
                            label: 'Độ ẩm đất',
                            value: '${environmentStatus['soilMoisture']!['value']}%',
                            status: environmentStatus['soilMoisture']!['status'] as String,
                            range: '${environmentStatus['soilMoisture']!['min']}-${environmentStatus['soilMoisture']!['max']}%',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Recent Alerts - Match React
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cảnh báo gần đây',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      Column(
                        children: [
                          _buildAlertItem(
                            icon: Icons.warning_amber,
                            iconColor: Colors.yellow.shade600,
                            backgroundColor: Colors.yellow.shade50,
                            title: 'Cây CS003 cần chú ý',
                            subtitle: 'Tình trạng sức khỏe giảm - 2 giờ trước',
                          ),
                          SizedBox(height: 12),
                          _buildAlertItem(
                            icon: Icons.opacity,
                            iconColor: Colors.blue.shade600,
                            backgroundColor: Colors.blue.shade50,
                            title: 'Độ ẩm đất vùng B thấp',
                            subtitle: 'Cần tưới nước - 1 giờ trước',
                          ),
                          SizedBox(height: 12),
                          _buildAlertItem(
                            icon: Icons.shield,
                            iconColor: Colors.green.shade600,
                            backgroundColor: Colors.green.shade50,
                            title: 'Xác thực chất lượng hoàn thành',
                            subtitle: '5 cây đạt chuẩn xuất khẩu - 30 phút trước',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildStatCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String value,
        required Color color,
        required Color backgroundColor,
        VoidCallback? onTap, // 👈 thêm callback khi nhấn
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap, // 👈 dùng khi click
      child: Card(
        elevation: 2,
        shadowColor: Colors.grey.shade300,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildStatCard(BuildContext context,{
  //
  //   required IconData icon,
  //   required String title,
  //   required String value,
  //   required Color color,
  //   required Color backgroundColor,
  // }) {
  //   return Card(
  //     child: Padding(
  //       padding: EdgeInsets.all(16),
  //       child: Row(
  //         children: [
  //           Container(
  //             padding: EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: backgroundColor,
  //               borderRadius: BorderRadius.circular(8),
  //             ),
  //             child: Icon(icon, size: 24, color: color),
  //           ),
  //           SizedBox(width: 12),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Text(
  //                   title,
  //                   style: TextStyle(
  //                     fontSize: MediaQuery.of(context).size.width * 0.03,
  //                     color: Colors.grey.shade600,
  //                   ),
  //                 ),
  //                 SizedBox(height: 4),
  //                 Text(
  //                   value,
  //                   style: TextStyle(
  //                     fontSize: MediaQuery.of(context).size.width * 0.05,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildHealthIndicator(BuildContext context, String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.03,
          height: MediaQuery.of(context).size.width * 0.03,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.01),
        Text(
          label,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.035,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.005),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'good':
        return Colors.green.shade600;
      case 'warning':
        return Colors.yellow.shade600;
      case 'critical':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'good':
        return Colors.green.shade100;
      case 'warning':
        return Colors.yellow.shade100;
      case 'critical':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildEnvironmentItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String status,
    required String range,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBackgroundColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusBadgeColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Lý tưởng: $range',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}