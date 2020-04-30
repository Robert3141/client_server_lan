import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isohttpd/isohttpd.dart';
import 'package:meta/meta.dart';
import 'package:emodebug/emodebug.dart';

part 'server.dart';
part 'client.dart';
part 'models.dart';
part 'host.dart';

//errors
const _ = EmoDebug();

class _e {
  static const String nodeReady = "Node is ready";
  static const String httpResponse = "http error with response";
  static const String httpNoResponse = "http error with no response";
  static const String noResponse = "no response";
}

const String _suffix = "/cmd";

abstract class _BaseNode {
  String _name;
  String _host;
  int _port;  
  IsoHttpd _iso;
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

  /// Debug print outputs of the data being received or sent. This is primarily for use in the debug development phase
  bool verbose;

  /// The way to access the status of the HTTP Listener
  void status() => iso.status();

  /// Future for when the Node is fully set up
  Future get onReady => _readyCompleter.future;

  /// Boolean to tell whether the Node is running
  bool get isRunning => _isRunning;

  /// The data stream to listen on for incoming data sent from devices on the LAN
  Stream<DataPacket> get dataResponse => _dataResponce.stream;

  /// The IP adress of the Node
  get host => _host;

  /// The String chosen as the name of the Node
  get name => _name;

  /// The Port of the Node
  get port => _port;

  /// The http server used for data transmission
  get iso => _iso;

  Future<void> _initNode(String _h, bool isServer,
      {@required bool start}) async {
    _host = _h;
    _isServer = isServer;
    //socket port
    _socketPort ??= _randomSocketPort();
    final router = _initRoutes();
    // run isolate
    _iso = IsoHttpd(host: host, port: port, router: router);
    await iso.run(startServer: start);
    _listenToIso();
    await iso.onServerStarted;
    _isRunning = true;
    await _initForDiscovery();
  }

  int _randomSocketPort() {
    return 9104;
    /*
    const int min = 9100;
    const int max = 9999;
    final n = Random().nextInt((max - min).toInt());
    return min + n;*/
  }

  IsoRouter _initRoutes() {
    this._host = host;
    this._port = port;
    final routes = <IsoRoute>[];
    routes.add(IsoRoute(handler: _responseHandler, path: _suffix));
    final router = IsoRouter(routes);
    //run isolate
    _iso = IsoHttpd(host: host, router: router);
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
          print("Received: $data");
        }
      } else if (data is DataPacket) {
        if (data.payload != null && data.payload!= "null") {
          _.data("Recieved Packet: ${data.name} : ${data.payload}");
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

  /// The method to transmit to another Node on the network. The data is transferred over LAN.
  Future<void> sendData(String title, dynamic data, String to) async {
    assert(to != null);
    assert(data != null);
    if (verbose) {
      _.smallArrowOut("Sending data $data to $to");
    }
    final response = await _sendData(title, data, to, _suffix);
    if (response == null || response.statusCode != HttpStatus.ok) {
      final ecode = response?.statusCode ?? _e.noResponse;
      _.warning("Error sending the data response: $ecode");
    }
  }

  Future<void> _sendInfo(String title, String to) async {
    final response = await _sendData(title, null, to, _suffix);
    if (response == null || response.statusCode != HttpStatus.ok) {
      final ecode = response?.statusCode ?? _e.noResponse;
      _.warning("Error sending the info response: $ecode");
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
        _.error(e, _e.httpResponse);
        return response;
      } else {
        _.error(e, _e.httpNoResponse);
      }
    } catch (e) {
      rethrow;
    }
    return response;
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
}
