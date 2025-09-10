enum MessCode {
  Unknown,
  IsOK,
  Not200,
  NotHost,
  ApiDateOut,
  ApiDateFalse,
  HashCode,
  Exception,
  Duplicate,
  AlreadyDeleted,
  AlreadyUsed,
  NotExist,
  NewAndInactive,
  MissingInput,
  InitializeNew,
  InvalidData,
  InvalidTable,
  InvalidConnection,
  IncompleteProcessing,
  RecheckInformation,
  RecheckInStock,
  DeleteFalse,
  InvalidPartnerID,
  InvalidTaxInfos,
  MissingTaxAccounts,
  MissingTaxInfos,
  InvalidDatetime,
  MissingByAdmin,
  RecheckDuplicateVoucherTaxNo,
  RecheckDuplicateVoucherNo,
  RecheckOfferAcnt,
  RecheckVoucherNo,
  RecheckPayableAcntId,
  RecheckOfferCrAcntId,
  RecheckChiPhi,
  RecheckChiPhiVanChuyen,
  RecheckDisntRate,
  RecheckTtlDisntAmt,
  RecheckDisntCrAcntId,
  RecheckTtlDisntAmtInExc,
  RefreshTokenExpired,
  AuthenticateNotMatchRefresh,
  LicenseExpired,
  RecheckDisntDbAcntId,
  RecheckRecvableAcntId,
  RecheckOfferDbAcntId,
  RecheckVoucherTaxNo,
  RecheckVoucherTypeTaxSign,
  RecheckVoucherTaxSign,
  RecheckAcntOpenType
}

extension MessCodeExtension on MessCode {
  String toJson() {
    return this.toString().split('.').last;
  }

  static MessCode fromJson(String json) {
    return MessCode.values.firstWhere((e) => e.toJson() == json);
  }
}
