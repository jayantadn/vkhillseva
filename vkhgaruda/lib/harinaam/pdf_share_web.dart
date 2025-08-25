// pdf_share_web.dart
// Web-specific PDF sharing implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:js/js_util.dart' as js_util;
import 'dart:typed_data';

Future<void> sharePdf(Uint8List pdfBytes,
    {String filename = 'report.pdf'}) async {
  try {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final file = html.File([blob], filename, {'type': 'application/pdf'});
    final nav = html.window.navigator;
    final hasShare = js_util.hasProperty(nav, 'share');
    final hasCanShare = js_util.hasProperty(nav, 'canShare');
    if (hasShare && hasCanShare) {
      final canShareFiles = js_util.callMethod<bool>(nav, 'canShare', [
            {
              'files': [file]
            }
          ]) ??
          false;
      if (canShareFiles) {
        await js_util.promiseToFuture(js_util.callMethod(nav, 'share', [
          {
            'title': filename,
            'text': 'Sharing a PDF.',
            'files': [file],
          }
        ]));
        return;
      }
    }
    // Fallback: download
    final url = html.Url.createObjectUrlFromBlob(blob);
    final a = html.AnchorElement(href: url)..download = filename;
    html.document.body?.append(a);
    a.click();
    a.remove();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    // Optionally handle error
  }
}
