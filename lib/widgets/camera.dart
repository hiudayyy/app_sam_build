import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:csam_mobile/api/api_camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../api/api.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamcamera_model.dart';

// Camera configuration for PTZ controls
class CameraConfig {
  double angle;      // Góc quay (độ)
  int range;         // Khoảng cách nhìn (số hàng: 1-17)
  double spread;     // Độ rộng góc nhìn (độ)

  CameraConfig({
    this.angle = 0,
    this.range = 8,
    this.spread = 80,
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
  bool isPlaying = true;
  String? urlcamera;
  VideoPlayerController? _controller;
  bool isLoading = false;
  bool _isVideoError = false;
  bool _showControlsOverlay = true;
  Timer? _hideControlsTimer;

  // PTZ & Grid Map
  CameraConfig cameraConfig = CameraConfig();
  double pulseOpacity = 0.25;
  int pulseDirection = 1;
  Timer? pulseTimer;
  final GlobalKey gridMapKey = GlobalKey();

  // Grid configuration - 6 columns x 17 rows
  final List<String> cols = ['A', 'B', 'C', 'D', 'E', 'F'];
  late final int rows = widget.losam?.soHang ?? 0;

  List<String> get leftCols => cols.sublist(0, 3);  // A, B, C
  List<String> get rightCols => cols.sublist(3, 6); // D, E, F

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
  // HÀM MỚI: Bắt đầu đếm ngược để ẩn controls
  void _startHideTimer() {
    // Hủy timer cũ nếu có
    _hideControlsTimer?.cancel();
    // Bắt đầu timer mới, sau 5 giây sẽ tự động ẩn
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControlsOverlay = false;
        });
      }
    });
  }

