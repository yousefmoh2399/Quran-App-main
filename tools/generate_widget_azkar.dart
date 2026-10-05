// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

void main() {
  print('Generating 300+ Azkar dataset for Android & iOS Widgets...');

  final sourceFile = File('tools/source/azkar.json');
  final rawData = jsonDecode(sourceFile.readAsStringSync()) as List;

  final azkarList = <Map<String, dynamic>>[];
  int id = 1;

  // 1. Map existing Hisn al-Muslim azkar
  for (final cat in rawData) {
    final catTitle = (cat['category'] ?? '').toString();
    final items = (cat['array'] as List? ?? []);

    String categoryKey = 'general';
    String categoryName = 'أذكار عامة';

    if (catTitle.contains('الصباح والمساء')) {
      categoryKey = 'morning_evening';
      categoryName = 'أذكار الصباح والمساء';
    } else if (catTitle.contains('النوم') || catTitle.contains('الاستيقاظ')) {
      categoryKey = 'sleep_wake';
      categoryName = 'أذكار النوم والاستيقاظ';
    } else if (catTitle.contains('الصلاة') || catTitle.contains('الوضوء') || catTitle.contains('المسجد') || catTitle.contains('الآذان')) {
      categoryKey = 'prayer';
      categoryName = 'أذكار الصلاة والمساجد';
    } else if (catTitle.contains('التسبيح') || catTitle.contains('التحميد') || catTitle.contains('التهليل')) {
      categoryKey = 'tasbeeh';
      categoryName = 'تسابيح وتحميد';
    } else if (catTitle.contains('الاستغفار')) {
      categoryKey = 'istighfar';
      categoryName = 'استغفار وتوبة';
    } else if (catTitle.contains('السفر') || catTitle.contains('الركوب')) {
      categoryKey = 'travel';
      categoryName = 'أذكار السفر';
    } else if (catTitle.contains('الكرب') || catTitle.contains('الهم') || catTitle.contains('الحزن')) {
      categoryKey = 'relief';
      categoryName = 'أدعية تفريج الكرب';
    } else {
      categoryKey = 'prophetic';
      categoryName = 'أدعية وأذكار نبوية';
    }

    for (final item in items) {
      final text = (item['text'] ?? '').toString().trim();
      if (text.isEmpty) continue;

      final count = int.tryParse(item['count']?.toString() ?? '1') ?? 1;
      final fadl = (item['fadl'] ?? '').toString().trim();
      final source = fadl.isNotEmpty ? fadl : 'حصن المسلم';

      azkarList.add({
        'id': id++,
        'text': text,
        'category': categoryKey,
        'category_name': categoryName,
        'source': source,
        'count': count,
      });
    }
  }

  print('Loaded from source: ${azkarList.length}');

  // 2. Add rich Quranic Supplications (الأدعية القرآنية مع اسم السورة ورقم الآية)
  final quranicDuas = [
    {
      'text': 'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      'source': 'سورة البقرة: 201',
    },
    {
      'text': 'رَبَّنَا لا تُؤَاخِذْنَا إِنْ نَسِينَا أَوْ أَخْطَأْنَا رَبَّنَا وَلا تَحْمِلْ عَلَيْنَا إِصْراً كَمَا حَمَلْتَهُ عَلَى الَّذِينَ مِنْ قَبْلِنَا',
      'source': 'سورة البقرة: 286',
    },
    {
      'text': 'رَبَّنَا وَلا تُحَمِّلْنَا مَا لا طَاقَةَ لَنَا بِهِ وَاعْفُ عَنَّا وَاغْفِرْ لَنَا وَارْحَمْنَا أَنْتَ مَوْلانَا فَانصُرْنَا عَلَى الْقَوْمِ الْكَافِرِينَ',
      'source': 'سورة البقرة: 286',
    },
    {
      'text': 'رَبَّنَا لا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِنْ لَدُنْكَ رَحْمَةً إِنَّكَ أَنْتَ الْوَهَّابُ',
      'source': 'سورة آل عمران: 8',
    },
    {
      'text': 'رَبَّنَا إِنَّنَا آمَنَّا فَاغْفِرْ لَنَا ذُنُوبَنَا وَقِنَا عَذَابَ النَّارِ',
      'source': 'سورة آل عمران: 16',
    },
    {
      'text': 'رَبَّنَا إِنَّنَا سَمِعْنَا مُنَادِياً يُنَادِي لِلإِيمَانِ أَنْ آمِنُوا بِرَبِّكُمْ فَآمَنَّا رَبَّنَا فَاغْفِرْ لَنَا ذُنُوبَنَا وَكَفِّرْ عَنَّا سَيِّئَاتِنَا وَتَوَفَّنَا مَعَ الأَبْرَارِ',
      'source': 'سورة آل عمران: 193',
    },
    {
      'text': 'رَبَّنَا وَآتِنَا مَا وَعَدْتَنَا عَلَى رُسُلِكَ وَلا تُخْزِنَا يَوْمَ الْقِيَامَةِ إِنَّكَ لا تُخْلِفُ الْمِيعَادَ',
      'source': 'سورة آل عمران: 194',
    },
    {
      'text': 'رَبَّنَا ظَلَمْنَا أَنفُسَنَا وَإِنْ لَمْ تَغْفِرْ لَنَا وَتَرْحَمْنَا لَنَكُونَنَّ مِنْ الْخَاسِرِينَ',
      'source': 'سورة الأعراف: 23',
    },
    {
      'text': 'رَبَّنَا لا تَجْعَلْنَا مَعَ الْقَوْمِ الظَّالِمِينَ',
      'source': 'سورة الأعراف: 47',
    },
    {
      'text': 'رَبَّنَا أَفْرِغْ عَلَيْنَا صَبْراً وَتَوَفَّنَا مُسْلِمِينَ',
      'source': 'سورة الأعراف: 126',
    },
    {
      'text': 'حَسْبِيَ اللَّهُ لا إِلَهَ إِلاَّ هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      'source': 'سورة التوبة: 129',
    },
    {
      'text': 'رَبِّ إِنِّي أَعُوذُ بِكَ أَنْ أَسْأَلَكَ مَا لَيْسَ لِي بِهِ عِلْمٌ وَإِلاَّ تَغْفِرْ لِي وَتَرْحَمْنِي أَكُنْ مِنْ الْخَاسِرِينَ',
      'source': 'سورة هود: 47',
    },
    {
      'text': 'رَبِّ اجْعَلْنِي مُقِيمَ الصَّلاةِ وَمِنْ ذُرِّيَّتِي رَبَّنَا وَتَقَبَّلْ دُعَاءِ',
      'source': 'سورة إبراهيم: 40',
    },
    {
      'text': 'رَبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
      'source': 'سورة إبراهيم: 41',
    },
    {
      'text': 'رَبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيراً',
      'source': 'سورة الإسراء: 24',
    },
    {
      'text': 'رَّبِّ أَدْخِلْنِي مُدْخَلَ صِدْقٍ وَأَخْرِجْنِي مُخْرَجَ صِدْقٍ وَاجْعَل لِّي مِن لَّدُنكَ سُلْطَانًا نَّصِيرًا',
      'source': 'سورة الإسراء: 80',
    },
    {
      'text': 'رَبَّنَا آتِنَا مِنْ لَدُنْكَ رَحْمَةً وَهَيِّئْ لَنَا مِنْ أَمْرِنَا رَشَداً',
      'source': 'سورة الكهف: 10',
    },
    {
      'text': 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي وَاحْلُلْ عُقْدَةً مِنْ لِسَانِي يَفْقَهُوا قَوْلِي',
      'source': 'سورة طه: 25-28',
    },
    {
      'text': 'رَبِّ زِدْنِي عِلْماً',
      'source': 'سورة طه: 114',
    },
    {
      'text': 'أَنِّي مَسَّنِيَ الضُّرُّ وَأَنْتَ أَرْحَمُ الرَّاحِمِينَ',
      'source': 'سورة الأنبياء: 83',
    },
    {
      'text': 'لا إِلَهَ إِلاَّ أَنْتَ سُبْحَانَكَ إِنِّي كُنتُ مِنْ الظَّالِمِينَ',
      'source': 'سورة الأنبياء: 87',
    },
    {
      'text': 'رَبِّ لا تَذَرْنِي فَرْداً وَأَنْتَ خَيْرُ الْوَارِثِينَ',
      'source': 'سورة الأنبياء: 89',
    },
    {
      'text': 'رَّبِّ أَعُوذُ بِكَ مِنْ هَمَزَاتِ الشَّيَاطِينِ وَأَعُوذُ بِكَ رَبِّ أَن يَحْضُرُونِ',
      'source': 'سورة المؤمنون: 97-98',
    },
    {
      'text': 'رَبَّنَا آمَنَّا فَاغْفِرْ لَنَا وَارْحَمْنَا وَأَنْتَ خَيْرُ الرَّاحِمِينَ',
      'source': 'سورة المؤمنون: 109',
    },
    {
      'text': 'رَّبِّ اغْفِرْ وَارْحَمْ وَأَنتَ خَيْرُ الرَّاحِمِينَ',
      'source': 'سورة المؤمنون: 118',
    },
    {
      'text': 'رَبَّنَا اصْرِفْ عَنَّا عَذَابَ جَهَنَّمَ إِنَّ عَذَابَهَا كَانَ غَرَاماً',
      'source': 'سورة الفرقان: 65',
    },
    {
      'text': 'رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَاماً',
      'source': 'سورة الفرقان: 74',
    },
    {
      'text': 'رَبِّ هَبْ لِي حُكْماً وَأَلْحِقْنِي بِالصَّالِحِينَ وَاجْعَلْ لِي لِسَانَ صِدْقٍ فِي الآخِرِينَ وَاجْعَلْنِي مِنْ وَرَثَةِ جَنَّةِ النَّعِيمِ',
      'source': 'سورة الشعراء: 83-85',
    },
    {
      'text': 'رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَى وَالِدَيَّ وَأَنْ أَعْمَلَ صَالِحاً تَرْضَاهُ وَأَدْخِلْنِي بِرَحْمَتِكَ فِي عِبَادِكَ الصَّالِحِينَ',
      'source': 'سورة النمل: 19',
    },
    {
      'text': 'رَبِّ إِنِّي لِمَا أَنزَلْتَ إِلَيَّ مِنْ خَيْرٍ فَقِيرٌ',
      'source': 'سورة القصص: 24',
    },
    {
      'text': 'رَبِّ انصُرْنِي عَلَى الْقَوْمِ الْمُفْسِدِينَ',
      'source': 'سورة العنكبوت: 30',
    },
    {
      'text': 'رَبَّنَا وَسِعْتَ كُلَّ شَيْءٍ رَّحْمَةً وَعِلْمًا فَاغْفِرْ لِلَّذِينَ تَابُوا وَاتَّبَعُوا سَبِيلَكَ وَقِهِمْ عَذَابَ الْجَحِيمِ',
      'source': 'سورة غافر: 7',
    },
    {
      'text': 'رَبَّنَا وَأَدْخِلْهُمْ جَنَّاتِ عَدْنٍ الَّتِي وَعَدتَّهُمْ وَمَن صَلَحَ مِنْ آبَائِهِمْ وَأَزْوَاجِهِمْ وَذُرِّيَّاتِهِمْ ۚ إِنَّكَ أَنتَ الْعَزِيزُ الْحَكِيمُ',
      'source': 'سورة غافر: 8',
    },
    {
      'text': 'رَبَّنَا اكْشِفْ عَنَّا الْعَذَابَ إِنَّا مُؤْمِنُونَ',
      'source': 'سورة الدخان: 12',
    },
    {
      'text': 'رَبَّنَا اغْفِرْ لَنَا وَلإِخْوَانِنَا الَّذِينَ سَبَقُونَا بِالإِيمَانِ وَلا تَجْعَلْ فِي قُلُوبِنَا غِلاًّ لِلَّذِينَ آمَنُوا رَبَّنَا إِنَّكَ رَءُوفٌ رَحِيمٌ',
      'source': 'سورة الحشر: 10',
    },
    {
      'text': 'رَّبَّنَا عَلَيْكَ تَوَكَّلْنَا وَإِلَيْكَ أَنَبْنَا وَإِلَيْكَ الْمَصِيرُ',
      'source': 'سورة الممتحنة: 4',
    },
    {
      'text': 'رَبَّنَا أَتْمِمْ لَنَا نُورَنَا وَاغْفِرْ لَنَا إِنَّكَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      'source': 'سورة التحريم: 8',
    },
    {
      'text': 'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِمَنْ دَخَلَ بَيْتِي مُؤْمِناً وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
      'source': 'سورة نوح: 28',
    },
    {
      'text': 'رَبِّ إِنِّي ظَلَمْتُ نَفْسِي فَاغْفِرْ لِي فَغَفَرَ لَهُ إِنَّهُ هُوَ الْغَفُورُ الرَّحِيمُ',
      'source': 'سورة القصص: 16',
    },
    {
      'text': 'رَبَّنَا تَقَبَّلْ مِنَّا إِنَّكَ أَنْتَ السَّمِيعُ الْعَلِيمُ',
      'source': 'سورة البقرة: 127',
    },
  ];

  for (final dua in quranicDuas) {
    azkarList.add({
      'id': id++,
      'text': dua['text']!,
      'category': 'quranic',
      'category_name': 'أدعية قرآنية',
      'source': dua['source']!,
      'count': 1,
    });
  }

  // 3. Add distinctive short Prophetic Dhikr & Tasbeeh
  final extraTasbeeh = [
    {
      'text': 'سُبْحَانَ اللهِ وَبِحَمْدِهِ ، سُبْحَانَ اللهِ الْعَظِيمِ',
      'source': 'صحيح البخاري: كلمتان خفيفتان على اللسان ثقيلتان في الميزان',
      'count': 100,
      'category': 'tasbeeh',
      'category_name': 'تسابيح وتحميد',
    },
    {
      'text': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللهِ الْعَلِيِّ الْعَظِيمِ',
      'source': 'صحيح البخاري: كنز من كنوز الجنة',
      'count': 10,
      'category': 'tasbeeh',
      'category_name': 'تسابيح وتحميد',
    },
    {
      'text': 'سُبْحَانَ اللهِ ، وَالْحَمْدُ للهِ ، وَلَا إِلَهَ إِلَّا اللهُ ، وَاللهُ أَكْبَرُ',
      'source': 'صحيح مسلم: أحب الكلام إلى الله',
      'count': 10,
      'category': 'tasbeeh',
      'category_name': 'تسابيح وتحميد',
    },
    {
      'text': 'أَسْتَغْفِرُ اللهَ الْعَظِيمَ الَّذِي لَا إِلَهَ إِلَّا هُوَ الْحَيَّ الْقَيُّومَ وَأَتُوبُ إِلَيْهِ',
      'source': 'سنن الترمذي: غفرت ذنوبه وإن كان فر من الزحف',
      'count': 3,
      'category': 'istighfar',
      'category_name': 'استغفار وتوبة',
    },
    {
      'text': 'اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
      'source': 'رواه الطبراني: من صلى عليّ صلاة صلى الله عليه بها عشرا',
      'count': 10,
      'category': 'salawat',
      'category_name': 'الصلاة على النبي ﷺ',
    },
    {
      'text': 'اللَّهُمَّ إِنَّكَ عَفُوٌّ كَرِيمٌ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
      'source': 'جامع الترمذي: دعاء ليلة القدر',
      'count': 1,
      'category': 'prophetic',
      'category_name': 'أدعية وأذكار نبوية',
    },
    {
      'text': 'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ ، أَصْلِحْ لِي شَأْنِي كُلَّهُ وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
      'source': 'سنن النسائي الكبرى',
      'count': 1,
      'category': 'prophetic',
      'category_name': 'أدعية وأذكار نبوية',
    },
    {
      'text': 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
      'source': 'سنن أبي داود: وصية النبي لمعاذ',
      'count': 1,
      'category': 'prophetic',
      'category_name': 'أدعية وأذكار نبوية',
    },
    {
      'text': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
      'source': 'صحيح مسلم',
      'count': 1,
      'category': 'prophetic',
      'category_name': 'أدعية وأذكار نبوية',
    },
    {
      'text': 'يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ',
      'source': 'سنن الترمذي: كان أكثر دعاء النبي ﷺ',
      'count': 1,
      'category': 'prophetic',
      'category_name': 'أدعية وأذكار نبوية',
    },
    {
      'text': 'اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ ، وَالْعَجْزِ وَالْكَسَلِ ، وَالْبُخْلِ وَالْجُبْنِ ، وَضَلَعِ الدَّيْنِ وَغَلَبَةِ الرِّجَالِ',
      'source': 'صحيح البخاري',
      'count': 1,
      'category': 'relief',
      'category_name': 'أدعية تفريج الكرب',
    },
    {
      'text': 'اللَّهُمَّ رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      'source': 'صحيح البخاري: أكثر دعاء النبي ﷺ',
      'count': 1,
      'category': 'prophetic',
      'category_name': 'أدعية وأذكار نبوية',
    },
    {
      'text': 'رَضِيتُ بِاللهِ رَبًّا ، وَبِالإِسْلَامِ دِينًا ، وَبِمُحَمَّدٍ صَلَّى اللهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا وَرَسُولًا',
      'source': 'سنن أبي داود',
      'count': 3,
      'category': 'morning_evening',
      'category_name': 'أذكار الصباح والمساء',
    },
    {
      'text': 'بِسْمِ اللهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      'source': 'سنن الترمذي',
      'count': 3,
      'category': 'morning_evening',
      'category_name': 'أذكار الصباح والمساء',
    },
    {
      'text': 'حَسْبِيَ اللهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
      'source': 'سنن أبي داود: من قالها كفاه الله ما أهمه',
      'count': 7,
      'category': 'morning_evening',
      'category_name': 'أذكار الصباح والمساء',
    },
  ];

  for (final item in extraTasbeeh) {
    azkarList.add({
      'id': id++,
      'text': item['text']!,
      'category': item['category']!,
      'category_name': item['category_name']!,
      'source': item['source']!,
      'count': item['count']!,
    });
  }

  print('Final total Azkar count: ${azkarList.length}');

  // Save to target destinations
  final jsonString = const JsonEncoder.withIndent('  ').convert(azkarList);

  // 1. Android res/raw
  final androidRawDir = Directory('android/app/src/main/res/raw');
  if (!androidRawDir.existsSync()) androidRawDir.createSync(recursive: true);
  File('android/app/src/main/res/raw/azkar_widget_data.json').writeAsStringSync(jsonString);

  // 2. iOS Widget Extension
  final iosWidgetDir = Directory('ios/MyHomeWidget');
  if (!iosWidgetDir.existsSync()) iosWidgetDir.createSync(recursive: true);
  File('ios/MyHomeWidget/azkar_widget_data.json').writeAsStringSync(jsonString);

  // 3. Assets for Flutter / Tests
  final assetsDataDir = Directory('assets/data');
  if (!assetsDataDir.existsSync()) assetsDataDir.createSync(recursive: true);
  File('assets/data/azkar_widget_data.json').writeAsStringSync(jsonString);

  print('Successfully wrote ${azkarList.length} items to Android, iOS, and assets!');
}
