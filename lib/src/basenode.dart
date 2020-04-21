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

  bool _isServer;
  int _socketPort;
  bool _isRunning = false;

  final Completer<void> _socketReady = Completer<void>();
  final List<ConnectedClientNode> _clients = <ConnectedClientNode>[];
  final Dio _dio = Dio(BaseOptions(connectTimeout: 5000, receiveTimeout: 3000));
  final Completer _readyCompleter = Completer<void>();
  final StreamController<DataPacket> _dataResponce =
      StreamController<DataPacket>.broadcast();

  /// The way to access the status of the HTTP Listener
  void status() => iso.status();

  /// Future for when the Node is fully set up
  Future get onReady => _readyCompleter.future;

  /// Boolean to tell whether the Node is running
  bool get isRunning => _isRunning;

  /// The data stream to listen on for incoming data sent from devices on the LAN
  Stream<DataPacket> get dataResponse => _dataResponce.stream;

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
    if (verbose && _isServer) {
      _.ok("Node is ready");
    }
    if (_isServer) {
      _readyCompleter.complete();
    }
  }

  Future<void> sendData(String title, dynamic data, String to) async {
    assert(to != null);
    assert(data != null);
    if (verbose) {
      _.smallArrowOut("Sending data $data to $to");
    }
    final response = await _sendData(title, data, to, "/cmd/response");
    if (response == null || response.statusCode != HttpStatus.ok) {
      final ecode = response?.statusCode ?? "no response";
      _.warning("Error sending the data response: $ecode");
    }
  }

  Future<void> _sendInfo(String title, String to) async {
    final response = await _sendData(title, null, to, "/cmd/response");
    if (response == null || response.statusCode != HttpStatus.ok) {
      final ecode = response?.statusCode ?? "no response";
      _.warning("Error sending the info response: $ecode");
    }
  }

  /// To be run when the HTTP Server is no longer required
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
    routes.add(IsoRoute(handler: _sendHandler, path: "/cmd"));
    routes.add(IsoRoute(handler: _responseHandler, path: "/cmd/response"));
    final router = IsoRouter(routes);
    //run isolate
    iso = IsoHttpd(host: host, router: router);
    return router;
  }

  void _listenToIso() {
    iso.logs.listen((dynamic data) async {
      if (data is Map<String, dynamic>) {
        data = DataPacket.fromJson(data);
        if (data.title == "client_connect") {
          final client = ConnectedClientNode(
              name: data.name,
              address: "${data.host}:${data.port}",
              lastSeen: DateTime.now());
          _clients.add(client);
          if (verbose) {
            _.state(
                "Client ${data.name} connected at ${data.host}:${data.port}");
          }
        } else {
          if (data.payload != "null") {
            _dataResponce.sink.add(data);
          } else if (verbose) {
            print("Empty packet recieved from ${data.host}:${data.port}");
          }
        }
      }
      if (data is String) {
        //data is message about server
        if (verbose) {
          print(data);
        }
      } else if (data is DataPacket) {
        if (data.payload != null) {
          _dataResponce.sink.add(data);
        } else if (verbose) {
          print("Empty packet recieved from ${data.host}:${data.port}");
        }
      } else {
        if (verbose) {
          _.error("Data received type ${data.runtimeType} not packet: " +
              data.toString());
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

  Future<Response> _sendData(
      String title, dynamic data, String to, String endPoint) async {
    assert(to != null);
    final uri = "http://$to$endPoint";
    Response response;
    final packet = DataPacket(
        host: host, port: port, name: name, title: title, payload: data);
    try {
      response = await _dio.post<dynamic>(uri, data: packet.encodeToString());
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
    final payload =
        DataPacket(host: host, port: port, name: name, title: "client_connect")
            .encodeToString();
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
