import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nftsam/api/api_caytrong.dart';
import 'package:nftsam/api/api_dashboard.dart';
import 'package:nftsam/api/api_thongbao.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nftsam/screens/plant_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../api/api.dart';
import '../api/api_caysam.dart';
import '../main.dart';
import '../models/vuontrong/sensor_model.dart';
import '../utils/app_dimensions.dart';
import '../models/cay_sam.dart';
import '../models/dashboard/dashboard_model.dart';
import '../models/kttoken.dart';
import '../models/response_model.dart';
import '../models/thongbao_model.dart';
import '../models/vuontrong/caysam_model.dart';
import '../models/vuontrong/losam_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/listcaysam.dart';
import '../widgets/listcayyeu.dart';
import '../widgets/listlosam.dart';
import '../widgets/notification_panel.dart';
import 'home_screen.dart';

import '/app_config.dart';

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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  DashBoardtotal? numbertotal;
  DashBoardSucKhoe? numbertotalSucKhoe;
  late TabController _tabController;
  List<ThongBaoModel>? tb;
  List<LoSamModel>? _loSamCanhBaoList;
  List<LoSamModel>? _listLoSam;
  List<CaySamModel>? _itemsCaySam = [];
  int _currentIndex = 0;

  bool _isLoadingBanner = true;
  bool _isLoadingCanhBao = true;

  Kttoken? user;
  StreamSubscription? _sensorSubscription;
  ApiResponse<SensorDeviceModel>? apilistsensor;
  SensorDeviceModel? _selectedDevice;
  List<SensorDeviceModel>? deviceList = [];
  String _searchQuery = '';
  LatLng? _center;
  late double _areaHa;
  final MapController _mapController = MapController();

  final List<LatLng> _loSamPoints = const [
    LatLng(15.112300, 108.016700),
    LatLng(15.112500, 108.017000),
    LatLng(15.112450, 108.017400),
    LatLng(15.112200, 108.017800),
    LatLng(15.111900, 108.017950),
    LatLng(15.111500, 108.017900),
    LatLng(15.111200, 108.017600),
    LatLng(15.111050, 108.017200),
    LatLng(15.111200, 108.016850),
    LatLng(15.111600, 108.016650),
  ];

  String _currentMapLayer = 'googleRoad';

  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  bool _isWeatherExpanded = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchWeather() async {
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=${_center?.latitude}&longitude=${_center?.longitude}&current=temperature_2m,wind_speed_10m,precipitation,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code&timezone=auto';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      AppConfig.printEx("Lỗi tải thời tiết: $e");
    }
  }

  double calculateAreaInHectares(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    final double lat0 = points[0].latitude;
    final double lng0 = points[0].longitude;
    const double rY = 111319.9;
    final double rX = 111319.9 * math.cos(lat0 * math.pi / 180.0);
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      double x1 = (points[i].longitude - lng0) * rX;
      double y1 = (points[i].latitude - lat0) * rY;
      double x2 = (points[j].longitude - lng0) * rX;
      double y2 = (points[j].latitude - lat0) * rY;
      area += (x1 * y2) - (x2 * y1);
    }
    double areaSqMeters = (area.abs() / 2.0);
    double ha = areaSqMeters / 10000.0;
    return double.parse(ha.toStringAsFixed(2));
  }

  String _getWeatherIcon(int code) {
    if (code >= 95) return "⛈";
    if (code >= 61) return "🌧";
    if (code >= 1) return "⛅";
    return "☀";
  }

  Widget _buildForecastCard(dynamic daily, int index) {
    DateTime dateObj = DateTime.parse(daily['time'][index]);
    String dayStr =
        "${dateObj.day.toString().padLeft(2, '0')}/${dateObj.month.toString().padLeft(2, '0')}";
    String icon = _getWeatherIcon(daily['weather_code'][index]);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dayStr,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Colors.grey.shade800)),
          const SizedBox(height: 4),
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            "${daily['temperature_2m_min'][index].round()}°-${daily['temperature_2m_max'][index].round()}°",
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, size: 8, color: Colors.blueAccent),
              const SizedBox(width: 1),
              Text(
                "${daily['precipitation_sum'][index]}mm",
                style: const TextStyle(
                    fontSize: 9,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAllData();

    _tabController = TabController(length: 2, vsync: this);

    _areaHa = calculateAreaInHectares(_loSamPoints);
    _sensorSubscription =
        signalRService.sensorStream.listen((dynamic allDeviceDataDynamic) {
          SensorDeviceModel allDeviceData;
          try {
            allDeviceData = allDeviceDataDynamic as SensorDeviceModel;
          } catch (e) {
            AppConfig.printEx("❌ Lỗi ép kiểu stream: $e");
            return;
          }
          if (allDeviceData != null) {
            final SensorDeviceModel firstDevice = allDeviceData;
            List<int> bytes = latin1.encode(firstDevice.deviceName ?? "");
            String correctText = utf8.decode(bytes);
            firstDevice.deviceName = correctText;
            _updateDeviceFromSignalR(firstDevice);
            if (firstDevice.deviceId == _selectedDevice?.deviceId) {
              updateEnvironmentData(_selectedDevice?.sensors);
            }
          }
        }, onError: (error) {
          AppConfig.printEx("❌ Lỗi trên sensorStream: $error");
        });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoadingBanner = true;
      _isLoadingCanhBao = true;
      numbertotal = null;
      numbertotalSucKhoe = null;
    });
    await _initializeAllData();
  }

  Future<void> _initializeAllData() async {
    await _loadLocalUserAndData();
    _fetchBannerData();
    _fetchLoSamCanhBao();
    _fetchDashboardStats();
    _fetchDashboardHealth();
    _fetchSensorData();
    _fetchThongBao();
    _fetchListLoSam();
    _fetchListVuonsam();
  }

  Future<void> _loadLocalUserAndData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString("ginseng_user");
      if (userJson != null) {
        user = Kttoken.fromJson(jsonDecode(userJson));
        if (mounted) setState(() {});
      }
    } catch (e) {
      AppConfig.printEx("Lỗi load user: $e");
    }
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final res = await API().getDashBoardSam();
      if (mounted) setState(() => numbertotal = res?.oneItem);
    } catch (e) {
      AppConfig.printEx("Lỗi Stats: $e");
    }
  }

  Future<void> _fetchDashboardHealth() async {
    try {
      final res = await API().getDashBoardSucKhoe();
      if (mounted) setState(() => numbertotalSucKhoe = res?.oneItem);
    } catch (e) {
      AppConfig.printEx("Lỗi Health: $e");
    }
  }

  Future<void> _fetchThongBao() async {
    try {
      final res = await API().listThongBao(status: 'TatCa');
      if (mounted && res?.message == "OK") {
        setState(() => tb = res?.items);
      }
    } catch (e) {
      AppConfig.printEx("Lỗi Thông báo: $e");
    }
  }

  Future<void> _fetchListLoSam() async {
    try {
      final res = await API().listLoSam(
        status: "1",
      );
      if (mounted) setState(() => _listLoSam = res);
    } catch (e) {
      AppConfig.printEx("Lỗi List Lô Sâm: $e");
    }
  }

  Future<void> _fetchListVuonsam() async {
    try {
      final apifarm = await API().listVuonTrong(status: 1, take: null, skip: 0);
      if (apifarm != null && apifarm.isNotEmpty) {
        if (mounted) {
          setState(() {
            _center = LatLng(apifarm.first.viTriCenterLat ?? 15.111,
                apifarm.first.viTriCenterLng ?? 108.017);
          });
          _fetchWeather();
        }
      }
    } catch (e) {
      AppConfig.printEx("Lỗi List Lô Sâm: $e");
    }
  }

  Future<void> _fetchSensorData() async {
    try {
      final res = await API().getDashBoardSensor();
      if (mounted) {
        setState(() {
          apilistsensor = res;
          if (res?.items?.isNotEmpty == true) {
            deviceList = res?.items;
            _selectedDevice = res?.items?.firstOrNull;
            if (_selectedDevice?.sensors != null) {
              updateEnvironmentData(_selectedDevice!.sensors);
            }
          }
        });
      }
    } catch (e) {
      AppConfig.printEx("Lỗi Sensor: $e");
    }
  }

  Future<void> _fetchBannerData() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, int> viewCounts = {};
      String? historyJson = prefs.getString('plant_view_counts');
      if (historyJson != null) {
        viewCounts = Map<String, int>.from(jsonDecode(historyJson));
      }

      List<CaySamModel> allPlants = [];

      bool isAdmin = user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>
      pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin") ?? false;

      if (isAdmin) {
        var sortedViewEntries = viewCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        List<String> topViewedIds = sortedViewEntries.take(10).map((e) => e.key).toList();

        if (topViewedIds.isNotEmpty) {
          String searchIn = topViewedIds.map((id) => "Id == \"$id\"").join(" or ");

          var viewedRes = await API().listCaySam(
              status: "1",
              top: 10,
              searchBy: [searchIn]
          );

          if (viewedRes?.items != null) {
            allPlants.addAll(viewedRes!.items!);
          }
        }

        if (allPlants.length < 10) {
          int needMore = 10 - allPlants.length;
          List<String> searchByParams = [];

          if (topViewedIds.isNotEmpty) {
            String searchNotIn = topViewedIds.map((id) => "Id != \"$id\"").join(" and ");
            searchByParams.add(searchNotIn);
          }

          var extraRes = await API().listCaySam(
              status: "1",
              skip: 0,
              top: needMore,
              searchBy: searchByParams.isNotEmpty ? searchByParams : null
          );

          if (extraRes?.items != null) {
            allPlants.addAll(extraRes!.items!);
          }
        }
      } else {
        var res = await API().listCaySam(status: "1", skip: 0);
        if (res?.items != null) {
          allPlants = res!.items!;
        }
      }

      if (allPlants.isNotEmpty) {
        allPlants.sort((a, b) {
          int viewA = viewCounts[a.caySamId.toString()] ?? 0;
          int viewB = viewCounts[b.caySamId.toString()] ?? 0;
          if (viewB != viewA) return viewB.compareTo(viewA);
          return 0;
        });

        if (mounted) {
          setState(() {
            _itemsCaySam = allPlants;
            _isLoadingBanner = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingBanner = false);
      }
    } catch (e) {
      AppConfig.printEx("Lỗi Banner: $e");
      if (mounted) setState(() => _isLoadingBanner = false);
    }
  }

  Future<void> _fetchLoSamCanhBao() async {
    if (!mounted) return;
    try {
      final result = await API().listLoSamCanhBao(top: 5);
      if (mounted) {
        setState(() {
          _loSamCanhBaoList = result;
          _isLoadingCanhBao = false;
        });
      }
    } catch (e) {
      AppConfig.printEx("Lỗi LoSamCanhBao: $e");
      if (mounted) setState(() => _isLoadingCanhBao = false);
    }
  }

  String getNametagLosam(int? name) {
    if (_listLoSam == null) return "...";
    final result = _listLoSam?.firstWhere(
          (item) => item.loSamId == name,
      orElse: () => LoSamModel(
          loSamId: 0,
          vuonTrongId: 0,
          dienTich: 0,
          soHang: 0,
          soCot: 0,
          trangThai: 0,
          soLuongCaySams: 0),
    );
    return result?.tenLo ?? "Không xác định";
  }

  Map<String, Map<String, dynamic>> environmentStatus = {
    'temperature': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 10, 'max': 30},
    'humidity': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 80, 'max': 95},
    'soilMoisture': {
      'value': 'N/A',
      'status': 'Chưa rõ',
      'min': 100,
      'max': 200
    },
    'dewPoint': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 15, 'max': 25},
  };

  String formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "Chưa cập nhật";
    try {
      DateTime dateTime = DateTime.parse(isoString);
      dateTime = dateTime.toLocal();
      return DateFormat('HH:mm:ss - dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  void _checkAndUpdateStatus({
    required Map<String, dynamic>? statusEntry,
    required double value,
    required String highStatus,
    required String lowStatus,
  }) {
    if (statusEntry == null) return;
    final double min = (statusEntry['min'] as num).toDouble();
    final double max = (statusEntry['max'] as num).toDouble();
    statusEntry['value'] = value.toStringAsFixed(1);
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
        if (deviceList?.first != null) {
          _selectedDevice = deviceList?.firstWhere(
                  (d) => d.deviceId == _selectedDevice!.deviceId,
              orElse: () => deviceList!.first);
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
            if (sensor.jValue != "") {
              final Map<String, dynamic> data = jsonDecode(sensor.jValue);
              if (data.containsKey('A1')) {
                final double rawValue = (data['A1'] as num).toDouble();
                final double percentageValue = (sensor.maxValueSS - rawValue) *
                    100 /
                    (sensor.maxValueSS - sensor.minValueSS);
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
                _checkAndUpdateStatus(
                  statusEntry: environmentStatus['dewPoint'],
                  value: dewPoint,
                  highStatus: 'cao',
                  lowStatus: 'thấp',
                );
              }
            }
          } catch (e) {
            AppConfig.printEx(
                'Lỗi phân tích JSON cho sensor ${sensor.sensorCode}: $e');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dashboard, size: 16),
                        const SizedBox(width: 8),
                        const Text('Tổng quan'),
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
                            const Icon(Icons.notifications, size: 16),
                            if (tb != null && tb!.any((item) => !item.seen))
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Text('Thông báo'),
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  NotificationPanel(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapLayer() {
    if (_currentMapLayer == 'topo') {
      return TileLayer(
        key: const ValueKey('topo_layer'),
        urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
        subdomains: const ['a', 'b', 'c'],
        maxNativeZoom: 17,
        maxZoom: 20,
        userAgentPackageName: 'com.huetechcoop.nftsam',
        errorTileCallback: (tile, error, stackTrace) {
          AppConfig.printEx("Lỗi Topo Map: $error");
        },
      );
    } else if (_currentMapLayer == 'googleSat') {
      return TileLayer(
        key: const ValueKey('sat_layer'),
        urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}',
        maxNativeZoom: 20,
        maxZoom: 20,
      );
    } else {
      return TileLayer(
        key: const ValueKey('road_layer'),
        urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
        maxNativeZoom: 20,
        maxZoom: 20,
      );
    }
  }

  Widget _buildLayerControl() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.layers, color: Colors.blue),
        onSelected: (value) => setState(() => _currentMapLayer = value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'googleRoad', child: Text("Google Road")),
          const PopupMenuItem(
              value: 'googleSat', child: Text("Google Satellite")),
          const PopupMenuItem(value: 'topo', child: Text("Địa hình OpenTopo")),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "btn_zoom_in",
          mini: true,
          backgroundColor: Colors.white,
          child: const Icon(Icons.add, color: Colors.black87),
          onPressed: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, currentZoom + 1);
          },
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "btn_zoom_out",
          mini: true,
          backgroundColor: Colors.white,
          child: const Icon(Icons.remove, color: Colors.black87),
          onPressed: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(_mapController.camera.center, currentZoom - 1);
          },
        ),
      ],
    );
  }

  Widget _buildWeatherPanel() {
    final current = _weatherData!['current'];
    final daily = _weatherData!['daily'];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = screenWidth / 390.0;
    return GestureDetector(
      onTap: () => setState(() => _isWeatherExpanded = !_isWeatherExpanded),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "🌿 LÔ SÂM ($_areaHa ha)",
                            style: TextStyle(
                              fontSize: (12 * textScale).clamp(10.0, 16.0),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Text(
                                  "${current['temperature_2m']}°C",
                                  style: TextStyle(
                                    fontSize:
                                    (20 * textScale).clamp(18.0, 28.0),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.air,
                                    size: (12 * textScale).clamp(10.0, 16.0),
                                    color: Colors.grey),
                                const SizedBox(width: 2),
                                Text(
                                  "${current['wind_speed_10m']} km/h",
                                  style: TextStyle(
                                      fontSize:
                                      (10 * textScale).clamp(9.0, 14.0)),
                                ),
                                const SizedBox(width: 10),
                                Icon(Icons.water_drop_outlined,
                                    size: (12 * textScale).clamp(10.0, 16.0),
                                    color: Colors.blue),
                                const SizedBox(width: 2),
                                Text(
                                  "${current['precipitation']} mm",
                                  style: TextStyle(
                                      fontSize:
                                      (10 * textScale).clamp(9.0, 14.0)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                        _isWeatherExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        size: 20,
                        color: Colors.blueGrey),
                  ],
                ),
                if (_isWeatherExpanded) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.black12),
                  ),
                  Row(
                    children: [
                      Expanded(child: _buildForecastCard(daily, 1)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildForecastCard(daily, 2)),
                      const SizedBox(width: 6),
                      Expanded(child: _buildForecastCard(daily, 3)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerBox(
      {double height = 100, double width = double.infinity}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
    final daily = _weatherData?['daily'];
    final myBounds = LatLngBounds(
      const LatLng(10.611, 103.347),
      const LatLng(19.611, 112.687),
    );
    bool isInsideBounds = _center != null && myBounds.contains(_center!);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingBanner)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: _buildShimmerBox(height: 200),
                )
              else if (_itemsCaySam != null && _itemsCaySam!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            aspectRatio: 16 / 9,
                            viewportFraction: 1.0,
                            autoPlay: true,
                            onPageChanged: (index, reason) {
                              setState(() => _currentIndex = index);
                            },
                          ),
                          items: _itemsCaySam!.map((item) {
                            return Builder(
                              builder: (BuildContext context) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlantDetailScreen(
                                            plant: item,
                                            onBack: () =>
                                                Navigator.pop(context)),
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: item.caySamNhatKys.firstOrNull
                                            ?.hinhAnhTongQuan ??
                                            "",
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        placeholder: (context, url) =>
                                            Container(color: Colors.grey[300]),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              color: Colors.grey[200],
                                              child: Icon(Icons.image_not_supported,
                                                  color: Colors.grey),
                                            ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            stops: [0.5, 1.0],
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.7)
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 15,
                                        left: 15,
                                        right: 15,
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.layers,
                                                    color: Colors
                                                        .yellowAccent.shade700,
                                                    size: 14),
                                                SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    getNametagLosam(
                                                        item.loSamId)
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color:
                                                      Colors.yellowAccent,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      fontSize: 12,
                                                      letterSpacing: 0.5,
                                                      shadows: [
                                                        Shadow(
                                                            offset:
                                                            Offset(0, 1),
                                                            blurRadius: 2.0,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                0.5))
                                                      ],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              item.maCaySam ?? "Chưa đặt tên",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  shadows: [
                                                    Shadow(
                                                        offset: Offset(0, 1),
                                                        blurRadius: 3.0,
                                                        color: Colors.black45)
                                                  ]),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              "Vị trí: ${item.viTriTrongLo ?? "_"}  •  Sức khỏe: ${getSucKhoeText(item.caySamNhatKys.firstOrNull?.diemSucKhoe)}  •  Tuổi: ${getTuoiCayText(item.tuoiCayId)}",
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontSize: 13,
                                                  height: 1.4),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(
                            children:
                            _itemsCaySam!.asMap().entries.map((entry) {
                              return AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: _currentIndex == entry.key ? 10.0 : 8.0,
                                height: 8.0,
                                margin: EdgeInsets.symmetric(horizontal: 3.0),
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(
                                        _currentIndex == entry.key
                                            ? 1.0
                                            : 0.4)),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(),
              if (numbertotal == null)
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 25,
                  mainAxisSpacing: 25,
                  childAspectRatio: 1.3,
                  children: List.generate(
                      4, (index) => _buildShimmerBox(height: 100)),
                )
              else
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 25,
                  mainAxisSpacing: 25,
                  childAspectRatio: 1.3,
                  children: [
                    if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>
                    pq.maVaiTro != "nft_invester" &&
                        pq.maVaiTro == "nft_admin") ??
                        false)
                      _buildStatCard(context,
                          icon: Icons.business_rounded,
                          title: 'Tổng số vườn',
                          value: numbertotal?.totalVuonTrong.toString() ?? "0",
                          color: Colors.blue.shade700, onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => HomeScreen(tabcurrent: 2)));
                          }),
                    if (user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>
                    pq.maVaiTro != "nft_invester" &&
                        pq.maVaiTro == "nft_admin") ??
                        false)
                      _buildStatCard(context,
                          icon: Icons.map_rounded,
                          title: 'Tổng số lô',
                          value: numbertotal?.totalLoSam.toString() ?? "0",
                          color: Colors.green.shade700, onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const DanhSachLoSamPage()));
                          }),
                    _buildStatCard(context,
                        icon: Icons.eco_rounded,
                        title: 'Tổng số cây',
                        value: numbertotal?.totalCaySam.toString() ?? "0",
                        color: Colors.teal.shade600, onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DanhSachCaySamPage()));
                        }),
                    _buildStatCard(context,
                        icon: Icons.sentiment_dissatisfied_rounded,
                        title: 'Cây yếu',
                        value: numbertotal?.totalSuckhoeYeu.toString() ?? "0",
                        color: Colors.orange.shade800, onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const DanhSachCayYeuPage()));
                        }),
                  ],
                ),
              const SizedBox(height: 24),
              if (numbertotalSucKhoe == null)
                _buildShimmerBox(height: 250)
              else
                Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Icon(Icons.favorite_rounded, size: 24, color: Colors.pinkAccent),
                          SizedBox(width: 10),
                          Text('Tổng quan sức khỏe',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.2))
                        ]),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('Tình trạng tổng thể',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey.shade700)),
                            const Spacer(),
                            Text(
                                '${(5 * (healthPercentage.round() / 100)).toStringAsFixed(2)}/5',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: healthColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                              value: healthPercentage / 100,
                              backgroundColor: healthColor.withOpacity(0.2),
                              valueColor:
                              AlwaysStoppedAnimation<Color>(healthColor),
                              minHeight: 10),
                        ),
                        const Divider(height: 32),

                        // --- GIAO DIỆN LƯỚI SỨC KHỎE CŨ ĐƯỢC GIỮ LẠI THEO ẢNH ---
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 5,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.7,
                          children: [
                            _buildHealthStatItem(
                                'Rất tốt',
                                numbertotalSucKhoe?.totalRatTot ?? 0,
                                Colors.green.shade600,
                                Icons.sentiment_very_satisfied_rounded,
                                5),
                            _buildHealthStatItem(
                                'Khá tốt',
                                numbertotalSucKhoe?.totalKhaTot ?? 0,
                                Colors.teal.shade500,
                                Icons.sentiment_satisfied_rounded,
                                4),
                            _buildHealthStatItem(
                                'Trung bình',
                                numbertotalSucKhoe?.totalTrungBinh ?? 0,
                                Colors.orange.shade600,
                                Icons.sentiment_neutral_rounded,
                                3),
                            _buildHealthStatItem(
                                'Yếu',
                                numbertotalSucKhoe?.totalYeu ?? 0,
                                Colors.deepOrange.shade500,
                                Icons.sentiment_dissatisfied_rounded,
                                2),
                            _buildHealthStatItem(
                                'Rất yếu',
                                numbertotalSucKhoe?.totalRatYeu ?? 0,
                                Colors.red.shade700,
                                Icons.sentiment_very_dissatisfied_rounded,
                                1),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              if (apilistsensor != null &&
                  (_isValidAndNotZero(
                      environmentStatus['soilMoisture']!['value']) ||
                      _isValidAndNotZero(
                          environmentStatus['dewPoint']!['value']) ||
                      _isValidAndNotZero(
                          environmentStatus['humidity']!['value']) ||
                      _isValidAndNotZero(
                          environmentStatus['temperature']!['value']) ||
                      (deviceList?.length ?? 0) > 1))
                Card(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          Icon(Icons.sensors, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Text('Tình trạng môi trường',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))
                        ]),
                        if ((apilistsensor?.items?.length ?? 0) > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                            child: DropdownButtonFormField<SensorDeviceModel>(
                              value: _selectedDevice,
                              decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 12.0),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0)),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                          width: 1.0)),
                                  filled: false),
                              isExpanded: true,
                              hint: const Text("Chọn thiết bị..."),
                              icon: const Icon(Icons.expand_more_rounded,
                                  size: 24),
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.black87),
                              onChanged: (SensorDeviceModel? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedDevice = newValue;
                                  });
                                  updateEnvironmentData(newValue.sensors);
                                }
                              },
                              items:
                              deviceList?.map((SensorDeviceModel device) {
                                return DropdownMenuItem<SensorDeviceModel>(
                                    value: device,
                                    child: Text(device.deviceName ?? "",
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87),
                                        overflow: TextOverflow.ellipsis));
                              }).toList(),
                            ),
                          ),
                        const Divider(height: 24),
                        Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(_selectedDevice?.deviceName ?? "",
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600))),
                        const SizedBox(height: 24),

                        // --- GIAO DIỆN SENSOR GỐC THEO YÊU CẦU ---
                        _buildEnvironmentOverview(),

                        Padding(
                            padding: const EdgeInsets.only(left: 8, top: 15),
                            child: Row(children: [
                              const Spacer(),
                              Text(formatDateTime(_selectedDevice?.updateTime),
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600))
                            ])),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 5. CẢNH BÁO
              if ((user?.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>
              pq.maVaiTro != "nft_invester" &&
                  pq.maVaiTro == "nft_admin") ??
                  false))
                if (_isLoadingCanhBao)
                  _buildShimmerBox(height: 150)
                else if (_loSamCanhBaoList?.isNotEmpty == true)
                  Card(
                    elevation: 3,
                    shadowColor: Colors.black.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 22, color: Colors.orange.shade700),
                            const SizedBox(width: 10),
                            const Text('Cảnh báo cần xử lý',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold))
                          ]),
                          const SizedBox(height: 12),
                          Column(
                            children: _loSamCanhBaoList!.map((loSam) {
                              return _buildAlertItem(
                                  icon: Icons.eco_outlined,
                                  iconColor: Colors.orange.shade600,
                                  title: 'Lô: ${loSam.tenLo ?? loSam.maLo}',
                                  subtitle: loSam.soLuongCaySams > 0
                                      ? '${loSam.soLuongCaySams} cây cần cập nhật nhật ký'
                                      : '',
                                  caySams: loSam.caySams,
                                  idzone: loSam.loSamId);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.map_rounded,
                      size: 22, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  const Text('Bản đồ & Thời tiết khu vực',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (_center != null)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,
                  width: double.infinity,
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _center ?? LatLng(0, 0),
                            initialZoom: 13,
                            minZoom: 5,
                            maxZoom: 20,
                            cameraConstraint: isInsideBounds
                                ? CameraConstraint.contain(bounds: myBounds)
                                : const CameraConstraint.unconstrained(),
                          ),
                          children: [
                            _buildMapLayer(),
                            StreamBuilder<MapEvent>(
                              stream: _mapController.mapEventStream,
                              builder: (context, snapshot) {
                                final currentZoom = _mapController.camera.zoom;
                                if (currentZoom < 14.0) {
                                  return MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _center ?? LatLng(0, 0),
                                        width: 25,
                                        height: 25,
                                        alignment: Alignment.topCenter,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: Color(0xFFD50000),
                                          size: 25,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return PolygonLayer(
                                  polygons: [
                                    Polygon(
                                      points: _loSamPoints,
                                      color: Colors.white.withOpacity(0.15),
                                      borderColor: const Color(0xFFD50000),
                                      borderStrokeWidth: 3,
                                      pattern: StrokePattern.dashed(
                                        segments: [5, 5],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _buildLayerControl(),
                        ),
                        Positioned(
                          top: 76,
                          right: 16,
                          child: _buildZoomControls(),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: _isLoadingWeather
                              ? _buildShimmerBox(height: 70)
                              : _buildWeatherPanel(),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required IconData icon,
        required String title,
        required String value,
        required Color color,
        VoidCallback? onTap}) {
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
                end: Alignment.bottomRight)),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.fontSizeExtraSmall),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.fontSizeExtraSmall),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon,
                        color: color, size: AppDimensions.fontSizeLarge)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: AppDimensions.responsiveWidth(
                                context, AppDimensions.fontSizeLarge),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(title,
                        style: TextStyle(
                            fontSize: AppDimensions.responsiveWidth(
                                context, AppDimensions.fontSizeSmall),
                            color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- CÁC HÀM XÂY DỰNG GIAO DIỆN SENSOR VÀ SỨC KHỎE CŨ ---
  Widget _buildEnvironmentOverview() {
    final LinearGradient tempGradient = LinearGradient(
        colors: [Colors.orange[700]!, Colors.yellow[500]!],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter);
    final LinearGradient dewPointGradient = LinearGradient(
        colors: [Colors.green[600]!, Colors.cyan[300]!],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (_isValidAndNotZero(environmentStatus['temperature']!['value']))
              Expanded(
                  child: _buildTemperatureBar(
                      value: double.tryParse(
                          environmentStatus['temperature']!['value']) ??
                          0.0,
                      unit: '°C',
                      label: 'Nhiệt độ',
                      min: (environmentStatus['temperature']!['min'] as num)
                          .toDouble(),
                      max: (environmentStatus['temperature']!['max'] as num)
                          .toDouble(),
                      gradient: tempGradient)),
            const SizedBox(width: 20),
            if (_isValidAndNotZero(environmentStatus['dewPoint']!['value']))
              Expanded(
                  child: _buildTemperatureBar(
                      value: double.tryParse(
                          environmentStatus['dewPoint']!['value']) ??
                          0.0,
                      unit: '°C',
                      label: 'Điểm sương',
                      min: (environmentStatus['dewPoint']!['min'] as num)
                          .toDouble(),
                      max: (environmentStatus['dewPoint']!['max'] as num)
                          .toDouble(),
                      gradient: dewPointGradient)),
          ],
        ),
        const SizedBox(height: 24),
        if (_isValidAndNotZero(environmentStatus['humidity']!['value']))
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                  child: _buildCircularProgress(
                      value: double.tryParse(
                          environmentStatus['humidity']!['value']) ??
                          0.0,
                      label: 'Độ ẩm không khí',
                      unit: '%',
                      color: Colors.green,
                      maxValue: 100)),
              const SizedBox(width: 20),
              if (_isValidAndNotZero(
                  environmentStatus['soilMoisture']!['value']))
                Expanded(
                    child: _buildCircularProgress(
                        value: double.tryParse(
                            environmentStatus['soilMoisture']!['value']) ??
                            0.0,
                        label: 'Độ ẩm đất',
                        unit: '%',
                        color: Colors.orange,
                        maxValue: 100)),
            ],
          ),
      ],
    );
  }

  Widget _buildTemperatureBar(
      {required double value,
        required String unit,
        required String label,
        required double min,
        required double max,
        required LinearGradient gradient}) {
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
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                      color: gradient.colors.last.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15))),
              TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: targetHeight),
                  duration: const Duration(milliseconds: 400),
                  builder: (BuildContext context, double animatedHeight,
                      Widget? child) {
                    return Container(
                        width: barWidth,
                        height: animatedHeight,
                        decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(15)));
                  })
            ])),
        const SizedBox(height: 8),
        Container(
            width: circleDiameter,
            height: circleDiameter,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: gradient.colors.first),
            child: Center(
                child: Text(value.toStringAsFixed(0),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)))),
        const SizedBox(height: 12),
        Text('$label\n${value.toStringAsFixed(1)}$unit',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildCircularProgress(
      {required double value,
        required String label,
        required String unit,
        required Color color,
        double maxValue = 100.0}) {
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
                duration: const Duration(milliseconds: 400),
                builder: (BuildContext context, double animatedValue,
                    Widget? child) {
                  return Stack(alignment: Alignment.center, children: [
                    SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                            value: animatedValue,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor: color.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color))),
                    child!
                  ]);
                },
                child: Text(
                    value < 0
                        ? '0$unit'
                        : (value > 100
                        ? '100$unit'
                        : (value == 100
                        ? '${value.toStringAsFixed(0)}$unit'
                        : '${value.toStringAsFixed(1)}$unit')),
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)))),
        const SizedBox(height: 12),
        Text('$label\n${value.toStringAsFixed(1)}$unit',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAlertItem(
      {required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        List<CaySamModel>? caySams,
        bool isLastItem = false,
        int? idzone}) {
    Color cardBackgroundColor = Colors.white;
    if (iconColor == Colors.orange.shade600 ||
        iconColor == Colors.red.shade600 ||
        iconColor == Colors.orange.shade700) {
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
      int maxLength = 30;
      if (positionsToShow.length > maxLength) {
        positionsToShow = '${positionsToShow.substring(0, maxLength)}...';
      }
      final moreCount = caySams.length > positionsList.length
          ? ' +${caySams.length - positionsList.length}'
          : '';
      plantPositionsInfo = subtitle != ''
          ? '\nCây $positionsToShow$moreCount chưa cập nhật ký trong nhiều tháng'
          : 'Cây $positionsToShow$moreCount chưa cập nhật ký trong nhiều tháng';
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
              if (idzone != null) {
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
                              zone: losamitem)));
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Lỗi tải dữ liệu lô: $e'),
                      backgroundColor: Colors.red));
                  AppConfig.printEx("Lỗi khi gọi getLoSamById: $e");
                }
              }
            },
            child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 12.0),
                child: Row(children: [
                  Container(
                      width: 5,
                      height: 45,
                      decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 12),
                  CircleAvatar(
                      radius: 20,
                      backgroundColor: iconColor.withOpacity(0.15),
                      child: Icon(icon, color: iconColor, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('$subtitle$plantPositionsInfo',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 13),
                                maxLines: plantPositionsInfo.isNotEmpty ? 3 : 2,
                                overflow: TextOverflow.ellipsis)
                          ])),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.shade400, size: 20)
                ]))));
  }

  // --- HÀM TẠO THẺ GRID SỨC KHỎE (CÓ CHUYỂN HƯỚNG) ---
  Widget _buildHealthStatItem(
      String title, int count, Color color, IconData icon, int healthId) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DanhSachCaySamPage(initialHealth: healthId),
            ),
          );
        },
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3), width: 1.0),
                borderRadius: BorderRadius.circular(12)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon,
                  color: color,
                  size: AppDimensions.responsiveWidth(
                      context, AppDimensions.fontSizeExtraLarge)),
              SizedBox(
                  height:
                  AppDimensions.responsiveHeight(context, AppDimensions.sp2)),
              Text(count.toString(),
                  style: TextStyle(
                      fontSize: AppDimensions.responsiveWidth(
                          context, AppDimensions.fontSizeSmall),
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: AppDimensions.responsiveWidth(
                          context, AppDimensions.fontSizeExtraSmall),
                      color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)
            ])),
      ),
    );
  }
}

String getSucKhoeText(int? diem) {
  switch (diem) {
    case 1:
      return "Rất tốt";
    case 2:
      return "Yếu";
    case 3:
      return "Trung bình";
    case 4:
      return "Tốt";
    case 5:
      return "Rất tốt";
    default:
      return "Không xác định";
  }
}

String getTuoiCayText(int? id) {
  switch (id) {
    case 1:
      return "3 năm";
    case 2:
      return "6-7 năm";
    case 3:
      return "8-9 năm";
    case 4:
      return "Trên 10 năm";
    default:
      return "Chưa rõ tuổi";
  }
}