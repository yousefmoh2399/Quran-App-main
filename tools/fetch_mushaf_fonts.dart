// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

const String kCdnUrl =
    'https://static.qurancdn.com/fonts/quran/hafs/v2/woff2';

Future<void> main() async {
  final targetDir = Directory('assets/fonts/qpc_v2');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  final client = HttpClient();
  client.maxConnectionsPerHost = 20;

  final missingPages = <int>[];
  for (int p = 1; p <= 604; p++) {
    final file = File('${targetDir.path}/p$p.woff2');
    if (!file.existsSync() || file.lengthSync() == 0) {
      missingPages.add(p);
    }
  }

  print('Total missing fonts to download: ${missingPages.length}/604');
  if (missingPages.isEmpty) {
    print('All 604 fonts already downloaded!');
    client.close();
    return;
  }

  final stopwatch = Stopwatch()..start();
  const chunkSize = 25;
  int completed = 604 - missingPages.length;

  for (int i = 0; i < missingPages.length; i += chunkSize) {
    final end = (i + chunkSize < missingPages.length)
        ? i + chunkSize
        : missingPages.length;
    final chunk = missingPages.sublist(i, end);

    await Future.wait(chunk.map((page) async {
      final uri = Uri.parse('$kCdnUrl/p$page.woff2');
      try {
        final req = await client.getUrl(uri);
        final res = await req.close();
        if (res.statusCode == 200) {
          final file = File('${targetDir.path}/p$page.woff2');
          final sink = file.openWrite();
          await res.pipe(sink);
          completed++;
        } else {
          print('❌ Failed p$page: ${res.statusCode}');
        }
      } catch (e) {
        print('❌ Error p$page: $e');
      }
    }));

    final progress = ((completed / 604) * 100).toStringAsFixed(1);
    stdout.write('\rDownloaded $completed/604 ($progress%)');
  }

  client.close();
  stopwatch.stop();
  print('\nDone in ${stopwatch.elapsed.inSeconds}s!');

  // Verify all 604 exist
  int count = 0;
  int totalBytes = 0;
  for (int p = 1; p <= 604; p++) {
    final file = File('${targetDir.path}/p$p.woff2');
    if (file.existsSync() && file.lengthSync() > 0) {
      count++;
      totalBytes += file.lengthSync();
    }
  }
  print('Successfully verified $count/604 font files.');
  print('Total font assets size: ${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB');
}
