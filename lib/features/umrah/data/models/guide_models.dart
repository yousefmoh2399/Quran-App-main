import 'package:flutter/foundation.dart';

@immutable
class ContentSourceModel {
  final String title;
  final String author;
  final String reviewedAt;
  final String status;
  final String? notes;

  const ContentSourceModel({
    required this.title,
    this.author = '',
    required this.reviewedAt,
    this.status = 'معتمد وموثق',
    this.notes,
  });

  factory ContentSourceModel.fromJson(Map<String, dynamic> json) {
    return ContentSourceModel(
      title: json['title'] as String? ?? 'صحيح السنة النبوية',
      author: json['author'] as String? ?? '',
      reviewedAt: json['reviewedAt'] as String? ?? '1446هـ',
      status: json['status'] as String? ?? 'معتمد وموثق',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'reviewedAt': reviewedAt,
        'status': status,
        if (notes != null) 'notes': notes,
      };
}

@immutable
class DuaModel {
  final String id;
  final String title;
  final String arabicText;
  final String source;
  final String reviewedAt;
  final int? lap;
  final String? from;
  final String? to;

  const DuaModel({
    required this.id,
    required this.title,
    required this.arabicText,
    required this.source,
    required this.reviewedAt,
    this.lap,
    this.from,
    this.to,
  });

  factory DuaModel.fromJson(Map<String, dynamic> json) {
    return DuaModel(
      id: json['id'] as String? ?? (json['lap'] != null ? 'lap_${json['lap']}' : 'dua_item'),
      title: json['title'] as String? ?? '',
      arabicText: json['arabic_text'] as String? ?? '',
      source: json['source'] as String? ?? 'صحيح السنة النبوية',
      reviewedAt: json['reviewedAt'] as String? ?? '1446هـ',
      lap: json['lap'] as int?,
      from: json['from'] as String?,
      to: json['to'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'arabic_text': arabicText,
        'source': source,
        'reviewedAt': reviewedAt,
        if (lap != null) 'lap': lap,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      };
}

@immutable
class GuideStepModel {
  final String id;
  final int order;
  final String title;
  final String shortDescription;
  final String instruction;
  final String? notes;
  final ContentSourceModel source;
  final List<DuaModel> duas;
  final List<DuaModel> lapsDuas;
  final bool isCompleted;
  final DateTime? completedAt;
  final int currentLap;

  const GuideStepModel({
    required this.id,
    required this.order,
    required this.title,
    required this.shortDescription,
    required this.instruction,
    this.notes,
    required this.source,
    this.duas = const [],
    this.lapsDuas = const [],
    this.isCompleted = false,
    this.completedAt,
    this.currentLap = 0,
  });

  GuideStepModel copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    int? currentLap,
  }) {
    return GuideStepModel(
      id: id,
      order: order,
      title: title,
      shortDescription: shortDescription,
      instruction: instruction,
      notes: notes,
      source: source,
      duas: duas,
      lapsDuas: lapsDuas,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      currentLap: currentLap ?? this.currentLap,
    );
  }

  factory GuideStepModel.fromJson(Map<String, dynamic> json) {
    final rawDuas = json['duas'] as List<dynamic>? ?? [];
    final rawLaps = json['laps_duas'] as List<dynamic>? ?? [];
    final sourceJson = json['source'] as Map<String, dynamic>?;

    return GuideStepModel(
      id: json['id'] as String? ?? 'step',
      order: json['order'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      instruction: json['instruction'] as String? ?? '',
      notes: json['notes'] as String?,
      source: sourceJson != null
          ? ContentSourceModel.fromJson(sourceJson)
          : const ContentSourceModel(
              title: 'دليل المناسك في ضوء الكتاب والسنة',
              reviewedAt: '1446هـ',
            ),
      duas: rawDuas.map((d) => DuaModel.fromJson(d as Map<String, dynamic>)).toList(),
      lapsDuas: rawLaps.map((d) => DuaModel.fromJson(d as Map<String, dynamic>)).toList(),
      isCompleted: false,
      currentLap: 0,
    );
  }
}

@immutable
class CongestionPatternModel {
  final String id;
  final String timeTitle;
  final String timeRange;
  final String crowdLevel;
  final String levelCode;
  final double levelPercent;
  final String notes;
  final String tip;

  const CongestionPatternModel({
    required this.id,
    required this.timeTitle,
    required this.timeRange,
    required this.crowdLevel,
    required this.levelCode,
    required this.levelPercent,
    required this.notes,
    required this.tip,
  });

  factory CongestionPatternModel.fromJson(Map<String, dynamic> json) {
    return CongestionPatternModel(
      id: json['id'] as String? ?? '',
      timeTitle: json['time_title'] as String? ?? '',
      timeRange: json['time_range'] as String? ?? '',
      crowdLevel: json['crowd_level'] as String? ?? '',
      levelCode: json['level_code'] as String? ?? 'medium',
      levelPercent: (json['level_percent'] as num?)?.toDouble() ?? 0.5,
      notes: json['notes'] as String? ?? '',
      tip: json['tip'] as String? ?? '',
    );
  }
}

@immutable
class CongestionEstimateModel {
  final String disclaimer;
  final String reviewedAt;
  final List<CongestionPatternModel> patterns;

