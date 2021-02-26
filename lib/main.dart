import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppThemeConfig {
  static AppThemeConfig _instance;
  factory AppThemeConfig() => _instance ??= AppThemeConfig._internal();
  AppThemeConfig._internal();

  final _appTheme = ThemeData(
    fontFamily: 'Comfortaa',
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    primaryColor: Color(0xFF181A20),
    accentColor: Color(0xFF7678ED),
    canvasColor: Color(0xFF181A20),
    cardColor: Color(0xFF262A34),
    dialogBackgroundColor: Color(0xFF262A34),
  );

  ThemeData get appTheme => _appTheme;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: AppThemeConfig().appTheme.primaryColor,
    ),
  );
  runApp(ProviderScope(child: Application()));
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OpenXC',
      home: OpenXC(),
      theme: AppThemeConfig().appTheme,
    );
  }
}

class OpenXC extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final bottomNavigationIndex = useProvider(BNavigationConfig().bNavigationIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: bottomNavigationIndex.state,
        children: BNavigationConfig().bNavigationPages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20.0),
            topLeft: Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black38, spreadRadius: 0.0, blurRadius: 10.0),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            currentIndex: bottomNavigationIndex.state,
            onTap: (index) {
              bottomNavigationIndex.state = index;
            },
            items: BNavigationConfig().bNavigationItems,
          ),
        ),
      ),
    );
  }
}

class BNavigationConfig {
  static BNavigationConfig _instance;
  factory BNavigationConfig() => _instance ??= BNavigationConfig._internal();
  BNavigationConfig._internal();

  final _bNavigationIndexProvider = StateProvider<int>((ref) => 0);

  StateProvider<int> get bNavigationIndexProvider => _bNavigationIndexProvider;

  final _bNavigationPages = [
    ConnectionTab(),
    DashboardTab(),
    SettingsTab(),
  ];

  List<Widget> get bNavigationPages => _bNavigationPages;

  final _bNavigationItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.account_tree_outlined),
      label: 'Connection',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics_outlined),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      label: 'Settings',
    ),
  ];

  List<BottomNavigationBarItem> get bNavigationItems => _bNavigationItems;
}

class ConnectionTab extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenXC'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('CONNECTION'),
      ),
    );
  }
}

class DashboardTab extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenXC'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('DASHBOARD'),
      ),
    );
  }
}

class SettingsTab extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenXC'),
        centerTitle: true,
      ),
      body: Center(
        child: Text('SETTINGS'),
      ),
    );
  }
}
