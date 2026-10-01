import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/data/app_database.dart';
import '../../../../core/data/repositories/user_repository.dart';

enum TafsirSource {
  muyassar(1, 'التفسير الميسر', 'ميسر ومختصر ومعتمد'),
  saadi(16, 'تفسير السعدي', 'تيسير الكريم الرحمن في تفسير كلام المنان'),
  ibnKathir(14, 'تفسير ابن كثير', 'تفسير القرآن العظيم للإمام ابن كثير');

  final int id;
  final String title;
  final String description;

  const TafsirSource(this.id, this.title, this.description);

  static TafsirSource fromId(int id) {
    for (final s in TafsirSource.values) {
      if (s.id == id) return s;
    }
    return TafsirSource.muyassar;
  }
}

class TafsirRepository {
  final UserRepository _userRepo = UserRepository();
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  TafsirRepository._();
  static final TafsirRepository instance = TafsirRepository._();

  /// Gets Tafsir for a specific verse from chosen source.
  /// Uses offline SQLite first, then local cache, then network API.
  Future<String> getAyahTafsir({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  }) async {
    // 1. Al-Muyassar is always available offline in app_data.db
    if (source == TafsirSource.muyassar) {
      final db = await AppDatabase.instance.database;
      final rows = await db.query(
        'ayahs',
        columns: ['tafsir_muyassar'],
        where: 'surah_id = ? AND ayah_number = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final text = rows.first['tafsir_muyassar'] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
      return 'التفسير غير متوفر حالياً';
    }

    // 2. Check local offline cache in user_data.db
    final cached = await _userRepo.getCachedTafsir(surahNumber, ayahNumber, source.id);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 3. Fetch from Quran.com Tafsir API
    try {
      final url = 'https://api.quran.com/api/v4/tafsirs/${source.id}/by_ayah/$surahNumber:$ayahNumber';
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final map = (response.data is String) ? json.decode(response.data) : response.data;
        final rawText = map['tafsir']?['text']?.toString() ?? '';

        // Strip HTML tags if present
        final cleanText = rawText.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&quot;', '"').replaceAll('&nbsp;', ' ').trim();

        if (cleanText.isNotEmpty) {
          await _userRepo.cacheTafsir(surahNumber, ayahNumber, source.id, cleanText);
          return cleanText;
        }
      }
    } catch (_) {}

    // Fallback to offline Muyassar if offline/network fails
    return await getAyahTafsir(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      source: TafsirSource.muyassar,
    );
  }
}
