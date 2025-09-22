import 'dart:math';
import '../models/cay_sam.dart';
import '../models/nhat_ky.dart';
import '../models/moi_truong.dart';
import '../models/xac_thuc.dart';
import '../models/farm_hierarchy.dart';

class MockData {
  // Hierarchical structure for investor view
  static List<Farm> mockFarms = [
    Farm(
      id: 'farm1',
      name: 'Trang trại Sâm Ngọc Linh',
      description: 'Trang trại chính chuyên trồng sâm Ngọc Linh chất lượng cao',
      totalAreas: 6,
      location: 'Lai Châu, Việt Nam',
      zones: [
        Zone(
          id: 'zone1',
          name: 'Vùng A - Đông Bắc',
          description: 'Vùng có khí hậu mát mẻ, thích hợp trồng sâm',
          farmId: 'farm1',
          areas: [
            Area(
              id: 'area1',
              name: 'Khu A1 - Thử nghiệm',
              description: 'Khu thử nghiệm các giống sâm mới',
              zoneId: 'zone1',
              gridSize: GridSize(rows: 18, cols: ['A', 'B', 'C', 'D', 'E', 'F']),
              plants: [],
            ),
            Area(
              id: 'area2',
              name: 'Khu A2 - Sản xuất chính',
              description: 'Khu sản xuất sâm thương mại chính',
              zoneId: 'zone1',
              gridSize: GridSize(rows: 18, cols: ['A', 'B', 'C', 'D', 'E', 'F']),
              plants: [],
            ),
          ],
        ),
        Zone(
          id: 'zone2',
          name: 'Vùng B - Tây Nam',
          description: 'Vùng có độ ẩm cao, phù hợp với sâm Việt Nam',
          farmId: 'farm1',
          areas: [
            Area(
              id: 'area3',
              name: 'Khu B1 - Nghiên cứu',
              description: 'Khu dành cho nghiên cứu và phát triển',
              zoneId: 'zone2',
              gridSize: GridSize(rows: 18, cols: ['A', 'B', 'C', 'D', 'E', 'F']),
              plants: [],
            ),
          ],
        ),
      ],
    ),
    Farm(
      id: 'farm2',
      name: 'Trang trại Sâm Việt Nam',
      description: 'Trang trại chuyên trồng sâm Việt Nam truyền thống',
      totalAreas: 4,
      location: 'Lào Cai, Việt Nam',
      zones: [
        Zone(
          id: 'zone3',
          name: 'Vùng C - Trung tâm',
          description: 'Vùng trung tâm với điều kiện khí hậu ổn định',
          farmId: 'farm2',
          areas: [
            Area(
              id: 'area4',
              name: 'Khu C1 - Thương mại',
              description: 'Khu sản xuất thương mại quy mô lớn',
              zoneId: 'zone3',
              gridSize: GridSize(rows: 18, cols: ['A', 'B', 'C', 'D', 'E', 'F']),
              plants: [],
            ),
            Area(
              id: 'area5',
              name: 'Khu C2 - Hữu cơ',
              description: 'Khu trồng sâm hữu cơ cao cấp',
              zoneId: 'zone3',
              gridSize: GridSize(rows: 18, cols: ['A', 'B', 'C', 'D', 'E', 'F']),
              plants: [],
            ),
          ],
        ),
      ],
    ),
  ];

