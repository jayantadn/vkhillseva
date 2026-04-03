// screenshot_share_io.dart
// Native/desktop screenshot sharing implementation
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> shareScreenshot(Uint8List screenshotBytes,
    {String filename = 'summary.png'}) async {
  final dir = await getTemporaryDirectory();
  final file = io.File('${dir.path}/$filename');
  await file.writeAsBytes(screenshotBytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'image/png', name: filename)],
    text: 'Here is your summary screenshot.',
    subject: 'Summary Screenshot',
  );
}
