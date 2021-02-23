import 'package:flutter/material.dart';
import 'package:client_server_lan/client_server_lan.dart';
import 'package:device_info/device_info.dart';

import 'city.dart';
import 'client_page.dart';
import 'server_page.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UDPLANtransfer',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String dropdownValue = 'Server';
  bool isLoading = false;
  String dataReceived = '';
  bool isRunning = false;
  String status = '';

  // Server
  ServerNode server;
  List<ConnectedClientNode> connectedClientNodes = [];

  // Client
  ClientNode client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UDPLANtransfer'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown(),
            Expanded(
              child: dropdownValue == 'Server'
                  ? ServerPage(
                      onStartPressed: startServer,
                      onDisposePressed: disposeServer,
                      connectedClientNodes: connectedClientNodes,
                      onFindClientsPressed: findClients,
                      onSendToClient: serverToClient,
                      dataReceived: dataReceived,
                      isLoading: isLoading,
                      isRunning: isRunning,
                      status: status,
                    )
                  : ClientPage(
                      onStartPressed: startClient,
                      onDisposePressed: disposeClient,
                      onSendToServer: clientToServer,
                      dataReceived: dataReceived,
                      onCheckServerPressed: checkServerExistance,
                      isLoading: isLoading,
                      isRunning: isRunning,
                      status: status,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DropdownButton<String> _buildDropdown() {
    return DropdownButton<String>(
      value: dropdownValue,
      disabledHint: Text(dropdownValue),
      onChanged: !isRunning
          ? (String newValue) {
              setState(() {
                dropdownValue = newValue;
              });
            }
          : null,
      items: <String>['Server', 'Client']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  void startServer() async {
    var deviceInfo = await DeviceInfoPlugin().androidInfo;
    setState(() {
      isLoading = true;
      server = ServerNode(
        name: 'Server-${deviceInfo.brand}-${deviceInfo.model}',
        verbose: true,
        onDispose: onDisposeServer,
        clientDispose: clientDispose,
        onError: onError,
      );
    });

    await server.init();
    await server.onReady;

    setState(() {
      status = 'Server ready on ${server.host}:${server.port} (${server.name})';
      isRunning = true;
      isLoading = false;
    });
    server.dataResponse.listen((DataPacket data) {
      setState(() {
        dataReceived = data.payload.toString();
      });
    });
  }

  void disposeServer() {
    setState(() {
      isLoading = true;
    });
    server.dispose();
  }

  void onDisposeServer() {
    setState(() {
      isRunning = false;
      status = 'Server is not running';
      isLoading = false;
      connectedClientNodes = [];
    });
  }

  void clientDispose(ConnectedClientNode c) async {
    setState(() {
      connectedClientNodes = [];
    });
    for (final s in server.clientsConnected) {
      setState(() {
        connectedClientNodes.add(s);
      });
    }
  }

  void findClients() async {
    await server.discoverNodes();
    await Future<Object>.delayed(const Duration(seconds: 2));
    setState(() {
      connectedClientNodes = [];
    });
    for (final s in server.clientsConnected) {
      setState(() {
        connectedClientNodes.add(s);
      });
    }
  }

  void serverToClient(String clientName, dynamic message) async {
    final client = server.clientUri(clientName);
    await server.sendData(message, 'userInfo', client);
  }

  // Client
  void startClient() async {
    var deviceInfo = await DeviceInfoPlugin().androidInfo;
    setState(() {
      isLoading = true;
      client = ClientNode(
        name: 'Client-${deviceInfo.brand}-${deviceInfo.model}',
        verbose: true,
        onDispose: onDisposeClient,
        onServerAlreadyExist: onServerAlreadyExist,
        onError: onError,
      );
    });

    await client.init();
    await client.onReady;

    setState(() {
      status = 'Client ready on ${client.host}:${client.port} (${client.name})';
      isRunning = true;
      isLoading = false;
    });

    client.dataResponse.listen((DataPacket data) {
      setState(() {
        if (data.payload.runtimeType == String) {
          dataReceived = data.payload;
        } else {
          dataReceived = City.fromMap(data.payload).toString();
        }
      });
    });
  }

  void disposeClient() {
    client.dispose();
  }

  void onDisposeClient() {
    setState(() {
      isRunning = false;
      status = 'Client is not running';
      isLoading = false;
    });
  }

  Future<void> onServerAlreadyExist(DataPacket dataPacket) async {
    print('Server already exist on ${dataPacket.host} (${dataPacket.name})');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Server Already Exist'),
          content:
              Text('Server ready on ${dataPacket.host} (${dataPacket.name})'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkServerExistance() async {
    await client.discoverServerNode();
  }

  void clientToServer(dynamic message) async {
    await client.sendData(message, 'userInfo');
  }

  Future<void> onError(String error) async {
    print('ERROR $error');
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(error),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }
}