  static List<CaySam> mockPlants = [
    CaySam(
      id: 'CS001',
      nhatKyId: 'NK001',
      moiTruongId: 'MT001',
      xacThucId: 'XT001',
      blockChain: 'BC001',
      tenCay: 'Sâm Việt Nam',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-01-15',
      trangThai: TrangThaiCay.khoeMauh,
      viTri: 'Khu A - Hàng 1',
      gridPosition: 'A1',
      investorId: '5',
      areaId: 'LO01',
    ),
    CaySam(
      id: 'CS002',
      nhatKyId: 'NK002',
      moiTruongId: 'MT001',
      xacThucId: 'XT002',
      blockChain: 'BC002',
      tenCay: 'Sâm Ngọc Linh',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-01-20',
      trangThai: TrangThaiCay.khoeMauh,
      viTri: 'Khu A - Hàng 2',
      gridPosition: 'A2',
      investorId: '5',
      areaId: '1',
    ),
    CaySam(
      id: 'CS003',
      nhatKyId: 'NK003',
      moiTruongId: 'MT002',
      xacThucId: 'XT003',
      blockChain: 'BC003',
      tenCay: 'Sâm Lai Châu',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-02-01',
      trangThai: TrangThaiCay.yeu,
      viTri: 'Khu B - Hàng 1',
      gridPosition: 'B1',
      investorId: '',
      areaId: '1',
    ),
    CaySam(
      id: 'CS004',
      nhatKyId: 'NK004',
      moiTruongId: 'MT001',
      xacThucId: 'XT001',
      blockChain: 'BC004',
      tenCay: 'Sâm Ngọc Linh',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-01-25',
      trangThai: TrangThaiCay.khoeMauh,
      viTri: 'Khu C - Hàng 3',
      gridPosition: 'C3',
      investorId: '5',
      areaId: 'area4',
    ),
    CaySam(
      id: 'CS005',
      nhatKyId: 'NK005',
      moiTruongId: 'MT002',
      xacThucId: 'XT002',
      blockChain: 'BC005',
      tenCay: 'Sâm Việt Nam',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-02-10',
      trangThai: TrangThaiCay.khoeMauh,
      viTri: 'Khu E - Hàng 5',
      gridPosition: 'E5',
      investorId: '5',
      areaId: 'area4',
    ),
    CaySam(
      id: 'CS006',
      nhatKyId: 'NK006',
      moiTruongId: 'MT001',
      xacThucId: 'XT003',
      blockChain: 'BC006',
      tenCay: 'Sâm Ngọc Linh',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-02-15',
      trangThai: TrangThaiCay.khoeMauh,
      viTri: 'Khu F - Hàng 8',
      gridPosition: 'F8',
      investorId: '5',
      areaId: 'area5',
    ),
    // Thêm cây có trạng thái "bệnh" để demo
    CaySam(
      id: 'CS007',
      nhatKyId: 'NK007',
      moiTruongId: 'MT002',
      xacThucId: 'XT007',
      blockChain: 'BC007',
      tenCay: 'Sâm Việt Nam',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-03-01',
      trangThai: TrangThaiCay.benh,
      viTri: 'Khu B - Hàng 3',
      gridPosition: 'B3',
      investorId: '',
      areaId: 'area2',
    ),
    // Thêm cây có trạng thái "chết" để demo
    CaySam(
      id: 'CS008',
      nhatKyId: 'NK008',
      moiTruongId: 'MT002',
      xacThucId: 'XT008',
      blockChain: 'BC008',
      tenCay: 'Sâm Lai Châu',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: '2024-01-10',
      trangThai: TrangThaiCay.chet,
      viTri: 'Khu C - Hàng 1',
      gridPosition: 'C1',
      investorId: '',
      areaId: 'area3',
    ),
  ];

  static List<CaySamNhatKy> mockDiary = [
    CaySamNhatKy(
      nhatKyId: 'NK001',
      ngayGhi: '2024-12-01',
      anhTongQuan: 'https://images.unsplash.com/photo-1589110254547-202e8e05be49?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxnaW5zZW5nJTIwcGxhbnRzJTIwY3VsdGl2YXRpb258ZW58MXx8fHwxNzU3MTMwNTkzfDA&ixlib=rb-4.1.0&q=80&w=400',
      soLa: 12,
      tinhTrang: TinhTrang(song: true, nguDong: false, chet: false),
      diemSucKhoe: 5,
      maNguoiGhi: 'NV001',
    ),
    CaySamNhatKy(
      nhatKyId: 'NK002',
      ngayGhi: '2024-12-01',
      soLa: 10,
      tinhTrang: TinhTrang(song: true, nguDong: false, chet: false),
      diemSucKhoe: 4,
      maNguoiGhi: 'NV001',
    ),
    CaySamNhatKy(
      nhatKyId: 'NK007',
      ngayGhi: '2024-12-05',
      soLa: 8,
      tinhTrang: TinhTrang(song: true, nguDong: false, chet: false),
      diemSucKhoe: 2,
      maNguoiGhi: 'NV002',
    ),
    CaySamNhatKy(
      nhatKyId: 'NK008',
      ngayGhi: '2024-12-01',
      soLa: 0,
      tinhTrang: TinhTrang(song: false, nguDong: false, chet: true),
      diemSucKhoe: 0,
      maNguoiGhi: 'NV003',
    ),
  ];

