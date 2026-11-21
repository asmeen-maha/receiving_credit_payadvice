// The app targets Flutter Web only; printing goes through `autoPrint`
// defined in web/index.html.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';

/// Opens the browser print dialog for [pdfBytes].
///
/// The blob URL is revoked by `autoPrint` when the next document replaces it,
/// not here: revoking right away can race the iframe load in some browsers.
void printPdf(Uint8List pdfBytes) {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  js.context.callMethod('autoPrint', [url]);
}
