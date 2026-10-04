import 'dart:convert';

class HadithBookmarkModel {
  final String id;
  final int chapterIndex;
  final int itemIndex;
  final String chapterName;
  final int hadithNumber;
  final String text;
  final String source;
  final bool isMemorized;
  final DateTime savedAt;

  HadithBookmarkModel({
    required this.id,
    this.chapterIndex = 0,
    this.itemIndex = 0,
    required this.chapterName,
    required this.hadithNumber,
    required this.text,
    this.source = 'صحيح',
    this.isMemorized = false,
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  HadithBookmarkModel copyWith({
    String? id,
    int? chapterIndex,
    int? itemIndex,
    String? chapterName,
    int? hadithNumber,
    String? text,
    String? source,
    bool? isMemorized,
    DateTime? savedAt,
  }) {
    return HadithBookmarkModel(
      id: id ?? this.id,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      itemIndex: itemIndex ?? this.itemIndex,
      chapterName: chapterName ?? this.chapterName,
      hadithNumber: hadithNumber ?? this.hadithNumber,
      text: text ?? this.text,
      source: source ?? this.source,
      isMemorized: isMemorized ?? this.isMemorized,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chapterIndex': chapterIndex,
      'itemIndex': itemIndex,
      'chapterName': chapterName,
      'hadithNumber': hadithNumber,
      'text': text,
      'source': source,
      'isMemorized': isMemorized,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory HadithBookmarkModel.fromMap(Map<String, dynamic> map) {
    return HadithBookmarkModel(
      id: map['id']?.toString() ?? '',
      chapterIndex: (map['chapterIndex'] as num?)?.toInt() ?? 0,
      itemIndex: (map['itemIndex'] as num?)?.toInt() ?? 0,
      chapterName: map['chapterName']?.toString() ?? '',
      hadithNumber: (map['hadithNumber'] as num?)?.toInt() ?? 0,
      text: map['text']?.toString() ?? '',
      source: map['source']?.toString() ?? 'صحيح',
      isMemorized: map['isMemorized'] == true,
      savedAt: map['savedAt'] != null
          ? DateTime.tryParse(map['savedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory HadithBookmarkModel.fromJson(String source) =>
      HadithBookmarkModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
