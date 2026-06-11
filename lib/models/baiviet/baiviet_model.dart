class BaiVietModel {
  final int? id;
  final int? theLoaiId;
  final String? taiKhoanId;
  final String? slug;
  final String? tieuDe;
  final String? noiDung;
  final String? moTaNgan;
  final String? ngayTao;
  final String? ngayCapNhat;
  final int? trangThai;
  final String? hinhAnh;
  final int? luotXem;

  BaiVietModel({
    this.id,
    this.theLoaiId,
    this.taiKhoanId,
    this.slug,
    this.tieuDe,
    this.noiDung,
    this.moTaNgan,
    this.ngayTao,
    this.ngayCapNhat,
    this.trangThai,
    this.hinhAnh,
    this.luotXem,
  });

  factory BaiVietModel.fromJson(Map<String, dynamic> json) {
    return BaiVietModel(
      id: json['id'],
      theLoaiId: json['theLoaiId'],
      taiKhoanId: json['taiKhoanId'],
      slug: json['slug'],
      tieuDe: json['tieuDe'],
      noiDung: json['noiDung'],
      moTaNgan: json['moTaNgan'],
      ngayTao: json['ngayTao'],
      ngayCapNhat: json['ngayCapNhat'],
      trangThai: json['trangThai'],
      hinhAnh: json['hinhAnh'],
      luotXem: json['luotXem'],
    );
  }
}