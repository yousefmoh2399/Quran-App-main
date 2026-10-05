import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_radius.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/design/responsive.dart';
import '../../data/ramadan_service.dart';

class RamadanZakatView extends StatefulWidget {
  const RamadanZakatView({super.key});

  @override
  State<RamadanZakatView> createState() => _RamadanZakatViewState();
}

class _RamadanZakatViewState extends State<RamadanZakatView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RamadanService _service = RamadanService.instance;

  // Zakat Fitr inputs
  int _familyMembers = 4;
  final TextEditingController _fitrPriceController = TextEditingController(text: '35');

  // Zakat Mal inputs
  final TextEditingController _cashController = TextEditingController(text: '');
  final TextEditingController _goldValueController = TextEditingController(text: '');
  final TextEditingController _tradeGoodsController = TextEditingController(text: '');
  final TextEditingController _debtsController = TextEditingController(text: '');
  final TextEditingController _goldGramPriceController = TextEditingController(text: '3500');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fitrPriceController.dispose();
    _cashController.dispose();
    _goldValueController.dispose();
    _tradeGoodsController.dispose();
    _debtsController.dispose();
    _goldGramPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text('حاسبة الزكاة الذكية'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textMuted,
          indicatorColor: colors.primary,
          tabs: const [
            Tab(text: 'زكاة الفطر'),
            Tab(text: 'زكاة المال والتجارة'),
          ],
        ),
      ),
      body: MaxWidthContainer(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildZakatFitrTab(),
            _buildZakatMalTab(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 1: Zakat al-Fitr
  // --------------------------------------------------------------------------
  Widget _buildZakatFitrTab() {
    final colors = context.appColors;
    final pricePerPerson = double.tryParse(_fitrPriceController.text) ?? 35.0;
    final fitrResult = _service.calculateZakatFitr(
      familyMembers: _familyMembers,
      pricePerPerson: pricePerPerson,
    );
    final totalZakat = fitrResult['totalZakat'] as double;

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Output Card
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF09261E), Color(0xFF134E3E)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: AppRadius.borderLg,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
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
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'عن $_familyMembers أفراد بمعدل ${pricePerPerson.toStringAsFixed(0)} للفرد الواحد',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Inputs Card
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: colors.primary.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عدد أفراد الأسرة (المُعَالين ومن تلزمك نفقتهم):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.text),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: colors.primary.withOpacity(0.1),
                        foregroundColor: colors.primary,
                      ),
                      onPressed: _familyMembers > 1
                          ? () {
                              HapticFeedback.selectionClick();
                              setState(() => _familyMembers--);
                            }
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '$_familyMembers',
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
                        HapticFeedback.selectionClick();
                        setState(() => _familyMembers++);
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'قيمة الزكاة المقدرة للفرد الواحد (حسب دار الإفتاء أو بلدك):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.text),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _fitrPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'مثال: 35 أو 40',
                    suffixText: 'للفرد',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fiqh Guidance
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F0),
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: const Color(0xFFE5D8B8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.menu_book_rounded, color: Color(0xFF09261E), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'الضوابط الشرعية لزكاة الفطر',
                      style: TextStyle(
                        color: Color(0xFF09261E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• الحكمة منها: طهرة للصائم من اللغو والرفث وطعمة للمساكين ليعم الفرح يوم العيد.\n'
                  '• المقدار الشرعي: صاع من غالب قوت البلد (قمح، أرز، تمر) ويساوي تقريباً 2.5 إلى 3 كجم.\n'
                  '• إخراجها نقداً: أجازه جمهور واسع من أهل العلم تيسيراً وسداً لحاجة الفقير الحقيقية.\n'
                  '• وقت الإخراج: تجب بغروب شمس آخر يوم من رمضان، ويجوز إخراجها من أول الشهر، وأفضل أوقاتها قبل صلاة العيد.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2C3E50), height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Tab 2: Zakat al-Mal
  // --------------------------------------------------------------------------
  Widget _buildZakatMalTab() {
    final colors = context.appColors;

    final cash = double.tryParse(_cashController.text) ?? 0.0;
    final goldVal = double.tryParse(_goldValueController.text) ?? 0.0;
    final tradeGoods = double.tryParse(_tradeGoodsController.text) ?? 0.0;
    final debts = double.tryParse(_debtsController.text) ?? 0.0;
    final goldGramPrice = double.tryParse(_goldGramPriceController.text) ?? 3500.0;

    final malResult = _service.calculateZakatMal(
      cashAndSavings: cash,
      goldAndSilverValue: goldVal,
      tradeGoodsValue: tradeGoods,
      immediateDebtsToDeduct: debts,
      goldGramPrice21k: goldGramPrice,
    );

    final netWealth = malResult['netWealth'] as double;
    final nisab = malResult['nisabThreshold'] as double;
    final isEligible = malResult['isEligible'] as bool;
    final zakatDue = malResult['zakatDue'] as double;

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Result Card
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEligible
                    ? [const Color(0xFF09261E), const Color(0xFF1B4D3E)]
                    : [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: AppRadius.borderLg,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                Text(
                  isEligible ? 'الزكاة المستحقة شرعاً (2.5%)' : 'لم تبلغ أموالك النصاب الشرعي بعد',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  isEligible
                      ? '${zakatDue.toStringAsFixed(2)} وحدة نقدية'
                      : '0.00',
                  style: TextStyle(
                    color: isEligible ? const Color(0xFFD4AF37) : Colors.white60,
                    fontSize: 30,
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
          ),
          const SizedBox(height: 16),

          // Inputs
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: colors.primary.withOpacity(0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNumberField(
                  controller: _cashController,
                  label: 'الأموال النقدية والودائع البنكية:',
                  hint: '0',
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  controller: _goldValueController,
                  label: 'قيمة الذهب والسبائك المدخرة:',
                  hint: '0',
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  controller: _tradeGoodsController,
                  label: 'قيمة عروض التجارة والبضائع المعدة للبيع:',
                  hint: '0',
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  controller: _debtsController,
                  label: 'الديون الفورية المستحقة عليك (تُخصم):',
                  hint: '0',
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  controller: _goldGramPriceController,
                  label: 'سعر جرام الذهب عيار 21 اليوم (لتحديد النصاب):',
                  hint: '3500',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fiqh Guidance
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F0),
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: const Color(0xFFE5D8B8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF09261E), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'شروط وجوب زكاة المال',
                      style: TextStyle(
                        color: Color(0xFF09261E),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. بلوغ النصاب: ما يعادل قيمة 85 جراماً من الذهب الخالص.\n'
                  '2. حَوَلَان الحَوْل: أن يمر على المال سنة هجرية كاملة وهو بالغ للنصاب.\n'
                  '3. خلو المال من الدَّيْن والحاجة الأصلية.\n'
                  '4. المقدار الواجب إخراجه: ربع العُشر أي (2.5%) من إجمالي المال.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2C3E50), height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: context.appColors.text),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
