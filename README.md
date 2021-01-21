# client_server_lan

[![Pub](https://img.shields.io/pub/v/client_server_lan.svg)](https://pub.dev/packages/client_server_lan)
[![Documentation](https://img.shields.io/badge/API-reference-blue)](https://pub.dev/documentation/client_server_lan/latest/client_server_lan/client_server_lan-library.html)

A LAN communication Flutter package based off [Node Commander](https://github.com/synw/nodecommander) but removing parts such as Commander Nodes and making communication between client and server two way.

ONLY SUPPORTS ANDROID AT THE MOMENT!!!

## Usage

### Run a Node

Start a Server Node

```dart
import 'dart:async';
import 'package:wifi/wifi.dart';
import 'package:client_server_lan/client_server_lan.dart';
void startServer() async {
    String ip = await Wifi.ip;
    server = ServerNode(
      name: "Server",
      verbose: true,
      host: ip,
      port: 8085,
    );
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
```
Start a Client Node

```dart
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
```
Server scan for Clients

```dart
void findClients() async {
    server.discoverNodes();
    await Future<dynamic>.delayed(const Duration(seconds: 2));
    clientIPs = "";
    for (final s in server.clientsConnected) {
      setState(() {
        clientIPs += "id=${s.name},IP=${s.address}\n";
      });
    }
  }
```

### Transfer Data

Transfer from Client to Server

```dart
void clientToServer() async {
    await client.sendData("userInfo",dataToSend, client.serverDetails.address);
  }
```

Transfer from Server to Client

```dart
void serverToClient(String clientName) async {
    final String client = server.clientUri(clientName);
    await server.sendData("userInfo",dataToSend, client);
  }
```
