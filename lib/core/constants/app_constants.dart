/// App-wide constants and backend code values.
abstract final class AppInfo {
  static const title = 'Receiving Credit & Pay Advance';
  static const version = 'V1.2.1';
}

/// `paytype` values returned by the API.
abstract final class PayTypeCode {
  static const credit = '2';
  static const payAdvance = '4';
}

/// `accode` (account code) values returned by the API.
abstract final class AccountCode {
  static const cash = '111';
  static const creditCard = '114';
  static const transfer = '133';
}

/// `activeflag` values used to track each row's workflow.
abstract final class ActiveFlag {
  /// Verified by staff (checkbox ticked).
  static const verified = 'Y';

  /// Receiving voucher printed (row is finished and hidden).
  static const printed = 'P';
}
