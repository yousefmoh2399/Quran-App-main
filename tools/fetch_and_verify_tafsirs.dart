// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

String cleanHtmlText(String text) {
  return text
      // Convert break and paragraph closing tags to newlines
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
      // Strip all remaining HTML tags
      .replaceAll(RegExp(r'<[^>]*>'), '')
      // Decode HTML entities
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('\u00A0', ' ')
      // Handle numeric entities
      .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
        final code = int.tryParse(match.group(1)!);
        return code != null ? String.fromCharCode(code) : match.group(0)!;
      })
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
        final code = int.tryParse(match.group(1)!, radix: 16);
        return code != null ? String.fromCharCode(code) : match.group(0)!;
      })
      // Normalize consecutive newlines and spaces
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

Future<Map<String, String>> fetchTafsir(int tafsirId, String name) async {
  print('\n----------------------------------------');
  print('Fetching Tafsir: $name (ID $tafsirId)...');
  print('----------------------------------------');

  final client = HttpClient();
  final Map<String, String> results = {}; // key: "surah:ayah", value: cleaned text

  try {
    for (int chapter = 1; chapter <= 114; chapter++) {
      int retries = 3;
      bool success = false;
      while (retries > 0 && !success) {
        try {
          final uri = Uri.parse(
              'https://api.quran.com/api/v4/tafsirs/$tafsirId/by_chapter/$chapter?per_page=300');
          final req = await client.getUrl(uri);
          final res = await req.close();
          if (res.statusCode == 200) {
            final body = await res.transform(utf8.decoder).join();
            final data = json.decode(body);
            final List tafsirs = data['tafsirs'] ?? [];
            for (final item in tafsirs) {
              final String verseKey = item['verse_key'] ?? '';
              final String rawText = item['text'] ?? '';
              final cleaned = cleanHtmlText(rawText);
              if (verseKey.isNotEmpty) {
                results[verseKey] = cleaned;
              }
            }
            success = true;
          } else {
            retries--;
            print('  [Retry] Chapter $chapter returned status ${res.statusCode}');
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          retries--;
          print('  [Retry] Chapter $chapter failed with error: $e');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (!success) {
        throw Exception('Failed to fetch chapter $chapter for tafsir $tafsirId');
      }

      if (chapter % 20 == 0 || chapter == 114) {
        print('  Fetched up to chapter $chapter/114... (${results.length} verses)');
      }
    }
  } finally {
    client.close();
  }

  print('Raw entries fetched for $name: ${results.length}');
  return results;
}

Map<String, String> fillGroupedVerses(
  Map<String, String> raw,
  List<dynamic> quranSurahs,
  String name,
) {
  final Map<String, String> filled = {};
  int inheritedCount = 0;

  for (final s in quranSurahs) {
    final int surahId = s['id'];
    String currentTafsir = '';
    for (final v in s['verses']) {
      final int ayahId = v['id'];
      final key = '$surahId:$ayahId';
      if (raw.containsKey(key) && raw[key]!.trim().isNotEmpty) {
        currentTafsir = raw[key]!;
        filled[key] = currentTafsir;
      } else {
        if (currentTafsir.isNotEmpty) {
          filled[key] = currentTafsir;
          inheritedCount++;
        } else {
          print('ERROR: First verse $key in chapter has no commentary!');
        }
      }
    }
  }

  print('$name: filled $inheritedCount grouped verses. Total verses: ${filled.length}');
  return filled;
}

void main() async {
  final stopwatch = Stopwatch()..start();

  // Load Quran surah structure for complete 6236 verification
  final quranEn = json.decode(File('tools/source/quran_en.json').readAsStringSync()) as List;

  // 1. Fetch Al-Saadi (ID 91)
  final rawSaadi = await fetchTafsir(91, 'Al-Saadi (تيسير الكريم الرحمن)');
  final saadi = fillGroupedVerses(rawSaadi, quranEn, 'Al-Saadi');

  // 2. Fetch Ibn Kathir (ID 14)
  final rawIbnKathir = await fetchTafsir(14, 'Ibn Kathir (تفسير القرآن العظيم)');
  final ibnKathir = fillGroupedVerses(rawIbnKathir, quranEn, 'Ibn Kathir');

  // Verify counts and empty verses
  int saadiEmpty = 0;
  saadi.forEach((k, v) { if (v.trim().isEmpty) saadiEmpty++; });

  int ibnKathirEmpty = 0;
  ibnKathir.forEach((k, v) { if (v.trim().isEmpty) ibnKathirEmpty++; });

  print('\n================ VERIFICATION ================');
  print('Total Quran Verses: 6236');
  print('Saadi: ${saadi.length} verses (Empty: $saadiEmpty)');
  print('Ibn Kathir: ${ibnKathir.length} verses (Empty: $ibnKathirEmpty)');

  if (saadi.length != 6236 || saadiEmpty > 0) {
    throw Exception('Saadi verification failed!');
  }
  if (ibnKathir.length != 6236 || ibnKathirEmpty > 0) {
    throw Exception('Ibn Kathir verification failed!');
  }

  // Save to JSON in tools/source/
  final toolsSource = Directory('tools/source');
  if (!toolsSource.existsSync()) toolsSource.createSync(recursive: true);

  File('tools/source/tafsir_saadi.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(saadi),
    encoding: utf8,
  );
  print('Saved tools/source/tafsir_saadi.json');

  File('tools/source/tafsir_ibn_kathir.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(ibnKathir),
    encoding: utf8,
  );
  print('Saved tools/source/tafsir_ibn_kathir.json');

  print('\nSUCCESS in ${stopwatch.elapsed.inSeconds} seconds.');
}
