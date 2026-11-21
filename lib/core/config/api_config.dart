/// Backend endpoints used by the app.
abstract final class ApiConfig {
  /// Marketing API: credit / pay advance / pay types / flag updates.
  static const marketingUrl = 'http://172.2.100.14/clientele_cm/marketing.php';

  /// Ticketing API: cashier transaction summary used by the income report.
  static const ticketingUrl = 'http://172.2.200.200/cmfrontapp/ticketing/ticketapi/datamodule/selfticketing.php';
}
