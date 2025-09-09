// screenshot_share_web.dart
// Web-specific screenshot sharing implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:js/js_util.dart' as js_util;
import 'dart:typed_data';

Future<void> shareScreenshot(Uint8List screenshotBytes,
    {String filename = 'summary.png'}) async {
  try {
    final blob = html.Blob([screenshotBytes], 'image/png');
    final file = html.File([blob], filename, {'type': 'image/png'});
    final nav = html.window.navigator;
    final hasShare = js_util.hasProperty(nav, 'share');
    final hasCanShare = js_util.hasProperty(nav, 'canShare');

    if (hasShare && hasCanShare) {
      final canShareFiles = js_util.callMethod<bool?>(nav, 'canShare', [
            {
              'files': [file]
            }
          ]) ??
          false;
      if (canShareFiles) {
        await js_util.promiseToFuture(js_util.callMethod(nav, 'share', [
          {
            'title': filename,
            'text': 'Sharing a summary screenshot.',
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
    // Could log error or show user-friendly message if needed
  }
}
