import 'package:flutter/material.dart';
import 'dart:async';
import 'package:client_server_lan/client_server_lan.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN Server-Client Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'LAN Server-Client Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ServerNode server;
  ClientNode client;
  static const String clientName = "client";
  static const String serverName = "server";
  bool dropdownEnabled = true;
  String serverStatus = "Server not running";
  String clientStatus = "Client not running";
  String clientIPs = "No devices connected";
  String dataToSend = "Testing 1 2 3";
  String dataReceived = "No response yet...";
  String clientToSend = clientName;
  String dropdownValue = serverName;
  bool isRunning() => dropdownValue == serverName
      ? server != null
          ? server.isRunning
          : false
      : client != null
          ? client.isRunning
          : false;

  void startServer() async {
    dropdownEnabled = false;
    server = ServerNode(
      name: serverName,
      verbose: true,
      onDispose: onDispose,
      clientDispose: clientDispose,
    );
    await server.init();
    await server.onReady;
    setState(() {
      serverStatus = "Server ready on ${server.host}:${server.port}";
    });
    server.dataResponse.listen((DataPacket data) {
      setState(() {
        dataReceived = data.payload;
      });
    });
  }

  void startClient() async {
    dropdownEnabled = false;
    client = ClientNode(
      name: clientName,
      verbose: true,
      onDispose: onDispose,
      onServerAlreadyExist: onServerAlreadyExist,
    );
    await client.init();
    await client.onReady;
    setState(() {
      clientStatus = "Client ready on ${client.host}:${client.port}";
    });
    client.dataResponse.listen((DataPacket data) {
      print("LISTENDATARESPONSE $data");
      setState(() {
        dataReceived = data.payload;
      });
    });
  }

  void onDispose() {
    setState(() {
      dropdownEnabled = true;
      clientIPs = "";
      clientStatus = dropdownValue == serverName
          ? "Server not running"
          : "Client not running";
    });
  }

  void onServerAlreadyExist(String host) {
    print("Server already exist on $host");
  }

  void clientDispose(ConnectedClientNode c) async {
    setState(() {
      clientIPs = "";
    });
    for (final s in server.clientsConnected) {
      setState(() {
        clientIPs += "id=${s.name},IP=${s.address}\n";
      });
    }
  }

  void findClients() async {
    server.discoverNodes();
    await Future<Object>.delayed(const Duration(seconds: 2));
    setState(() {
      clientIPs = "";
    });
    for (final s in server.clientsConnected) {
      setState(() {
        clientIPs += "id=${s.name},IP=${s.address}\n";
      });
    }
  }

  void clientToServer() async {
    await client.sendData(dataToSend, "userInfo");
  }

  void serverToClient(String clientName) async {
    final String client = server.clientUri(clientName);
    await server.sendData(dataToSend, "userInfo", client);
  }

  void connectedNodes() async {
    client.discoverServerNode();
  }

  void disposeClient() {
    client.dispose();
    setState(() {
      clientStatus = "Client not running";
    });
    dropdownEnabled = true;
  }

  void disposeServer() {
    server.dispose();
    setState(() {
      serverStatus = "Server not running";
    });
    dropdownEnabled = true;
  }

  @override
  void dispose() {
    dropdownEnabled
        ? dropdownValue == serverName
            ? disposeServer()
            : disposeClient()
        : print("Disposing");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> mainWidgets = [
      DropdownButton<String>(
        value: dropdownValue,
        icon: Icon(Icons.arrow_downward),
        iconSize: 24,
        elevation: 16,
        style: TextStyle(color: Colors.deepPurple),
        underline: Container(
          height: 2,
          color: Colors.deepPurpleAccent,
        ),
        onChanged: (String newValue) {
          if (dropdownEnabled) {
            setState(() {
              dropdownValue = newValue;
            });
          }
        },
        items: <String>[serverName, clientName]
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
      dropdownValue == serverName
          ? Column(
              children: <Widget>[
                Text(serverStatus),
                RaisedButton(
                  child: Text("Start Server"),
                  onPressed: () => startServer(),
                ),
                RaisedButton(
                  child: Text("Scan Clients"),
                  onPressed: () => dropdownEnabled ? null : findClients(),
                ),
                Text(clientIPs),
                TextField(
                  decoration: InputDecoration(
                      labelText: "Client to send data to",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20)),
                  onChanged: (String text) {
                    setState(() {
                      clientToSend = text;
                    });
                  },
                ),
              ],
            )
          : Column(
              children: <Widget>[
                Text(clientStatus),
                RaisedButton(
                  child: Text("Start Client"),
                  onPressed: () => startClient(),
                ),
              ],
            ),
    ];
    List<Widget> bottomWidgets = [
      TextField(
        decoration: InputDecoration(
            labelText: "Data to send",
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(20)),
        onChanged: (String text) {
          setState(() {
            dataToSend = text;
          });
        },
      ),
      RaisedButton(
        child: Text("Send Data"),
        onPressed: () => dropdownEnabled
            ? null
            : dropdownValue == serverName
                ? serverToClient(clientToSend)
                : clientToServer(),
      ),
      Text(dataReceived),
      RaisedButton(
        child: Text("Dispose $dropdownValue"),
        onPressed: () => dropdownEnabled
            ? null
            : dropdownValue == serverName
                ? disposeServer()
                : disposeClient(),
      ),
      SizedBox(height: 20),
      RaisedButton(
        child: Text("Connected Clients"),
        onPressed: () => dropdownEnabled ? null : connectedNodes(),
      ),
    ];
    if (isRunning()) mainWidgets.addAll(bottomWidgets);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: mainWidgets,
        ),
      ),
    );
  }
}
