import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:csam_mobile/api/api_camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../api/api.dart';
import '../models/camera.dart';
import '../models/kttoken.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamcamera_model.dart';

class CameraConfig {
  double angle;
  int range;
  double spread;

  CameraConfig({
    this.angle = 0,
    this.range = 0,
    this.spread = 0,
  });

  CameraConfig copyWith({
    double? angle,
    int? range,
    double? spread,
  }) {
    return CameraConfig(
      angle: angle ?? this.angle,
      range: range ?? this.range,
      spread: spread ?? this.spread,
    );
  }
}

class CameraViewWithGrid extends StatefulWidget {
  final List<LoSamCameraModel> cameras; // LoSamCameraModel
  final LoSamModel? losam;

  const CameraViewWithGrid({
    Key? key,
    required this.cameras,
    required this.losam,
  }) : super(key: key);

  @override
  _CameraViewWithGridState createState() => _CameraViewWithGridState();
}

class _CameraViewWithGridState extends State<CameraViewWithGrid> with SingleTickerProviderStateMixin {
  LoSamCameraModel? selectedCamera;
  CameraStreamResponse? resCamera;
  bool isPlaying = true;
  String? urlcamera;
  VideoPlayerController? _controller;
  bool isLoading = false;
  bool _isVideoError = false;
  bool _showControlsOverlay = true;
  Timer? _hideControlsTimer;
  Kttoken? user;

  // PTZ & Grid Map
  CameraConfig cameraConfig = CameraConfig();
  double pulseOpacity = 0.25;
  int pulseDirection = 1;
  Timer? pulseTimer;
  final GlobalKey gridMapKey = GlobalKey();

  final List<String> cols = ['A', 'B', 'C', 'D', 'E', 'F'];
  late final int rows = widget.losam?.soHang ?? 0;

