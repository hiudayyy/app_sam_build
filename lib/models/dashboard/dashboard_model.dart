import '../vuontrong/sensor_model.dart';

class DashBoardtotal {
  final int totalVuonTrong;
  final int totalLoSam;
  final int totalCaySam;
  final int totalSuckhoeYeu;

  DashBoardtotal({
    required this.totalVuonTrong,
    required this.totalLoSam,
    required this.totalCaySam,
    required this.totalSuckhoeYeu,
  });

  factory DashBoardtotal.fromJson(Map<String, dynamic> json) {
    return DashBoardtotal(
      totalVuonTrong: json['totalVuonTrong'] ?? 0,
      totalLoSam: json['totalLoSam'] ?? 0,
      totalCaySam: json['totalCaySam'] ?? 0,
      totalSuckhoeYeu: json['totalSucKhoeYeu'] ?? 0,
    );
  }
}
class DashBoardSucKhoe {
  final int totalRatTot;
  final int totalKhaTot;
  final int totalTrungBinh;
  final int totalYeu;
  final int totalRatYeu;
  final double HealthPercentage;

  DashBoardSucKhoe({
    required this.totalRatTot,
    required this.totalKhaTot,
    required this.totalTrungBinh,
    required this.totalYeu,
    required this.totalRatYeu,
    required this.HealthPercentage,
  });

  factory DashBoardSucKhoe.fromJson(Map<String, dynamic> json) {
    return DashBoardSucKhoe(
      totalRatTot: json['totalRatTot'] ?? 0,
      totalKhaTot: json['totalKhaTot'] ?? 0,
      totalTrungBinh: json['totalTrungBinh'] ?? 0,
      totalYeu: json['totalYeu'] ?? 0,
      totalRatYeu: json['totalRatYeu'] ?? 0,
      HealthPercentage: (json['healthPercentage'] ?? 0 as num).toDouble(),
    );
  }
}