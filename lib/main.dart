import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get_it/get_it.dart';
import 'package:get_it_hooks/get_it_hooks.dart';

import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:flutter_blue/flutter_blue.dart';

final getIt = GetIt.instance;
void setupGetIt() {
  getIt.registerSingleton(AppShellVM());
  getIt.registerSingleton(ConnectionTabVM());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  setupGetIt();
  runApp(Application());
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Comfortaa',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
        primaryColor: Color(0xFF181A20),
        accentColor: Color(0xFF7678ED),
        canvasColor: Color(0xFF181A20),
        cardColor: Color(0xFF262A34),
        dialogBackgroundColor: Color(0xFF262A34),
      ),
      title: 'OpenXC',
      home: AppShellView(),
    );
  }
}

class AppShellView extends HookWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: useWatchOnly((AppShellVM appShellVM) => appShellVM.navIndex),
        children: useGet<AppShellVM>().navTabs,
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
            currentIndex: useWatchOnly((AppShellVM appShellVM) => appShellVM.navIndex),
            onTap: (index) {
              useGet<AppShellVM>().navIndex = index;
            },
            items: useGet<AppShellVM>().navItems,
          ),
        ),
      ),
    );
  }
}

class AppShellVM extends ChangeNotifier {
  // Tab Views
  List<Widget> _navTabs = [
    ConnectionTab(),
    DashboardTab(),
    SettingsTab(),
  ];
  List<Widget> get navTabs => _navTabs;

  // Navigation Items
  List<BottomNavigationBarItem> _navItems = [
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
  List<BottomNavigationBarItem> get navItems => _navItems;

  // Navigation Index
  int _navIndex = 0;
  int get navIndex => _navIndex;
  set navIndex(int val) {
    this._navIndex = val;
    notifyListeners();
  }
}

class InfoCard extends StatelessWidget {
  final bool isVisible;
  final String title;
  final String subtitle;
  final Color subtitleColor;

