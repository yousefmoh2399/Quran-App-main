// ignore_for_file: prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app_android/core/util/color.dart';
import 'package:quran_app_android/core/util/widgets/custom_toast.dart';

import 'package:quran_app_android/features/azkar/presentation/views/widgets/zikr_image_share_dialog.dart';

class SectionsBottom extends StatelessWidget {
  const SectionsBottom({super.key,required this.model});
  final model;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Builder(
          builder: (btnContext) => GestureDetector(
            onTap: () {
              final text = model.text.toString().replaceFirst(':', '');
              showDialog(
                context: context,
                builder: (_) => ZikrImageShareDialog(
                  zikrText: text,
                  categoryTitle: 'أذكار وأدعية',
                ),
              );
            },
            child: const Icon(
              Icons.image_outlined,
              size: 25.0,
              color: AppColors.kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(width: 15.0),
        Builder(
          builder: (btnContext) => GestureDetector(
            onTap: () {
              final text = model.text.toString().replaceFirst(':', '');
              ZikrShareHelper.showShareOptions(
                context,
                zikrText: text,
                categoryTitle: 'أذكار وأدعية',
              );
            },
            child: const Icon(
              Icons.share,
              size: 25.0,
              color: AppColors.kPrimaryColor,
            ),
          ),
        ),
        const SizedBox(width: 20.0),
        Container(
          width: 55,
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 3,
              color:  AppColors.kPrimaryColor,
            ),
          ),
          child: Text(
            '${model.count}',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontFamily: 'BalooBhaijaan2',
                  color: Colors.black,
                  fontSize: 27,
                ),
          ),
        ),
        const SizedBox(width: 20.0),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(
                    text: model.text.toString().replaceFirst(':', '')))
                .then((value) async {
              await defaultToast(text: 'تم النسخ');
            });
          },
          child: const Icon(
            Icons.copy,
            size: 25.0,
            color: AppColors.kPrimaryColor,
          ),
        ),
      ],
    );
  }
}
