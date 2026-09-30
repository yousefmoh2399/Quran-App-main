import 'package:quran_app_android/core/util/assets.dart';

class OnBoardingModel {
  final String image;
  final String title;
  final String description;
  final String badge;

  const OnBoardingModel({
    required this.image,
    required this.title,
    required this.description,
    required this.badge,
  });
}

final List<OnBoardingModel> onboardingData = [
  const OnBoardingModel(
    badge: 'القرآن والتفسير',
    title: 'تلاوة عطرة وتدبر لكتاب الله',
    description:
        'اقرأ المصحف الشريف بخط واضح مع التفسير الميسر لكل آية، أوفلاين بالكامل دون الحاجة لاتصال بالإنترنت.',
    image: AssetsData.json_5,
  ),
  const OnBoardingModel(
    badge: 'الأذكار والحديث',
    title: 'حصن المسلم والحديث الشريف',
    description:
        'موسوعة شاملة لأذكار الصباح والمساء، والسبحة الرقمية الذكية، وأحاديث موطأ الإمام مالك.',
    image: AssetsData.json_4,
  ),
  const OnBoardingModel(
    badge: 'المواقيت والقبلة',
    title: 'مواقيت دقيقة وبوصلة القبلة',
    description:
        'حساب دقيق لمواقيت الصلاة حسب موقعك الجغرافي، مع بوصلة حديثة تحدد اتجاه الكعبة المشرفة بدقة.',
    image: AssetsData.location,
  ),
  const OnBoardingModel(
    badge: 'التنبيهات والأوراد',
    title: 'تذكير دائم بطاعة الله',
    description:
        'إشعارات ذكية تنبهك لأذكار الصباح والمساء ومواعيد الصلوات لتبقى على صلة دائمة ومستمرة بالله.',
    image: AssetsData.notification,
  ),
];
