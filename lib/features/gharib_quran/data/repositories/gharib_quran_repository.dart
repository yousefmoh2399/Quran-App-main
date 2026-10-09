import '../../../../core/data/arabic_normalizer.dart';
import '../models/quran_vocabulary_word.dart';

/// Repository for authentic Quranic Vocabulary (معجم غريب القرآن).
/// 100% Offline with zero external dependencies.
class GharibQuranRepository {
  GharibQuranRepository._();
  static final GharibQuranRepository instance = GharibQuranRepository._();

  /// Curated dataset of authentic Gharib Al-Quran words across the Quran
  static const List<QuranVocabularyWord> _wordsDataset = [
    QuranVocabularyWord(
      id: 'voc_1',
      word: 'عَسْعَسَ',
      root: 'ع-س-س',
      meaning: 'أَدْبَرَ بِظَلامِهِ وَانْصَرَفَ، وَقِيلَ: أَقْبَلَ أَوَّلُهُ',
      surahId: 81,
      surahName: 'التكوير',
      ayahNumber: 17,
      pageNumber: 586,
      ayahSnippet: 'وَاللَّيْلِ إِذَا عَسْعَسَ',
      linguisticBenefit: 'من بديع ألفاظ القرآن التي تُطلق على الضدين، وفي حركة لفظها إيقاعٌ يصور تحرك جند الظلام عند ولائه وإدباره.',
    ),
    QuranVocabularyWord(
      id: 'voc_2',
      word: 'قَسْوَرَةٍ',
      root: 'ق-س-ر',
      meaning: 'الأَسَدُ الشَّدِيدُ، وَقِيلَ: الرُّمَاةُ وَالصَّيَّادُونَ',
      surahId: 74,
      surahName: 'المدثر',
      ayahNumber: 51,
      pageNumber: 576,
      ayahSnippet: 'فَرَّتْ مِن قَسْوَرَةٍ',
      linguisticBenefit: 'اشتقاقه من القسر وهو القهر والغلبة؛ فسمى الأسد قسورة لأنه يقهر السباع ويقسر الفريسة.',
    ),
    QuranVocabularyWord(
      id: 'voc_3',
      word: 'حَنَانًا',
      root: 'ح-ن-ن',
      meaning: 'رَحْمَةً وَشَفَقَةً وَعَطْفًا مِنَّا عَلَى خَلْقِهِ',
      surahId: 19,
      surahName: 'مريم',
      ayahNumber: 13,
      pageNumber: 306,
      ayahSnippet: 'وَحَنَانًا مِّن لَّدُنَّا وَزَكَاةً ۖ وَكَانَ تَقِيًّا',
      linguisticBenefit: 'وصف الله تعالى رحمته ليحيى بالحنان؛ وهو اللين والرقة البالغة التي تفيض عطاءً دون مشقة.',
    ),
    QuranVocabularyWord(
      id: 'voc_4',
      word: 'غِسْلِينٍ',
      root: 'غ-س-ل',
      meaning: 'صَدِيدُ أَهْلِ النَّارِ وَمَا يَسِيلُ مِنْ جُلُودِهِمْ وَفُرُوجِهِمْ',
      surahId: 69,
      surahName: 'الحاقة',
      ayahNumber: 36,
      pageNumber: 568,
      ayahSnippet: 'وَلَا طَعَامٌ إِلَّا مِنْ غِسْلِينٍ',
      linguisticBenefit: 'وزن فِعْلين يدل على المبالغة في النتن والقذارة كأنه غُسالة الجروح والأنتان أجمع.',
    ),
    QuranVocabularyWord(
      id: 'voc_5',
      word: 'كُبِتُوا',
      root: 'ك-ب-ت',
      meaning: 'أُذِلُّوا وَأُخْزُوا وَأُهْلِكُوا كَمَا فُعِلَ بِمَنْ قَبْلَهُمْ',
      surahId: 58,
      surahName: 'المجادلة',
      ayahNumber: 5,
      pageNumber: 542,
      ayahSnippet: 'كُبِتُوا كَمَا كُبِتَ الَّذِينَ مِن قَبْلِهِمْ',
      linguisticBenefit: 'الكبت هو شدة الغيظ المصحوب بالهوان والخزي حتى ينكسر قلب المحارب.',
    ),
    QuranVocabularyWord(
      id: 'voc_6',
      word: 'الْخُنَّسِ',
      root: 'خ-ن-س',
      meaning: 'الْكَوَاكِبُ الَّتِي تَخْنِسُ (تَخْتَفِي) نَهَارًا وَتَظْهَرُ لَيْلًا',
      surahId: 81,
      surahName: 'التكوير',
      ayahNumber: 15,
      pageNumber: 586,
      ayahSnippet: 'فَلَا أُقْسِمُ بِالْخُنَّسِ',
      linguisticBenefit: 'الخنس هو التراجع والاستتار، ومنه الوسواس الخناس لأنه يفر ويختفي عند ذكر الله.',
    ),
    QuranVocabularyWord(
      id: 'voc_7',
      word: 'ضِيزَىٰ',
      root: 'ض-و-ز',
      meaning: 'قِسْمَةٌ جَائِرَةٌ ظَالِمَةٌ نَاقِصَةٌ مَائِلَةٌ عَنِ الْحَقِّ',
      surahId: 53,
      surahName: 'النجم',
      ayahNumber: 22,
      pageNumber: 527,
      ayahSnippet: 'تِلْكَ إِذًا قِسْمَةٌ ضِيزَىٰ',
      linguisticBenefit: 'ضاز في الحكم إذا ظلم وجار، وجاءت بالياء والكسر لتناسب فواصل سور النجم ذات الوقع القوي.',
    ),
    QuranVocabularyWord(
      id: 'voc_8',
      word: 'صَلْدًا',
      root: 'ص-ل-د',
      meaning: 'حَجَرًا أَمْلَسَ نَقِيًّا لَا شَيْءَ عَلَيْهِ مِنَ التُّرَابِ أَوِ النَّبَاتِ',
      surahId: 2,
      surahName: 'البقرة',
      ayahNumber: 264,
      pageNumber: 44,
      ayahSnippet: 'فَتَرَكَهُ صَلْدًا',
      linguisticBenefit: 'تصوير معجز لضياع أجر المرائي: كالمطر الذي يغسل الحجر الأملس فلا ينبت فيه شيء أبداً.',
    ),
    QuranVocabularyWord(
      id: 'voc_9',
      word: 'فَاقِعٌ',
      root: 'ف-ق-ع',
      meaning: 'خَالِصُ الصُّفْرَةِ شَدِيدُ النَّصَاعَةِ يَسُرُّ النَّاظِرِينَ',
      surahId: 2,
      surahName: 'البقرة',
      ayahNumber: 69,
      pageNumber: 10,
      ayahSnippet: 'صَفْرَاءُ فَاقِعٌ لَّوْنُهَا تَسُرُّ النَّاظِرِينَ',
      linguisticBenefit: 'العرب تقول: أصفر فاقع، وأحمر قانئ، وأبيض ناصع، وأسود حالك؛ فالفاقع خاص بالصفرة البهيجة.',
    ),
    QuranVocabularyWord(
      id: 'voc_10',
      word: 'سِجِّيلٍ',
      root: 'س-ج-ل',
      meaning: 'طِينٍ مُتَحَجِّرٍ مَطْبُوخٍ بِحَرَارَةِ النَّارِ شَدِيدِ الإِحْرَاقِ',
      surahId: 105,
      surahName: 'الفيل',
      ayahNumber: 4,
      pageNumber: 601,
      ayahSnippet: 'تَرْمِيهِم بِحِجَارَةٍ مِّن سِجِّيلٍ',
      linguisticBenefit: 'معرّب من الفارسية (سنج وكل) أي حجر وطين، ويدل على قذائف هلاك خارقة للجسد.',
    ),
    QuranVocabularyWord(
      id: 'voc_11',
      word: 'كُشِطَتْ',
      root: 'ك-ش-ط',
      meaning: 'قُلِعَتْ وَنُزِعَتْ كَمَا يُكْشَطُ الْجِلْدُ عَنِ الشَّاةِ',
      surahId: 81,
      surahName: 'التكوير',
      ayahNumber: 11,
      pageNumber: 586,
      ayahSnippet: 'وَإِذَا السَّمَاءُ كُشِطَتْ',
      linguisticBenefit: 'الكشط هو رفع الشيء المطبق عن مكانه دفعة واحدة، دلالة على سرعة زوال السماء وانكشاف ما ورائها.',
    ),
    QuranVocabularyWord(
      id: 'voc_12',
      word: 'فِجَاجًا',
      root: 'ف-ج-ج',
      meaning: 'مَسَالِكَ وَطُرُقًا وَاسِعَةً بَيْنَ الْجِبَالِ',
      surahId: 21,
      surahName: 'الأنبياء',
      ayahNumber: 31,
      pageNumber: 324,
      ayahSnippet: 'وَجَعَلْنَا فِيهَا فِجَاجًا سُبُلًا',
      linguisticBenefit: 'الفج هو الطريق الواسع الواضح بين جبلين يسهل على السالكين المرور فيه دون انقطاع.',
    ),
    QuranVocabularyWord(
      id: 'voc_13',
      word: 'رَتْقًا',
      root: 'ر-ت-ق',
      meaning: 'مُلْتَصِقَتَيْنِ لَا فَرَاغَ وَلَا فَتْقَ بَيْنَهُمَا فَمَا كَانَ يَنْزِلُ مَطَرٌ وَلَا يَنْبُتُ شَجَرٌ',
      surahId: 21,
      surahName: 'الأنبياء',
      ayahNumber: 30,
      pageNumber: 324,
      ayahSnippet: 'كَانَتَا رَتْقًا فَفَتَقْنَاهُمَا',
      linguisticBenefit: 'الرتق ضد الفتق؛ وهو الالتئام والضم التام الذي يعجز البشر عن إحداثه أو شقه.',
    ),
    QuranVocabularyWord(
      id: 'voc_14',
      word: 'أَثَاثًا',
      root: 'أ-ث-ث',
      meaning: 'مَتَاعَ الْبَيْتِ وَمَا يُسْتَفَادُ مِنْهُ مِنْ فُرُشٍ وَكِسْوَةٍ وَأَوَانٍ فَاخِرَةٍ',
      surahId: 19,
      surahName: 'مريم',
      ayahNumber: 74,
      pageNumber: 310,
      ayahSnippet: 'هُمْ أَحْسَنُ أَثَاثًا وَرِءْيًا',
      linguisticBenefit: 'أث الشيء إذا كثر وتكاثف؛ فالأثاث هو المتاع الكثير المتكاثف الذي يملأ البيت فخامة.',
    ),
    QuranVocabularyWord(
      id: 'voc_15',
      word: 'تَبَتَّلْ',
      root: 'ب-ت-ل',
      meaning: 'انْقَطِعْ إِلَى عِبَادَتِهِ وَأَخْلِصْ لَهُ الْعَمَلَ انْقِطَاعًا تَامًّا',
      surahId: 73,
      surahName: 'المزمل',
      ayahNumber: 8,
      pageNumber: 574,
      ayahSnippet: 'وَتَبَتَّلْ إِلَيْهِ تَبْتِيلًا',
      linguisticBenefit: 'البتل هو القطع؛ والتبتل لله هو قطع كل تعلق بمخلوق وتفريغ القلب لجلال الخالق.',
    ),
    QuranVocabularyWord(
      id: 'voc_16',
      word: 'مُّبْلِسُونَ',
      root: 'ب-ل-س',
      meaning: 'يَائِسُونَ سَاكِتُونَ مِنْ شِدَّةِ الْحَيْرَةِ وَانْقِطَاعِ الْحُجَّةِ',
      surahId: 6,
      surahName: 'الأنعام',
      ayahNumber: 44,
      pageNumber: 132,
      ayahSnippet: 'فَإِذَا هُم مُّبْلِسُونَ',
      linguisticBenefit: 'الإبلاس هو اليأس والسكوت المصحوب بالحسرة والندامة، ومنه سُمي إبليس لإبلاسه من رحمة الله.',
    ),
    QuranVocabularyWord(
      id: 'voc_17',
      word: 'مَسْغَبَةٍ',
      root: 'س-غ-ب',
      meaning: 'مَجَاعَةٍ شَدِيدَةٍ يَجْهَدُ فِيهَا الْجُوعُ وَيَشُقُّ فِيهَا الْحُصُولُ عَلَى الْقُوتِ',
      surahId: 90,
      surahName: 'البلد',
      ayahNumber: 14,
      pageNumber: 594,
      ayahSnippet: 'فِي يَوْمٍ ذِي مَسْغَبَةٍ',
      linguisticBenefit: 'السغب هو الجوع مع التعب والعطش؛ فالإطعام في هذا اليوم عظيم الأجر لشدة الحاجة.',
    ),
    QuranVocabularyWord(
      id: 'voc_18',
      word: 'كَبَدٍ',
      root: 'ك-ب-د',
      meaning: 'نَصَبٍ وَمَشَقَّةٍ وَمُكَابَدَةٍ لِشَدَائِدِ الدُّنْيَا وَالآخِرَةِ',
      surahId: 90,
      surahName: 'البلد',
      ayahNumber: 4,
      pageNumber: 594,
      ayahSnippet: 'لَقَدْ خَلَقْنَا الْإِنسَانَ فِي كَبَدٍ',
      linguisticBenefit: 'الكبد هو ألم المشقة والجهد، وقيل انتصاب القامة واستواؤها خلافاً للحيوانات.',
    ),
    QuranVocabularyWord(
      id: 'voc_19',
      word: 'التَّرَاقِيَ',
      root: 'ت-ر-ق',
      meaning: 'عِظَامَ أَعْلَى الصَّدْرِ حَوْلَ الْحَلْقِ (عِنْدَ بُلُوغِ الرُّوحِ الْحُلْقُومَ)',
      surahId: 75,
      surahName: 'القيامة',
      ayahNumber: 26,
      pageNumber: 578,
      ayahSnippet: 'كَلَّا إِذَا بَلَغَتِ التَّرَاقِيَ',
      linguisticBenefit: 'جمع ترقوة؛ وهي العظم الممتد بين ثغرة النحر والعاتق، وتدل على اللحظة الأخيرة للاحتضار.',
    ),
    QuranVocabularyWord(
      id: 'voc_20',
      word: 'نَاصِيَةٍ',
      root: 'ن-ص-ي',
      meaning: 'مُقَدَّمِ شَعْرِ الرَّأْسِ، وَهِيَ مَوْضِعُ الْقِيَادَةِ وَالإِرَادَةِ',
      surahId: 96,
      surahName: 'العلق',
      ayahNumber: 15,
      pageNumber: 597,
      ayahSnippet: 'لَنَسْفَعًا بِالنَّاصِيَةِ',
      linguisticBenefit: 'السفع بالناصية هو الجذب الشديد بعنف وإذلال، وتخصيص الناصية لأنها أعلى ما في الإنسان وموضع عزه.',
    ),
    QuranVocabularyWord(
      id: 'voc_21',
      word: 'الصَّمَدُ',
      root: 'ص-م-د',
      meaning: 'السَّيِّدُ الْمُطْلَقُ الَّذِي تُصْمَدُ (تُقْصَدُ) إِلَيْهِ الْحَوَائِجُ، الْمُسْتَغْنِي عَنْ كُلِّ أَحَدٍ',
      surahId: 112,
      surahName: 'الإخلاص',
      ayahNumber: 2,
      pageNumber: 604,
      ayahSnippet: 'اللَّهُ الصَّمَدُ',
      linguisticBenefit: 'أصل الصمد في لغة العرب: القصد؛ فالخلائق كلها تقصده في كل مسألة ولا يقصد هو سبحانه أحداً.',
    ),
    QuranVocabularyWord(
      id: 'voc_22',
      word: 'غَاسِقٍ',
      root: 'غ-س-ق',
      meaning: 'اللَّيْلِ إِذَا أَظْلَمَ وَاشْتَدَّتْ عَتَمَتُهُ وَسَرَتْ فِيهِ الشُّرُورُ',
      surahId: 113,
      surahName: 'الفلق',
      ayahNumber: 3,
      pageNumber: 604,
      ayahSnippet: 'وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ',
      linguisticBenefit: 'الغسق هو أول ظلمة الليل عند امتلاء الأفق بالسواد، ووقب أي دخل ظلامه واستحكم.',
    ),
    QuranVocabularyWord(
      id: 'voc_23',
      word: 'سَلْسَبِيلًا',
      root: 'س-ل-س',
      meaning: 'عَيْنًا فِي الْجَنَّةِ سَهْلَةَ الْمَسَاغِ لَذِيذَةَ الْجَرْيِ لَا غُصَّةَ فِيهَا',
      surahId: 76,
      surahName: 'الإنسان',
      ayahNumber: 18,
      pageNumber: 579,
      ayahSnippet: 'عَيْنًا فِيهَا تُسَمَّىٰ سَلْسَبِيلًا',
      linguisticBenefit: 'سلسيل لغةً: السهل الانحدار في الحلق لخفته وعذوبته وطيب طعمه ورائحته.',
    ),
    QuranVocabularyWord(
      id: 'voc_24',
      word: 'أَمْشَاجٍ',
      root: 'م-ش-ج',
      meaning: 'أَخْلاطٍ مُمْتَزِجَةٍ مِنْ مَاءِ الرَّجُلِ وَمَاءِ الْمَرْأَةِ وَأَطْوَارِ الْجَنِينِ',
      surahId: 76,
      surahName: 'الإنسان',
      ayahNumber: 2,
      pageNumber: 578,
      ayahSnippet: 'خَلَقْنَا الْإِنسَانَ مِن نُّطْفَةٍ أَمْشَاجٍ',
      linguisticBenefit: 'المشج هو خلط الشيء بغيره حتى يصيرا شيئاً واحداً؛ دلالة على الإعجاز البيولوجي للقرآن.',
    ),
    QuranVocabularyWord(
      id: 'voc_25',
      word: 'حُطَمَةُ',
      root: 'ح-ط-م',
      meaning: 'نَارُ جَهَنَّمَ الَّتِي تَحْطِمُ وَتَهُشِّمُ وَتَكْسِرُ كُلَّ مَا يُلْقَىٰ فِيهَا',
      surahId: 104,
      surahName: 'الهمزة',
      ayahNumber: 4,
      pageNumber: 601,
      ayahSnippet: 'كَلَّا ۖ لَيُنبَذَنَّ فِي الْحُطَمَةِ',
      linguisticBenefit: 'صيغة فُعَلَة تدل على الكثرة والاعتياد، أي كثيرة الحطم والتكسير للعظام والأجساد.',
    ),
    QuranVocabularyWord(
      id: 'voc_26',
      word: 'الصَّاخَّةُ',
      root: 'ص-خ-خ',
      meaning: 'صَيْحَةُ الْقِيَامَةِ الَّتِي تَصُخُّ الآذَانَ (تَشُقُّهَا) لِشِدَّةِ هَوْلِهَا',
      surahId: 80,
      surahName: 'عبس',
      ayahNumber: 33,
      pageNumber: 585,
      ayahSnippet: 'فَإِذَا جَاءَتِ الصَّاخَّةُ',
      linguisticBenefit: 'الصخ هو القرع الشديد المؤلم الذي يكاد يذهب بالسمع، يعبر عن فزع ذلك اليوم العظيم.',
    ),
    QuranVocabularyWord(
      id: 'voc_27',
      word: 'نَمَارِقُ',
      root: 'ن-م-ر-ق',
      meaning: 'وَسَائِدُ وَمَرَافِقُ مَصْفُوفَةٌ لِلْمُتَّكِئِينَ فِي الْجَنَّةِ',
      surahId: 88,
      surahName: 'الغاشية',
      ayahNumber: 15,
      pageNumber: 592,
      ayahSnippet: 'وَنَمَارِقُ مَصْفُوفَةٌ',
      linguisticBenefit: 'النمرقة هي الوسادة الصغيرة اللينة التي يُتكأ عليها في مجالس الشرف والملك.',
    ),
    QuranVocabularyWord(
      id: 'voc_28',
      word: 'زَرَابِيُّ',
      root: 'ز-ر-ب',
      meaning: 'بُسُطٌ وَطَنَافِسُ فَاخِرَةٌ مَبْثُوثَةٌ كَثِيرَةٌ ذَاتُ خَمَلٍ نَاعِمٍ',
      surahId: 88,
      surahName: 'الغاشية',
      ayahNumber: 16,
      pageNumber: 592,
      ayahSnippet: 'وَزَرَابِيُّ مَبْثُوثَةٌ',
      linguisticBenefit: 'الزربية هي البساط المنسوج المزركش بألوان حسنة دقيقة الصنعة.',
    ),
    QuranVocabularyWord(
      id: 'voc_29',
      word: 'ضَرِيعٍ',
      root: 'ض-ر-ع',
      meaning: 'نَبْتٍ شَوْكِيٍّ يَابِسٍ مُرٍّ خَبِيثِ الرَّائِحَةِ لَا تَرْعَاهُ حَتَّى الْإِبِلُ',
      surahId: 88,
      surahName: 'الغاشية',
      ayahNumber: 6,
      pageNumber: 592,
      ayahSnippet: 'لَّيْسَ لَهُمْ طَعَامٌ إِلَّا مِن ضَرِيعٍ',
      linguisticBenefit: 'الشبرق إذا يبس سُمي ضريعاً، وهو شديد السمية لا يسمن الجائع ولا يروي عطشه.',
    ),
    QuranVocabularyWord(
      id: 'voc_30',
      word: 'شِقَاقٍ',
      root: 'ش-ق-ق',
      meaning: 'خِلافٍ وَعِنَادٍ وَمُعَانَدَةٍ تَجْعَلُ الْمُخَالِفَ فِي شِقٍّ وَالْحَقَّ فِي شِقٍّ آخَرَ',
      surahId: 2,
      surahName: 'البقرة',
      ayahNumber: 137,
      pageNumber: 21,
      ayahSnippet: 'فَإِنَّمَا هُمْ فِي شِقَاقٍ',
      linguisticBenefit: 'الشقاق مأخوذ من الشق (الجانب)؛ لأن العاصي ينعزل في جانب كراهة للحق وأهله.',
    ),
  ];

