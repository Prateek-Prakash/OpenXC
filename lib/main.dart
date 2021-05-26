import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

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
    final connectionStatusBoolProvider = useProvider(ConnectionConfig().connectionStatusBoolProvider);
    final connectionStatusStringProvider = useProvider(ConnectionConfig().connectionStatusStringProvider);
    final connectionStatusColorProvider = useProvider(ConnectionConfig().connectionStatusColorProvider);
    final actionButtonStringProvider = useProvider(ConnectionConfig().actionButtonStringProvider);

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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    dataSourceProvider.state,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    connectionStatusStringProvider.state,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      color: connectionStatusColorProvider.state,
                    ),
                  ),
                ),
              ),
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
            label: Text(actionButtonStringProvider.state),
            onPressed: () async {
              if (connectionStatusBoolProvider.state == false) {
                if (await ConnectionConfig().connect()) {
                  connectionStatusBoolProvider.state = true;
                  connectionStatusStringProvider.state = 'Connected';
                  connectionStatusColorProvider.state = Color(0xFF9DE089);
                  actionButtonStringProvider.state = 'DISCONNECT';
                }
              } else if (connectionStatusBoolProvider.state == true) {
                if (await ConnectionConfig().disconnect()) {
                  connectionStatusBoolProvider.state = false;
                  connectionStatusStringProvider.state = 'Disconnected';
                  connectionStatusColorProvider.state = Color(0xFFDF927B);
                  actionButtonStringProvider.state = 'CONNECT';
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

const DEVICE_NAME_PREFIX = "OPENXC-VI-";
const OPENXC_SERVICE_UUID = "6800D38B-423D-4BDB-BA05-C9276D8453E1";
const WRITE_CHARACTERISTIC_UUID = "6800D38B-5262-11E5-885D-FEFF819CDCE2";
const NOTIFY_CHARACTERISTIC_UUID = "6800D38B-5262-11E5-885D-FEFF819CDCE3";

class ConnectionConfig {
  static ConnectionConfig _instance;
  factory ConnectionConfig() => _instance ??= ConnectionConfig._internal();
  ConnectionConfig._internal();

  final _dataSourceProvider = StateProvider<String>((ref) => 'Bluetooth Low Energy (BLE)');
  StateProvider<String> get dataSourceProvider => _dataSourceProvider;

  final _connectionStatusBoolProvider = StateProvider<bool>((ref) => false);
  StateProvider<bool> get connectionStatusBoolProvider => _connectionStatusBoolProvider;

  final _connectionStatusStringProvider = StateProvider<String>((ref) => 'Disconnected');
  StateProvider<String> get connectionStatusStringProvider => _connectionStatusStringProvider;

  final _connectionStatusColorProvider = StateProvider<Color>((ref) => Color(0xFFDF927B));
  StateProvider<Color> get connectionStatusColorProvider => _connectionStatusColorProvider;

  final _actionButtonStringProvider = StateProvider<String>((ref) => 'CONNECT');
  StateProvider<String> get actionButtonStringProvider => _actionButtonStringProvider;

  Future<bool> connect() async {
    // Disconnect All Devices
    await this.disconnect();

    BluetoothService openXCService;

    List<ScanResult> scanResults = await FlutterBlue.instance.scan(timeout: Duration(seconds: 5)).toList();
    for (ScanResult scanResult in scanResults) {
      this.printScanResult(scanResult);
      String deviceName = scanResult.advertisementData.localName.trim().toUpperCase();
      if (deviceName.contains(DEVICE_NAME_PREFIX)) {
        BluetoothDevice bluetoothDevice = scanResult.device;
        await bluetoothDevice.connect();

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

        // Listen: Read Data
        await notifyCharacteristic.setNotifyValue(true);

        return true;
      }
    }
    return false;
  }

  Future<bool> disconnect() async {
    List<BluetoothDevice> bluetoothDevices = await FlutterBlue.instance.connectedDevices;
    bluetoothDevices.forEach((bluetoothDevice) async {
      await bluetoothDevice.disconnect();
    });
    return true;
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
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Container(
                padding: EdgeInsets.all(5.0),
                child: ListTile(
                  title: Text(
                    'Messages Received',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    '2020',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
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
              onTap: () {},
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
              onTap: () {},
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
