// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

const String kCdnUrl = 'https://static.qurancdn.com/fonts/quran/hafs/v1/ttf';

Future<void> main() async {
  final targetDir = Directory('assets/fonts/qpc_v1');
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  final client = HttpClient();
  client.maxConnectionsPerHost = 25;

  final missingPages = <int>[];
  for (int p = 1; p <= 604; p++) {
    final file = File('${targetDir.path}/p$p.ttf');
    if (!file.existsSync() || file.lengthSync() == 0) {
      missingPages.add(p);
    }
  }

  print('Total missing V1 fonts to download: ${missingPages.length}/604');
  if (missingPages.isEmpty) {
    print('All 604 V1 fonts already downloaded!');
  } else {
    final stopwatch = Stopwatch()..start();
    const chunkSize = 25;
    int completed = 604 - missingPages.length;

    for (int i = 0; i < missingPages.length; i += chunkSize) {
      final end = (i + chunkSize < missingPages.length)
          ? i + chunkSize
          : missingPages.length;
      final chunk = missingPages.sublist(i, end);

      await Future.wait(chunk.map((page) async {
        final uri = Uri.parse('$kCdnUrl/p$page.ttf');
        try {
          final req = await client.getUrl(uri);
          final res = await req.close();
          if (res.statusCode == 200) {
            final file = File('${targetDir.path}/p$page.ttf');
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
    print('\nDownload finished in ${stopwatch.elapsed.inSeconds}s!');
  }

  // Verify magic bytes for all 604 files
  print('\nVerifying magic bytes for all 604 TTF files...');
  int validCount = 0;
  int totalBytes = 0;
  final failedPages = <int>[];

  for (int p = 1; p <= 604; p++) {
    final file = File('${targetDir.path}/p$p.ttf');
    if (!file.existsSync() || file.lengthSync() < 4) {
      failedPages.add(p);
      continue;
    }

    final header = file.openSync().readSync(4);
    // TTF magic bytes: 0x00 0x01 0x00 0x00 or "true" (0x74 0x72 0x75 0x65)
    final isTtf = (header[0] == 0x00 && header[1] == 0x01 && header[2] == 0x00 && header[3] == 0x00) ||
                  (header[0] == 0x74 && header[1] == 0x72 && header[2] == 0x75 && header[3] == 0x65);

    if (isTtf) {
      validCount++;
      totalBytes += file.lengthSync();
    } else {
      print('❌ Invalid magic bytes for p$p: $header');
      failedPages.add(p);
    }
  }

  print('========================================');
  print('Verified: $validCount/604 valid TTF files.');
  print('Total V1 fonts size: ${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB ($totalBytes bytes)');
  print('Average per font: ${(totalBytes / 604 / 1024).toStringAsFixed(1)} KB');
  if (failedPages.isNotEmpty) {
    print('Failed pages: $failedPages');
  }
  print('========================================');
}
