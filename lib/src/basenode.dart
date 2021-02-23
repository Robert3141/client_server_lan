import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:get_ip/get_ip.dart';
import 'package:isohttpd/isohttpd.dart';
import 'package:meta/meta.dart';
import 'package:emodebug/emodebug.dart';

part 'server.dart';
part 'client.dart';
part 'models.dart';
part 'host.dart';

//errors
const _ = EmoDebug();
const String _suffix = "/cmd";

// Strings for debug outputs
// ignore: camel_case_types
class _e {
  static const String nodeReady = "Node is ready";
  static const String httpResponse = "http error with response";
  static const String httpNoResponse = "http error with no response";
  static const String noResponse = "no response";
  static const String shouldNotReceive =
      "this node should not have received this command";
  static const String serverError = "Server error.";
  static ArgumentError addressNull =
      ArgumentError("The address cannot be null");
  static ArgumentError dataNull = ArgumentError("The data cannot be null");
  static ArgumentError nameNull =
      ArgumentError("The name of the node cannot be null or empty");
  static ArgumentError titleInternal = ArgumentError(
      "The title cannot be used as it is an internal title. Full list of titles: ${_s.titles}");
  static UnsupportedError platformNotSupported =
      UnsupportedError("Unable to optain the local IP address of this device");
}

// Strings for internal commands
// ignore: camel_case_types
class _s {
  static const String clientConnect = "client_connect";
  static const String getClientNames = "client_names";
  static const String forwardData = "forward_data";
  static const String clientDisconnect = "client_disconnect";
  static const String clientDispose = "client_dispose";
  static const String checkServerExist = "check_server_already_exist";
  static const String imAlreadyServer = "im_already_server";

  //list of all these strings
  static const List<String> titles = [
    clientConnect,
    getClientNames,
    forwardData,
    clientDisconnect,
    clientDispose,
    checkServerExist,
    imAlreadyServer,
  ];
}

abstract class _BaseNode {
  String _name;
  String _host;
  int _port;
  IsoHttpd _iso;
  RawDatagramSocket _socket;
  bool _isServer;
  bool _debug = false; // TODO make false on any package releases
  int _socketPort;
  bool _isRunning = false;
  Function() onDispose = () {};
  Function(DataPacket) onServerAlreadyExist = (dataPacket) {};
  Function(String) onError = (error) {};

  final Completer<void> _socketReady = Completer<void>();
  final List<ConnectedClientNode> _clients = <ConnectedClientNode>[];
  final Dio _dio = Dio(BaseOptions(connectTimeout: 5000, receiveTimeout: 3000));
  final Completer _readyCompleter = Completer<void>();
  final StreamController<DataPacket> _dataResponce =
      StreamController<DataPacket>.broadcast();
  final StreamController<List<ConnectedClientNode>> _connectedClients =
      StreamController<List<ConnectedClientNode>>.broadcast();

