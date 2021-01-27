import 'package:flutter/material.dart';
import 'dart:async';
import 'package:wifi/wifi.dart';
import 'package:client_server_lan/client_server_lan.dart';
import 'dart:io';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  bool dropdownEnabled = true;
  String serverStatus = "Server not running";
  String clientStatus = "Client not running";
  String clientIPs = "No devcies connected";
  String dataToSend = "Testing 1 2 3";
  String dataRecieved = "No response yet...";
  String clientToSend = "Moto g3 Client";
  String dropdownValue = "Server";

  void startServer() async {
    dropdownEnabled = false;
    if (Platform.isAndroid || Platform.isIOS) {
      String ip = await Wifi.ip;
      server = ServerNode(
        name: "Server",
        verbose: true,
        host: ip,
      );
    } else {
      server = ServerNode(name: "Server", verbose: true);
    }
    await server.init();
    await server.onReady;
    setState(() {
      serverStatus = "Server ready on ${server.host}:${server.port}";
    });
    server.dataResponse.listen((DataPacket data) {
      setState(() {
        dataRecieved = data.payload;
      });
    });
  }

  void startClient() async {
    dropdownEnabled = false;
    String ip = await Wifi.ip;
    client = ClientNode(
      name: "Client Node",
      verbose: true,
      host: ip,
      port: 8085,
    );
    await client.init();
    await client.onReady;
    setState(() {
      clientStatus = "Client ready on ${client.host}:${client.port}";
    });
    client.dataResponse.listen((DataPacket data) {
      setState(() {
        dataRecieved = data.payload;
      });
    });
  }

  void findClients() async {
    server.discoverNodes();
    await Future<Object>.delayed(const Duration(seconds: 2));
    clientIPs = "";
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
        ? dropdownValue == "Server"
            ? disposeServer()
            : disposeClient()
        : print("Disposing");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
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
              items: <String>["Server", "Client"]
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            dropdownValue == "Server"
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
                  : dropdownValue == "Server"
                      ? serverToClient(clientToSend)
                      : clientToServer(),
            ),
            Text(dataRecieved),
            RaisedButton(
              child: Text("Dispose $dropdownValue"),
              onPressed: () => dropdownEnabled
                  ? null
                  : dropdownValue == "Server"
                      ? disposeServer()
                      : disposeClient(),
            ),
          ],
        ),
      ),
    );
  }
}
