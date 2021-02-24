# client_server_lan

[![Pub](https://img.shields.io/pub/v/client_server_lan.svg)](https://pub.dev/packages/client_server_lan)
[![Documentation](https://img.shields.io/badge/API-reference-blue)](https://pub.dev/documentation/client_server_lan/latest/client_server_lan/client_server_lan-library.html)

A LAN communication Flutter package based off [Node Commander](https://github.com/synw/nodecommander) but removing parts such as Commander Nodes and making communication between client and server two way.

## Usage

### Add to android files

In android/app/AndroidManifest

```
<application ...
  android:networkSecurityConfig="@xml/network_security_config" >

 <meta-data android:name="io.flutter.network-policy"
        android:resource="@xml/network_security_config"/>
```

Then create a folder xml inside create a file: network_security_config.xml

```
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="true">
     <trust-anchors>
        <certificates src="system" />
    </trust-anchors>
  </base-config>
 </network-security-config>
```

### Run a Node

Start a Server Node

```dart
import 'dart:async';
import 'package:client_server_lan/client_server_lan.dart';
ServerNode server;
void startServer() async {
    server = ServerNode(
      name: "server_name",//any text name
      verbose: true,//output for debugging purposes
      onDispose: onDispose,//function run on server disposed
      clientDispose: clientDispose,//function run on client dispose
    );
    await server.init();
    await server.onReady;
    setState(() {
      serverStatus = "Server ready on ${server.host}:${server.port}";
    });
    server.dataResponse.listen((DataPacket data) {
      setState(() {
        String dataReceived = data.payload;
      });
    });
```

Start a Client Node

```dart
import 'dart:async';
import 'package:client_server_lan/client_server_lan.dart';
ClientNode client;
void startClient() async {
    client = ClientNode(
      name: clientName,//any text name
      verbose: true,//output for debugging purposes
      onDispose: onDispose,//function run on client dispose
    );
    await client.init();
    await client.onReady;
    setState(() {
      clientStatus = "Client ready on ${client.host}:${client.port}";
    });
    client.dataResponse.listen((DataPacket data) {
      setState(() {
        String dataReceived = data.payload;
      });
    });
  }
```

Server scan for Clients

```dart
void findClients() async {
    server.discoverNodes();
    await Future<Object>.delayed(const Duration(seconds: 2));
    //outputs client names and IPs (not neccessary)
    setState(() {
      clientIPs = "";
    });
    for (final s in server.clientsConnected) {
      setState(() {
        clientIPs += "id=${s.name},IP=${s.address}\n";
      });
    }
  }
```

### Transfer Data

WARNING: Data not excepted with titles in `client.internalTitles`/`server.internalTitles`

Transfer from Client to Server

```dart
void clientToServer(String dataToSend) async {
    await client.sendData(dataToSend, "userInfo");
  }
```

Transfer from Server to Client

```dart
void serverToClient(String dataToSend, String clientName) async {
    final String client = server.clientUri(clientName);
    await server.sendData(dataToSend, "userInfo", client);
  }
```

## Example

New Example app courtesy of [Fikrirazzaq](https://github.com/fikrirazzaq)

![Example](https://raw.githubusercontent.com/Robert3141/client_server_lan/master/example/art/example_screenshot.jpg)
