import 'dart:async';
import 'dart:convert';

import 'package:nftsam/api/api_caytrong.dart';
import 'package:nftsam/api/api_dashboard.dart';
import 'package:nftsam/api/api_thongbao.dart';
import 'package:nftsam/screens/plant_management_view_screen.dart';
import 'package:nftsam/screens/plants_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api.dart';
import '../main.dart';
import '../models/vuontrong/sensor_model.dart';
import '../utils/app_dimensions.dart';
import '../models/cay_sam.dart';
import '../models/dashboard/dashboard_model.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/thongbao_model.dart';
import '../models/user.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/listcaysam.dart';
import '../widgets/listcayyeu.dart';
import '../widgets/listlosam.dart';
import '../widgets/notification_panel.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  final List<CaySam> plants;


  const DashboardScreen({
    Key? key,
    required this.plants,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  DashBoardtotal? numbertotal;
  DashBoardSucKhoe? numbertotalSucKhoe;
  late TabController _tabController;
  List<ThongBaoModel>? tb;
  List<LoSamModel>? _loSamCanhBaoList;
  bool _isLoadingCanhBao = true;
  Kttoken? user;
  StreamSubscription? _sensorSubscription;
  String? deviceName = "";
  ApiResponse<SensorDeviceModel>? apilistsensor;
  SensorDeviceModel? _selectedDevice;
  List<SensorDeviceModel>? deviceList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeData();
    _fetchLoSamCanhBao();
    _sensorSubscription = signalRService.sensorStream.listen(
            (dynamic allDeviceData_dynamic) {
          SensorDeviceModel allDeviceData;
          try {

            allDeviceData = allDeviceData_dynamic as SensorDeviceModel;
          } catch (e) {
            print("❌ Lỗi ép kiểu stream: $e");
            print("Dữ liệu nhận được không phải List<SensorDeviceModel>: $allDeviceData_dynamic");
            return; // Dừng lại nếu kiểu dữ liệu sai
          }
          // print(allDeviceData.deviceName);
          // print(allDeviceData.sensors?.first.jValue);
          // print(allDeviceData.sensors?[1].jValue);

          // print("✅ [DashboardScreen] Đã nhận được ${allDeviceData.length} cụm thiết bị.");
          if (allDeviceData != null) {
            final SensorDeviceModel firstDevice = allDeviceData;
            List<int> bytes = latin1.encode(firstDevice.deviceName ?? "");
            String correctText = utf8.decode(bytes);
            firstDevice.deviceName = correctText;
            _updateDeviceFromSignalR(firstDevice);
            if (firstDevice.deviceId == _selectedDevice?.deviceId) {
              updateEnvironmentData(_selectedDevice?.sensors);
            }
          } else {
            print("⚠️ [DashboardScreen] Danh sách thiết bị nhận được bị rỗng (empty).");
          }

        }, onError: (error) {
      print("❌ Lỗi trên sensorStream: $error");
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> environmentStatus = {
    'temperature': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 10, 'max': 30},
    'humidity': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 80, 'max': 95},
    'soilMoisture': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 100, 'max': 200},
    'dewPoint': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 15, 'max': 25},
  };
  // Map<String, Map<String, dynamic>> environmentStatus = {
  //   'temperature': {'value': 'N/A', 'status': 'tốt', 'min': 20, 'max': 30},
  //   'humidity': {'value': 'N/A', 'status': 'tốt', 'min': 50, 'max': 80},
  //   'soilMoisture': {'value': 'N/A', 'status': 'tốt', 'min': 80, 'max': 90},
  //   'dewPoint': {'value': 'N/A', 'status': 'tốt', 'min': 15, 'max': 25},
  // };

