import 'package:csam_mobile/api/api_caysam.dart';
import 'package:csam_mobile/api/api_option.dart';
import 'package:csam_mobile/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../api/api.dart';
import '../models/cay_sam.dart';
import '../models/option_model.dart';

class BatchPlantUpdateScreen extends StatefulWidget {
  final List<String> selectedPositions;
  final List<CaySamModel> caysam;
  final String areaId;
  final String areaName;

  const BatchPlantUpdateScreen({
    Key? key,
    required this.selectedPositions,
    required this.caysam,
    required this.areaId,
    required this.areaName,
  }) : super(key: key);

  @override
  State<BatchPlantUpdateScreen> createState() => _BatchPlantUpdateScreenState();
}

class _BatchPlantUpdateScreenState extends State<BatchPlantUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  final ImagePicker _picker = ImagePicker();

// Common data for all plants
  DateTime? _selectedDate;
  int _soLa = 0;
  double _diemSucKhoe = 5.0;
  String? _tinhTrang;

// Individual plant data
  Map<String, PlantData> _plantsData = {};

// UI State
  int _currentStep = 0;
  bool _isLoading = false;
  String _selectedLoSamId = '';
  String _selectedTuoiCayId = '';
  List<OptionModel> OptionLoSamTinhTrang = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _initializePlantsData();
    _initializeData();
  }

  void _initializePlantsData() {
    for (String position in widget.selectedPositions) {
      _plantsData[position] = PlantData(
        position: position,
        maCaySam: 'SAM-${position}-${DateTime.now().millisecondsSinceEpoch}',
        loSamId: '',
        tuoiCayId: '',
      );
    }

  }
  Future<void> _initializeData() async {
    final api = API();
    final apiOptintt = await api.OptionLoSamTinhTrang();
    if (apiOptintt != null) {
      setState(() {
        OptionLoSamTinhTrang = apiOptintt;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Expanded(
                child: _buildContent(),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.eco,
              color: Colors.green.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cập nhật hàng loạt - ${widget.selectedPositions.length} cây',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Khu vực: ${widget.areaName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStep1CommonData(),
        _buildStep2IndividualData(),
        _buildStep3Summary(),
      ],
    );
  }

  Widget _buildStep1CommonData() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Step indicator
            _buildStepIndicator(0),
            const SizedBox(height: 24),

// Summary panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Thông tin chung',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Khu vực: ${widget.areaName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      Text(
                        'Số lượng: ${widget.selectedPositions.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vị trí: ${widget.selectedPositions.take(5).join(', ')}${widget.selectedPositions.length > 5 ? '...' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// Date field
            InkWell(
              onTap: _selectDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Ngày ghi',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Chọn ngày',
                ),
              ),
            ),

            const SizedBox(height: 16),

