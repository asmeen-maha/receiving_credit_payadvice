// `printPdf(Uint8List)` — opens the browser print dialog on web; no-op elsewhere.
export 'pdf_printer_stub.dart' if (dart.library.html) 'pdf_printer_web.dart';
