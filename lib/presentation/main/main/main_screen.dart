import 'dart:math' as math;

import 'package:dating_assistant/misc/appearance.dart';
import 'package:dating_assistant/misc/components/fade_page_route.dart';
import 'package:dating_assistant/presentation/main/history/history_screen.dart';
import 'package:dating_assistant/presentation/main/home/home_screen.dart';
import 'package:dating_assistant/presentation/main/main/main_view_model.dart';
import 'package:dating_assistant/presentation/main/main/views/main_tab_bar.dart';
import 'package:dating_assistant/presentation/main/profile/profile_screen.dart';
import 'package:flutter/material.dart';

/// Главный экран (≈ MainViewController): вкладки Main, History, Profile и стеклянный таб-бар поверх них.
///
/// У каждой вкладки свой Navigator (≈ NavigationController в табе): экраны внутри вкладки открываются
/// под таб-баром, а при переключении вкладок их стек сохраняется. Экран, который должен закрыть
/// таб-бар (пейгейт, шторки), открываем в корневом: `Navigator.of(context, rootNavigator: true)`.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static Route<void> route() => FadePageRoute(builder: (_) => const MainScreen());

  /// Делает главный экран корневым — как window.rootViewController в Swift-проектах.
  static void setAsRoot(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(route(), (_) => false);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _viewModel = MainViewModel();

  final _navigatorKeys = {for (final tab in MainTab.values) tab: GlobalKey<NavigatorState>()};

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Таб-бар входит в safe area экранов во вкладках, как в UITabBarController: контент прокручивается
    // под капсулой, а SafeArea и отступы поднимают последний элемент над ней.
    final media = MediaQuery.of(context);
    final tabBarExtent = MainTabBar.extent(context);
    final tabMedia = media.copyWith(
      padding: media.padding.copyWith(bottom: math.max(0, tabBarExtent - media.viewInsets.bottom)),
      viewPadding: media.viewPadding.copyWith(bottom: tabBarExtent),
    );

    // Material — фон и стиль текста по умолчанию для таб-бара, без него подписи подчёркнуты.
    return Material(
      color: Appearance.black,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final selectedTab = _viewModel.selectedTab;
          return Stack(
            fit: StackFit.expand,
            children: [
              MediaQuery(
                data: tabMedia,
                child: IndexedStack(
                  index: selectedTab.index,
                  sizing: StackFit.expand,
                  children: [
                    for (final tab in MainTab.values)
                      if (_viewModel.isOpened(tab))
                        _TabNavigator(
                          navigatorKey: _navigatorKeys[tab]!,
                          isSelected: tab == selectedTab,
                          root: switch (tab) {
                            MainTab.home => const HomeScreen(),
                            MainTab.history => const HistoryScreen(),
                            MainTab.profile => const ProfileScreen(),
                          },
                        )
                      else
                        const SizedBox.shrink(),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: MainTabBar(selectedTab: selectedTab, onSelect: _select),
              ),
            ],
          );
        },
      ),
    );
  }

  void _select(MainTab tab) {
    if (tab == _viewModel.selectedTab) {
      // Как в UITabBarController: повторное нажатие возвращает вкладку к её первому экрану.
      _navigatorKeys[tab]!.currentState?.popUntil((route) => route.isFirst);
      return;
    }
    // Клавиатура с уходящей вкладки не должна остаться над новой.
    FocusManager.instance.primaryFocus?.unfocus();
    _viewModel.select(tab);
  }
}

/// Стек экранов одной вкладки (≈ NavigationController).
class _TabNavigator extends StatefulWidget {
  const _TabNavigator({required this.navigatorKey, required this.isSelected, required this.root});

  final GlobalKey<NavigatorState> navigatorKey;

  final bool isSelected;

  /// Первый экран вкладки.
  final Widget root;

  @override
  State<_TabNavigator> createState() => _TabNavigatorState();
}

class _TabNavigatorState extends State<_TabNavigator> {
  /// Вложенному Navigator нужен свой HeroController: контроллер из MaterialApp достаётся только корневому.
  final _heroController = MaterialApp.createMaterialHeroController();

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Скрытая вкладка не крутит анимации и не перехватывает «Назад».
    return TickerMode(
      enabled: widget.isSelected,
      child: NavigatorPopHandler<Object?>(
        enabled: widget.isSelected,
        // «Назад» на Android сначала закрывает экраны внутри вкладки.
        onPopWithResult: (_) => widget.navigatorKey.currentState?.maybePop(),
        child: HeroControllerScope(
          controller: _heroController,
          child: Navigator(
            key: widget.navigatorKey,
            onGenerateRoute: (settings) => MaterialPageRoute<void>(settings: settings, builder: (_) => widget.root),
          ),
        ),
      ),
    );
  }
}
