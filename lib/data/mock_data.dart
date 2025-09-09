import 'dart:math';
import '../models/cay_sam.dart';
import '../models/nhat_ky.dart';
import '../models/moi_truong.dart';
import '../models/xac_thuc.dart';

class MockData {
  static List<CaySam> mockPlants = [
    CaySam(
      id: 'CS001',
      nhatKyId: 'NK001',
      moiTruongId: 'MT001',
      xacThucId: 'XT001',
      blockChain: 'BC001',
      tenCay: 'Sâm Việt Nam',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: DateTime.parse('2024-01-15'),
      trangThai: TrangThaiCay.khoeMauh,
      viTri: 'Khu A - Hàng 1',
    ),
    CaySam(
      id: 'CS002',
      nhatKyId: 'NK002',
      moiTruongId: 'MT001',
      xacThucId: 'XT002',
      blockChain: 'BC002',
      tenCay: 'Sâm Ngọc Linh',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: DateTime.parse('2024-01-20'),
      trangThai: TrangThaiCay.khoeMauh,
      viTri: 'Khu A - Hàng 2',
    ),
    CaySam(
      id: 'CS003',
      nhatKyId: 'NK003',
      moiTruongId: 'MT002',
      xacThucId: 'XT003',
      blockChain: 'BC003',
      tenCay: 'Sâm Lai Châu',
      loaiCay: 'Panax vietnamensis',
      ngayTrong: DateTime.parse('2024-02-01'),
      trangThai: TrangThaiCay.yeu,
      viTri: 'Khu B - Hàng 1',
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
      diemChatLuong: 9.2,
      nguoiKiemDinh: 'Nguyễn Văn A',
      ngayCapNhat: '2024-11-15T14:30:00Z',
      taiLieuDinhKem: [
        'chung_chi_chat_luong_CS001.pdf',
        'bao_cao_kiem_dinh_CS001.pdf'
      ],
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-11-10T09:00:00Z',
          nguoiThayDoi: 'Nguyễn Văn A',
          hanhDong: 'Tạo yêu cầu kiểm định',
          ghiChu: 'Yêu cầu kiểm định chất lượng định kỳ',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-11-12T10:30:00Z',
          nguoiThayDoi: 'Nguyễn Văn A',
          hanhDong: 'Bắt đầu kiểm định',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-11-15T14:30:00Z',
          nguoiThayDoi: 'Nguyễn Văn A',
          hanhDong: 'Hoàn thành kiểm định',
          ghiChu: 'Kết quả: Đạt chuẩn chất lượng cao - 9.2/10',
        ),
      ],
      ghiChu: 'Sâm phát triển tốt, không có dấu hiệu bệnh tật. Đạt tiêu chuẩn xuất khẩu.',
    ),
    CaySamXacThuc(
      xacThucId: 'XT002',
      caySamId: 'CS002',
      ngayKiemDinh: '2024-11-20',
      loaiKiemDinh: LoaiKiemDinh.benhTat,
      trangThaiKiemDinh: TrangThaiKiemDinh.dangKiemDinh,
      ketQuaKiemDinh: 'Đang tiến hành kiểm tra bệnh tật',
      nguoiKiemDinh: 'Trần Thị B',
      ngayCapNhat: '2024-11-20T08:15:00Z',
      taiLieuDinhKem: [
        'mau_la_CS002.jpg',
        'hinh_anh_re_CS002.jpg'
      ],
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-11-18T14:00:00Z',
          nguoiThayDoi: 'Trần Thị B',
          hanhDong: 'Tạo yêu cầu kiểm định',
          ghiChu: 'Phát hiện lá có dấu hiệu bất thường',
        ),
        KiemDinhHistory(
          ngayThayDoi: '2024-11-20T08:15:00Z',
          nguoiThayDoi: 'Trần Thị B',
          hanhDong: 'Bắt đầu kiểm định',
        ),
      ],
      ghiChu: 'Cần kiểm tra kỹ các dấu hiệu bệnh tật trên lá và rễ.',
    ),
    CaySamXacThuc(
      xacThucId: 'XT003',
      caySamId: 'CS003',
      ngayKiemDinh: '2024-11-05',
      loaiKiemDinh: LoaiKiemDinh.sinhTruong,
      trangThaiKiemDinh: TrangThaiKiemDinh.choKiemDinh,
      ketQuaKiemDinh: 'Chờ lịch kiểm định sinh trưởng',
      nguoiKiemDinh: 'Lê Văn C',
      ngayCapNhat: '2024-11-05T16:45:00Z',
      lichSuKiemDinh: [
        KiemDinhHistory(
          ngayThayDoi: '2024-11-05T16:45:00Z',
          nguoiThayDoi: 'Lê Văn C',
          hanhDong: 'Tạo yêu cầu kiểm định',
          ghiChu: 'Kiểm tra tình hình sinh trưởng sau 3 tháng trồng',
        ),
      ],
      ghiChu: 'Cây đã trồng được 3 tháng, cần đánh giá tình hình phát triển.',
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