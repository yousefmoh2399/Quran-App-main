class AzkarCategoryEntity {
  final int id;
  final String name;
  final String? audio;
  final String? filename;

  const AzkarCategoryEntity({
    required this.id,
    required this.name,
    this.audio,
    this.filename,
  });

  factory AzkarCategoryEntity.fromMap(Map<String, dynamic> map) {
    return AzkarCategoryEntity(
      id: map['id'] as int,
      name: map['name'] as String,
      audio: map['audio'] as String?,
      filename: map['filename'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'audio': audio,
      'filename': filename,
    };
  }
}

class AzkarItemEntity {
  final int id;
  final int categoryId;
  final String categoryName;
  final int? itemId;
  final String textAr;
  final int count;
  final String? audio;
  final String? filename;

  const AzkarItemEntity({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    this.itemId,
    required this.textAr,
    required this.count,
    this.audio,
    this.filename,
  });

  factory AzkarItemEntity.fromMap(Map<String, dynamic> map) {
    return AzkarItemEntity(
      id: map['id'] as int,
      categoryId: map['category_id'] as int,
      categoryName: map['category_name'] as String,
      itemId: map['item_id'] as int?,
      textAr: map['text_ar'] as String,
      count: map['count'] as int,
      audio: map['audio'] as String?,
      filename: map['filename'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'item_id': itemId,
      'text_ar': textAr,
      'count': count,
      'audio': audio,
      'filename': filename,
    };
  }
}

class AzkarCategoryWithItems {
  final AzkarCategoryEntity category;
  final List<AzkarItemEntity> items;

  const AzkarCategoryWithItems({
    required this.category,
    required this.items,
  });
}
