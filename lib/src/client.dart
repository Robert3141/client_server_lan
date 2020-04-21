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

  @override
  String name;
  @override
  String host;
  @override
  int port;
  @override
  bool verbose;

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

  ConnectedClientNode get serverDetails => _server;
  
  Future<void> _initClientNode(String host, {@required bool start}) async {
    await _initNode(host, false, start: start);
    await _listenForDiscovery();
    if (verbose) {
      _.ok("Node is ready");
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
      final payload = <String, String>{
        "host": "$host",
        "port": "$port",
        "name": "$name"
      };
      final String addr = "${data["host"]}:${data["port"]}";
      await sendData(payload, addr);
    });
  }  
}