  /// Debug print outputs of the data being received or sent.
  /// This is primarily for use in the debug development phase
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
    _isServer = isServer;
    //socket port
    _socketPort ??= _randomSocketPort();
    final router = _initRoutes();
    // run isolate
    print("host = $_host $host $_h");
    this._host = _h;
    _iso = IsoHttpd(host: _h, port: port, router: router);
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
    iso.logs.listen((Object data) async {
      if (data is Map<String, Object>) {
        print("TYPE: MAP");
        //convert to packet
        data = DataPacket.fromJson(data);
      }
      if (data is String) {
        print("TYPE: STRING");

        //data is message about server
        if (verbose) {
          print("Received: $data");
        }
      } else if (data is DataPacket) {
        print("TYPE: DATAPACKET");

        //print
        if (_debug) print("----received $data");
        //update last seen
        if (_clients != null) {
          for (int i = 0; i < _clients.length; i++) {
            if (_clients[i].host == data.host) {
              _clients[i].lastSeen = DateTime.now();
              i = _clients.length;
            }
          }
        }
        // Data in format as expected
        switch (data.title) {
          case _s.clientConnect:
            _handleConnect(data);
            break;
          case _s.clientDisconnect:
            _handleDisconnect(data);
            break;
          case _s.clientDispose:
            _handleDispose(data);
            break;
          case _s.forwardData:
            await _handleForwardData(data);
            break;
          case _s.getClientNames:
            _handleGetNames(data);
            break;
          default:
            //packet Received
            _.data("Received Packet: ${data.name} : ${data.payload}");
            _dataResponce.sink.add(data);
            break;
        }
      } else {
        // Data not in expected format
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
  Future<void> sendData(String data, [String title = "no name", String to]) =>
      _sendDataDynamic(data, title, to);

  Future<void> _sendDataDynamic(dynamic data,
      [String title = "no name", String to]) async {
    if (to == null) throw _e.addressNull;
    if (data == null) throw _e.dataNull;
    if (_s.titles.contains(title)) throw _e.titleInternal;

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
      if (response?.statusCode != null) {
        final ecode = response?.statusCode ?? _e.noResponse;
        _.warning("Error sending the info response: $ecode");
      }
    }
  }

  Future<Response> _sendData(
      String title, String data, String to, String endPoint) async {
    if (to == null) throw _e.addressNull;
    final uri = "http://$to$endPoint";
    Response response;
    final packet = DataPacket(
        host: host, port: port, name: name, title: title, payload: data);

    if (_debug) print("----sending $packet");
    try {
      response = await _dio.post<Object>(uri, data: packet.encodeToString());
    } on DioError catch (e) {
      if (e.response != null) {
        _.error(e, _e.httpResponse);
        onError("Error: $e");
        return response;
      } else {
        _.error(e, _e.httpNoResponse);
        onError("Error: ${_e.serverError}");
        return null;
      }
    } catch (e) {
      onError("Error: $e");
      rethrow;
    }
    return response;
  }

  /// To be run when the HTTP Server is no longer required
  void dispose() {
    _isRunning = false;
    _dataResponce.close();
    _connectedClients.close();
    _socket.close();
    iso.kill();
    if (verbose) {
      print(_isServer ? "Server Disposed" : "Client Disposed");
    }
    onDispose();
  }

  //
  // DATA RECEIVED ALGORITHMS
  //

  void _handleConnect(DataPacket data) {
    //client connect request
    final client = ConnectedClientNode(
        name: data.name,
        address: "${data.host}:${data.port}",
        lastSeen: DateTime.now());
    //check client not the same as currently in database if so update current client
    if (_clients.any((element) => element.address == client.address)) {
      //client exists so replace
      for (int i = 0; i < _clients.length; i++) {
        if (client.address == _clients[i].address) _clients[i] = client;
      }
    } else {
      //client is new
      _clients.add(client);
    }
    if (verbose) {
      _.state("Client ${data.name} connected at ${data.host}:${data.port}");
    }
  }

  void _handleGetNames(DataPacket data) {
    if (_isServer) {
      //return connected clients
      _sendDataDynamic(_clients, _s.getClientNames, data.host);
    } else {
      //share to stream the connected clients
      _connectedClients.sink.add(data._payload);
    }
  }

  Future<void> _handleForwardData(DataPacket data) async {
    if (_isServer) {
      // The server recieves the packet
      if (verbose) {
        _.smallArrowOut("Sending data $data to ${data.to}");
      }
      //send the data
      final uri = "http://${data.to}$_suffix";
      Response response;
      final packet = data;
      try {
        response = await _dio.post<dynamic>(uri, data: packet.encodeToString());
      } on DioError catch (e) {
        if (e.response != null) {
          _.error(e, _e.httpResponse);
        } else {
          _.error(e, _e.httpNoResponse);
        }
      } catch (e) {
        rethrow;
      }
      //await the response
      if (response == null || response.statusCode != HttpStatus.ok) {
        final ecode = response?.statusCode ?? _e.noResponse;
        _.warning("Error sending the data response: $ecode");
      }
    } else {
      // The client recieves the packet
      _.data("Received Packet: ${data.name} : ${data.payload}");
      _dataResponce.sink.add(data);
    }
  }

  void _handleDisconnect(DataPacket data) {
    if (!_isServer) {
      if (verbose) _.error(_e.shouldNotReceive);
    }
  }

  void _handleDispose(DataPacket data) {
    if (!_isServer) {
      //should occur
      //stop running so that it doesn't report back to server
      _isRunning = false;
      this.dispose();
    } else {
      if (verbose) _.error(_e.shouldNotReceive);
    }
  }
}
