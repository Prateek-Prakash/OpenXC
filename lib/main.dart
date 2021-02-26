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
    accentColor: Color(0xFFCBA6FC),
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
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
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
      body: Container(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                padding: EdgeInsets.all(5.0),
                child: ListTile(
                  title: Text(
                    'Data Source',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    'Bluetooth Low Energy',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                padding: EdgeInsets.all(5.0),
                child: ListTile(
                  title: Text(
                    'Connection Status',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    'Connected',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF9DE089)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                padding: EdgeInsets.all(5.0),
                child: ListTile(
                  title: Text(
                    'Connection Status',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    'Disconnected',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFFDF927B)),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                padding: EdgeInsets.all(5.0),
                child: ListTile(
                  title: Text(
                    'VI Device Name',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    'Disconnected',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                padding: EdgeInsets.all(5.0),
                child: ListTile(
                  title: Text(
                    'Messages Received',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(
                    '2020',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
                  ),
                ),
              ),
            ),
          ],
        ),
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
