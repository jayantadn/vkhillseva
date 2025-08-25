// pdf_share_io.dart
// Native/desktop PDF sharing implementation
import 'dart:typed_data';
import 'dart:io' as io;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> sharePdf(Uint8List pdfBytes,
    {String filename = 'report.pdf'}) async {
  final dir = await getTemporaryDirectory();
  final file = io.File('${dir.path}/$filename');
  await file.writeAsBytes(pdfBytes, flush: true);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf', name: filename)],
    text: 'Here is your PDF.',
    subject: 'PDF Share',
  );
}
