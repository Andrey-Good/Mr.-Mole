import 'package:flutter/material.dart';
import 'package:mr_mole/features/home/presentation/bloc/home_bloc.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';

class MainTab extends StatelessWidget {
  final HomeBloc homeBloc;

  const MainTab({
    super.key,
    required this.homeBloc,
  });

  @override
  Widget build(BuildContext context) {
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
                    'Mr. Mole',
                    textAlign: TextAlign.left,
                  ),
                ),
                IconButton(
                  icon: CommonWidgets.commonIcon(Icons.settings),
                  onPressed: () => homeBloc.add(OpenSettingsEvent()),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CommonWidgets.titleText(
                      'Добро пожаловать в Mr. Mole',
                    ),
                    const SizedBox(height: 64),
                    CommonWidgets.commonCard(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          CommonWidgets.commonIcon(
                            Icons.medical_services,
                            size: 48,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: CommonWidgets.commonButton(
                                  text: 'Галерея',
                                  onPressed: () =>
                                      homeBloc.add(OpenGalleryEvent()),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CommonWidgets.commonButton(
                                  text: 'Камера',
                                  onPressed: () =>
                                      homeBloc.add(OpenCameraEvent()),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          CommonWidgets.subtitleText(
                            'Сфотографируйте родинку или выберите изображение из галереи для анализа',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
