import 'dart:convert';
import 'dart:io'; // Cần để check Platform.isAndroid
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nftsam/api/api.dart';
import 'package:nftsam/api/api_caysam.dart';
import 'package:flutter/material.dart';

// Import chính của thư viện
import 'package:nfc_manager/nfc_manager.dart';
// Nếu IDE báo lỗi không tìm thấy NdefFormatableAndroid, hãy bỏ comment dòng dưới:
// import 'package:nfc_manager/nfc_manager_android.dart';

import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:nftsam/models/message_enum.dart';
import '../models/vuontrong/caysam_model.dart';

enum NfcStatus { scanning, success, error }

class NfcWriterModal extends StatefulWidget {
  final CaySamModel plant;
  const NfcWriterModal({super.key, required this.plant});

  @override
  State<NfcWriterModal> createState() => _NfcWriterModalState();
}

class _NfcWriterModalState extends State<NfcWriterModal> {
  NfcStatus _status = NfcStatus.scanning;
  String _feedbackMessage = 'Đang chờ thẻ NFC...\nVui lòng đưa thẻ lại gần điện thoại.';
  bool _isSessionClosed = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _startNfcWriting();
    });
  }

  @override
  void dispose() {
    if (!_isSessionClosed) {
      // Dùng checkAvailability thay vì isAvailable cho bản 4.1.0 trở lên,
      // nhưng stopSession vẫn dùng instance.
      NfcManager.instance.stopSession().catchError((_) {});
    }
    super.dispose();
  }

  Future<void> _startNfcWriting() async {
    // Ver 4.1.0+: Dùng checkAvailability() thay vì isAvailable


    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _updateStatus(NfcStatus.error, 'NFC không được bật hoặc thiết bị không hỗ trợ.', '');
        return;
      }
      NfcManager.instance.startSession(
        alertMessageIos: "Đang xác thực thẻ...\nVui lòng GIỮ NGUYÊN điện thoại.",
        onSessionErrorIos: (error) {
          _updateStatus(NfcStatus.error, "Đã hủy quét thẻ", "");
        },
        onDiscovered: (NfcTag tag) async {
          try {
            // --- BƯỚC 1: Lấy UID ---
            String uid = _getTagId(tag.data);
            print(uid);

            // --- BƯỚC 2: Chuẩn bị dữ liệu ---
            final String myLink = 'https://nft.samnghigia.com/caysam/${widget.plant.caySamId}';
            final urirecord = _createNdefUriRecord(myLink);
            final message = NdefMessage(records: [urirecord]);

            // --- BƯỚC 3: GHI DỮ LIỆU (FIX CHO BẢN 4.0.0+) ---

            // 1. Kiểm tra NDEF tiêu chuẩn (Cả iOS và Android đều có)
            var ndefObj = Ndef.from(tag);

            if (ndefObj != null) {
              if (!ndefObj.isWritable) {
                throw Exception('Thẻ này bị khóa (Read-only), không thể ghi!');
              }
              final checkuid = await API().CheckNFCCaySam(serialNumber: uid);
              if (checkuid?.message == "Thẻ NFC đã tồn tại!") {
                throw Exception('${checkuid?.message}');
              }else{
                await ndefObj.write(message: message);
                //await ndefObj.writeLock();
              }
            } else {
              // >> TRƯỜNG HỢP 2: Thẻ chưa format (Thường gặp trên Android)
              if (Platform.isAndroid) {
                var ndefFormatable = NdefFormatableAndroid.from(tag);

                if (ndefFormatable != null) {
                  await ndefFormatable.format(message);
                } else {
                  throw Exception('Thẻ không hỗ trợ định dạng NDEF (Android).');
                }
              } else {
                // Trên iOS, nếu ndefObj == null nghĩa là thẻ không tương thích hoặc chưa format NDEF.
                // iOS CoreNFC rất kén thẻ chưa format.
                throw Exception('Thẻ không đúng định dạng NDEF (Vui lòng thử thẻ khác).');
              }
            }

            // --- BƯỚC 4: Kết thúc ---
            await _updateStatus(NfcStatus.success, 'Xác thực & Ghi thành công!', uid);

          } catch (e) {
            print(e);
            await _updateStatus(NfcStatus.error, 'Lỗi: ${e.toString()}', '');
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
      ).catchError((e) {
        _updateStatus(NfcStatus.error, 'Không thể bắt đầu phiên NFC', '');
      });
    } catch (e) {
      if (e.toString().contains("not_supported")) {
        await _updateStatus(NfcStatus.error, 'Thiết bị này không hỗ trợ NFC.', '');
      }else if (e.toString().contains("NFC is not enabled")) {
        await _updateStatus(NfcStatus.error, "Vui lòng bật NFC trong Cài đặt!", '');
      } else {
        await _updateStatus(NfcStatus.error, 'Lỗi hệ thống: $e', '');
      }
    }
  }

  String _getTagId(dynamic rawData) {
    List<int>? identifier;

    try {
      if (rawData is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
        const techKeys = [
          'nfcA', 'mifare', 'mifareClassic', 'isodep', 'nfcB', 'nfcF', 'nfcV', 'iso15693'
        ];

        for (var key in techKeys) {
          if (data.containsKey(key) && data[key] is Map) {
            final techData = data[key] as Map;
            if (techData.containsKey('identifier')) {
              identifier = List<int>.from(techData['identifier']);
              break;
            }
          }
        }

        // Fallback: Tìm identifier ngay tại root
        if (identifier == null && data.containsKey('identifier')) {
          identifier = List<int>.from(data['identifier']);
        }
      }
      // ---------------------------------------------------------
      // TRƯỜNG HỢP 2: Dữ liệu là Object (TagPigeon - iOS Mới)
      // ---------------------------------------------------------
      else {
        // 1. Thử miFare (Lưu ý: F viết hoa)
        if (identifier == null) {
          try {
            final dynamic obj = rawData.miFare;
            if (obj?.identifier != null) {
              identifier = List<int>.from(obj.identifier);
            }
          } catch (_) {}
        }

        // 2. Thử iso15693
        if (identifier == null) {
          try {
            final dynamic obj = rawData.iso15693;
            if (obj?.identifier != null) {
              identifier = List<int>.from(obj.identifier);
            }
          } catch (_) {}
        }

        // 3. Thử feliCa (Lưu ý: C viết hoa, dùng currentIDm)
        if (identifier == null) {
          try {
            final dynamic obj = rawData.feliCa;
            if (obj?.currentIDm != null) {
              identifier = List<int>.from(obj.currentIDm);
            }
          } catch (_) {}
        }

        // 4. Thử iso7816
        if (identifier == null) {
          try {
            final dynamic obj = rawData.iso7816;
            if (obj?.identifier != null) {
              identifier = List<int>.from(obj.identifier);
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      print("Lỗi parse ID: $e");
      return "";
    }

    // Convert List<int> sang Hex String
    if (identifier != null && identifier.isNotEmpty) {
      return identifier
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join('')
          .toUpperCase();
    }

    return "";
  }

  Future<void> _updateStatus(NfcStatus status, String message, String uid) async {
    _isSessionClosed = true;
    String? iosAlertMessage;
    String? iosErrorMessage;

    if (status == NfcStatus.success) {
      try {
        final data = await API().updateNFCCaySam(id: widget.plant.caySamId, serialNumber: uid);
        if (data?.messCode == MessCode.IsOK) {
          iosAlertMessage = "Ghi thẻ thành công!";
          if (mounted) {
            setState(() {
              _status = status;
              _feedbackMessage = message;
            });
          }
        } else {
          status = NfcStatus.error;
          iosErrorMessage = data?.message ?? 'Lỗi Server';
          if (mounted) {
            setState(() {
              _status = status;
              _feedbackMessage = iosErrorMessage!;
            });
          }
        }
      } catch (apiError) {
        status = NfcStatus.error;
        iosErrorMessage = "Lỗi kết nối Server";
      }
    } else {
      iosErrorMessage = message;
      if (mounted) {
        setState(() {
          _status = status;
          _feedbackMessage = message;
        });
      }
    }

    if (Platform.isIOS) {
      await NfcManager.instance.stopSession(
        alertMessageIos: iosAlertMessage,
        errorMessageIos: iosErrorMessage,
      ).catchError((_) {});

      if (mounted) Navigator.of(context).pop();
    } else {
      NfcManager.instance.stopSession().catchError((_) {});
      if (status == NfcStatus.success) {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
      }
    }
  }

  NdefRecord _createNdefUriRecord(String uri) {
    Uri parsedUri = Uri.parse(uri);
    String scheme = parsedUri.scheme.toLowerCase();
    String host = parsedUri.host;
    String path = parsedUri.path;
    int prefixByte;
    String remainingPayload;
    if (scheme == 'https') {
      prefixByte = 0x04;
      remainingPayload = '$host$path';
    } else if (scheme == 'http') {
      prefixByte = 0x03;
      remainingPayload = '$host$path';
    } else {
      prefixByte = 0x00;
      remainingPayload = uri;
    }
    final uriBytes = utf8.encode(remainingPayload);
    final payloadBytes = Uint8List.fromList([prefixByte, ...uriBytes]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList(utf8.encode('U')),
      identifier: Uint8List(0),
      payload: payloadBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTitle(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildStatusIndicator(),
          const SizedBox(height: 16),
          Text(
            _feedbackMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _getColor()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_status) {
      case NfcStatus.scanning: return 'Sẵn sàng quét';
      case NfcStatus.success: return 'Thành công!';
      case NfcStatus.error: return 'Thất bại';
    }
  }
  Color _getColor() {
    switch (_status) {
      case NfcStatus.scanning: return Colors.blue.shade700;
      case NfcStatus.success: return Colors.green.shade700;
      case NfcStatus.error: return Colors.red.shade700;
    }
  }
  Widget _buildStatusIndicator() {
    switch (_status) {
      case NfcStatus.scanning:
        return _buildAnimatedIcon(Icons.nfc, Colors.blue.shade700);
      case NfcStatus.success:
        return _buildAnimatedIcon(Icons.check_circle, Colors.green.shade700);
      case NfcStatus.error:
        return _buildAnimatedIcon(Icons.error, Colors.red.shade700);
    }
  }
  Widget _buildAnimatedIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 64, color: color),
    );
  }
}