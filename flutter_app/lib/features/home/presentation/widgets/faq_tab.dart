import 'package:flutter/material.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';

class FAQTab extends StatelessWidget {
  const FAQTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FAQItem> faqItems = [
      FAQItem(
        question: 'Что такое Mr. Mole?',
        answer:
            'Mr. Mole - это приложение для анализа родинок и выявления потенциально опасных изменений кожи. Приложение не заменяет консультацию врача и служит только для предварительной оценки.',
      ),
      FAQItem(
        question: 'Как правильно сделать снимок родинки?',
        answer:
            'Для получения качественного снимка убедитесь, что: 1) Родинка находится в центре кадра, 2) Освещение равномерное, без теней, 3) Камера держится параллельно поверхности кожи, 4) Фокус настроен правильно.',
      ),
      FAQItem(
        question: 'Как часто нужно проверять родинки?',
        answer:
            'Рекомендуется проверять родинки регулярно, примерно раз в 3-6 месяца, особенно если они находятся в местах, подверженных трению или солнечному воздействию. При обнаружении любых изменений обратитесь к дерматологу.',
      ),
      FAQItem(
        question: 'Безопасны ли мои данные?',
        answer:
            'Да, ваши изображения обрабатываются локально на устройстве и не передаются в интернет без вашего явного согласия. Мы серьезно относимся к конфиденциальности ваших медицинских данных.',
      ),
    ];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CommonWidgets.titleText(
                    'FAQ',
                    textAlign: TextAlign.left,
                  ),
                ),
                CommonWidgets.commonButton(
                  text: 'Поддержка',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...faqItems.map((item) => FAQExpansionTile(item: item)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}

class FAQExpansionTile extends StatelessWidget {
  final FAQItem item;

  const FAQExpansionTile({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return CommonWidgets.commonCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        title: CommonWidgets.titleText(
          item.question,
        ),
        children: [
          CommonWidgets.subtitleText(
            item.answer,
          ),
        ],
      ),
    );
  }
}