  const CongestionEstimateModel({
    required this.disclaimer,
    required this.reviewedAt,
    this.patterns = const [],
  });

  factory CongestionEstimateModel.fromJson(Map<String, dynamic> json) {
    final rawPatterns = json['patterns'] as List<dynamic>? ?? [];
    return CongestionEstimateModel(
      disclaimer: json['disclaimer'] as String? ??
          'تقدير تقريبي مبني على الأنماط التاريخية والمعتادة - ليس بيانات حية أو لحظية.',
      reviewedAt: json['reviewedAt'] as String? ?? '2026-10-01',
      patterns: rawPatterns
          .map((p) => CongestionPatternModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class SourceReviewItem {
  final String sourceName;
  final String publisher;
  final String edition;
  final String status;
  final String reviewedAt;
  final String notes;

  const SourceReviewItem({
    required this.sourceName,
    required this.publisher,
    required this.edition,
    required this.status,
    required this.reviewedAt,
    required this.notes,
  });

  factory SourceReviewItem.fromJson(Map<String, dynamic> json) {
    return SourceReviewItem(
      sourceName: json['source_name'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      edition: json['edition'] as String? ?? '',
      status: json['status'] as String? ?? 'معتمد وموثق',
      reviewedAt: json['reviewed_at'] as String? ?? '1446هـ',
      notes: json['notes'] as String? ?? '',
    );
  }
}

@immutable
class GuideModel {
  final String id;
  final String title;
  final String subtitle;
  final int version;
  final String disclaimer;
  final String reviewedAt;
  final ContentSourceModel defaultSource;
  final List<GuideStepModel> steps;
  final CongestionEstimateModel congestion;
  final List<SourceReviewItem> sourcesReview;

  const GuideModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.version,
    required this.disclaimer,
    required this.reviewedAt,
    required this.defaultSource,
    required this.steps,
    required this.congestion,
    required this.sourcesReview,
  });

  factory GuideModel.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    final rawSources = json['sources_review'] as List<dynamic>? ?? [];
    final defSourceJson = json['defaultSource'] as Map<String, dynamic>?;
    final congestionJson = json['congestion_estimates'] as Map<String, dynamic>? ?? {};

    return GuideModel(
      id: json['guide_id'] as String? ?? 'umrah',
      title: json['title'] as String? ?? 'دليل المناسك',
      subtitle: json['subtitle'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      disclaimer: json['disclaimer'] as String? ??
          'دليل إرشادي لمناسك الحج والعمرة مستمد من القرآن الكريم وصحيح السنة النبوية المطهرة.',
      reviewedAt: json['reviewedAt'] as String? ?? '1446هـ',
      defaultSource: defSourceJson != null
          ? ContentSourceModel.fromJson(defSourceJson)
          : const ContentSourceModel(
              title: 'دليل المناسك في ضوء الكتاب والسنة',
              reviewedAt: '1446هـ',
            ),
      steps: rawSteps.map((s) => GuideStepModel.fromJson(s as Map<String, dynamic>)).toList(),
      congestion: CongestionEstimateModel.fromJson(congestionJson),
      sourcesReview: rawSources
          .map((s) => SourceReviewItem.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class TripDiaryEntry {
  final int? id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripDiaryEntry({
    this.id,
    required this.title,
    required this.content,
    this.category = 'عام',
    required this.createdAt,
    required this.updatedAt,
  });

  TripDiaryEntry copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripDiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TripDiaryEntry.fromMap(Map<String, dynamic> map) {
    return TripDiaryEntry(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'عام',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'content': content,
        'category': category,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

@immutable
class PilgrimChecklistItem {
  final String id;
  final String title;
  final String category;
  final String note;
  final bool isChecked;
  final bool isCustom;
  final DateTime createdAt;

  PilgrimChecklistItem({
    required this.id,
    required this.title,
    required this.category,
    this.note = '',
    this.isChecked = false,
    this.isCustom = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  PilgrimChecklistItem copyWith({
    String? id,
    String? title,
    String? category,
    String? note,
    bool? isChecked,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return PilgrimChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      isChecked: isChecked ?? this.isChecked,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory PilgrimChecklistItem.fromMap(Map<String, dynamic> map) {
    return PilgrimChecklistItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'عام',
      note: map['note'] as String? ?? '',
      isChecked: (map['is_checked'] as int? ?? 0) == 1,
      isCustom: (map['is_custom'] as int? ?? 0) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'note': note,
        'is_checked': isChecked ? 1 : 0,
        'is_custom': isCustom ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };
}