// Số lá field
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Số lá',
                prefixIcon: Icon(Icons.eco),
                border: OutlineInputBorder(),
                helperText: 'Số lượng lá trên cây',
              ),
              keyboardType: TextInputType.number,
              initialValue: _soLa.toString(),
              onChanged: (value) {
                setState(() {
                  _soLa = int.tryParse(value) ?? 0;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số lá';
                }
                if (int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'Số lá phải là số dương';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

// Điểm sức khỏe field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điểm sức khỏe: ${_diemSucKhoe.toInt()}/5',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                ),
                child: Slider(
                  value: _diemSucKhoe,
                  min: 1,
                  max: 5,            // ✅ Giới hạn tối đa là 5
                  divisions: 4,      // ✅ 4 vạch chia → 5 giá trị
                  activeColor: _getHealthColor(_diemSucKhoe),
                  onChanged: (value) {
                    setState(() {
                      _diemSucKhoe = value;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1', style: TextStyle(color: Colors.grey.shade600)),
                  Text('3', style: TextStyle(color: Colors.grey.shade600)),
                  Text('5', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

// Tình trạng field
            DropdownButtonFormField<String>(
              value: _tinhTrang,
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
          ],
        ),
      ),
    );
  }

  Widget _buildStep2IndividualData() {
    return Column(
      children: [
// Step indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildStepIndicator(1),
        ),

// Instructions
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cập nhật thông tin riêng cho từng cây',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

// Plant list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.selectedPositions.length,
            itemBuilder: (context, index) {
              final position = widget.selectedPositions[index];
              final plantData = _plantsData[position]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
// Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              position,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              plantData.maCaySam,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

// Image upload section
                      Row(
                        children: [
                          Expanded(
                            child: _buildImageUploadCard(
                              position,
                              'general',
                              'Ảnh tổng quan',
                              plantData.generalImage,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildImageUploadCard(
                              position,
                              'detail',
                              'Ảnh chi tiết',
                              plantData.detailImage,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Summary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(2),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.red.shade50],
              ),
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Xác nhận thông tin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Kiểm tra lại thông tin trước khi lưu',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

// Common data summary
          _buildSummarySection(
            'Thông tin chung (${widget.selectedPositions.length} cây)',
            [
              'Ngày ghi: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              'Số lá: $_soLa',
              'Điểm sức khỏe: ${_diemSucKhoe.toInt()}/5',
              'Tình trạng: $_tinhTrang',
            ],
          ),

          const SizedBox(height: 16),

// Individual data summary
          _buildSummarySection(
            'Hình ảnh đã upload',
            widget.selectedPositions.map((position) {
              final plantData = _plantsData[position]!;
              final generalCount = plantData.generalImage != null ? 1 : 0;
              final detailCount = plantData.detailImage != null ? 1 : 0;
              return '$position: ${generalCount + detailCount} ảnh';
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check,
                              color: Colors.green.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: i <= currentStep ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                  color: i <= currentStep ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (i < 2) ...[
            Expanded(
              child: Container(
                height: 2,
                color: i < currentStep ? Colors.green : Colors.grey.shade300,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildImageUploadCard(
      String position,
      String imageType,
      String title,
      File? imageFile,
      ) {
    return InkWell(
      onTap: () => _uploadImage(position, imageType),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: imageFile != null
            ? Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(position, imageType),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo,
                color: Colors.grey.shade400, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<File> getAllImagesInOrder() {
    final List<File> images = [];

    for (final pos in widget.selectedPositions) {
      final plantData = _plantsData[pos]!;

      if (plantData.generalImage == null || plantData.detailImage == null) {
        throw Exception("⚠️ Vị trí $pos chưa đủ ảnh");
      }

      images.add(plantData.generalImage!);
      images.add(plantData.detailImage!);
    }

    return images;
  }
  List<String> getOrderedCaySamIds(
      List<CaySamModel> caySamList,
      List<String> selectedPositions,
      ) {
    final List<String> orderedIds = [];

    for (final pos in selectedPositions) {
      final matchedList =
      caySamList.where((c) => c.viTriTrongLo == pos).toList();

      if (matchedList.isNotEmpty) {
        orderedIds.add(matchedList.first.caySamId);
      }
    }

    return orderedIds;
  }

  bool validateAllImages() {
    for (final pos in widget.selectedPositions) {
      final plantData = _plantsData[pos]!;
      if (plantData.generalImage == null || plantData.detailImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ Vị trí $pos chưa đủ ảnh (cần Ảnh tổng quan và Ảnh chi tiết)"),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Quay lại'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_getButtonText()),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Tiếp theo';
      case 1:
        return 'Xem tóm tắt';
      case 2:
        return 'Lưu (${widget.selectedPositions.length})';
      default:
        return 'Tiếp theo';
    }
  }

  Color _getHealthColor(double health) {
    if (health >= 4) return Colors.green;
    if (health >= 3) return Colors.orange;
    return Colors.red;
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _uploadImage(String position, String imageType) async {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text("Chụp ảnh"),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: const Text("Chọn từ thư viện"),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked != null && _plantsData[position] != null) {
        setState(() {
          final file = File(picked.path);
          if (imageType == 'general') {
            _plantsData[position]!.generalImage = file;
          } else {
            _plantsData[position]!.detailImage = file;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 Đã thêm ảnh $imageType cho vị trí $position'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(String position, String imageType) {
    setState(() {
      if (imageType == 'general') {
        _plantsData[position]!.generalImage = null;
      } else {
        _plantsData[position]!.detailImage = null;
      }
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleNextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && !_formKey.currentState!.validate()) {
        return;
      }

      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm();
    }
  }

  void _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
// Prepare update data
      if (!validateAllImages()) return;

      final images = getAllImagesInOrder();
      final ids = getOrderedCaySamIds(widget.caysam, widget.selectedPositions);
      final updateData = {
        'Ids': ids,
        'NgayGhi': _selectedDate!.toIso8601String(),
        'SoLa': _soLa,
        'DiemSucKhoe': _diemSucKhoe.toInt(),
        'TinhTrang': int.parse(_tinhTrang ?? ""),
      };
      final apiResponse = await API().addNhatKys(
        data: updateData,
        files: images,
      );

// Show success message
      if (mounted) {
        if (apiResponse != null && apiResponse.message == "OK"){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🌱 Đã cập nhật ${widget.selectedPositions.length} cây thành công!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(updateData);
        }else{
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi cập nhật API: ${apiResponse?.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }

      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class PlantData {
  final String position;
  final String maCaySam;
  String loSamId;
  String tuoiCayId;
  File? generalImage;
  File? detailImage;

  PlantData({
    required this.position,
    required this.maCaySam,
    required this.loSamId,
    required this.tuoiCayId,
    this.generalImage,
    this.detailImage,
  });
}
