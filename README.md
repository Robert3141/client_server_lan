# client_server_lan

A LAN communication Flutter package based off [Node Commander](https://github.com/synw/nodecommander) but removing parts such as Commander Nodes and making communication between client and server two way.

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
      name: "Server name",
      verbose: true,
      host: ip,
      port: 8085,
    );
    await server.init();
    await server.onReady;
    setState(() {
      serverStatus = "Server ready on ${server.host}:${server.port}";
    });
    server.dataResponse.listen((dynamic data) {
      setState(() {
        dataRecieved = data.toString();
      });
    });
}
```
Start a Client Node

```dart
void startClient() async {
    String ip = await Wifi.ip;
    client = ClientNode(
      name: "Client Name",
      verbose: true,
      host: ip,
      port: 8085,
    );
    await client.init();
    await client.onReady;
    setState(() {
      clientStatus = "Client ready on ${client.host}:${client.port}";
    });
    client.dataResponse.listen((dynamic data) {
      setState(() {
        dataRecieved = data.toString();
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
    await client.sendData(dataToSend, client.serverDetails.address);
}
```

Transfer from Server to Client

```dart
void serverToClient(String clientName) async {
    final String client = server.clientUri(clientName);
    await server.sendData(dataToSend, client);    
}
```