  static List<CaySamMoiTruong> mockEnvironment = [
    CaySamMoiTruong(
      moiTruongId: 'MT001',
      ngayDo: '2024-12-06T10:00:00Z',
      doAmDat: 65.0,
      nhietDo: 22.0,
      doAmKhongKhi: 75.0,
      luongMua: 0.0,
      ghiChu: 'Điều kiện lý tưởng',
    ),
    CaySamMoiTruong(
      moiTruongId: 'MT002',
      ngayDo: '2024-12-06T10:00:00Z',
      doAmDat: 45.0,
      nhietDo: 25.0,
      doAmKhongKhi: 60.0,
      luongMua: 0.0,
      ghiChu: 'Cần tưới nước',
    ),
  ];

  static List<CaySamXacThuc> mockVerification = [
    CaySamXacThuc(
      xacThucId: 'XT001',
      caySamId: 'CS001',
      ngayKiemDinh: '2024-11-15',
      loaiKiemDinh: LoaiKiemDinh.chatLuong,
      trangThaiKiemDinh: TrangThaiKiemDinh.hoanThanh,
      ketQuaKiemDinh: 'Đạt chuẩn chất lượng cao',
      diemChatLuong: 8.5,
      nguoiKiemDinh: 'Nguyễn Văn A',
      ngayCapNhat: '2024-11-15T14:30:00Z',
      taiLieuDinhKem: [
        'certificates/XT001_quality_cert.pdf',
        'images/XT001_inspection_photos.jpg'
      ],
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-11-15T08:00:00Z',
          nguoiThayDoi: 'Nguyễn Văn A',
          hanhDong: 'Bắt đầu kiểm định chất lượng',
          ghiChu: 'Thu thập mẫu sâm để phân tích',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-11-15T14:30:00Z',
          nguoiThayDoi: 'Nguyễn Văn A',
          hanhDong: 'Hoàn thành kiểm định',
          ghiChu: 'Kết quả đạt chất lượng cao, đủ tiêu chuẩn xuất khẩu',
        ),
      ],
      ghiChu: 'Sâm phát triển tốt, không có dấu hiệu bệnh tật. Độ ẩm và màu sắc lý tưởng.',
    ),
    CaySamXacThuc(
      xacThucId: 'XT002',
      caySamId: 'CS002',
      ngayKiemDinh: '2024-12-01',
      loaiKiemDinh: LoaiKiemDinh.benhTat,
      trangThaiKiemDinh: TrangThaiKiemDinh.hoanThanh,
      ketQuaKiemDinh: 'Không phát hiện bệnh tật',
      diemChatLuong: 7.8,
      nguoiKiemDinh: 'Trần Thị B',
      ngayCapNhat: '2024-12-01T16:45:00Z',
      taiLieuDinhKem: [
        'reports/XT002_disease_analysis.pdf',
      ],
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-12-01T09:15:00Z',
          nguoiThayDoi: 'Trần Thị B',
          hanhDong: 'Kiểm tra bệnh tật',
          ghiChu: 'Kiểm tra visual và lấy mẫu lá',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-12-01T16:45:00Z',
          nguoiThayDoi: 'Trần Thị B',
          hanhDong: 'Hoàn thành kiểm định bệnh tật',
          ghiChu: 'Không phát hiện bệnh tật, cây khỏe mạnh',
        ),
      ],
      ghiChu: 'Kiểm tra định kỳ hàng tháng, cây trong tình trạng tốt.',
    ),
    CaySamXacThuc(
      xacThucId: 'XT003',
      caySamId: 'CS003',
      ngayKiemDinh: '2024-12-05',
      loaiKiemDinh: LoaiKiemDinh.sinhTruong,
      trangThaiKiemDinh: TrangThaiKiemDinh.dangKiemDinh,
      ketQuaKiemDinh: 'Đang đánh giá tốc độ sinh trưởng',
      diemChatLuong: null,
      nguoiKiemDinh: 'Lê Văn C',
      ngayCapNhat: '2024-12-05T10:20:00Z',
      taiLieuDinhKem: [
        'measurements/XT003_growth_data.xlsx',
      ],
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-12-05T10:20:00Z',
          nguoiThayDoi: 'Lê Văn C',
          hanhDong: 'Bắt đầu đánh giá sinh trưởng',
          ghiChu: 'Đo chiều cao, số lá và đường kính thân',
        ),
      ],
      ghiChu: 'Kiểm định đang được thực hiện, dự kiến hoàn thành vào ngày 08/12/2024.',
    ),
    CaySamXacThuc(
      xacThucId: 'XT004',
      caySamId: 'CS004',
      ngayKiemDinh: '2024-10-20',
      loaiKiemDinh: LoaiKiemDinh.chatLuong,
      trangThaiKiemDinh: TrangThaiKiemDinh.hoanThanh,
      ketQuaKiemDinh: 'Chất lượng xuất sắc',
      diemChatLuong: 9.2,
      nguoiKiemDinh: 'Phạm Thị D',
      ngayCapNhat: '2024-10-20T15:00:00Z',
      taiLieuDinhKem: [
        'certificates/XT004_premium_cert.pdf',
        'lab_results/XT004_chemical_analysis.pdf',
        'images/XT004_product_photos.jpg'
      ],
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-10-20T08:30:00Z',
          nguoiThayDoi: 'Phạm Thị D',
          hanhDong: 'Thu thập mẫu cao cấp',
          ghiChu: 'Lựa chọn mẫu sâm có tuổi đời 3 năm',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-10-20T12:15:00Z',
          nguoiThayDoi: 'Phạm Thị D',
          hanhDong: 'Phân tích thành phần',
          ghiChu: 'Kiểm tra hàm lượng saponin và các chất hoạt tính',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-10-20T15:00:00Z',
          nguoiThayDoi: 'Phạm Thị D',
          hanhDong: 'Hoàn thành đánh giá chất lượng',
          ghiChu: 'Đạt tiêu chuẩn xuất khẩu cao cấp, chứng nhận premium',
        ),
      ],
      ghiChu: 'Sâm đạt chất lượng xuất sắc với hàm lượng saponin cao, đủ điều kiện xuất khẩu sang thị trường quốc tế.',
    ),
    CaySamXacThuc(
      xacThucId: 'XT005',
      caySamId: 'CS005',
      ngayKiemDinh: '2024-12-10',
      loaiKiemDinh: LoaiKiemDinh.benhTat,
      trangThaiKiemDinh: TrangThaiKiemDinh.choKiemDinh,
      ketQuaKiemDinh: 'Chưa bắt đầu kiểm định',
      diemChatLuong: null,
      nguoiKiemDinh: 'Hoàng Văn E',
      ngayCapNhat: '2024-12-06T11:00:00Z',
      taiLieuDinhKem: null,
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-12-06T11:00:00Z',
          nguoiThayDoi: 'Hoàng Văn E',
          hanhDong: 'Lên lịch kiểm định',
          ghiChu: 'Đăng ký kiểm định định kỳ theo quy trình',
        ),
      ],
      ghiChu: 'Kiểm định định kỳ đã được lên lịch, chờ thực hiện.',
    ),
    CaySamXacThuc(
      xacThucId: 'XT006',
      caySamId: 'CS006',
      ngayKiemDinh: '2024-11-25',
      loaiKiemDinh: LoaiKiemDinh.chatLuong,
      trangThaiKiemDinh: TrangThaiKiemDinh.huy,
      ketQuaKiemDinh: 'Kiểm định bị hủy do điều kiện thời tiết',
      diemChatLuong: null,
      nguoiKiemDinh: 'Vũ Thị F',
      ngayCapNhat: '2024-11-25T07:30:00Z',
      taiLieuDinhKem: null,
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-11-24T16:00:00Z',
          nguoiThayDoi: 'Vũ Thị F',
          hanhDong: 'Lên lịch kiểm định',
          ghiChu: 'Đặt lịch kiểm định chất lượng',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-11-25T07:30:00Z',
          nguoiThayDoi: 'Vũ Thị F',
          hanhDong: 'Hủy kiểm định',
          ghiChu: 'Mưa lớn không thể tiếp cận khu vực, hoãn sang tuần sau',
        ),
      ],
      ghiChu: 'Kiểm định bị hủy do thời tiết xấu. Sẽ được lên lịch lại sau khi thời tiết ổn định.',
    ),
  ];

  static List<SensorReading> generateSensorData() {
    final data = <SensorReading>[];
    final now = DateTime.now();
    final random = Random();

    for (int i = 23; i >= 0; i--) {
      final timestamp = now.subtract(Duration(hours: i));
      data.add(SensorReading(
        timestamp: timestamp,
        temperature: 20 + random.nextDouble() * 8,
        humidity: 60 + random.nextDouble() * 30,
        soilMoisture: 50 + random.nextDouble() * 40,
        rainfall: random.nextDouble() < 0.1 ? random.nextDouble() * 5 : 0,
      ));
    }

    return data;
  }
}

class SensorReading {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double rainfall;

  SensorReading({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.rainfall,
  });
}