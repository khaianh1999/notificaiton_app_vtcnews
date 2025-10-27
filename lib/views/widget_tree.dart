// lib/views/widget_tree.dart
import 'package:notification_vtcnews/main.dart';
import 'package:notification_vtcnews/views/pages/my_group.dart';
import 'package:notification_vtcnews/views/pages/my_statistical.dart';
import 'widgets/navbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'pages/home_page.dart';
import '../data/notifiers.dart';
import 'pages/my_task.dart';
import 'pages/my_group.dart';
// REMOVE the Firebase import as it's no longer needed here
// import 'package:firebase_messaging/firebase_messaging.dart';

class WidgetTree extends StatefulWidget {
  // REMOVE the initialMessage field
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  //–– WebView stuff (giữ nguyên)
  WebViewController? _itemsWebController;
  bool _itemsCanGoBack = false;
  void _handleItemsController(WebViewController ctrl) =>
      _itemsWebController = ctrl;
  void _handleItemsCanGoBack(bool value) {
    if (_itemsCanGoBack != value) setState(() => _itemsCanGoBack = value);
  }

  //–– PageView
  late final PageController _pageCtrl;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // The HomePage no longer needs the initialMessage
    _pages = [
      HomePage(),
      MyTask(),
      MyGroup(),
      TaskStatisticsScreen(),
    ];

    _pageCtrl = PageController(initialPage: selectedPageNotifier.value);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pageIdx = selectedPageNotifier.value;
    final showBack = pageIdx == 2 && _itemsCanGoBack;

    return Scaffold(
      // appBar: AppBar(
      //   centerTitle: true,
      //   title: Image.asset('assets/images/logo.webp', height: 25),
      //   leading:
      //       showBack
      //           ? IconButton(
      //             icon: const Icon(Icons.arrow_back),
      //             onPressed: () async {
      //               if (_itemsWebController != null &&
      //                   await _itemsWebController!.canGoBack()) {
      //                 await _itemsWebController!.goBack();
      //               }
      //             },
      //           )
      //           : const SizedBox.shrink(),
      //   actions: [
      //     IconButton(
      //       icon: ValueListenableBuilder(
      //         valueListenable: isDarkModeNotifier,
      //         builder:
      //             (_, isDark, __) =>
      //                 Icon(isDark ? Icons.light_mode : Icons.dark_mode),
      //       ),
      //       onPressed:
      //           () => isDarkModeNotifier.value = !isDarkModeNotifier.value,
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: PageView(
          controller: _pageCtrl,
          physics: NeverScrollableScrollPhysics(),
          onPageChanged: (idx) => selectedPageNotifier.value = idx,
          children: _pages,
        ),
      ),
      bottomNavigationBar: NavBarWidget(controller: _pageCtrl ),
    );
  }
}
