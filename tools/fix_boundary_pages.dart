// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> fetchJson(HttpClient client, String url) async {
  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close();
  if (res.statusCode != 200) {
    throw Exception('HTTP ${res.statusCode} for $url');
  }
  final body = await res.transform(utf8.decoder).join();
  return json.decode(body) as Map<String, dynamic>;
}

Future<void> main() async {
  final client = HttpClient();

  // 1. Fix Page 207
  print('Fixing page 207...');
  final p207Data = await fetchJson(client,
      'https://api.quran.com/api/v4/verses/by_page/207?words=true&word_fields=line_number,code_v1,code_v2,text_uthmani,location');
  final lines207 = <int, List<dynamic>>{};
  for (final v in p207Data['verses'] as List<dynamic>) {
    final vKey = v['verse_key'] as String;
    for (final w in v['words'] as List<dynamic>) {
      final ln = w['line_number'] as int;
      final loc = (w['location'] as String?) ?? '$vKey:${w['position']}';
      final wordObj = Map<String, dynamic>.from(w);
      wordObj['location'] = loc;
      wordObj['verse_key'] = vKey;
      lines207.putIfAbsent(ln, () => []).add(wordObj);
    }
  }

  final newLines207 = <Map<String, dynamic>>[];
  for (int l = 1; l <= 14; l++) {
    final words = lines207[l] ?? [];
    final textStr = words.map((w) => w['text_uthmani'] ?? '').join(' ').trim();
    newLines207.add({
      'line': l,
      'type': 'text',
      'text': textStr,
      'verseRange': words.isNotEmpty
          ? '${words.first['verse_key']}-${words.last['verse_key']}'
          : '',
      'words': words
          .map((w) => {
                'location': w['location'],
                'word': w['text_uthmani'] ?? '',
                'qpcV2': w['code_v2'] ?? '',
                'qpcV1': w['code_v1'] ?? '',
              })
          .toList(),
    });
  }
  // Line 15 is header for Surah 10 (Yunus)
  newLines207.add({
    'line': 15,
    'type': 'surah-header',
    'text': 'سورة يونس',
    'surah': '010',
  });
  File('tools/source/mushaf_layout/page-207.json').writeAsStringSync(
      json.encode({'page': 207, 'lines': newLines207}),
      encoding: utf8);
  print('✅ Page 207 fixed: 15 lines (14 text + Surah 10 header)');

  // 2. Fix Page 586 (Surah 81 At-Takwir)
  print('Fixing page 586...');
  final p586Data = await fetchJson(client,
      'https://api.quran.com/api/v4/verses/by_page/586?words=true&word_fields=line_number,code_v1,code_v2,text_uthmani,location');
  final lines586 = <int, List<dynamic>>{};
  for (final v in p586Data['verses'] as List<dynamic>) {
    final vKey = v['verse_key'] as String;
    for (final w in v['words'] as List<dynamic>) {
      final ln = w['line_number'] as int;
      final loc = (w['location'] as String?) ?? '$vKey:${w['position']}';
      final wordObj = Map<String, dynamic>.from(w);
      wordObj['location'] = loc;
      wordObj['verse_key'] = vKey;
      lines586.putIfAbsent(ln, () => []).add(wordObj);
    }
  }

  final newLines586 = <Map<String, dynamic>>[
    {
      'line': 1,
      'type': 'surah-header',
      'text': 'سورة التكوير',
      'surah': '081',
    },
    {
      'line': 2,
      'type': 'basmala',
      'qpcV2': 'ﭑﭒﭓ',
      'qpcV1': '#"!',
    },
  ];
  for (int l = 3; l <= 14; l++) {
    final words = lines586[l] ?? [];
    final textStr = words.map((w) => w['text_uthmani'] ?? '').join(' ').trim();
    newLines586.add({
      'line': l,
      'type': 'text',
      'text': textStr,
      'verseRange': words.isNotEmpty
          ? '${words.first['verse_key']}-${words.last['verse_key']}'
          : '',
      'words': words
          .map((w) => {
                'location': w['location'],
                'word': w['text_uthmani'] ?? '',
                'qpcV2': w['code_v2'] ?? '',
                'qpcV1': w['code_v1'] ?? '',
              })
          .toList(),
    });
  }
  // Line 15: header for Surah 82 (Al-Infitar)
  newLines586.add({
    'line': 15,
    'type': 'surah-header',
    'text': 'سورة الإنفطار',
    'surah': '082',
  });
  File('tools/source/mushaf_layout/page-586.json').writeAsStringSync(
      json.encode({'page': 586, 'lines': newLines586}),
      encoding: utf8);
  print('✅ Page 586 fixed: 15 lines (Surah 81 header + basmala + 12 text + Surah 82 header)');

  // 3. Fix Page 590 (Surah 85 Al-Burooj)
  print('Fixing page 590...');
  final p590Data = await fetchJson(client,
      'https://api.quran.com/api/v4/verses/by_page/590?words=true&word_fields=line_number,code_v1,code_v2,text_uthmani,location');
  final lines590 = <int, List<dynamic>>{};
  for (final v in p590Data['verses'] as List<dynamic>) {
    final vKey = v['verse_key'] as String;
    for (final w in v['words'] as List<dynamic>) {
      final ln = w['line_number'] as int;
      final loc = (w['location'] as String?) ?? '$vKey:${w['position']}';
      final wordObj = Map<String, dynamic>.from(w);
      wordObj['location'] = loc;
      wordObj['verse_key'] = vKey;
      lines590.putIfAbsent(ln, () => []).add(wordObj);
    }
  }

  final newLines590 = <Map<String, dynamic>>[
    {
      'line': 1,
      'type': 'surah-header',
      'text': 'سورة البروج',
      'surah': '085',
    },
    {
      'line': 2,
      'type': 'basmala',
      'qpcV2': 'ﭑﭒﭓ',
      'qpcV1': '#"!',
    },
  ];
  for (int l = 3; l <= 14; l++) {
    final words = lines590[l] ?? [];
    final textStr = words.map((w) => w['text_uthmani'] ?? '').join(' ').trim();
    newLines590.add({
      'line': l,
      'type': 'text',
      'text': textStr,
      'verseRange': words.isNotEmpty
          ? '${words.first['verse_key']}-${words.last['verse_key']}'
          : '',
      'words': words
          .map((w) => {
                'location': w['location'],
                'word': w['text_uthmani'] ?? '',
                'qpcV2': w['code_v2'] ?? '',
                'qpcV1': w['code_v1'] ?? '',
              })
          .toList(),
    });
  }
  // Line 15: header for Surah 86 (At-Tariq)
  newLines590.add({
    'line': 15,
    'type': 'surah-header',
    'text': 'سورة الطارق',
    'surah': '086',
  });
  File('tools/source/mushaf_layout/page-590.json').writeAsStringSync(
      json.encode({'page': 590, 'lines': newLines590}),
      encoding: utf8);
  print('✅ Page 590 fixed: 15 lines (Surah 85 header + basmala + 12 text + Surah 86 header)');

  client.close();
  print('All 3 boundary pages successfully corrected with valid word locations!');
}
