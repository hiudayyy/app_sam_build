import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nftsam/api/api_dashboard.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../api/api.dart';
import '../models/response_model.dart';
import '../models/vuontrong/sensor_model.dart';
import '../providers/auth_provider.dart';
import '../services/signalr_service.dart';

import '/app_config.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

// BỔ SUNG TickerProviderStateMixin ĐỂ XỬ LÝ ANIMATION LIÊN TỤC
class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin {
  // === BẢN ĐỒ & THỜI TIẾT ===
  final MapController _mapController = MapController();
  String _currentMapLayer = 'googleRoad';
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  LatLng? _center;
  late double _areaHa;

  // === ANIMATION CONTROLLERS ===
  late AnimationController _floatController;
  late AnimationController _rotateController;

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

  // === CẢM BIẾN ===
  StreamSubscription? _sensorSubscription;
  ApiResponse<SensorDeviceModel>? apilistsensor;
  SensorDeviceModel? _selectedDevice;
  List<SensorDeviceModel>? deviceList = [];
  Map<String, Map<String, dynamic>> environmentStatus = {
    'temperature': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 10, 'max': 30},
    'humidity': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 80, 'max': 95},
    'soilMoisture': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 100, 'max': 200},
    'dewPoint': {'value': 'N/A', 'status': 'Chưa rõ', 'min': 15, 'max': 25},
  };

  @override
  void initState() {
    super.initState();
    _areaHa = _calculateAreaInHectares(_loSamPoints);

    // Khởi tạo Animation cho Mây (trôi lên xuống) và Mặt trời (Xoay)
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _rotateController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();

    _initData();
  }

  Future<void> _initData() async {
    _center = const LatLng(15.111, 108.017);
    await _fetchWeather();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        _fetchSensorData();
        _setupSignalR();
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _rotateController.dispose();
    _sensorSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoadingWeather = true);
    await _initData();
  }

  // ==========================================
  // HÀM XỬ LÝ DỮ LIỆU
  // ==========================================
  Future<void> _fetchWeather() async {
    final url = 'https://api.open-meteo.com/v1/forecast?latitude=${_center?.latitude}&longitude=${_center?.longitude}&current=temperature_2m,wind_speed_10m,precipitation,weather_code&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code&timezone=auto';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _weatherData = json.decode(response.body);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      AppConfig.printEx("Lỗi tải thời tiết: $e");
    }
  }

  double _calculateAreaInHectares(List<LatLng> points) {
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
    return double.parse(((area.abs() / 2.0) / 10000.0).toStringAsFixed(2));
  }

  String _getWeatherDesc(int code) {
    if (code >= 95) return "Có bão";
    if (code >= 61) return "Trời mưa";
    if (code >= 1) return "Nhiều mây";
    return "Trời nắng";
  }

  IconData _getWeatherIconData(int code) {
    if (code >= 95) return Icons.thunderstorm_rounded;
    if (code >= 61) return Icons.water_drop_rounded;
    if (code >= 1) return Icons.cloud_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherIconColor(int code) {
    if (code >= 95) return Colors.deepPurple;
    if (code >= 61) return Colors.blue;
    if (code >= 1) return Colors.grey.shade600;
    return Colors.orange;
  }

  Future<void> _fetchSensorData() async {
    try {
      final res = await API().getDashBoardSensor();
      if (mounted && res?.items?.isNotEmpty == true) {
        setState(() {
          apilistsensor = res;
          deviceList = res?.items;
          _selectedDevice = res?.items?.firstOrNull;
          if (_selectedDevice?.sensors != null) _updateEnvironmentData(_selectedDevice!.sensors);
        });
      }
    } catch (e) {
      AppConfig.printEx("Lỗi Sensor: $e");
    }
  }

  void _setupSignalR() {
    final signalRService = SignalRService();
    _sensorSubscription = signalRService.sensorStream.listen((dynamic data) {
      try {
        final SensorDeviceModel firstDevice = data as SensorDeviceModel;
        List<int> bytes = latin1.encode(firstDevice.deviceName ?? "");
        firstDevice.deviceName = utf8.decode(bytes);

        setState(() {
          deviceList = deviceList?.map((oldDevice) {
            return oldDevice.deviceId == firstDevice.deviceId ? firstDevice : oldDevice;
          }).toList();

          if (_selectedDevice != null && deviceList != null) {
            _selectedDevice = deviceList?.firstWhere((d) => d.deviceId == _selectedDevice!.deviceId, orElse: () => deviceList!.first);
            if (firstDevice.deviceId == _selectedDevice?.deviceId) _updateEnvironmentData(_selectedDevice?.sensors);
          }
        });
      } catch (e) {}
    });
  }

  void _updateEnvironmentData(List<SensorModel>? sensors) {
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
                final double percentageValue = (sensor.maxValueSS - rawValue) * 100 / (sensor.maxValueSS - sensor.minValueSS);
                _checkAndUpdateStatus(statusEntry: environmentStatus['soilMoisture'], value: percentageValue, highStatus: 'thừa ẩm', lowStatus: 'khô');
              }
              if (data.containsKey('Temperature')) _checkAndUpdateStatus(statusEntry: environmentStatus['temperature'], value: (data['Temperature'] as num).toDouble(), highStatus: 'nóng', lowStatus: 'lạnh');
              if (data.containsKey('Humidity')) _checkAndUpdateStatus(statusEntry: environmentStatus['humidity'], value: (data['Humidity'] as num).toDouble(), highStatus: 'ẩm', lowStatus: 'khô');
              if (data.containsKey('DewPoint')) _checkAndUpdateStatus(statusEntry: environmentStatus['dewPoint'], value: (data['DewPoint'] as num).toDouble(), highStatus: 'cao', lowStatus: 'thấp');
            }
          } catch (e) {}
        }
      }
    });
  }

  void _checkAndUpdateStatus({required Map<String, dynamic>? statusEntry, required double value, required String highStatus, required String lowStatus}) {
    if (statusEntry == null) return;
    final double min = (statusEntry['min'] as num).toDouble();
    final double max = (statusEntry['max'] as num).toDouble();
    statusEntry['value'] = value.toStringAsFixed(1);
    if (value > max) statusEntry['status'] = highStatus;
    else if (value < min) statusEntry['status'] = lowStatus;
    else statusEntry['status'] = 'Tốt';
  }

  bool _isValidAndNotZero(String? valueString) {
    if (valueString == null) return false;
    final double? value = double.tryParse(valueString);
    return value != null && value != 0.0;
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "Chưa cập nhật";
    try {
      DateTime dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat('HH:mm - dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return isoString;
    }
  }

  // ==========================================
  // GIAO DIỆN CHÍNH
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bool isGuest = authProvider.user == null;

    final myBounds = LatLngBounds(const LatLng(10.611, 103.347), const LatLng(19.611, 112.687));
    bool isInsideBounds = _center != null && myBounds.contains(_center!);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInUp(delayMs: 100, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(Icons.cloud_rounded, const Color(0xFF2E7D32), 'Thời tiết khu vực'),
                  _isLoadingWeather ? _buildShimmerBox(height: 180) : _buildUnifiedWeatherCard(),
                ],
              )),
              const SizedBox(height: 20),

              if (!isGuest && apilistsensor != null &&
                  (_isValidAndNotZero(environmentStatus['soilMoisture']!['value']) ||
                      _isValidAndNotZero(environmentStatus['dewPoint']!['value']) ||
                      _isValidAndNotZero(environmentStatus['humidity']!['value']) ||
                      _isValidAndNotZero(environmentStatus['temperature']!['value']))) ...[
                FadeInUp(delayMs: 200, child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(Icons.sensors_rounded, const Color(0xFF2E7D32), 'Chỉ số môi trường'),
                    _buildUnifiedSensorCard(),
                  ],
                )),
                const SizedBox(height: 20),
              ],

              FadeInUp(delayMs: 300, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(Icons.map_rounded, const Color(0xFF2E7D32), 'Bản đồ vườn'),
                  _buildUnifiedMapCard(isInsideBounds, myBounds),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, Color iconColor, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
        ],
      ),
    );
  }

  Widget _buildUnifiedWeatherCard() {
    if (_weatherData == null) return const SizedBox();
    final current = _weatherData!['current'];
    final daily = _weatherData!['daily'];
    final int code = current['weather_code'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header nhiệt độ chính
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0, end: current['temperature_2m'].toDouble()),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutQuart,
                            builder: (context, value, child) => Text(
                              "${value.round()}",
                              style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: Color(0xFF1B5E20), height: 1.0),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text("°C", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF43A047))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_getWeatherDesc(code),
                          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildWeatherChip(Icons.air_rounded, "${current['wind_speed_10m']} km/h", const Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          _buildWeatherChip(Icons.water_drop_rounded, "${current['precipitation']} mm", const Color(0xFF0277BD)),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildRichWeatherIcon(code, size: 70),
              ],
            ),
          ),
          // Divider
          Divider(color: Colors.grey.shade100, height: 1, indent: 16, endIndent: 16),
          // Dự báo 3 ngày
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildForecastItem(daily, 1),
                Container(width: 1, height: 48, color: Colors.grey.shade100),
                _buildForecastItem(daily, 2),
                Container(width: 1, height: 48, color: Colors.grey.shade100),
                _buildForecastItem(daily, 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }



  Widget _buildForecastItem(dynamic daily, int index) {
    DateTime dateObj = DateTime.parse(daily['time'][index]);
    String dayStr = "${dateObj.day.toString().padLeft(2, '0')}/${dateObj.month.toString().padLeft(2, '0')}";
    final int code = daily['weather_code'][index];

    return Column(
      children: [
        Text(dayStr, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        _buildRichWeatherIcon(code, size: 28),
        const SizedBox(height: 8),
        Text(
          "${daily['temperature_2m_min'][index].round()}° - ${daily['temperature_2m_max'][index].round()}°",
          style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }

  // --- HÀM TẠO ICON THỜI TIẾT ĐỘNG (ANIMATED) ---
  Widget _buildRichWeatherIcon(int code, {required double size}) {
    // 1. Mưa / Sấm sét (Mây trôi + sét/mưa)
    if (code >= 61) {
      bool isStorm = code >= 95;
      return SizedBox(
        width: size * 1.2, height: size * 1.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.cloud_rounded, color: Colors.black12, size: size + 4), // Bóng đổ mây
            AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, math.sin(_floatController.value * math.pi) * (size * -0.1)),
                child: child,
              ),
              child: Icon(Icons.cloud_rounded, color: isStorm ? Colors.blueGrey.shade700 : Colors.blueGrey.shade400, size: size),
            ),
            Positioned(
              bottom: isStorm ? 0 : -size * 0.01,
              right: isStorm ? size * 0.2 : null,
              child: isStorm
                  ? Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: size * 0.6)
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded, color: Colors.blue.shade400, size: size * 0.35),
                  Icon(Icons.water_drop_rounded, color: Colors.blue.shade600, size: size * 0.35),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Có Mây (Mặt trời xoay + Mây trôi)
    if (code >= 1) {
      return SizedBox(
        width: size * 1.2, height: size * 1.2,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0, right: 0,
              child: AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) => Transform.rotate(angle: _rotateController.value * 2 * math.pi, child: child),
                child: Container(
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 10)]),
                  child: Icon(Icons.wb_sunny_rounded, color: Colors.orange.shade400, size: size * 0.65),
                ),
              ),
            ),
            Positioned(
              bottom: size * 0.1, left: 0,
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, math.sin(_floatController.value * math.pi) * (size * -0.05)),
                  child: child,
                ),
                child: Stack(
                  children: [
                    Icon(Icons.cloud_rounded, color: Colors.black12, size: size * 0.9),
                    Icon(Icons.cloud_rounded, color: Colors.grey.shade300, size: size * 0.85),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Trời nắng (Mặt trời xoay và toả sáng)
    return Container(
      width: size * 1.2, height: size * 1.2,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 16, spreadRadius: 4)]
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) => Transform.rotate(angle: _rotateController.value * 2 * math.pi, child: child),
          child: Icon(Icons.wb_sunny_rounded, color: Colors.orange.shade500, size: size),
        ),
      ),
    );
  }

  // --- CẢM BIẾN ---
  Widget _buildUnifiedSensorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((deviceList?.length ?? 0) > 1)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.grey.shade200, width: 1.0)
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<SensorDeviceModel>(
                    value: _selectedDevice,
                    decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        border: InputBorder.none),
                    isExpanded: true,
                    hint: const Text("Chọn thiết bị..."),
                    icon: const Icon(Icons.expand_more_rounded, size: 24, color: Colors.green),
                    style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
                    onChanged: (SensorDeviceModel? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedDevice = newValue);
                        _updateEnvironmentData(newValue.sensors);
                      }
                    },
                    items: deviceList?.map((SensorDeviceModel device) {
                      return DropdownMenuItem<SensorDeviceModel>(
                          value: device,
                          child: Text(device.deviceName ?? "", style: const TextStyle(fontSize: 15, color: Colors.black87), overflow: TextOverflow.ellipsis));
                    }).toList(),
                  ),
                ),
              )
            else
              Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(_selectedDevice?.deviceName ?? "", style: const TextStyle(fontSize: 16, color: Color(0xFF102A43), fontWeight: FontWeight.bold))
              ),

            _buildEnvironmentOverview(),

            Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.sync_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(_formatDateTime(_selectedDevice?.updateTime), style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500))
                    ]
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentOverview() {
    final LinearGradient tempGradient = LinearGradient(colors: [Colors.orange[700]!, Colors.yellow[500]!], begin: Alignment.bottomCenter, end: Alignment.topCenter);
    final LinearGradient dewPointGradient = LinearGradient(colors: [Colors.green[600]!, Colors.cyan[300]!], begin: Alignment.bottomCenter, end: Alignment.topCenter);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (_isValidAndNotZero(environmentStatus['temperature']!['value']))
              Expanded(child: _buildTemperatureBar(value: double.tryParse(environmentStatus['temperature']!['value']) ?? 0.0, unit: '°C', label: 'Nhiệt độ', min: (environmentStatus['temperature']!['min'] as num).toDouble(), max: (environmentStatus['temperature']!['max'] as num).toDouble(), gradient: tempGradient)),
            const SizedBox(width: 20),
            if (_isValidAndNotZero(environmentStatus['dewPoint']!['value']))
              Expanded(child: _buildTemperatureBar(value: double.tryParse(environmentStatus['dewPoint']!['value']) ?? 0.0, unit: '°C', label: 'Điểm sương', min: (environmentStatus['dewPoint']!['min'] as num).toDouble(), max: (environmentStatus['dewPoint']!['max'] as num).toDouble(), gradient: dewPointGradient)),
          ],
        ),
        const SizedBox(height: 32),
        if (_isValidAndNotZero(environmentStatus['humidity']!['value']))
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildCircularProgress(value: double.tryParse(environmentStatus['humidity']!['value']) ?? 0.0, label: 'Độ ẩm không khí', unit: '%', color: Colors.green, maxValue: 100)),
              const SizedBox(width: 20),
              if (_isValidAndNotZero(environmentStatus['soilMoisture']!['value']))
                Expanded(child: _buildCircularProgress(value: double.tryParse(environmentStatus['soilMoisture']!['value']) ?? 0.0, label: 'Độ ẩm đất', unit: '%', color: Colors.orange, maxValue: 100)),
            ],
          ),
      ],
    );
  }

  Widget _buildTemperatureBar({required double value, required String unit, required String label, required double min, required double max, required LinearGradient gradient}) {
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
            width: barWidth, height: barHeight,
            child: Stack(alignment: Alignment.bottomCenter, children: [
              Container(width: barWidth, height: barHeight, decoration: BoxDecoration(color: gradient.colors.last.withOpacity(0.3), borderRadius: BorderRadius.circular(15))),
              TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: targetHeight),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double animatedHeight, Widget? child) {
                    return Container(width: barWidth, height: animatedHeight, decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(15)));
                  })
            ])),
        const SizedBox(height: 8),
        Container(
            width: circleDiameter, height: circleDiameter,
            decoration: BoxDecoration(shape: BoxShape.circle, color: gradient.colors.first),
            child: Center(
                child: Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
        const SizedBox(height: 12),
        Text('$label\n${value.toStringAsFixed(1)}$unit', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCircularProgress({required double value, required String label, required String unit, required Color color, double maxValue = 100.0}) {
    double progress = value / maxValue;
    if (progress.isNaN || progress.isInfinite) progress = 0.0;
    progress = progress.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            width: 80, height: 80,
            child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (BuildContext context, double animatedValue, Widget? child) {
                  return Stack(alignment: Alignment.center, children: [
                    SizedBox(
                        width: 80, height: 80,
                        child: CircularProgressIndicator(value: animatedValue, strokeWidth: 12, strokeCap: StrokeCap.round, backgroundColor: color.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(color))),
                    child!
                  ]);
                },
                child: Text(value < 0 ? '0$unit' : (value > 100 ? '100$unit' : (value == 100 ? '${value.toStringAsFixed(0)}$unit' : '${value.toStringAsFixed(1)}$unit')), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)))),
        const SizedBox(height: 12),
        Text('$label\n${value.toStringAsFixed(1)}$unit', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // --- BẢN ĐỒ ---
  Widget _buildUnifiedMapCard(bool isInsideBounds, LatLngBounds myBounds) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 300,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center ?? const LatLng(0, 0),
                    initialZoom: 14,
                    minZoom: 5,
                    maxZoom: 20,
                    cameraConstraint: isInsideBounds ? CameraConstraint.contain(bounds: myBounds) : const CameraConstraint.unconstrained(),
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
                              Marker(point: _center ?? const LatLng(0, 0), width: 25, height: 25, alignment: Alignment.topCenter, child: const Icon(Icons.location_on, color: Color(0xFFD50000), size: 30)),
                            ],
                          );
                        }
                        return PolygonLayer(
                          polygons: [
                            Polygon(points: _loSamPoints, color: const Color(0xFF4CAF50).withOpacity(0.25), borderColor: const Color(0xFF2E7D32), borderStrokeWidth: 3),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                Positioned(top: 12, right: 12, child: _buildLayerControl()),
                Positioned(top: 72, right: 12, child: _buildZoomControls())
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerControl() {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.layers_rounded, color: Color(0xFF102A43)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) => setState(() => _currentMapLayer = value),
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'googleRoad', child: Text("Đường phố (Google)")),
          const PopupMenuItem(value: 'googleSat', child: Text("Vệ tinh (Google)")),
          const PopupMenuItem(value: 'topo', child: Text("Địa hình (OpenTopo)")),
        ],
      ),
    );
  }

  Widget _buildMapLayer() {
    if (_currentMapLayer == 'topo') return TileLayer(key: const ValueKey('topo_layer'), urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', subdomains: const ['a', 'b', 'c'], maxNativeZoom: 17, maxZoom: 20);
    else if (_currentMapLayer == 'googleSat') return TileLayer(key: const ValueKey('sat_layer'), urlTemplate: 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}', maxNativeZoom: 20, maxZoom: 20);
    else return TileLayer(key: const ValueKey('road_layer'), urlTemplate: 'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}', maxNativeZoom: 20, maxZoom: 20);
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1), child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.add_rounded, color: Color(0xFF102A43)))),
          Container(height: 1, width: 20, color: Colors.grey.shade300),
          InkWell(onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1), child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.remove_rounded, color: Color(0xFF102A43)))),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({double height = 100}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300, highlightColor: Colors.grey.shade100,
      child: Container(height: height, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
    );
  }
}

// ==========================================
// WIDGET HỖ TRỢ: HIỆU ỨNG TRÔI LÊN XẾP TẦNG
// ==========================================
class FadeInUp extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const FadeInUp({Key? key, required this.child, required this.delayMs}) : super(key: key);

  @override
  _FadeInUpState createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(opacity: _opacityAnim, child: widget.child),
    );
  }
}