  /// Returns words for a specific Ayah (if recorded), or empty list.
  List<QuranVocabularyWord> getWordsForAyah(int surahId, int ayahNumber) {
    return _wordsDataset
        .where((w) => w.surahId == surahId && w.ayahNumber == ayahNumber)
        .toList();
  }

  /// Returns the top 3-5 vocabulary words for a given Mushaf page.
  /// If the page has direct matches, returns them.
  /// Otherwise, intelligently pulls words from the closest page or same Surah.
  List<QuranVocabularyWord> getWordsForPage(int pageNumber) {
    // 1. Direct page match
    final pageWords = _wordsDataset.where((w) => w.pageNumber == pageNumber).toList();
    if (pageWords.isNotEmpty) {
      return pageWords;
    }

    // 2. Nearby page match (within +/- 5 pages)
    final nearbyWords = _wordsDataset
        .where((w) => (w.pageNumber - pageNumber).abs() <= 8)
        .toList();
    if (nearbyWords.isNotEmpty) {
      nearbyWords.sort((a, b) =>
          (a.pageNumber - pageNumber).abs().compareTo((b.pageNumber - pageNumber).abs()));
      return nearbyWords.take(4).toList();
    }

    // 3. Fallback: Proportional selection from the dataset
    final fallbackIndex = (pageNumber % _wordsDataset.length);
    final results = <QuranVocabularyWord>[];
    for (int i = 0; i < 3; i++) {
      results.add(_wordsDataset[(fallbackIndex + i) % _wordsDataset.length]);
    }
    return results;
  }

