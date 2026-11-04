import 'dart:math' as math;

import 'package:dating_assistant/misc/assets.dart';
import 'package:dating_assistant/misc/custom_views/glass_panel.dart';
import 'package:dating_assistant/presentation/main/main/main_view_model.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar_item.dart';
import 'package:flutter/widgets.dart';

/// Стеклянный таб-бар главного экрана (≈ TabView): капсула над нижним краем, контент прокручивается под ней.
class MainTabBar extends StatelessWidget {
  const MainTabBar({super.key, required this.selectedTab, required this.onSelect});

  /// Высота капсулы.
  static const height = 60.0;

  final MainTab selectedTab;

  final ValueChanged<MainTab> onSelect;

  /// Отступ капсулы от низа экрана: над полоской «домой» на iPhone, на экранах без неё — 16.
  /// Берём viewPadding: он не меняется, когда выезжает клавиатура.
  static double bottomOffset(BuildContext context) => math.max(MediaQuery.viewPaddingOf(context).bottom + 3, 16);

  /// Сколько места внизу экрана занимает таб-бар.
  static double extent(BuildContext context) => height + bottomOffset(context);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomOffset(context)),
      // Как у системного таб-бара: крупный системный шрифт почти не увеличивает подписи, иначе они не влезут.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: SizedBox(
          height: height,
          child: GlassPanel(
            borderRadius: BorderRadius.circular(height / 2),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  for (final tab in MainTab.values)
                    Expanded(
                      child: MainTabBarItem(
                        icon: tab.icon,
                        title: tab.title,
                        isSelected: tab == selectedTab,
                        onTap: () => onSelect(tab),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on MainTab {
  String get title => switch (this) {
    MainTab.home => 'Main',
    MainTab.history => 'History',
    MainTab.profile => 'Profile',
  };

  String get icon => switch (this) {
    MainTab.home => AppIcons.dashboard,
    MainTab.history => AppIcons.history,
    MainTab.profile => AppIcons.user,
  };
}