  InfoCard({this.isVisible, this.title, this.subtitle, this.subtitleColor});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: this.isVisible != null ? this.isVisible : true,
      child: Card(
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Container(
          padding: EdgeInsets.all(5.0),
          child: ListTile(
            title: Text(
              this.title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              this.subtitle,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
                color: subtitleColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
            InfoCard(
              title: 'Data Source',
              subtitle: 'Bluetooth Low Energy (BLE)',
            ),
            SizedBox(height: 10.0),
            InfoCard(
              title: 'Connection Status',
              subtitle: useWatchOnly((ConnectionTabVM connectionTabVM) => connectionTabVM.connectionStatusLabel),
              subtitleColor: useWatchOnly((ConnectionTabVM connectionTabVM) => connectionTabVM.connectionStatusColor),
            ),
            SizedBox(height: 10.0),
            InfoCard(
              isVisible: useWatchOnly((ConnectionTabVM connectionTabVM) => connectionTabVM.isConnected),
              title: 'VI Name',
              subtitle: useWatchOnly((ConnectionTabVM connectionTabVM) => connectionTabVM.viName),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
        child: SizedBox(
          width: double.infinity,
          height: 40.0,
          child: FloatingActionButton.extended(
            elevation: 5.0,
            label: Text(useWatchOnly((ConnectionTabVM connectionTabVM) => connectionTabVM.fabLabel)),
            onPressed: () async {
              if (!useGet<ConnectionTabVM>().isConnected) {
                await useGet<ConnectionTabVM>().connect();
              } else {
                await useGet<ConnectionTabVM>().disconnect();
              }
            },
          ),
        ),
      ),
    );
  }
}

class ConnectionTabVM extends ChangeNotifier {
  // OpenXC BLE Constants
  static const DEVICE_NAME_PREFIX = 'OPENXC-VI-';
  static const OPENXC_SERVICE_UUID = '6800D38B-423D-4BDB-BA05-C9276D8453E1';
  static const WRITE_CHARACTERISTIC_UUID = '6800D38B-5262-11E5-885D-FEFF819CDCE2';
  static const NOTIFY_CHARACTERISTIC_UUID = '6800D38B-5262-11E5-885D-FEFF819CDCE3';

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  String _connectionStatusLabel = 'Disconnected';
  String get connectionStatusLabel => _connectionStatusLabel;

  Color _connectionStatusColor = Color(0xFFDF927B);
  Color get connectionStatusColor => _connectionStatusColor;

  String _fabLabel = 'CONNECT';
  String get fabLabel => _fabLabel;

  String _viName = 'Unknown';
  String get viName => _viName;

  // Connect Method
  Future<void> connect() async {
    // Disconnect All Devices
    await this.disconnect();

    BluetoothService openXCService;

    List<ScanResult> scanResults = await FlutterBlue.instance.scan(timeout: Duration(seconds: 5)).toList();
    for (ScanResult scanResult in scanResults) {
      // Print Scane Result
      this.printScanResult(scanResult);

      // Find OpenXC Device
      String deviceName = scanResult.advertisementData.localName.trim().toUpperCase();
      if (deviceName.contains(DEVICE_NAME_PREFIX)) {
        BluetoothDevice bluetoothDevice = scanResult.device;
        await bluetoothDevice.connect();

        // Find OpenXC Service
        List<BluetoothService> bluetoothServices = await bluetoothDevice.discoverServices();
        for (BluetoothService bluetoothService in bluetoothServices) {
          if (bluetoothService.uuid.toString().toUpperCase() == OPENXC_SERVICE_UUID) {
            openXCService = bluetoothService;
            print('Service UUID: ${openXCService.uuid.toString().toUpperCase()}');
            break;
          }
        }

        // Assign Write Characteristic
        BluetoothCharacteristic writeCharacteristic = openXCService.characteristics
            .where((X) => X.uuid.toString().toUpperCase() == WRITE_CHARACTERISTIC_UUID)
            .first;
        print('Write Characteristic UUID: ${writeCharacteristic.uuid.toString().toUpperCase()}');

        // Assign Notify Characteristic
        BluetoothCharacteristic notifyCharacteristic = openXCService.characteristics
            .where((X) => X.uuid.toString().toUpperCase() == NOTIFY_CHARACTERISTIC_UUID)
            .first;
        print('Notify Characteristic UUID: ${notifyCharacteristic.uuid.toString().toUpperCase()}');

        // Keep Connected
        await notifyCharacteristic.setNotifyValue(true);

        // Update Connection Related Variables
        this._isConnected = true;
        this._connectionStatusLabel = 'Connected';
        this._connectionStatusColor = Color(0xFF9DE089);
        this._fabLabel = 'DISCONNECT';
        this._viName = deviceName;
        notifyListeners();
      }
    }
  }

  // Disconnect Method
  Future<void> disconnect() async {
    List<BluetoothDevice> bluetoothDevices = await FlutterBlue.instance.connectedDevices;
    bluetoothDevices.forEach((bluetoothDevice) async {
      await bluetoothDevice.disconnect();
    });

    // Update Connection Related Variables
    this._isConnected = false;
    this._connectionStatusLabel = 'Disconnected';
    this._connectionStatusColor = Color(0xFFDF927B);
    this._fabLabel = 'CONNECT';
    this._viName = 'Unknown';
    notifyListeners();
  }

  void printScanResult(ScanResult scanResult) {
    String deviceId = scanResult.device.id.toString().toUpperCase();
    String deviceName = scanResult.advertisementData.localName.replaceAll(RegExp(r'\0'), '').trim().toUpperCase();
    if (deviceName.isNotEmpty) {
      print('$deviceId :: $deviceName');
    }
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
      body: Container(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoCard(
              title: 'Messages Received',
              subtitle: '2020',
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsListTile extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;

  SettingsListTile({this.iconData, this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Icon(
          this.iconData,
          color: Colors.white,
        ),
        backgroundColor: Colors.transparent,
      ),
      title: Text(this.title),
      subtitle: Text(this.subtitle),
      trailing: Icon(Icons.keyboard_arrow_right),
      onTap: () {},
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
            SettingsListTile(
              iconData: Icons.account_tree,
              title: 'Connection',
              subtitle: 'BLE • USB • Trace File',
            ),
            SettingsListTile(
              iconData: Icons.save,
              title: 'Recording',
              subtitle: 'Trace Files • Dweet.IO',
            ),
            SettingsListTile(
              iconData: Icons.info,
              title: 'About',
              subtitle: 'Application • Platform',
            ),
          ],
        ).toList(),
      ),
    );
  }
}