  /// Returns a deterministic daily featured word based on day of year.
  QuranVocabularyWord getDailyWord([DateTime? date]) {
    final d = date ?? DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    final index = dayOfYear % _wordsDataset.length;
    return _wordsDataset[index];
  }

  /// Searches words by query across word, meaning, root, and Surah name.
  List<QuranVocabularyWord> searchWords(String query) {
    final rawQ = query.trim().toLowerCase();
    if (rawQ.isEmpty) return _wordsDataset;
    final normQ = ArabicNormalizer.normalize(rawQ).toLowerCase();

    return _wordsDataset.where((w) {
      final normWord = ArabicNormalizer.normalize(w.word).toLowerCase();
      final normMeaning = ArabicNormalizer.normalize(w.meaning).toLowerCase();
      final normRoot = ArabicNormalizer.normalize(w.root).toLowerCase();
      final normSurah = ArabicNormalizer.normalize(w.surahName).toLowerCase();
      final normSnippet = ArabicNormalizer.normalize(w.ayahSnippet).toLowerCase();

      return normWord.contains(normQ) ||
          normMeaning.contains(normQ) ||
          normRoot.contains(normQ) ||
          normSurah.contains(normQ) ||
          normSnippet.contains(normQ) ||
          w.word.contains(rawQ) ||
          w.root.contains(rawQ) ||
          w.meaning.contains(rawQ);
    }).toList();
  }

  /// All available vocabulary words.
  List<QuranVocabularyWord> getAllWords() => List.unmodifiable(_wordsDataset);
}
