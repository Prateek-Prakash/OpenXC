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
    final dataSourceProvider = useProvider(ConnectionConfig().dataSourceProvider);

    final connectionStatusIndex = useProvider(ConnectionConfig().connectionStatusIndexProvider);

    String connectionStatus = ConnectionConfig().connectionStatuses[connectionStatusIndex.state];
    Color connectionStatusColor = ConnectionConfig().connectionStatusColors[connectionStatusIndex.state];

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
                    dataSourceProvider.state,
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
                    connectionStatus,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: connectionStatusColor),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.ac_unit),
        onPressed: () {
          if (connectionStatusIndex.state == 0) {
            connectionStatusIndex.state = 1;
          } else if (connectionStatusIndex.state == 1) {
            connectionStatusIndex.state = 0;
          }
        },
      ),
    );
  }
}

class ConnectionConfig {
  static ConnectionConfig _instance;
  factory ConnectionConfig() => _instance ??= ConnectionConfig._internal();
  ConnectionConfig._internal();

  final _dataSourceProvider = StateProvider<String>((ref) => 'Bluetooth Low Energy (BLE)');

  StateProvider<String> get dataSourceProvider => _dataSourceProvider;

  final _connectionStatusIndexProvider = StateProvider<int>((ref) => 0);

  StateProvider<int> get connectionStatusIndexProvider => _connectionStatusIndexProvider;

  final _connectionStatuses = [
    'Disconnected',
    'Connected',
  ];

  List<String> get connectionStatuses => _connectionStatuses;

  final _connectionStatusColors = [
    Color(0xFFDF927B),
    Color(0xFF9DE089),
  ];

  List<Color> get connectionStatusColors => _connectionStatusColors;
}

class DashboardTab extends HookWidget {
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

class SettingsTab extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenXC'),
        centerTitle: true,
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  Icons.account_tree,
                  color: Colors.white,
                ),
                backgroundColor: Colors.transparent,
              ),
              title: Text('Connection'),
              subtitle: Text('BLE • USB • Trace File'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
              },
            ),
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  Icons.save,
                  color: Colors.white,
                ),
                backgroundColor: Colors.transparent,
              ),
              title: Text('Recording'),
              subtitle: Text('Trace Files • Dweet.IO'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
              },
            ),
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  Icons.info,
                  color: Colors.white,
                ),
                backgroundColor: Colors.transparent,
              ),
              title: Text('About'),
              subtitle: Text('Application • Platform'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {},
            ),
          ],
        ).toList(),
      ),
    );
  }
}
