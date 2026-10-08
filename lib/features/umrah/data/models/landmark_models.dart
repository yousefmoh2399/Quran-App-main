import 'package:flutter/material.dart';

class LandmarkItem {
  final String id;
  final String name;
  final String city; // 'مكة المكرمة' or 'المدينة المنورة'
  final String category; // 'أركان ومشاعر', 'معالم تاريخية', 'أبواب ومعالم'
  final String summary;
  final String virtues;
  final List<String> mannersAndSunnahs;
  final List<String> commonMistakes;
  final String practicalAdvice;
  final IconData icon;

  const LandmarkItem({
    required this.id,
    required this.name,
    required this.city,
    required this.category,
    required this.summary,
    required this.virtues,
    required this.mannersAndSunnahs,
    required this.commonMistakes,
    required this.practicalAdvice,
    required this.icon,
  });
}
