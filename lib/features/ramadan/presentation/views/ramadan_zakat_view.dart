import 'package:flutter/material.dart';
import '../../../zakat_calculator/presentation/views/zakat_calculator_view.dart';

/// RamadanZakatView wraps ZakatCalculatorView for full backwards-compatibility
/// across all Ramadan Hub routes and navigation.
class RamadanZakatView extends StatelessWidget {
  const RamadanZakatView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ZakatCalculatorView();
  }
}
