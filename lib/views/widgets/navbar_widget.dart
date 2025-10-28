import 'package:flutter/material.dart';
import 'package:notification_vtcnews/data/notifiers.dart';

class NavBarWidget extends StatelessWidget {
  const NavBarWidget({super.key, required this.controller});
  final PageController controller;

  static const brandRed = Color(0xFFA2171C);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final selectedColor = isDark ? Colors.white : brandRed;
    final unselectedColor =
        isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white10 : Colors.black12,
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (_, index, __) {
          return BottomNavigationBar(
            currentIndex: index,
            // onTap: (idx) => selectedPageNotifier.value = idx,
            onTap: (idx) {
              selectedPageNotifier.value = idx;
              controller.animateToPage(
                idx,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
              );
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: bgColor,
            elevation: 0,
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            iconSize: 24,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
               BottomNavigationBarItem(
                icon: Icon(Icons.playlist_add_check_outlined),
               activeIcon: Icon(Icons.playlist_add_check),
                 label: 'MyTask',
               ),
               BottomNavigationBarItem(
                 icon: Icon(Icons.playlist_add_check_outlined),
                 activeIcon: Icon(Icons.playlist_add_check),
                 label: 'MyGroup',
               ),
               BottomNavigationBarItem(
                 icon: Icon(Icons.bar_chart_rounded),
                 activeIcon: Icon(Icons.bar_chart_rounded),
                 label: 'Dashboard',
               ),
            ],
          );
        },
      ),
    );
  }
}
