import '../../../../core/data/app_database.dart';

enum TafsirSource {
  muyassar(1, 'التفسير الميسر', 'ميسر ومختصر ومعتمد', 'tafsir_muyassar'),
  saadi(16, 'تفسير السعدي', 'تيسير الكريم الرحمن في تفسير كلام المنان', 'tafsir_saadi'),
  ibnKathir(14, 'تفسير ابن كثير', 'تفسير القرآن العظيم للإمام ابن كثير', 'tafsir_ibn_kathir');

  final int id;
  final String title;
  final String description;
  final String dbColumn;

  const TafsirSource(this.id, this.title, this.description, this.dbColumn);

  static TafsirSource fromId(int id) {
    for (final s in TafsirSource.values) {
      if (s.id == id) return s;
    }
    return TafsirSource.muyassar;
  }
}

class TafsirRepository {
  TafsirRepository._();
  static final TafsirRepository instance = TafsirRepository._();

  /// Gets Tafsir for a specific verse from chosen source directly from SQLite database.
  /// 100% offline, zero network requests.
  Future<String> getAyahTafsir({
    required int surahNumber,
    required int ayahNumber,
    required TafsirSource source,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      final rows = await db.query(
        'ayahs',
        columns: [source.dbColumn],
        where: 'surah_id = ? AND ayah_number = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final text = rows.first[source.dbColumn] as String?;
        if (text != null && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    } catch (_) {}

    return 'التفسير غير متوفر حالياً';
  }
}
