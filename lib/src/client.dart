part of 'basenode.dart';

class ClientNode extends BaseClientNode {
  ClientNode(
      {@required this.name, this.host, this.port = 8084, this.verbose = false})
      : assert(name != null) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (host == null) {
        throw ArgumentError("Please provide a host");
      }
    }
  }

  /// The name of the node on the network
  @override
  String name;

  /// The IP address of the device
  @override
  String host;

  /// The Port to use for communication
  @override
  int port;

  /// Whether to debug print outputs of what's happening
  @override
  bool verbose;

  /// Used to setup the Node ready for use
  Future<void> init({String ip, bool start = true}) async {
    ip ??= host;
    ip ??= await getHost();
    await _initClientNode(ip, start: start);
  }
}

abstract class BaseClientNode with BaseNode {
  BaseClientNode() {
    _isServer = false;
  }

  ConnectedClientNode _server;

  /// Provides information about the server if one is connected
  ConnectedClientNode get serverDetails => _server;

  Future<void> _initClientNode(String host, {@required bool start}) async {
    await _initNode(host, false, start: start);
    await _listenForDiscovery();
    if (verbose) {
      _.ok(_e.nodeReady);
    }
    _readyCompleter.complete();
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
      final String addr = "${data["host"]}:${data["port"]}";
      await _sendInfo("client_connect", addr);
    });
  }
}
