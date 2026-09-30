import 'package:flutter/material.dart';
import '../../../mushaf/presentation/views/mushaf_view.dart';

/// Legacy DetailsScreen wrapper replaced with the authentic 604-page Madinah Mushaf.
class DetailsScreen extends StatelessWidget {
  const DetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MushafView();
  }
}
