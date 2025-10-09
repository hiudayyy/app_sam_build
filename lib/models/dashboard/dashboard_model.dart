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