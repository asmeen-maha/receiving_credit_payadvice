import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Logo images available to reports.
abstract final class ReportLogo {
  static const company = 'assets/images/logo_cm_bk.jpg';
  static const ticketing = 'assets/images/Ticketing.jpg';
}

/// Fonts and logo shared by every PDF report.
class ReportAssets {
  final pw.MemoryImage logo;

  /// Thai text font.
  final pw.Font pgVim;

  /// Trajan Pro regular — Latin text / numbers.
  final pw.Font trajan;

  /// Trajan Pro bold — headings and totals.
  final pw.Font trajanBold;

  const ReportAssets._(this.logo, this.pgVim, this.trajan, this.trajanBold);

  /// Raw asset bytes, kept after the first load. On the web every
  /// `rootBundle.load` is an HTTP request, so this saves several round trips
  /// (and the 220 KB logo) on every voucher printed.
  static final Map<String, Future<Uint8List>> _bytes = {};

  static Future<Uint8List> _load(String key) => _bytes[key] ??= rootBundle.load(key).then(
        (data) => data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        onError: (Object e) {
          _bytes.remove(key); // retry next time
          throw e;
        },
      );

  static Future<ReportAssets> load({String logo = ReportLogo.company}) async {
    // Sequential on purpose: parallel loads raced in widget tests.
    final logoBytes = await _load(logo);
    final pgVim = await _load('assets/fonts/pgvim.ttf');
    final trajan = await _load('assets/fonts/trajanpro-regular.ttf');
    final trajanBold = await _load('assets/fonts/trajanpro-bold.ttf');
    // Font/image objects are cheap wrappers; new ones per document keep each
    // PDF's embedded font independent of other documents being generated.
    return ReportAssets._(
      pw.MemoryImage(logoBytes),
      pw.Font.ttf(pgVim.buffer.asByteData(pgVim.offsetInBytes, pgVim.lengthInBytes)),
      pw.Font.ttf(trajan.buffer.asByteData(trajan.offsetInBytes, trajan.lengthInBytes)),
      pw.Font.ttf(trajanBold.buffer.asByteData(trajanBold.offsetInBytes, trajanBold.lengthInBytes)),
    );
  }
}
