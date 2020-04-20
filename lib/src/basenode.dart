import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:isohttpd/isohttpd.dart';
import 'package:meta/meta.dart';
import 'package:emodebug/emodebug.dart';

part 'server.dart';
part 'client.dart';
part 'models.dart';
part 'host.dart';

const _ = EmoDebug();

abstract class BaseNode {
  String name;
  String host;
  int port;
  IsoHttpd iso;
  bool verbose;
  RawDatagramSocket _socket;
  ConnectedClientNode _server;
  bool _isServer;
  int _socketPort;
  bool _isRunning = false;

  final Completer<void> _socketReady = Completer<void>();
  final List<ConnectedClientNode> _clients = <ConnectedClientNode>[];
  final Dio _dio = Dio(BaseOptions(connectTimeout: 5000, receiveTimeout: 3000));
  final Completer _readyCompleter = Completer<void>();
  final StreamController<String> _dataResponce =
      StreamController<String>.broadcast();

  Future get onReady => _readyCompleter.future;
  bool get isRunning => _isRunning;
  Stream<String> get dataResponse => _dataResponce.stream;

  void start() => iso.start();
  void stop() => iso.stop();
  void status() => iso.status();

  Future<void> _initNode(String _host, bool isServer,
      {@required bool start}) async {
    host = _host;
    _isServer = isServer;
    //socket port
    _socketPort ??= _randomSocketPort();
    final router = _initRoutes();
    // run isolate
    iso = IsoHttpd(host: host, port: port, router: router);
    await iso.run(startServer: start);
    _listenToIso();
    await iso.onServerStarted;
    _isRunning = true;
    await _initForDiscovery();
    if (!_isServer) {
      _listenForDiscovery();
    }
    if (verbose) {
      _.ok("Node is ready");
    }
    _readyCompleter.complete();
  }

  Future<void> sendData(dynamic data, String to) async {
    assert(to != null);
    assert(data != null);
    if (verbose) {
      _.smallArrowOut("Sending data $data to $to");
    }
    final response = await _sendData(data, to, "/cmd/response");
    if (response == null || response.statusCode != HttpStatus.ok) {
      final ecode = response?.statusCode ?? "no response";
      _.warning("Error sending the data response: $ecode");
    }
  }

  void dispose() {
    _dataResponce.close();
    _socket.close();
    iso.kill();
    if (verbose) {
      print(_isServer ? "Server Disposed" : "Client Disposed");
    }
  }

  IsoRouter _initRoutes() {
    this.host = host;
    this.port = port;
    final routes = <IsoRoute>[];
    routes.add(IsoRoute(handler: sendHandler, path: "/cmd"));
    routes.add(IsoRoute(handler: responseHandler, path: "/cmd/response"));
    final router = IsoRouter(routes);
    //run isolate
    iso = IsoHttpd(host: host, router: router);
    return router;
  }

  void _listenToIso() {
    iso.logs.listen((dynamic data) async {
      //print("PAYLOAD RECIEVED $data");
      if (data is String) {
        //verify data
        _dataResponce.sink.add(data.toString());
        //print("PAYLOAD IS STRING");
      } else {
        final client = ConnectedClientNode(
            name: data["name"].toString(),
            address: "${data["host"]}:${data["port"]}",
            lastSeen: DateTime.now());
        _clients.add(client);
        if (verbose) {
          _.state(
              "Client ${client.name} connected at ${data["host"]}:${data["port"]}");
        }
      }
    });
  }

  Future<void> _initForDiscovery() async {
    if (verbose) {
      print("Intializing for discovery on $host:$port");
    }
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _socketPort)
      ..broadcastEnabled = true;
    if (verbose) {
      print("Socket is ready at ${_socket.address.host}:$_socketPort");
    }
    if (!_socketReady.isCompleted) {
      _socketReady.complete();
    }
  }

  Future<void> _listenForDiscovery() async {
    assert(_socket != null);
    await _socketReady.future;
    if (verbose) {
      print("Listening on socket ${_socket.address.host}:$_socketPort");
    }
    _socket.listen((RawSocketEvent e) async {
      final d = _socket.receive();
      if (d == null) {
        return;
      }
      final message = utf8.decode(d.data).trim();
      final dynamic data = json.decode(message);
      _server = ConnectedClientNode(
          address: "${data["host"]}:${data["port"]}",
          name: data["name"].toString(),
          lastSeen: DateTime.now());
      if (verbose) {
        print(
            "Recieved connection request from Client ${data["host"]}:${data["port"]}");
      }
      final payload = <String, String>{
        "host": "$host",
        "port": "$port",
        "name": "$name"
      };
      final String addr = "${data["host"]}:${data["port"]}";
      await sendData(payload, addr);
    });
  }

  Future<Response> _sendData(dynamic data, String to, String endPoint) async {
    assert(data != null);
    assert(to != null);
    final uri = "http://$to$endPoint";
    //print("URI=$uri");
    Response response;
    try {
      //final dynamic data = //_dataToJson(_data,"$host:$port");
      //print("POSTING TO DIO");
      response = await _dio.post<dynamic>(uri, data: data);
      //print("POSTED TO DIO");
    } on DioError catch (e) {
      if (e.response != null) {
        _.error(e, "http error with response");
        return response;
      } else {
        _.error(e, "http error with no response");
      }
    } catch (e) {
      rethrow;
    }
    return response;
  }

  Future<void> _broadcastForDiscovery() async {
    assert(host != null);
    assert(_isServer);
    await _socketReady.future;
    final payload = '{"host":"$host", "port": "$port", "name": "$name"}';
    final data = utf8.encode(payload);
    String broadcastAddr;
    final l = host.split(".");
    broadcastAddr = "${l[0]}.${l[1]}.${l[2]}.255";
    if (verbose) {
      print("Broadcasting to $broadcastAddr: $payload");
    }
    _socket.send(data, InternetAddress(broadcastAddr), _socketPort);
  }

  int _randomSocketPort() {
    return 9104;
    /*
    const int min = 9100;
    const int max = 9999;
    final n = Random().nextInt((max - min).toInt());
    return min + n;*/
  }
}
