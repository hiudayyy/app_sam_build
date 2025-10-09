import 'dart:convert';
import 'dart:io';

import 'package:csam_mobile/api/api_option.dart';
import 'package:csam_mobile/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api.dart';
import '../models/option_model.dart';

class AddPlantScreen extends StatefulWidget {
  final Function(Map<String, dynamic>, List<File?>) onSubmit;
  final VoidCallback onCancel;
  final String? gridPosition;
  final int? losamId;
  final String? areaId;
  final CaySamModel? caysam;
  final String? EditNhatKy;

  const AddPlantScreen({
    Key? key,
    required this.onSubmit,
    required this.onCancel,
    this.gridPosition,
    this.losamId,
    this.areaId,
    this.caysam,
    this.EditNhatKy,
  }) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _maCayController = TextEditingController();
  final _tenCayController = TextEditingController();
  final _loaiCayController = TextEditingController();
  final _viTriController = TextEditingController();
  final _gridPositionController = TextEditingController();
  final _soLaController = TextEditingController();
    String? _tuoicay;
  String? _diemSucKhoe;
  String? _tinhTrang;
    int? _sola;
  File? _selectedImageTQ;
  File? _selectedImageCT;
  String? _selectedImageTQUrl;
  String? _selectedImageCTUrl;
  final ImagePicker _picker = ImagePicker();
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoSamTinhTrang = [];
  List<OptionModel> OptionLoSamDiemSucKhoe = [];

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _initializeData();
  }
  void _removeImageTQ() {
    setState(() {
      _selectedImageTQ = null;
      _selectedImageTQUrl = null; // xóa luôn URL nếu muốn
    });
  }
  void _removeImageCT() {
    setState(() {
      _selectedImageCT = null;
      _selectedImageCTUrl = null; // xóa luôn URL nếu có
    });
  }
  Future<void> _showImagePickerDialogTQ() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoTQ();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageTQ();
                },
              ),
              if (_selectedImageTQ != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImageTQ();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _showImagePickerDialogCT() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoCT();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageCT();
                },
              ),
              if (_selectedImageCT != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImageCT();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _pickImageTQ() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageTQ = File(image.path);
          _selectedImageTQUrl = null; // reset URL
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<File> base64ToFile(String base64Str, String filename) async {
    final bytes = base64Decode(base64Str);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
  Future<void> _takePhotoTQ() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageTQ = File(image.path);
          _selectedImageTQUrl = null; // reset URL
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chụp ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> _pickImageCT() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageCT = File(image.path);
          _selectedImageCTUrl = null; // reset URL để hiển thị ảnh mới
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhotoCT() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageCT = File(image.path);
          _selectedImageCTUrl = null; // reset URL để hiển thị ảnh mới
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chụp ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  void _initializeFields() {
    // Auto-fill grid position
    if (widget.gridPosition != null) {
      _gridPositionController.text = widget.gridPosition!;
    }

    // Auto-generate mã cây sâm: areaId_gridPosition
    if (widget.areaId != null && widget.gridPosition != null) {
      _maCayController.text = '${widget.areaId}_${widget.gridPosition}';
    }

    // Auto-fill vị trí with area name and grid position
    if (widget.gridPosition != null) {
      _viTriController.text = '${widget.gridPosition}';
    }

    // Default values
    _loaiCayController.text = 'Panax vietnamensis';
    _tenCayController.text = 'Sâm Ngọc Linh';
  }
  Future<void> _initializeData() async {
    // Calculate plant statistics

    final api = API();
    final apiOptinlt = await api.OptionLoSamLoaiTuoi();
    if (apiOptinlt != null) {
      setState(() {
        OptionLoSamLoaiTuoi = apiOptinlt;
      });
    }
    final apiOptintt = await api.OptionLoSamTinhTrang();
    if (apiOptintt != null) {
      setState(() {
        OptionLoSamTinhTrang = apiOptintt;
      });
    }
    final apiOptindsk = await api.OptionLoSamDiemSucKhoe();
    if (apiOptindsk != null) {
      setState(() {
        OptionLoSamDiemSucKhoe = apiOptindsk;
      });
    }
    _tuoicay = widget.caysam?.tuoiCayId.toString() ?? "";
    if(widget.caysam != null && widget.EditNhatKy == null){
      _viTriController.text = widget.caysam?.viTriTrongLo ?? "";
      _maCayController.text = widget.caysam?.maCaySam ?? "";
      _soLaController.text = widget.caysam?.caySamNhatKys.first?.soLa.toString() ?? "";
      _diemSucKhoe = widget.caysam?.caySamNhatKys.first?.diemSucKhoe.toString() ?? "";
      _tinhTrang = widget.caysam?.caySamNhatKys.first?.tinhTrang.toString() ?? "";
      final hinhTQ = widget.caysam?.caySamNhatKys.first?.hinhAnhTongQuan;
      final hinhCT = widget.caysam?.caySamNhatKys.first?.hinhAnhChiTiet;
      if (hinhTQ != null) {
        if (hinhTQ.startsWith('http')) {
          _selectedImageTQUrl = hinhTQ;   // URL từ server
          _selectedImageTQ = null;
        } else {
          _selectedImageTQ = await base64ToFile(hinhTQ, "anh_tq.jpg"); // base64
          _selectedImageTQUrl = null;
        }
      }

      // Ảnh chi tiết
      if (hinhCT != null) {
        if (hinhCT.startsWith('http')) {
          _selectedImageCTUrl = hinhCT;
          _selectedImageCT = null;
        } else {
          _selectedImageCT = await base64ToFile(hinhCT, "anh_ct.jpg");
          _selectedImageCTUrl = null;
        }
      }
/*      _selectedImageCT = widget.caysam?.caySamNhatKys.first?.hinhAnhChiTiet != null
          ? File(widget.caysam!.caySamNhatKys.first!.hinhAnhChiTiet!)
          : null;*/
    }
  }
  @override
  void dispose() {
    _maCayController.dispose();
    _tenCayController.dispose();
    _loaiCayController.dispose();
    _viTriController.dispose();
    _gridPositionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final plantData = {
        "CaySam": {
          "LoSam_ID": widget.losamId,
          "ViTriTrongLo": _viTriController.text,
          "MaCaySam": _maCayController.text,
          "TuoiCay_ID": int.parse(_tuoicay ?? "")
        },
        "CaySamNhatKy": {
          "NgayGhi": DateTime.now().toIso8601String(),
          "SoLa": int.parse(_soLaController.text ?? ""),
          "DiemSucKhoe": int.parse(_diemSucKhoe ?? ""),
          "TinhTrang":  int.parse(_tinhTrang ?? "")
        },
      };
      widget.onSubmit(
        plantData,
        [_selectedImageTQ, _selectedImageCT],
      );
    }
  }
  void _handleSubmitnk() {
    if (_formKey.currentState!.validate()) {
      final plantData = {
          "TuoiId": int.parse(_tuoicay ?? ""),
          "HinhAnh": true,
        "CaySamNhatKy": {
          "NgayGhi": DateTime.now().toIso8601String(),
          "SoLa": int.parse(_soLaController.text ?? ""),
          "DiemSucKhoe": int.parse(_diemSucKhoe ?? ""),
          "TinhTrang":  int.parse(_tinhTrang ?? "")
        },
      };
      widget.onSubmit(
        plantData,
        [_selectedImageTQ, _selectedImageCT],
      );
    }
  }
  void _handleSubmitnktm() {
    if (_formKey.currentState!.validate()) {
      final plantData = {
          "CaySamId": widget.caysam?.caySamId,
          "NgayGhi": DateTime.now().toIso8601String(),
          "SoLa": int.parse(_soLaController.text ?? ""),
          "DiemSucKhoe": int.parse(_diemSucKhoe ?? ""),
          "TinhTrang":  int.parse(_tinhTrang ?? "")
        };
      widget.onSubmit(
        plantData,
        [_selectedImageTQ, _selectedImageCT],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
              () {
            // Nếu chưa có cây
            if (widget.caysam == null) {
              return 'Thêm cây mới${widget.gridPosition != null ? ' - Ô ${widget.gridPosition}' : ''}';
            }
              if (widget.EditNhatKy == null) {
                return "Cập nhật nhật ký";
              }
            return 'Thêm mới nhật ký${widget.gridPosition != null ? ' - Ô ${widget.gridPosition}' : ''}';
          }(),
        ),
        backgroundColor: widget.caysam != null ? Colors.blue.shade600:Colors.green.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mã cây sâm (readonly)
                TextFormField(
                  controller: _maCayController,
                  decoration: InputDecoration(
                    labelText: 'Mã cây sâm',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.lock, color: Colors.grey),
                    helperText: 'Mã tự động: {mã_lô}_{vị_trí_ô}',
                  ),
                  readOnly: true,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),

                // Vị trí trong lô (readonly)
                TextFormField(
                  controller: _gridPositionController,
                  decoration: InputDecoration(
                    labelText: 'Vị trí trong lô',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.grid_3x3, color: Colors.grey),
                  ),
                  readOnly: true,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _soLaController,
                  decoration: const InputDecoration(
                    labelText: 'Số lá',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    _sola = int.tryParse(value) ?? 0;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Vui lòng nhập số lá';
                    if (int.tryParse(value) == null) return 'Chỉ được nhập số';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: OptionLoSamLoaiTuoi.any((opt) => opt.value == _tuoicay) ? _tuoicay : null,
                  decoration: const InputDecoration(
                    labelText: 'Tuổi của cây trồng',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timeline),
                  ),
                  items: OptionLoSamLoaiTuoi.map((opt) {
                    IconData icon;
                    switch (opt.value) {
                      case '1':
                        icon = FontAwesomeIcons.seedling;
                        break;
                      case '2':
                        icon = FontAwesomeIcons.leaf;
                        break;
                      case '3':
                        icon = Icons.park;
                        break;
                      case '4':
                        icon = Icons.forest;
                        break;
                      default:
                        icon = Icons.help_outline;
                    }

                    return DropdownMenuItem<String>(
                      value: opt.value,
                      child: Row(
                        children: [
                          Icon(icon, size: 18, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(opt.text),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tuoicay = value!; // ✅ set lại đúng biến
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: OptionLoSamDiemSucKhoe.any((opt) => opt.value == _diemSucKhoe) ? _diemSucKhoe : null,
                  decoration: const InputDecoration(
                    labelText: 'Sức khỏe',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_heart), // icon phù hợp hơn
                  ),
                  items: OptionLoSamDiemSucKhoe.map((opt) {
                    Color color;
                    switch (opt.value) {
                      case '5':
                        color = Colors.green; // rất khỏe
                        break;
                      case '4':
                        color = Colors.blue; // khỏe
                        break;
                      case '3':
                        color = Colors.yellow; // trung bình
                        break;
                      case '2':
                        color = Colors.orange; // yếu
                        break;
                      case '1':
                        color = Colors.red; // rất yếu
                        break;
                      default:
                        color = Colors.grey;
                    }

                    return DropdownMenuItem<String>(
                      value: opt.value,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(opt.text),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _diemSucKhoe = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: OptionLoSamTinhTrang.any((opt) => opt.value == _tinhTrang) ? _tinhTrang : null,
                  decoration: const InputDecoration(
                    labelText: 'Tình Trạng',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment), // icon phù hợp hơn
                  ),
                  items: OptionLoSamTinhTrang.map((opt) {
                    Color color;
                    switch (opt.value) {
                      case '1':
                        color = Colors.green; // rất khỏe
                        break;
                      case '2':
                        color = Colors.blue; // khỏe
                        break;
                      case '3':
                        color = Colors.red; // rất yếu
                        break;
                      default:
                        color = Colors.grey;
                    }

                    return DropdownMenuItem<String>(
                      value: opt.value,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(opt.text),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tinhTrang = value!;
                    });
                  },
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hình ảnh tổng quan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Image Preview
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: _selectedImageTQ != null || _selectedImageTQUrl != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                // Nếu có URL thì ưu tiên hiển thị từ server
                                if (_selectedImageTQUrl != null)
                                  Image.network(
                                    _selectedImageTQUrl!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildErrorImage();
                                    },
                                  )
                                // Nếu có File local thì hiển thị File
                                else if (_selectedImageTQ != null)
                                  Image.file(
                                    _selectedImageTQ!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildErrorImage();
                                    },
                                  ),

                                // Nút xóa ảnh
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _removeImageTQ,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Chưa có hình ảnh',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )

                        ),
                        SizedBox(height: 16),

                        // Upload Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showImagePickerDialogTQ,
                            icon: Icon(Icons.camera_alt),
                            label: Text(_selectedImageTQ != null
                                ? 'Thay đổi ảnh'
                                : 'Chọn ảnh'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        SizedBox(height: 8),
                        Text(
                          'Hỗ trợ định dạng: JPG, PNG, GIF (tối đa 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hình ảnh chi tiết',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Image Preview
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: _selectedImageCT != null || _selectedImageCTUrl != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                // Nếu có URL thì ưu tiên hiển thị từ server
                                if (_selectedImageCTUrl != null)
                                  Image.network(
                                    _selectedImageCTUrl!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildErrorImage();
                                    },
                                  )
                                // Nếu có File local thì hiển thị File
                                else if (_selectedImageCT != null)
                                  Image.file(
                                    _selectedImageCT!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildErrorImage();
                                    },
                                  ),

                                // Nút xóa ảnh
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _removeImageCT,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Chưa có hình ảnh',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                        // Upload Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showImagePickerDialogCT,
                            icon: Icon(Icons.camera_alt),
                            label: Text(_selectedImageCT != null
                                ? 'Thay đổi ảnh'
                                : 'Chọn ảnh'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),

                        SizedBox(height: 8),
                        Text(
                          'Hỗ trợ định dạng: JPG, PNG, GIF (tối đa 5MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        icon: Icon(Icons.close),
                        label: Text('Hủy'),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey),
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.caysam == null) {
                            _handleSubmit();
                          } else {
                            if (widget.EditNhatKy == null) {
                              _handleSubmitnk(); // cập nhật
                            } else {
                              _handleSubmitnktm();
                            }
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: Text(() {
                          if (widget.caysam == null) {
                            return 'Lưu cây mới';
                          }
                            if (widget.EditNhatKy == null) {
                              return 'Cập nhật Nhật ký';
                            }
                          return 'Thêm mới Nhật ký';
                        }()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: () {
                            if (widget.caysam == null) return Colors.green.shade600;
                              if (widget.EditNhatKy == null) {
                                return Colors.blue.shade600; // cập nhật
                              }
                            return Colors.green.shade600; // thêm mới
                          }(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildErrorImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        'Ảnh lỗi',
        style: TextStyle(
          color: Colors.red.shade400,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

}