// HÀM MỚI: Xử lý khi người dùng chạm vào video
  void _toggleControlsOverlay() {
    if (mounted) {
      setState(() {
        // Đảo ngược trạng thái hiển thị
        _showControlsOverlay = !_showControlsOverlay;
        // Nếu controls đang hiển thị, bắt đầu đếm giờ để ẩn đi
        if (_showControlsOverlay) {
          _startHideTimer();
        } else {
          // Nếu người dùng chủ động ẩn, hủy timer
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
  double getRangeInPixels() {
    final RenderBox? renderBox = gridMapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 300.0;
    final gridHeight = renderBox.size.height;
    final rowHeight = gridHeight / rows;
    return cameraConfig.range * rowHeight;
  }

  // PTZ Control
  Future<void> handlePTZ(String action) async {
    // TODO: Gọi API PTZ ở đây
    // await API().controlCameraPTZ(cameraId: selectedCamera.id, action: action);
    print('PTZ command: $action for camera ${selectedCamera?.id}');

    if (mounted) {
      setState(() {
        CameraConfig newConfig = cameraConfig;

        switch (action) {
          case 'left':
            newConfig = newConfig.copyWith(angle: newConfig.angle - 10);
            break;
          case 'right':
            newConfig = newConfig.copyWith(angle: newConfig.angle + 10);
            break;
          case 'up':
            newConfig = newConfig.copyWith(
              range: (newConfig.range + 1).clamp(1, 9),
            );
            break;
          case 'down':
            newConfig = newConfig.copyWith(
              range: (newConfig.range - 1).clamp(1, 9),
            );
            break;
          case 'zoomIn':
            newConfig = newConfig.copyWith(
              spread: (newConfig.spread - 5).clamp(40, 100),
            );
            break;
          case 'zoomOut':
            newConfig = newConfig.copyWith(
              spread: (newConfig.spread + 5).clamp(40, 100),
            );
            break;
          case 'reset':
            newConfig = CameraConfig(angle: 0, range: 8, spread: 80);
            break;
        }

        cameraConfig = newConfig;
      });
    }
  }

  void startVideo() {
    if (urlcamera == null || urlcamera!.isEmpty) return;
    print(urlcamera);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(urlcamera!),
    )..initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller!.play();
      }
    });
  }

  Future<void> _initializeData() async {
    if (widget.cameras.length == 1) {
      setState(() {
        selectedCamera = widget.cameras.first;
        isLoading = true;

      });

      try {
        // TODO: Uncomment khi có API thật
        //
        // if (res != null) {
        //   setState(() {
        //     urlcamera = res.uri;
        //   });
        //   startVideo();
        // }

        // Mock for testing
        final res = await API().startStreamCamera(widget.cameras.first);
        setState(() {
          urlcamera = res?.uri;
        });
        startVideo();
      } catch (e) {
        print("❌ Lỗi startStreamCamera: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
    if(widget.losam != null){
      cameraConfig.range = ((widget.losam!.soHang) / 2).floor();
    }
    _controller = VideoPlayerController.network(urlcamera ?? "")
      ..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isVideoError = true; // ✅ đánh dấu lỗi
          });
        }
      });

    _controller!.addListener(() {
      if (_controller!.value.hasError) {
        setState(() {
          _isVideoError = true;
        });
      }
    });
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

  // WIDGET MỚI: Danh sách camera được thiết kế lại hoàn toàn với giao diện hiện đại
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

                  // ✅ Sử dụng Container để tạo nền gradient cho item được chọn
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
                            setState(() { urlcamera = selectedCamera?.rtsp; });
                            startVideo();
                          } catch (e) {
                            print("❌ Lỗi startStreamCamera: $e");
                          } finally {
                            if (mounted) setState(() => isLoading = false);
                          }
                          _controller = VideoPlayerController.network(urlcamera ?? "")
                            ..initialize().then((_) {
                              if (mounted) setState(() {});
                            }).catchError((error) {
                              if (mounted) {
                                setState(() {
                                  _isVideoError = true; // ✅ đánh dấu lỗi
                                });
                              }
                            });

                          _controller!.addListener(() {
                            if (_controller!.value.hasError) {
                              setState(() {
                                _isVideoError = true;
                              });
                            }
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // ✅ Icon được thiết kế lại với chỉ báo trạng thái chồng lên
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
                                    child: _buildCompactStatusIndicator(camera.trangThai ?? 1),
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

                const SizedBox(height: 16),

                // --- Video Player & Controls ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      color: Colors.black,
                      // Bọc Stack bằng GestureDetector để bắt sự kiện chạm
                      child: GestureDetector(
                        onTap: _toggleControlsOverlay,
                        child: Stack(
                          children: [
                            // Video Player hoặc thông báo Lỗi/Loading luôn ở giữa
                            Center(child: _buildVideoPlayer()),

                            // Dùng AnimatedOpacity để tạo hiệu ứng mờ dần cho toàn bộ controls
                            AnimatedOpacity(
                              opacity: _showControlsOverlay && isVideoReady ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              // IgnorePointer ngăn người dùng tương tác với controls khi chúng bị ẩn
                              child: IgnorePointer(
                                ignoring: !(_showControlsOverlay && isVideoReady),
                                child: Stack(
                                  children: [
                                    // Lớp nền mờ để controls nổi bật hơn
                                    Container(color: Colors.black.withOpacity(0.2)),
                                    // Thông tin camera (dưới, trái)
                                    Positioned(
                                      bottom: 12,
                                      left: 12,
                                      child: _buildRedesignedCameraInfo(),
                                    ),
                                    // PTZ Controls (giữa, phải)
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridColumn(List<String> columns) {
    // Tính toán cell height chính xác để không overflow
    final cellHeight = 27.0; // Giảm từ 28 xuống 27 để tránh overflow

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
  // Widget này giờ chỉ phục vụ một mục đích: thông báo khi không có camera nào
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
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.zoom_out_map, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              'Tầm xa: ${cameraConfig.range}/$rows hàng',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.open_in_full_outlined, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              'Độ rộng: ${cameraConfig.spread.toStringAsFixed(0)}°',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ]),
        ],
      ),
    );
  }
}

// Custom painter for camera cone
class CameraConePainter extends CustomPainter {
  final double angle;
  final double range;
  final double spread;
  final double pulseOpacity;
  final double? containerWidth;

  CameraConePainter({
    required this.angle,
    required this.range,
    required this.spread,
    required this.pulseOpacity,
    this.containerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Camera position ở giữa container
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);

    // Giới hạn range tối đa 80% chiều cao
    final maxRange = math.min(range, size.height * 0.8);

    final paint = Paint()
      ..color = Colors.blue.withOpacity(pulseOpacity)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final angleRad = angle * math.pi / 180;
    final startAngle = angleRad - (spread / 2) * math.pi / 180;
    final endAngle = angleRad + (spread / 2) * math.pi / 180;

    final path = Path();
    path.moveTo(centerX, centerY);

    for (int i = 0; i <= 30; i++) {
      final t = startAngle + (i / 30) * (endAngle - startAngle);
      final x = centerX + maxRange * math.sin(t);
      final y = centerY - maxRange * math.cos(t);
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
