import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_typography.dart';
import '../../../../core/design/responsive.dart';
import '../../../../core/services/app_haptics_service.dart';
import '../../data/models/salary_zakat_model.dart';
import '../controllers/zakat_calculator_controller.dart';
import '../widgets/charity_suggestion_card.dart';
import '../widgets/salary_zakat_card.dart';
import '../widgets/zakat_faqs_widget.dart';

class ZakatCalculatorView extends StatefulWidget {
  const ZakatCalculatorView({super.key});

  @override
  State<ZakatCalculatorView> createState() => _ZakatCalculatorViewState();
}

class _ZakatCalculatorViewState extends State<ZakatCalculatorView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ZakatCalculatorController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = Get.isRegistered<ZakatCalculatorController>()
        ? Get.find<ZakatCalculatorController>()
        : Get.put(ZakatCalculatorController());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.bg,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0.5,
          title: Text(
            'حاسبة الزكاة والصدقات الذكية',
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: colors.text,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_rounded, size: 20),
              tooltip: 'نسخ ملخص الحساب',
              onPressed: () {
                AppHaptics.selection();
                _controller.copySummary();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: colors.primary,
            unselectedLabelColor: colors.textMuted,
            indicatorColor: colors.primary,
            labelStyle: const TextStyle(
              fontFamily: AppTypography.uiFont,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 12.5,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance_wallet_rounded, size: 20),
                text: 'زكاة المرتب',
              ),
              Tab(
                icon: Icon(Icons.savings_rounded, size: 20),
                text: 'زكاة المال والتجارة',
              ),
              Tab(
                icon: Icon(Icons.volunteer_activism_rounded, size: 20),
                text: 'زكاة الفطر',
              ),
            ],
          ),
        ),
        body: MaxWidthContainer(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSalaryZakatTab(colors),
              _buildComprehensiveMalTab(colors),
              _buildFitrTab(colors),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // TAB 1: زكاة المرتب والدخل وسعر الذهب (الميزة المطلوبة)
  // ==========================================================================
  Widget _buildSalaryZakatTab(AppColorsExtension colors) {
    return Obx(() {
      final res = _controller.salaryResult.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dynamic Result Card (Obligatory Zakat or Below Nisab status)
            SalaryZakatCard(
              result: res,
              onCopy: _controller.copySummary,
            ),
            const SizedBox(height: 16),

            // If salary is below Nisab: Show the Charity Suggestion Card!
            if (res.amountEntered > 0 && !res.isZakatObligatory) ...[
              CharitySuggestionCard(
                result: res,
                selectedChoice: _controller.selectedCharityChoice.value,
                customAmount: _controller.customCharityAmount.value,
                onSelectChoice: _controller.selectCharityChoice,
                onCustomAmountChanged: _controller.setCustomCharityAmount,
                onOpenReminders: _controller.navigateToSadaqahReminders,
              ),
              const SizedBox(height: 16),
            ],

            // Input Fields Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: colors.primary.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'بيانات المرتب وسعر الذهب اليوم',
                          style: TextStyle(
                            fontFamily: AppTypography.uiFont,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: colors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Salary Calculation Type Segmented Control
                  Text(
                    'طبيعة المبلغ المدخل:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colors.text),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'المدخرات من المرتب (حال عليها الحول)',
                          isSelected: _controller.calculationType.value == SalaryCalculationType.yearlySavings,
                          onTap: () => _controller.setCalculationType(SalaryCalculationType.yearlySavings),
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'المرتب الشهري المباشر',
                          isSelected: _controller.calculationType.value == SalaryCalculationType.monthlySalary,
                          onTap: () => _controller.setCalculationType(SalaryCalculationType.monthlySalary),
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Salary Amount Input Field
                  _buildInputField(
                    controller: _controller.salaryController,
                    label: _controller.calculationType.value == SalaryCalculationType.yearlySavings
                        ? 'مجموع ما ادخرته من راتبك (البالغ للحول):'
                        : 'قيمة المرتب أو الدخل الشهري:',
                    hint: 'مثال: 15000 أو 50000',
                    suffix: 'وحدة نقدية',
                    icon: Icons.monetization_on_outlined,
                    colors: colors,
                  ),
                  const SizedBox(height: 14),

                  // Gold Karat Selection
                  Text(
                    'عيار الذهب المعتمد لحساب النصاب:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colors.text),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'عيار 21 (الأكثر شيوعاً)',
                          isSelected: _controller.selectedKarat.value == GoldKarat.karat21,
                          onTap: () => _controller.setGoldKarat(GoldKarat.karat21),
                          colors: colors,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'عيار 24 (الذهب الخالص 85 جم)',
                          isSelected: _controller.selectedKarat.value == GoldKarat.karat24,
                          onTap: () => _controller.setGoldKarat(GoldKarat.karat24),
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Gold Price per gram
                  _buildInputField(
                    controller: _controller.goldPriceController,
                    label: 'سعر جرام الذهب ${_controller.selectedKarat.value == GoldKarat.karat24 ? "عيار 24" : "عيار 21"} اليوم:',
                    hint: 'مثال: 3600',
                    suffix: 'لـلجرام',
                    icon: Icons.workspace_premium_rounded,
                    colors: colors,
                  ),
                  const SizedBox(height: 14),

                  // Deductible Debts
                  _buildInputField(
                    controller: _controller.debtsController,
                    label: 'الديون الفورية المستحقة عليك حالاً (تُخصم إن وُجدت):',
                    hint: '0',
                    suffix: 'وحدة نقدية',
                    icon: Icons.remove_circle_outline_rounded,
                    colors: colors,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // FAQs & Fiqh Guidance
            const ZakatFaqsWidget(),
          ],
        ),
      );
    });
  }

  // ==========================================================================
  // TAB 2: زكاة المال وعروض التجارة الشاملة
  // ==========================================================================
  Widget _buildComprehensiveMalTab(AppColorsExtension colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mal Result Card
          Builder(
            builder: (ctx) {
              final result = _controller.getComprehensiveMalResult();
              final isEligible = result['isEligible'] as bool;
              final zakatDue = result['zakatDue'] as double;
              final netWealth = result['netWealth'] as double;
              final nisab = result['nisabThreshold'] as double;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isEligible
                        ? [const Color(0xFF09261E), const Color(0xFF144D3E)]
                        : [const Color(0xFF1E3A5F), const Color(0xFF162E4A)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: isEligible ? const Color(0xFFD4AF37) : Colors.teal.shade300.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isEligible ? 'الزكاة المفروضة شرعاً (2.5%)' : 'المال لم يبلغ النصاب بعد',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEligible ? '${zakatDue.toStringAsFixed(2)} وحدة نقدية' : '0.00',
                      style: TextStyle(
                        color: isEligible ? const Color(0xFFD4AF37) : Colors.white60,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'صافي الوعاء الزكوي: ${netWealth.toStringAsFixed(0)} | النصاب (85 جم): ${nisab.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Mal Inputs Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: colors.primary.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(
                  controller: _controller.cashController,
                  label: 'الأموال النقدية والودائع البنكية:',
                  hint: '0',
                  suffix: 'وحدة',
                  icon: Icons.account_balance_rounded,
                  colors: colors,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _controller.goldValueController,
                  label: 'قيمة الذهب والسبائك المدخرة:',
                  hint: '0',
                  suffix: 'وحدة',
                  icon: Icons.workspace_premium_rounded,
                  colors: colors,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _controller.tradeGoodsController,
                  label: 'قيمة عروض التجارة والبضائع المعدة للبيع:',
                  hint: '0',
                  suffix: 'وحدة',
                  icon: Icons.storefront_rounded,
                  colors: colors,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _controller.malDebtsController,
                  label: 'الديون الفورية المستحقة عليك (تُخصم):',
                  hint: '0',
                  suffix: 'وحدة',
                  icon: Icons.remove_circle_outline_rounded,
                  colors: colors,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _controller.malGoldPriceController,
                  label: 'سعر جرام الذهب عيار 21 اليوم (لتحديد النصاب):',
                  hint: '3600',
                  suffix: 'لـلجرام',
                  icon: Icons.toll_rounded,
                  colors: colors,
                  onChanged: () => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fiqh Guidance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F0),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: const Color(0xFFE5D8B8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'شروط وجوب زكاة المال:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF4A3E1B)),
                ),
                SizedBox(height: 6),
                Text(
                  '1. بلوغ النصاب: ما يعادل قيمة 85 جراماً من الذهب الخالص.\n'
                  '2. حَوَلان الحَوْل: مرور سنة هجرية كاملة على بلوغ النصاب.\n'
                  '3. خلو المال من الديون الفورية ونفقات المعيشة الأساسية.\n'
                  '4. المقدار الواجب إخراجه: ربع العُشر أي (2.5%) من إجمالي المال.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // TAB 3: زكاة الفطر
  // ==========================================================================
  Widget _buildFitrTab(AppColorsExtension colors) {
    return Obx(() {
      final fitrResult = _controller.getFitrResult();
      final totalZakat = fitrResult['totalZakat'] as double;
      final pricePerPerson = fitrResult['pricePerPerson'] as double;
      final members = _controller.fitrFamilyMembers.value;

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Total Fitr Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF09261E), Color(0xFF144D3E)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text(
                    'إجمالي زكاة الفطر الواجب إخراجها',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${totalZakat.toStringAsFixed(0)} وحدة نقدية',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'عن $members أفراد بمعدل ${pricePerPerson.toStringAsFixed(0)} للفرد الواحد',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fitr Inputs
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: colors.primary.withOpacity(0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عدد أفراد الأسرة (المُعَالين ومن تلزمك نفقتهم):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: colors.text),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary.withOpacity(0.1),
                          foregroundColor: colors.primary,
                        ),
                        onPressed: members > 1
                            ? () {
                                AppHaptics.selection();
                                _controller.decrementFitrMembers();
                              }
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '$members',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: colors.primary.withOpacity(0.1),
                          foregroundColor: colors.primary,
                        ),
                        onPressed: () {
                          AppHaptics.selection();
                          _controller.incrementFitrMembers();
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildInputField(
                    controller: _controller.fitrPriceController,
                    label: 'قيمة الزكاة المقدرة للفرد الواحد (حسب دار الإفتاء):',
                    hint: 'مثال: 35 أو 40',
                    suffix: 'للفرد',
                    icon: Icons.person_outline_rounded,
                    colors: colors,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fitr Fiqh Guidance
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F0),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: const Color(0xFFE5D8B8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'الضوابط الشرعية لزكاة الفطر:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF4A3E1B)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• الحكمة: طهرة للصائم من اللغو والرفث وطعمة للمساكين ليعم الفرح يوم العيد.\n'
                    '• المقدار: صاع من غالب قوت البلد (قمح، أرز، تمر) ويساوي تقريباً 2.5 كجم.\n'
                    '• القيمة نقداً: أجازها أئمة كبار (كالحنفية وعمر بن عبد العزيز) تيسيراً وسداً لحاجة الفقير.\n'
                    '• وقت الإخراج: تجب بغروب شمس آخر يوم من رمضان وتستمر حتى صلاة العيد.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF333333), height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // --------------------------------------------------------------------------
  // UI Helpers
  // --------------------------------------------------------------------------

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required AppColorsExtension colors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          AppHaptics.selection();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withOpacity(0.12) : colors.bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? colors.primary : colors.divider.withOpacity(0.5),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.uiFont,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.primary : colors.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required AppColorsExtension colors,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colors.text),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: colors.primary, size: 20),
            suffixText: suffix,
            suffixStyle: TextStyle(fontSize: 12, color: colors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.divider.withOpacity(0.7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            filled: true,
            fillColor: colors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (_) {
            if (onChanged != null) onChanged();
          },
        ),
      ],
    );
  }
}