  List<String> get leftCols => cols.sublist(0, 3);
  List<String> get rightCols => cols.sublist(3, 6);

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startPulseAnimation();
  }

  @override
  void dispose() {
    _controller?.dispose();
    pulseTimer?.cancel();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControlsOverlay = false;
        });
      }
    });
  }
  Future<void> handlePTZ(String action) async {
    await MoveCamera(action);
  }

  double getRangeInPixels() {
    return cameraConfig.range.toDouble();
  }
  void _toggleControlsOverlay() {
    if (mounted) {
      setState(() {
        _showControlsOverlay = !_showControlsOverlay;
        if (_showControlsOverlay) {
          _startHideTimer();
        } else {
          _hideControlsTimer?.cancel();
        }
      });
    }
  }
  void _startPulseAnimation() {
    pulseTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          pulseOpacity += 0.05 * pulseDirection;
          if (pulseOpacity >= 0.4) {
            pulseDirection = -1;
          } else if (pulseOpacity <= 0.1) {
            pulseDirection = 1;
          }
        });
      }
    });
  }

  // Convert range (số hàng) sang pixels dựa trên chiều cao grid map
  // double getRangeInPixels() {
  //   final RenderBox? renderBox = gridMapKey.currentContext?.findRenderObject() as RenderBox?;
  //   if (renderBox == null) return 300.0;
  //   final gridHeight = renderBox.size.height;
  //   final rowHeight = gridHeight / rows;
  //   return cameraConfig.range * rowHeight;
  // }
  //
  // // PTZ Control
  // Future<void> handlePTZ(String action) async {
  //   print('PTZ command: $action for camera ${selectedCamera?.id}');
  //
  //   if (mounted) {
  //     setState(() {
  //       CameraConfig newConfig = cameraConfig;
  //
  //       switch (action) {
  //         case 'left':
  //           MoveCamera("left");
  //           newConfig = newConfig.copyWith(angle: newConfig.angle - 15);
  //           break;
  //         case 'right':
  //           MoveCamera("right");
  //           newConfig = newConfig.copyWith(angle: newConfig.angle + 15);
  //           break;
  //         case 'up':
  //           MoveCamera("up");
  //           newConfig = newConfig.copyWith(
  //             range: (newConfig.range + 1).clamp(1, 9),
  //           );
  //           break;
  //         case 'down':
  //           MoveCamera("down");
  //           newConfig = newConfig.copyWith(
  //             range: (newConfig.range - 1).clamp(1, 9),
  //           );
  //           break;
  //         case 'zoomIn':
  //           MoveCamera("zoomIn");
  //           newConfig = newConfig.copyWith(
  //             spread: (newConfig.spread - 5).clamp(40, 100),
  //           );
  //           break;
  //         case 'zoomOut':
  //           MoveCamera("zoomOut");
  //           newConfig = newConfig.copyWith(
  //             spread: (newConfig.spread + 5).clamp(40, 100),
  //           );
  //           break;
  //         case 'reset':
  //           MoveCamera("reset");
  //           newConfig = CameraConfig(angle: 0, range: 8, spread: 80);
  //           break;
  //       }
  //
  //       cameraConfig = newConfig;
  //     });
  //   }
  // }

  void startVideo() {
    if (urlcamera == null || urlcamera!.isEmpty) {
      print("URL camera rỗng, không thể bắt đầu.");
      setState(() {
        _isVideoError = true;
      });
      return;
    }

    print("Bắt đầu video với URL: $urlcamera");

    // 1. Tạo controller MỚI
    final newController = VideoPlayerController.networkUrl(
      Uri.parse(urlcamera!),
    );

    // 2. Thêm trình lắng nghe LỖI vào nó
    newController.addListener(() {
      if (newController.value.hasError) {
        if (mounted) {
          setState(() {
            _isVideoError = true;
          });
          print("Lỗi VideoPlayer: ${newController.value.errorDescription}");
        }
      }
    });

    // 3. Khởi tạo và phát
    newController.initialize().then((_) {
      if (mounted) {
        print("Video đã khởi tạo thành công.");
        setState(() {
          _controller = newController;
          _controller!.play();
          _isVideoError = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isVideoError = true;
        });
        print("Lỗi khi initialize video: $error");
      }
    });
  }

  // Dòng 220, thay thế hàm _initializeData() cũ
  Future<void> _initializeData() async {
    if (widget.cameras.length == 1) {
      setState(() {
        selectedCamera = widget.cameras.first;
        isLoading = true;
        _isVideoError = false; // Reset trạng thái lỗi
      });

      try {
        resCamera = await API().startStreamCamera(widget.cameras.first);
        if (mounted) {
          setState(() {
            urlcamera = resCamera?.uri;
            var state = resCamera?.cameraState;
            if (state != null) {
              cameraConfig = CameraConfig(
                angle: (state.angle ?? 0).toDouble(),
                range: (state.range ?? 120).toInt(),
                spread: (state.spread ?? 80).toDouble(),
              );
            }
          });
          print("🔍 API Response -  | Angle: ${cameraConfig.angle} | Range: ${cameraConfig.range} | Spread: ${cameraConfig.spread}");
          startVideo();
        }
      } catch (e) {
        print("❌ Lỗi startStreamCamera: $e");
        if (mounted) setState(() => _isVideoError = true);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }

    // if (widget.losam != null) {
    //   cameraConfig.range = ((widget.losam!.soHang) / 2).floor();
    // }
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
  }
  Future<void> StartCamera(String actionCamera) async {
    if (widget.cameras.length > 1) {
      resCamera = await API().startStreamCamera(selectedCamera!);
    }
      try {
        setState(() {
          urlcamera = resCamera?.uri;
          var state = resCamera?.cameraState;
          if (state != null) {
            cameraConfig = CameraConfig(
              angle: (state.angle ?? 0).toDouble(),
              range: (state.range ?? 120).toInt(),
              spread: (state.spread ?? 80).toDouble(),
            );
          }
        });
        startVideo();

      } catch (e) {
        print("❌ Lỗi startStreamCamera: $e");
        if (mounted) setState(() => _isVideoError = true);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }


  }
  Future<void> MoveCamera(String actionCamera) async {
    try {
      if (selectedCamera != null) {
        selectedCamera?.action = actionCamera;
      }
      final dynamic res = await API().MoveStreamCamera(selectedCamera!);

      if (res != null && mounted) {
        setState(() {
          double newAngle = res is Map ? (res['angle'] ?? cameraConfig.angle).toDouble() : (res.angle ?? cameraConfig.angle).toDouble();
          int newRange = res is Map ? (res['range'] ?? cameraConfig.range).toInt() : (res.range ?? cameraConfig.range).toInt();
          double newSpread = res is Map ? (res['spread'] ?? cameraConfig.spread).toDouble() : (res.spread ?? cameraConfig.spread).toDouble();

          cameraConfig = cameraConfig.copyWith(
            angle: newAngle,
            range: newRange,
            spread: newSpread,
          );
        });
        print("🔍 API Response - Action: $actionCamera | Angle: ${cameraConfig.angle} | Range: ${cameraConfig.range} | Spread: ${cameraConfig.spread}");
      }
    } catch (e) {
      print("❌ Lỗi MoveStreamCamera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showList = widget.cameras.length > 1 && selectedCamera == null;
    const double listWidth = 320; // Chiều rộng cố định cho danh sách camera

    return Scaffold(
      appBar: AppBar(
        title: Text('Camera giám sát - ${widget.losam?.tenLo ?? ""}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : selectedCamera != null
                ? _buildCameraViewWithGrid(selectedCamera!)
                : widget.cameras.isEmpty
                ? _buildNoCameraSelected()
                : Container(),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 0,
            bottom: 0,

            left: showList ? 0 : -listWidth,
            width: listWidth,
            child: _buildCameraListOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraListOverlay() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Chọn Camera',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: widget.cameras.length,
                itemBuilder: (context, index) {
                  final camera = widget.cameras[index];
                  final isSelected = selectedCamera?.id == camera.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: isSelected
                          ? LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.grey.shade100,
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          setState(() {
                            selectedCamera = camera;
                            isLoading = true;
                            _isVideoError = false;
                            _controller?.dispose();
                            _controller = null;
                          });

                          try {
                            // setState(() {
                            //   urlcamera = selectedCamera?.rtsp;
                            // });
                            StartCamera("");
                          } catch (e) {
                            print("❌ Lỗi startStreamCamera: $e");
                            if (mounted) setState(() => _isVideoError = true);
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : Colors.white,
                                    child: Icon(
                                      Icons.videocam_rounded,
                                      color: isSelected ? Colors.white : Colors.green.shade700,
                                      size: 26,
                                    ),
                                  ),
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: _buildCompactStatusIndicator(camera.trangThai ?? 0),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      camera.loSamLoaiCamera?.ten ?? "Camera không tên",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Vị trí: ${camera.loSam ?? "Chưa rõ"}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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


  Widget _buildCompactStatusIndicator(int status) {
    final isOnline = status == 0;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOnline ? Colors.greenAccent.shade400 : Colors.redAccent,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? Colors.greenAccent.shade400 : Colors.redAccent).withOpacity(0.6),
            blurRadius: 5,
          )
        ],
      ),
    );
  }

  Widget _buildCameraViewWithGrid(LoSamCameraModel camera) {
    final isVideoReady = _controller != null && _controller!.value.isInitialized && !_isVideoError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Giám sát & Điều khiển",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [


                // --- Video Player & Controls ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      color: Colors.black,
                      child: GestureDetector(
                        onTap: _toggleControlsOverlay,
                        child: Stack(
                          children: [
                            Center(child: _buildVideoPlayer()),
                            AnimatedOpacity(
                              opacity: _showControlsOverlay && isVideoReady ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: IgnorePointer(
                                ignoring: !(_showControlsOverlay && isVideoReady),
                                child: Stack(
                                  children: [
                                    Container(color: Colors.black.withOpacity(0.2)),
                                    if(user!.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>
                                    pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin"))
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      child: _buildRedesignedCameraInfo(),
                                    ),
                                    if(user!.htTaiKhoan.htPhanQuyenTaiKhoans.any((pq) =>
                                    pq.maVaiTro != "nft_invester" && pq.maVaiTro == "nft_admin"))
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      right: 12,
                                      child: _buildRedesignedPTZControls(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.map_outlined, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              "Sơ đồ Lô Sâm",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100]),
                        padding: const EdgeInsets.all(8),
                        height: (rows * 27.0) + 16,
                        child: Stack(
                          key: gridMapKey,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildGridColumn(leftCols)),
                                Container(width: 30, color: Colors.grey[300]),
                                Expanded(child: _buildGridColumn(rightCols)),
                              ],
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: CameraConePainter(
                                  angle: cameraConfig.angle,
                                  range: getRangeInPixels(),
                                  spread: cameraConfig.spread,
                                  pulseOpacity: pulseOpacity,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: ((rows * 27.0) / 2) - 8,
                              child: Center(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [Colors.red, Colors.red.shade900],
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridColumn(List<String> columns) {
    final cellHeight = 27.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(columns.length, (c) {
            final col = columns[c];
            return Expanded(
              child: Container(
                height: cellHeight,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  border: Border.all(color: Colors.grey[600]!, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    '$col${r + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isVideoError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text("Không thể phát video", style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullscreenVideoPage(controller: _controller!),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          SizedBox(height: 8),
          Text("Đang tải video...", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
  Widget _buildNoCameraSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Không có camera khả dụng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Khu vực này chưa được lắp đặt camera giám sát.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildRedesignedPTZControls() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Zoom controls
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularPTZButton(Icons.zoom_in, () => handlePTZ('zoomIn')),
                const SizedBox(height: 8),
                const Text("ZOOM", style: TextStyle(color: Colors.white70, fontSize: 10)),
                const SizedBox(height: 8),
                _buildCircularPTZButton(Icons.zoom_out, () => handlePTZ('zoomOut')),
              ],
            ),

            const SizedBox(width: 16),

            // D-Pad for movement
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularPTZButton(Icons.keyboard_arrow_up, () => handlePTZ('up')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCircularPTZButton(Icons.keyboard_arrow_left, () => handlePTZ('left')),
                    const SizedBox(width: 8),
                    _buildCircularPTZButton(Icons.settings_backup_restore, () => handlePTZ('reset'), isCenter: true),
                    const SizedBox(width: 8),
                    _buildCircularPTZButton(Icons.keyboard_arrow_right, () => handlePTZ('right')),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCircularPTZButton(Icons.keyboard_arrow_down, () => handlePTZ('down')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularPTZButton(IconData icon, VoidCallback onPressed, {bool isCenter = false}) {
    return CircleAvatar(
      radius: isCenter ? 22 : 25,
      backgroundColor: isCenter ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.2),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        iconSize: isCenter ? 20 : 28,
        onPressed: onPressed,
      ),
    );
  }

// GIAO DIỆN MỚI: Bảng thông tin camera được thiết kế lại
  Widget _buildRedesignedCameraInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCamera?.loSamLoaiCamera?.ten ?? "Camera",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Divider(color: Colors.white24, height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.rotate_90_degrees_ccw, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              'Góc quay: ${cameraConfig.angle.toStringAsFixed(0)}°',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ]),
          // const SizedBox(height: 4),
          // Row(mainAxisSize: MainAxisSize.min, children: [
          //   const Icon(Icons.zoom_out_map, size: 14, color: Colors.white70),
          //   const SizedBox(width: 6),
          //   Text(
          //     'Tầm xa: ${cameraConfig.range}/$rows hàng',
          //     style: const TextStyle(color: Colors.white, fontSize: 12),
          //   ),
          // ]),
          // const SizedBox(height: 4),
          // Row(mainAxisSize: MainAxisSize.min, children: [
          //   const Icon(Icons.open_in_full_outlined, size: 14, color: Colors.white70),
          //   const SizedBox(width: 6),
          //   Text(
          //     'Độ rộng: ${cameraConfig.spread.toStringAsFixed(0)}°',
          //     style: const TextStyle(color: Colors.white, fontSize: 12),
          //   ),
          // ]),
        ],
      ),
    );
  }
}

class CameraConePainter extends CustomPainter {
  final double angle;       // API: angle
  final double range;       // API: range (dùng làm bán kính pixel)
  final double spread;      // API: spread
  final double pulseOpacity;

  CameraConePainter({
    required this.angle,
    required this.range,
    required this.spread,
    required this.pulseOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = range;

    final paint = Paint()
      ..color = Colors.green.withOpacity(pulseOpacity) // Web dùng màu xanh/pulse
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Chuyển đổi độ sang radian
    final angleRad = angle * math.pi / 180;
    final spreadRad = spread * math.pi / 180;

    // Tính góc bắt đầu và kết thúc
    final startAngle = angleRad - (spreadRad / 2);
    final endAngle = angleRad + (spreadRad / 2);

    final path = Path();
    path.moveTo(centerX, centerY); // Bắt đầu từ tâm

    // Vẽ cung tròn mô phỏng (40 bước để mịn như web)
    for (int i = 0; i <= 40; i++) {
      final t = startAngle + (i / 40) * (endAngle - startAngle);

      final x = centerX + radius * math.sin(t);
      final y = centerY - radius * math.cos(t);

      path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(CameraConePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.range != range ||
        oldDelegate.spread != spread ||
        oldDelegate.pulseOpacity != pulseOpacity;
  }
}
class FullscreenVideoPage extends StatelessWidget {
  final VideoPlayerController controller;

  const FullscreenVideoPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned(
            top: 32,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

}
