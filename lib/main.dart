import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:badges/badges.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  accentColor: Color(0xFFFFD740),
  scaffoldBackgroundColor: Color(0xFF303030),
  canvasColor: Color(0xFF212121),
);

List<Widget> _tabWidgets = [
  ConnectionTab(),
  DashboardTab(),
  SendTab(),
  SettingsTab(),
];

BluetoothService openXCService;
BluetoothCharacteristic writeCharacteristic;
BluetoothCharacteristic notifyCharacteristic;

Map<String, String> dashboardItems = Map<String, String>();
Map<String, int> dashboardCounts = Map<String, int>();
List<String> orderedKeys = List<String>();

String commandSent = 'Version';
String commandResponse = '';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: appTheme.primaryColor,
    ),
  );
  runApp(Application());
}

class Application extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OpenXC',
      home: OpenXC(),
      theme: appTheme,
    );
  }
}

class OpenXC extends StatefulWidget {
  @override
  _OpenXCState createState() => _OpenXCState();
}

class _OpenXCState extends State<OpenXC> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: _tabWidgets,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _tabIndex,
        onTap: (int index) {
          setState(() {
            _tabIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            title: Text('Connection'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            title: Text('Dashboard'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.unarchive),
            title: Text('Send'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }
}

class ConnectionTab extends StatefulWidget {
  @override
  _ConnectionTabState createState() => _ConnectionTabState();
}

class _ConnectionTabState extends State<ConnectionTab> {
  static const DEVICE_NAME_PREFIX = "OPENXC-VI-";
  static const OPENXC_SERVICE_UUID = "6800D38B-423D-4BDB-BA05-C9276D8453E1";
  static const WRITE_CHARACTERISTIC_UUID = "6800D38B-5262-11E5-885D-FEFF819CDCE2";
  static const NOTIFY_CHARACTERISTIC_UUID = "6800D38B-5262-11E5-885D-FEFF819CDCE3";

  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription scanSub;
  StreamSubscription deviceStateSub;
  StreamSubscription readSub;

  String connectionString = 'DISCONNECTED';
  IconData connectionIcon = Icons.bluetooth_disabled;
  String fabString = 'CONNECT';

  List<int> dataBuffer = List<int>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenXC'),
      ),
      body: Container(
        padding: EdgeInsets.all(5.0),
        child: Column(
          children: <Widget>[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(
                    connectionIcon,
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.transparent,
                ),
                title: Text(connectionString),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'ConnectionFAB',
        onPressed: () async {
          if (fabString == 'CONNECT') {
            await _connectDevice();
          } else {
            await _disconnectDevices();
          }
        },
        label: Text(fabString),
      ),
    );
  }

  void _printScanResults(List<ScanResult> scanResults) {
    for (ScanResult scanResult in scanResults) {
      print('${scanResult.device.id.toString()} :: ${scanResult.device.name.toUpperCase()}');
    }
  }

  Future<void> _connectDevice() async {
    await _disconnectDevices();
    await flutterBlue.stopScan();
    await flutterBlue.startScan(timeout: Duration(seconds: 5));

    // Listen: Scan Results
    scanSub = flutterBlue.scanResults.listen((scanResults) async {
      _printScanResults(scanResults);
      for (ScanResult scanResult in scanResults) {
        String advertisementName = scanResult.advertisementData.localName.toUpperCase();
        if (advertisementName.contains(DEVICE_NAME_PREFIX)) {
          BluetoothDevice foundDevice = scanResult.device;

          await flutterBlue.stopScan();
          await foundDevice.connect();

          // Listen: State Changes
          deviceStateSub = foundDevice.state.listen((deviceState) async {
            print('Device State: ${deviceState.toString()}');
          });

          setState(() {
            connectionString = 'CONNECTED • $advertisementName';
            connectionIcon = Icons.bluetooth_connected;
            fabString = 'DISCONNECT';
          });
          List<BluetoothService> bluetoothServices = await foundDevice.discoverServices();
          for (BluetoothService bluetoothService in bluetoothServices) {
            if (bluetoothService.uuid.toString().toUpperCase() == OPENXC_SERVICE_UUID) {
              // Assign Service
              openXCService = bluetoothService;
              print('Service UUID: ${openXCService.uuid.toString().toUpperCase()}');
              break;
            }
          }

          // Assign Write Characteristic
          writeCharacteristic = openXCService.characteristics
              .where((X) => X.uuid.toString().toUpperCase() == WRITE_CHARACTERISTIC_UUID)
              .first;
          print('Write Characteristic UUID: ${writeCharacteristic.uuid.toString().toUpperCase()}');

          // Assign Notify Characteristic
          notifyCharacteristic = openXCService.characteristics
              .where((X) => X.uuid.toString().toUpperCase() == NOTIFY_CHARACTERISTIC_UUID)
              .first;
          print('Notify Characteristic UUID: ${notifyCharacteristic.uuid.toString().toUpperCase()}');

          // Listen: Read Data
          await notifyCharacteristic.setNotifyValue(true);
          readSub = notifyCharacteristic.value.listen((rawData) {
            dataBuffer.addAll(rawData);
            _tryDecodingDataBuffer();
          });

          break;
        }
      }
    });
  }

  Future<void> _disconnectDevices() async {
    List<BluetoothDevice> connectedDevices = await flutterBlue.connectedDevices;
    connectedDevices.forEach((connectedDevice) async {
      await connectedDevice.disconnect();
    });
    scanSub?.cancel();
    deviceStateSub?.cancel();
    readSub?.cancel();
    openXCService = null;
    writeCharacteristic = null;
    notifyCharacteristic = null;
    setState(() {
      connectionString = 'DISCONNECTED';
      connectionIcon = Icons.bluetooth_disabled;
      fabString = 'CONNECT';
    });
  }

  void _tryDecodingDataBuffer() {
    int terminatorIndex = dataBuffer.indexOf(0);
    if (terminatorIndex != -1) {
      List<int> rawData = dataBuffer.sublist(0, terminatorIndex);
      dataBuffer.removeRange(0, terminatorIndex);
      dataBuffer.removeAt(0);
      try {
        String decodedData = utf8.decode(rawData);
        dynamic jsonData = json.decode(decodedData);
        print('JSON Data: $jsonData');
        if (jsonData['command_response'] != null) {
          // Command Response
          commandResponse = decodedData;
        } else {
          // Vehicle Message
          String itemKey = jsonData['name'].toString().toUpperCase().replaceAll('_', ' ');
          String itemValue = jsonData['value'].toString().toUpperCase().replaceAll('_', ' ');
          if (jsonData['event'] != null) {
            String itemEvent = jsonData['event'].toString().toUpperCase().replaceAll('_', ' ');
            itemValue += ' • $itemEvent';
          }
          dashboardItems[itemKey] = itemValue;
          if (!dashboardCounts.containsKey(itemKey)) {
            dashboardCounts[itemKey] = 1;
          } else {
            dashboardCounts[itemKey]++;
          }
          orderedKeys = dashboardItems.keys.toList()..sort();
        }
      } catch (someException) {}
    }
  }
}

class DashboardTab extends StatefulWidget {
  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OpenXC'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.clear_all),
            tooltip: 'Clear',
            onPressed: () {
              dashboardItems.clear();
              dashboardCounts.clear();
            },
          ),
        ],
      ),
      body: Container(
        child: Visibility(
          visible: dashboardItems.isEmpty,
          child: Center(
            child: Text(
              '• NO MESSAGES •',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          replacement: ListView.builder(
            padding: EdgeInsets.all(5.0),
            itemCount: dashboardItems.length,
            itemBuilder: (context, index) {
              return Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: Text(orderedKeys[index]),
                      subtitle: Text(dashboardItems[orderedKeys[index]]),
                      trailing: Badge(
                        toAnimate: false,
                        shape: BadgeShape.square,
                        borderRadius: 5.0,
                        badgeColor: appTheme.accentColor,
                        badgeContent: Text(
                          dashboardCounts[orderedKeys[index]].toString(),
                          style: TextStyle(color: appTheme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SendTab extends StatefulWidget {
  @override
  _SendTabState createState() => _SendTabState();
}

class _SendTabState extends State<SendTab> {
  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('OpenXC'),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(text: 'COMMAND'),
              Tab(text: 'DIAGNOSTIC'),
              Tab(text: 'CAN'),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            SendCommandTab(),
            SendDiagnosticTab(),
            SendCANTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'SendFAB',
          onPressed: () async {
            if (writeCharacteristic != null) {
              _sendStringData(getDefinedCommand(commandSent));
            }
          },
          label: Text('SEND'),
        ),
      ),
    );
  }

  String getDefinedCommand(String commandName) {
    commandName = commandName.toLowerCase().replaceAll(' ', '_');
    return '{"command":"$commandName"}';
  }

  Future<void> _sendStringData(String stringData) async {
    List<int> encodedData = List<int>();
    encodedData.addAll(utf8.encode(stringData));
    encodedData.add(0);
    _sendEncodedData(encodedData);
  }

  Future<void> _sendEncodedData(List<int> encodedData) async {
    await Future.delayed(Duration(milliseconds: 50));
    if (encodedData.length <= 20) {
      await writeCharacteristic.write(encodedData, withoutResponse: true);
      print('Write Data: ${utf8.decode(encodedData)}');
    } else {
      List<int> dataChunk = encodedData.sublist(0, 20);
      await writeCharacteristic.write(dataChunk, withoutResponse: true);
      print('Write Data: ${utf8.decode(dataChunk)}');
      await _sendEncodedData(encodedData.sublist(20));
    }
  }
}

class SendCommandTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: Column(
        children: <Widget>[
          DropdownButton<String>(
            value: commandSent,
            onChanged: (value) {
              commandSent = value;
            },
            items: [
              DropdownMenuItem(
                value: 'Version',
                child: Text('Version'),
              ),
              DropdownMenuItem(
                value: 'Device ID',
                child: Text('Device ID'),
              ),
              DropdownMenuItem(
                value: 'Platform',
                child: Text('Platform'),
              ),
            ],
          ),
          Text(commandResponse),
        ],
      ),
    );
  }
}

class SendDiagnosticTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: Center(
        child: Icon(Icons.new_releases),
      ),
    );
  }
}

class SendCANTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.0),
      child: Center(
        child: Icon(Icons.new_releases),
      ),
    );
  }
}

class SettingsTab extends StatefulWidget {
  @override
  _SettingsTabState createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              leading: CircleAvatar(
                child: Icon(
                  Icons.link,
                  color: Colors.white,
                ),
                backgroundColor: Colors.transparent,
              ),
              title: Text('Data Source'),
              subtitle: Text('Bluetooth • Trace File'),
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
              subtitle: Text('Trace File • Dweet.IO'),
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RecordingSettingsPage()));
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

class RecordingSettingsPage extends StatefulWidget {
  @override
  _RecordingSettingsPageState createState() => _RecordingSettingsPageState();
}

class _RecordingSettingsPageState extends State<RecordingSettingsPage> {
  bool _recordTraceFile = false;
  bool _sendToDweet = false;
  String _dweetThingName = 'Questionable-Koala';

  void _restorePrefs() async {
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    setState(() {
      _recordTraceFile = sharedPrefs.getBool('RECORD_TRACE_FILE') ?? false;
      _sendToDweet = sharedPrefs.getBool('SEND_TO_DWEET') ?? false;
      _dweetThingName = sharedPrefs.getString('DWEET_THING_NAME') ?? 'Questionable-Koala';
    });
  }

