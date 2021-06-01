import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:badges/badges.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_hooks/get_it_hooks.dart';

final getIt = GetIt.instance;
void setupGetIt() {
  getIt.registerSingleton(AppShellVM());
  getIt.registerSingleton(ConnectionTabVM());
  getIt.registerSingleton(DashboardTabVM());
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
  final bool visible;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final Widget trailing;

  InfoCard({this.visible, this.title, this.subtitle, this.subtitleColor, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: this.visible != null ? this.visible : true,
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
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: subtitleColor,
              ),
            ),
            trailing: this.trailing,
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
              trailing: Visibility(
                visible: useWatchOnly((ConnectionTabVM connectionTabVM) => connectionTabVM.isScanning),
                child: SizedBox(
                  width: 25.0,
                  height: 25.0,
                  child: SpinKitRipple(
                    color: Colors.white,
                    size: 25.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.0),
            InfoCard(
              visible: useWatchOnly((ConnectionTabVM connectionTabVM) => connectionTabVM.isConnected),
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

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  String _connectionStatusLabel = 'Disconnected';
  String get connectionStatusLabel => _connectionStatusLabel;

  Color _connectionStatusColor = Color(0xFFDF927B);
  Color get connectionStatusColor => _connectionStatusColor;

  String _fabLabel = 'CONNECT';
  String get fabLabel => _fabLabel;

  String _viName = 'Unknown';
  String get viName => _viName;

  StreamSubscription _stateSub;
  BluetoothService _openXCService;
  BluetoothCharacteristic _writeCharacteristic;
  BluetoothCharacteristic _notifyCharacteristic;
  StreamSubscription _readSub;

  // Connect Method
  Future<void> connect() async {
    if (!this._isScanning) {
      // Disconnect All Devices
      await this.disconnect();

      this._isScanning = true;
      this._connectionStatusLabel = 'Scanning';
      this._connectionStatusColor = Color(0xFFFFEAA7);
      notifyListeners();

      List<ScanResult> scanResults = await FlutterBlue.instance.scan(timeout: Duration(seconds: 5)).toList();
      for (ScanResult scanResult in scanResults) {
        // Print Scane Result
        this._printScanResult(scanResult);

        // Find OpenXC Device
        String deviceName = scanResult.advertisementData.localName.trim().toUpperCase();
        if (deviceName.contains(DEVICE_NAME_PREFIX)) {
          BluetoothDevice bluetoothDevice = scanResult.device;
          await bluetoothDevice.connect();

          // Listen: State Changes
          this._stateSub = bluetoothDevice.state.listen((state) async {
            print('Device State: ${state.toString().toUpperCase()}');
          });

          // Find OpenXC Service
          List<BluetoothService> bluetoothServices = await bluetoothDevice.discoverServices();
          for (BluetoothService bluetoothService in bluetoothServices) {
            if (bluetoothService.uuid.toString().toUpperCase() == OPENXC_SERVICE_UUID) {
              this._openXCService = bluetoothService;
              print('Service UUID: ${this._openXCService.uuid.toString().toUpperCase()}');
              break;
            }
          }

          // Assign Write Characteristic
          this._writeCharacteristic = this
              ._openXCService
              .characteristics
              .where((X) => X.uuid.toString().toUpperCase() == WRITE_CHARACTERISTIC_UUID)
              .first;
          print('Write Characteristic UUID: ${this._writeCharacteristic.uuid.toString().toUpperCase()}');

          // Assign Notify Characteristic
          this._notifyCharacteristic = this
              ._openXCService
              .characteristics
              .where((X) => X.uuid.toString().toUpperCase() == NOTIFY_CHARACTERISTIC_UUID)
              .first;
          print('Notify Characteristic UUID: ${this._notifyCharacteristic.uuid.toString().toUpperCase()}');

          // Keep Connected
          await this._notifyCharacteristic.setNotifyValue(true);
          this._readSub = this._notifyCharacteristic.value.listen((data) {
            useGet<DashboardTabVM>().addToDataBuffer(data);
          });

          // Update Connection Related Variables
          this._isConnected = true;
          this._isScanning = false;
          this._connectionStatusLabel = 'Connected';
          this._connectionStatusColor = Color(0xFF9DE089);
          this._fabLabel = 'DISCONNECT';
          this._viName = deviceName;

          notifyListeners();
        }
      }

      if (this._isScanning) {
        this._isScanning = false;
        this._connectionStatusLabel = 'Disconnected';
        this._connectionStatusColor = Color(0xFFDF927B);
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

    this._stateSub?.cancel();
    this._openXCService = null;
    this._writeCharacteristic = null;
    this._notifyCharacteristic = null;
    this._readSub?.cancel();

    // Clear Data
    useGet<DashboardTabVM>().clearDataBuffer();

    // Update Connection Related Variables
    this._isConnected = false;
    this._connectionStatusLabel = 'Disconnected';
    this._connectionStatusColor = Color(0xFFDF927B);
    this._fabLabel = 'CONNECT';
    this._viName = 'Unknown';

    notifyListeners();
  }

  void _printScanResult(ScanResult scanResult) {
    String deviceId = scanResult.device.id.toString().toUpperCase();
    String deviceName = scanResult.advertisementData.localName.replaceAll(RegExp(r'\0'), '').trim().toUpperCase();
    if (deviceName.isNotEmpty) {
      print('$deviceId :: $deviceName');
    }
  }
}

class VehicleMessageCard extends HookWidget {
  final String messageKey;

  VehicleMessageCard({this.messageKey});

  @override
  Widget build(BuildContext context) {
    String messageName = useGet<DashboardTabVM>().messagesMap[this.messageKey].name;
    String messageValue = useWatchXOnly((DashboardTabVM dashboardTabVM) => dashboardTabVM.messagesMap[this.messageKey],
        (VehicleMessage vehicleMessage) => vehicleMessage.value);
    String messageCount = useWatchXOnly((DashboardTabVM dashboardTabVM) => dashboardTabVM.messagesMap[this.messageKey],
        (VehicleMessage vehicleMessage) => vehicleMessage.count.toString());
    return Card(
      elevation: 0.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(
              messageName,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              messageValue,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            trailing: Badge(
              toAnimate: false,
              shape: BadgeShape.square,
              borderRadius: BorderRadius.circular(5.0),
              badgeColor: Theme.of(context).accentColor,
              badgeContent: Text(
                messageCount,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
          ),
        ],
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
        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {
              useGet<DashboardTabVM>().clearAllData();
            },
          ),
        ],
      ),
      body: Container(
          child: Visibility(
        visible: useWatchOnly((DashboardTabVM dashboardTabVM) => dashboardTabVM.messageKeys.isEmpty),
        child: Center(
          child: Text(
            '• NO VEHICLE MESSAGES •',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        replacement: ListView.builder(
          padding: EdgeInsets.all(5.0),
          itemCount: useWatchOnly((DashboardTabVM dashboardTabVM) => dashboardTabVM.messageKeys.length),
          itemBuilder: (context, index) {
            return VehicleMessageCard(
              messageKey: useGet<DashboardTabVM>().messageKeys[index],
            );
          },
        ),
      )),
    );
  }
}

class VehicleMessage extends ChangeNotifier {
  final Map jsonMap;
  final String decodedMessage;
  final String name;

  String _value = 'UNKNOWN';
  String get value => _value;
  set value(String val) {
    this._value = val;
    notifyListeners();
  }

  int _count = 1;
  int get count => _count;
  set count(int val) {
    this._count = val;
    notifyListeners();
  }

  VehicleMessage(this.jsonMap, this.decodedMessage, this.name, this._value);

  VehicleMessage.fromJson(Map jsonMap)
      : this.jsonMap = jsonMap,
        this.decodedMessage = json.encode(jsonMap),
        this.name = jsonMap['name'].toString().toUpperCase().replaceAll('_', ' '),
        this._value = jsonMap['event'] != null
            ? (jsonMap['value'] + ' • ' + jsonMap['event']).toString().toUpperCase().replaceAll('_', ' ')
            : jsonMap['value'].toString().toUpperCase().replaceAll('_', ' ');
}

class DashboardTabVM extends ChangeNotifier {
  List<int> _dataBuffer = [];
  List<int> get dataBuffer => _dataBuffer;

  List<String> _decodedData = [];
  List<String> get decodedData => _decodedData;

  List<VehicleMessage> _vehicleMessages = [];
  List<VehicleMessage> get vehicleMessages => _vehicleMessages;

  List<String> _messageKeys = [];
  List<String> get messageKeys => _messageKeys;

  Map<String, VehicleMessage> _messagesMap = Map<String, VehicleMessage>();
  Map<String, VehicleMessage> get messagesMap => _messagesMap;

  void addToDataBuffer(List<int> data) {
    this._dataBuffer.addAll(data);
    this._decodeDataBuffer();
    notifyListeners();
  }

  void clearAllData() {
    this._dataBuffer.clear();
    this._decodedData.clear();
    this._vehicleMessages.clear();
    this._messageKeys.clear();
    this._messagesMap.clear();
    notifyListeners();
  }

  void clearDataBuffer() {
    this._dataBuffer.clear();
    notifyListeners();
  }

  void _decodeDataBuffer() {
    int terminatorIndex = this._dataBuffer.indexOf(0);
    while (terminatorIndex != -1) {
      List<int> encodedMessage = this._dataBuffer.sublist(0, terminatorIndex);
      this._dataBuffer.removeRange(0, terminatorIndex + 1);
      try {
        String decodedMessage = utf8.decode(encodedMessage);
        Map jsonMap = json.decode(decodedMessage);
        this._decodedData.add(decodedMessage);
        VehicleMessage vehicleMessage = VehicleMessage.fromJson(jsonMap);
        this._vehicleMessages.add(vehicleMessage);
        if (this._messagesMap.containsKey(vehicleMessage.name)) {
          this._messagesMap[vehicleMessage.name].value = vehicleMessage.value;
          this._messagesMap[vehicleMessage.name].count++;
        } else {
          this._messagesMap[vehicleMessage.name] = vehicleMessage;
          this._messageKeys = this._messagesMap.keys.toList()..sort();
        }
        print('JSON Data: $decodedMessage');
      } catch (exception) {}
      terminatorIndex = this._dataBuffer.indexOf(0);
    }
  }
}

class SettingsListTile extends StatelessWidget {
  final IconData iconData;
  final String title;
  final String subtitle;
  final Function onTap;

  SettingsListTile({this.iconData, this.title, this.subtitle, this.onTap});

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
      onTap: this.onTap,
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
              subtitle: 'BLE • Trace File',
              onTap: () {},
            ),
            SettingsListTile(
              iconData: Icons.save,
              title: 'Recording',
              subtitle: 'Trace Files • Dweet.IO',
              onTap: () {},
            ),
            SettingsListTile(
              iconData: Icons.info,
              title: 'About',
              subtitle: 'Application • Platform',
              onTap: () {},
            ),
          ],
        ).toList(),
      ),
    );
  }
}