// MỚI: Hàm trợ giúp để kiểm tra giá trị và cập nhật trạng thái
// Đặt hàm này bên trong class State của bạn
  String formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "Chưa cập nhật";
    try {
      // 1. Chuyển chuỗi ISO thành đối tượng DateTime
      DateTime dateTime = DateTime.parse(isoString);

      // 2. (Tùy chọn) Chuyển sang múi giờ địa phương của điện thoại
      // Nếu server trả về giờ UTC, dòng này rất quan trọng
      dateTime = dateTime.toLocal();

      // 3. Định dạng theo ý bạn: Giờ:Phút:Giây / Ngày/Tháng/Năm
      return DateFormat('HH:mm:ss - dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return isoString; // Nếu lỗi (chuỗi không đúng định dạng), trả về nguyên gốc
    }
  }
  void _checkAndUpdateStatus({
    required Map<String, dynamic>? statusEntry,
    required double value,
    required String highStatus, // Ví dụ: 'nóng', 'ẩm', 'thừa'
    required String lowStatus,  // Ví dụ: 'lạnh', 'khô'
  }) {
    if (statusEntry == null) return;

    final double min = (statusEntry['min'] as num).toDouble();
    final double max = (statusEntry['max'] as num).toDouble();

    // Cập nhật giá trị
    statusEntry['value'] = value.toStringAsFixed(1);

    // Cập nhật trạng thái
    if (value > max) {
      statusEntry['status'] = highStatus;
    } else if (value < min) {
      statusEntry['status'] = lowStatus;
    } else {
      statusEntry['status'] = 'tốt';
    }
  }
  bool _isValidAndNotZero(String? valueString) {
    if (valueString == null) return false;
    final double? value = double.tryParse(valueString);
    return value != null && value != 0.0;
  }
  Widget _buildEnvironmentOverview() {

    // Gradient màu Cam -> Vàng cho Nhiệt độ
    final LinearGradient tempGradient = LinearGradient(
      colors: [Colors.orange[700]!, Colors.yellow[500]!],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    // Gradient màu Xanh lá -> Xanh lơ cho Điểm sương
    final LinearGradient dewPointGradient = LinearGradient(
      colors: [Colors.green[600]!, Colors.cyan[300]!],
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ----- HÀNG TRÊN (Nhiệt độ & Điểm sương) -----
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if(_isValidAndNotZero(environmentStatus['temperature']!['value']))
            Expanded(
              child: _buildTemperatureBar(
                value: double.tryParse(environmentStatus['temperature']!['value']) ?? 0.0,
                unit: '°C',
                label: 'Nhiệt độ',
                min: (environmentStatus['temperature']!['min'] as num).toDouble(),
                max: (environmentStatus['temperature']!['max'] as num).toDouble(),
                gradient: tempGradient, // <--- Truyền gradient vào
              ),
            ),
            const SizedBox(width: 20),
            if(_isValidAndNotZero(environmentStatus['dewPoint']!['value']))
            Expanded(
              child: _buildTemperatureBar(
                value: double.tryParse(environmentStatus['dewPoint']!['value']) ?? 0.0,
                unit: '°C',
                label: 'Điểm sương',
                min: (environmentStatus['dewPoint']!['min'] as num).toDouble(),
                max: (environmentStatus['dewPoint']!['max'] as num).toDouble(),
                gradient: dewPointGradient, // <--- Truyền gradient vào
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        if(_isValidAndNotZero(environmentStatus['humidity']!['value']))
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildCircularProgress(
                value: double.tryParse(environmentStatus['humidity']!['value']) ?? 0.0,
                label: 'Độ ẩm không khí',
                unit: '%',
                color: Colors.green, // Giữ nguyên màu xanh
                maxValue: 100,
              ),
            ),
            const SizedBox(width: 20),
            if(_isValidAndNotZero(environmentStatus['soilMoisture']!['value']))
            Expanded(
              child: _buildCircularProgress(
                value: double.tryParse(environmentStatus['soilMoisture']!['value']) ?? 0.0,
                label: 'Độ ẩm đất',
                unit: '%',
                color: Colors.orange, // Giữ nguyên màu cam
                maxValue: 100,
              ),
            ),
          ],
        ),
      ],
    );
  }
  // (3) Hàm này sẽ được gọi bởi SignalR
  void _updateDeviceFromSignalR(SensorDeviceModel newDevice) {
    setState(() {
      deviceList = deviceList?.map((oldDevice) {
        if (oldDevice.deviceId == newDevice.deviceId) {
          return newDevice;
        } else {
          return oldDevice;
        }
      }).toList();
      if (_selectedDevice != null) {
        if(deviceList?.first != null){
          _selectedDevice = deviceList?.firstWhere(
                  (d) => d.deviceId == _selectedDevice!.deviceId,
              orElse: () => deviceList!.first // Dự phòng
          );
        }

      }
    });
  }
  void updateEnvironmentData(List<SensorModel>? sensors) {
    setState(() {
      environmentStatus = {
        'temperature': {'value': 'N/A', 'status': 'tốt', 'min': 0, 'max': 50},
        'humidity': {'value': 'N/A', 'status': 'tốt', 'min': 50, 'max': 80},
        'soilMoisture': {'value': 'N/A', 'status': 'tốt', 'min': 80, 'max': 90},
        'dewPoint': {'value': 'N/A', 'status': 'tốt', 'min': 0, 'max': 50},
      };
      if (sensors != null) {
        for (var sensor in sensors) {
          try {
            if(sensor.jValue != ""){
              final Map<String, dynamic> data = jsonDecode(sensor.jValue);
              if (data.containsKey('A1')) {
                final double rawValue = (data['A1'] as num).toDouble();
                final double percentageValue = (sensor.maxValueSS - rawValue) * 100 / (sensor.maxValueSS - sensor.minValueSS);

                // MỚI: Dùng hàm trợ giúp
                _checkAndUpdateStatus(
                  statusEntry: environmentStatus['soilMoisture'],
                  value: percentageValue,
                  highStatus: 'thừa ẩm',
                  lowStatus: 'khô',
                );
              }

              if (data.containsKey('Temperature')) {
                final double temp = (data['Temperature'] as num).toDouble();
                _checkAndUpdateStatus(
                  statusEntry: environmentStatus['temperature'],
                  value: temp,
                  highStatus: 'nóng',
                  lowStatus: 'lạnh',
                );
              }
              if (data.containsKey('Humidity')) {
                final double humidity = (data['Humidity'] as num).toDouble();
                _checkAndUpdateStatus(
                  statusEntry: environmentStatus['humidity'],
                  value: humidity,
                  highStatus: 'ẩm',
                  lowStatus: 'khô',
                );
              }

              if (data.containsKey('DewPoint')) {
                final double dewPoint = (data['DewPoint'] as num).toDouble();

                // MỚI: Dùng hàm trợ giúp
                _checkAndUpdateStatus(
                  statusEntry: environmentStatus['dewPoint'],
                  value: dewPoint,
                  highStatus: 'cao', // Cân nhắc đổi tên 'cao', 'thấp'
                  lowStatus: 'thấp',
                );
              }
            }

          } catch (e) {
            print('Lỗi phân tích JSON cho sensor ${sensor.sensorCode}: $e');
          }
        }
      }
    }); // MỚI: Kết thúc lệnh setState
  }
  Future<void> _initializeData() async {
    final api = API();
    final apifarm = await api.getDashBoardSam();
    apilistsensor = await api.getDashBoardSensor();
    if(apilistsensor!.items?.first.sensors !=null){
      deviceList = apilistsensor?.items;
      _selectedDevice = apilistsensor!.items?.first;
      updateEnvironmentData(apilistsensor?.items?.first.sensors);
    }
    final apisuckhoe = await api.getDashBoardSucKhoe();
    final thongbao = await API().listThongBao( status: 'TatCa',);
    if(thongbao?.message == "OK"){
      tb = thongbao?.items;
    }
    if (!mounted) return;
    if (apifarm?.oneItem != null) {
      setState(() {
        numbertotal = apifarm?.oneItem;
      });
    }
    if (apisuckhoe?.oneItem != null) {
      setState(() {
        numbertotalSucKhoe = apisuckhoe?.oneItem;
      });
    }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
  }
  Future<void> _fetchLoSamCanhBao() async {
    if (!mounted) return;
    setState(() => _isLoadingCanhBao = true);
    try {
      final result = await API().listLoSamCanhBao(top: 5);
      if (mounted) {
        setState(() {
          _loSamCanhBaoList = result;
          _isLoadingCanhBao = false;
        });
      }
    } catch (e) {
      print("Lỗi khi tải LoSamCanhBao: $e");
      if (mounted) {
        setState(() => _isLoadingCanhBao = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            // Tab Navigation
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, size: 16),
                        SizedBox(width: 8),
                        Text('Tổng quan'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(Icons.notifications, size: 16),
                            if (tb != null && tb!.any((item) => !item.seen))
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8),
                        Text('Thông báo'),
                      ],
                    ),
                  ),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Theme.of(context).primaryColor,
                indicatorWeight: 3,
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Overview Tab
                  _buildOverviewTab(),

                  // Notifications Tab
                  NotificationPanel(),
                ],
              ),
            ),
          ],
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
        VoidCallback? onTap,
      }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.fontSizeExtraSmall),
          onTap: onTap,
          child: Padding(
            padding:  EdgeInsets.all(AppDimensions.fontSizeExtraSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Icon(icon, color: color,size: AppDimensions.fontSizeLarge,),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: AppDimensions.responsiveWidth(context, AppDimensions.fontSizeLarge),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppDimensions.responsiveWidth(context, AppDimensions.fontSizeSmall),
                        color: Colors.grey.shade700,
                      ),
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

  Widget _buildOverviewTab() {
    final healthPercentage = numbertotalSucKhoe?.HealthPercentage ?? 0;
    final healthColor = healthPercentage >= 80
        ? Colors.green
        : healthPercentage >= 60
        ? Colors.orange
        : Colors.red;

    return Scaffold( // Thêm Scaffold để có thể đổi màu nền
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ thống kê 2x2
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 25,
              mainAxisSpacing: 25,
              childAspectRatio: 1.3, // Điều chỉnh tỷ lệ cho bố cục dọc
              children: [
                if(user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin") ?? false)
                  _buildStatCard( // Widget is only added if the condition is true
                    context,
                    icon: Icons.business_rounded,
                    title: 'Tổng số vườn',
                    value: numbertotal?.totalVuonTrong.toString() ?? "0",
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeScreen(tabcurrent: 2)));
                    },
                  ),

                if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin") ?? false)
                _buildStatCard(
                  context,
                  icon: Icons.map_rounded,
                  title: 'Tổng số lô',
                  value: numbertotal?.totalLoSam.toString() ?? "0",
                  color: Colors.green.shade700,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachLoSamPage()));
                  },
                ),
                _buildStatCard(
                  context,
                  icon: Icons.eco_rounded,
                  title: 'Tổng số cây',
                  value: numbertotal?.totalCaySam.toString() ?? "0",
                  color: Colors.teal.shade600,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachCaySamPage()));
                  },
                ),
                _buildStatCard(
                  context,
                  icon: Icons.sentiment_dissatisfied_rounded,
                  title: 'Cây yếu',
                  value: numbertotal?.totalSuckhoeYeu.toString() ?? "0",
                  color: Colors.orange.shade800,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachCayYeuPage()));
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.favorite_border_rounded, size: 22),
                        SizedBox(width: 8),
                        Text('Tổng quan sức khỏe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Tình trạng tổng thể', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                        const Spacer(),
                        Text('${(5 * (healthPercentage.round()/100)).toStringAsFixed(2)}/5', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: healthColor)), // Có thể đổi chữ "Khỏe mạnh" thành "Tốt"
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: healthPercentage / 100,
                        backgroundColor: healthColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                        minHeight: 10,
                      ),
                    ),
                    const Divider(height: 32),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                      children: [
                        _buildHealthStatItem('Rất tốt', numbertotalSucKhoe?.totalRatTot ?? 0, Colors.green.shade600, Icons.sentiment_very_satisfied_rounded), // Điểm 5
                        _buildHealthStatItem('Khá tốt', numbertotalSucKhoe?.totalKhaTot ?? 0 , Colors.teal.shade500, Icons.sentiment_satisfied_rounded), // Điểm 4
                        _buildHealthStatItem('Trung bình', numbertotalSucKhoe?.totalTrungBinh ?? 0, Colors.orange.shade600, Icons.sentiment_neutral_rounded), // Điểm 3
                        _buildHealthStatItem('Yếu', numbertotalSucKhoe?.totalYeu ?? 0, Colors.deepOrange.shade500, Icons.sentiment_dissatisfied_rounded), // Điểm 2
                        _buildHealthStatItem('Rất yếu', numbertotalSucKhoe?.totalRatYeu ?? 0, Colors.red.shade700, Icons.sentiment_very_dissatisfied_rounded), // Điểm 1
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if(_isValidAndNotZero(environmentStatus['soilMoisture']!['value']) ||
          _isValidAndNotZero(environmentStatus['dewPoint']!['value']) ||
          _isValidAndNotZero(environmentStatus['humidity']!['value']) ||
        _isValidAndNotZero(environmentStatus['temperature']!['value']))
            Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sensors,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                            'Tình trạng môi trường',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                      ],
                    ),
                    if((apilistsensor?.items?.length ?? 0) > 1)
                    Padding(
                      padding: const EdgeInsets.only(top:8.0,bottom: 8),
                      child: DropdownButtonFormField<SensorDeviceModel>(
                        value: _selectedDevice,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 12.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                          ),
                          // Bỏ màu nền (hoặc đặt màu trong suốt)
                          filled: false,
                        ),

                        // (5) Các thuộc tính còn lại
                        isExpanded: true,
                        hint: const Text("Chọn thiết bị..."),
                        icon: const Icon(Icons.expand_more_rounded, size: 24),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        onChanged: (SensorDeviceModel? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedDevice = newValue;
                            });
                            updateEnvironmentData(newValue.sensors);
                          }
                        },
                        items: deviceList?.map((SensorDeviceModel device) {
                          return DropdownMenuItem<SensorDeviceModel>(
                            value: device,
                            child: Text(
                              device.deviceName ?? "",
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Text('Dữ liệu từ cảm biến thời gian thực', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const Divider(height: 24),
                    Padding(
                      padding: const EdgeInsets.only(left:8),
                      child: Text(_selectedDevice?.deviceName ?? "",

                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildEnvironmentOverview(),
                    Padding(
                      padding: const EdgeInsets.only(left: 8,top:15),
                      child: Row(
                        children: [
                          Spacer(),
                          Text(

                            formatDateTime(_selectedDevice?.updateTime),

                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) => pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin") ?? false)
            Card(
              elevation: 3,
              shadowColor: Colors.black.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (giữ nguyên)
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 22, color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        const Text(
                          'Cảnh báo cần xử lý', // Có thể đổi tiêu đề nếu muốn
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _isLoadingCanhBao
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
                        : (_loSamCanhBaoList == null || _loSamCanhBaoList!.isEmpty)
                        ? SizedBox()
                        : Column(
                      children: _loSamCanhBaoList!.map((loSam) {
                        return _buildAlertItem(
                          icon: Icons.eco_outlined,
                          iconColor: Colors.orange.shade600,
                          title: 'Lô: ${loSam.tenLo ?? loSam.maLo}',
                          subtitle: loSam.soLuongCaySams > 0 ? '${loSam.soLuongCaySams} cây cần cập nhật nhật ký' : '',
                          caySams: loSam.caySams,
                          idzone:loSam.loSamId,
                        );
                      }).toList(),
                    ),

                    // _buildAlertItem(
                    //   icon: Icons.water_drop_outlined,
                    //   iconColor: Colors.blue.shade600,
                    //   title: 'Độ ẩm đất vùng B thấp',
                    //   subtitle: 'Cần tưới nước - 1 giờ trước',
                    // ),
                    // _buildAlertItem(
                    //   icon: Icons.shield_outlined,
                    //   iconColor: Colors.green.shade600,
                    //   title: 'Xác thực chất lượng hoàn thành',
                    //   subtitle: '5 cây đạt chuẩn xuất khẩu - 30 phút trước',
                    //   isLastItem: true, // Item cuối cùng
                    // ),
// ...
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildHealthStatItem(String title, int count, Color color, IconData icon) {
    return Container(
      // ✨ GIẢM PADDING DỌC
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5), // Giảm padding dọc từ 12 xuống 10
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: AppDimensions.responsiveWidth(context, AppDimensions.fontSizeExtraLarge)), // Giữ nguyên icon
          SizedBox(height:AppDimensions.responsiveHeight(context, AppDimensions.sp2), ), // Giảm từ 8 xuống 6
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: AppDimensions.responsiveWidth(context, AppDimensions.fontSizeSmall),
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1, // Đảm bảo số không xuống dòng
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2), // Giảm từ 4 xuống 2
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimensions.responsiveWidth(context, AppDimensions.fontSizeExtraSmall),
              color: Colors.grey.shade700,
            ),
            maxLines: 1, // Đảm bảo tiêu đề không xuống dòng
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  Widget _buildTemperatureBar({
    required double value,
    required String unit,
    required String label,
    required double min,
    required double max,
    required LinearGradient gradient,
  }) {
    const double barHeight = 91.0;
    const double barWidth = 19.0;
    const double circleDiameter = 32.0;

    double normalizedValue = (value - min) / (max - min);
    normalizedValue = normalizedValue.clamp(0.0, 1.0);
    if (normalizedValue.isNaN) normalizedValue = 0.0;

    final double targetHeight = barHeight * normalizedValue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: barWidth,
          height: barHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: gradient.colors.last.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: targetHeight),
                duration: const Duration(milliseconds: 400),
                builder: (BuildContext context, double animatedHeight, Widget? child) {
                  return Container(
                    width: barWidth,
                    height: animatedHeight, // Chiều cao mượt mà
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        Container(
          width: circleDiameter,
          height: circleDiameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gradient.colors.first,
          ),
          child: Center(
            child: Text(
              value.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$label ${value.toStringAsFixed(1)}$unit',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress({
    required double value,
    required String label,
    required String unit,
    required Color color,
    double maxValue = 100.0,
  }) {
    // 'progress' là giá trị mục tiêu (target) (ví dụ: 0.695)
    double progress = value / maxValue;
    if (progress.isNaN || progress.isInfinite) progress = 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 400), // 0.4 giây
            builder: (BuildContext context, double animatedValue, Widget? child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: animatedValue,
                      strokeWidth: 12,

                      // ----- THÊM DÒNG NÀY -----
                      strokeCap: StrokeCap.round, // <-- Làm cho đầu thanh bo tròn
                      // -------------------------

                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  child!,
                ],
              );
            },
            child: Text(
              '${value.toStringAsFixed(0)}$unit', // Hiển thị số nguyên (e.g., 70%)
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '$label\n${value.toStringAsFixed(1)}$unit',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    List<CaySamModel>? caySams,
    bool isLastItem = false,
    int? idzone,
  }) {
    Color cardBackgroundColor = Colors.white;
    if (iconColor == Colors.orange.shade600 || iconColor == Colors.red.shade600 || iconColor == Colors.orange.shade700) {
      cardBackgroundColor = iconColor.withOpacity(0.08);
    } else if (iconColor == Colors.green.shade600) {
      cardBackgroundColor = Colors.green.shade50.withOpacity(0.5);
    }
    String plantPositionsInfo = '';
    if (caySams != null && caySams.isNotEmpty) {
      var positionsList = caySams
          .map((cs) => cs.viTriTrongLo)
          .whereType<String>()
          .take(4)
          .toList();
      String positionsToShow = positionsList.join(', ');
      int maxLength = 30; // 👈
      if (positionsToShow.length > maxLength) {
        positionsToShow = '${positionsToShow.substring(0, maxLength)}...';
      }
      final moreCount = caySams.length > positionsList.length ? ' +${caySams.length - positionsList.length}' : '';
      plantPositionsInfo = subtitle != '' ? '\nCây $positionsToShow$moreCount chưa cập nhật ký trong nhiều tháng' : 'Cây $positionsToShow$moreCount chưa cập nhật ký trong nhiều tháng';
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: isLastItem ? 0 : 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.05),
      color: cardBackgroundColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          LoSamModel? losamitem;
          if(idzone != null){
            showLoadingDialog(context, message: 'Đang tải dữ liệu lô...');
            try {
              losamitem = await API().getLoSamById(idzone);
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    tabcurrent: 2,
                    shouldShowDialog: true,
                    zone: losamitem, // Truyền dữ liệu đã lấy được
                  ),
                ),
              );

            } catch (e) {
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi tải dữ liệu lô: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              print("Lỗi khi gọi getLoSamById: $e");
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 45,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withOpacity(0.15),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subtitle$plantPositionsInfo',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      maxLines: plantPositionsInfo.isNotEmpty ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