  void _savePrefs() async {
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    sharedPrefs.setBool('RECORD_TRACE_FILE', _recordTraceFile);
    sharedPrefs.setBool('SEND_TO_DWEET', _sendToDweet);
    sharedPrefs.setString('DWEET_THING_NAME', _dweetThingName);
  }

  void _clearPrefs() async {
    SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.clear();
  }

  @override
  void initState() {
    super.initState();
    _restorePrefs();
  }

  @override
  void dispose() {
    _savePrefs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recording'),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            SwitchListTile(
              activeColor: appTheme.accentColor,
              value: _recordTraceFile,
              title: Text('Record Trace File'),
              subtitle: Text(_recordTraceFile ? 'Enabled' : 'Disabled'),
              onChanged: (value) async {
                setState(() {
                  _recordTraceFile = !_recordTraceFile;
                });
              },
            ),
            ListTile(
              title: Text('View Trace Files'),
              subtitle: Text('0 Files'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ViewTraceFilesPage()));
              },
            ),
            SwitchListTile(
              activeColor: appTheme.accentColor,
              value: _sendToDweet,
              title: Text('Send To Dweet.IO'),
              subtitle: Text(_sendToDweet ? 'Enabled' : 'Disabled'),
              onChanged: (value) async {
                setState(() {
                  _sendToDweet = !_sendToDweet;
                });
              },
            ),
            Visibility(
              visible: _sendToDweet,
              child: ListTile(
                title: Text('Dweet.IO Thing Name'),
                subtitle: Text(_dweetThingName),
                onTap: () {},
              ),
            ),
            ListTile(
              title: Text('Reset Settings'),
              subtitle: Text('Restore Default Values'),
              onTap: () {
                setState(() {
                  _recordTraceFile = false;
                  _sendToDweet = false;
                });
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}

class ViewTraceFilesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trace Files'),
      ),
    );
  }
}
