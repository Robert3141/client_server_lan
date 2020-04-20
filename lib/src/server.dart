part of 'basenode.dart';

class ServerNode extends BaseServerNode {
  ServerNode(
      {@required this.name,
      this.host,
      this.port = 8084,
      this.verbose = false})
      : assert(name != null) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (host == null) {
        throw ArgumentError("Please provide a host for the node");
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
    var _h = ip;
    _h ??= host;
    _h ??= await getHost();
    await _initServerNode(_h, start: start);
  }
}

abstract class BaseServerNode with BaseNode {
  BaseServerNode() {
    _isServer = true;
  }

  List<ConnectedClientNode> get clientsConnected => _clients;
  
  Future<void> discoverNodes() async => _broadcastForDiscovery();
  Future<void> _initServerNode(String host, {@required bool start}) async => await _initNode(host, true, start: start);

  bool hasClient(String name) {
    for (final client in _clients) {
      if (client.name == name) {
        return true;
      }
    }
    return false;
  }

  String clientUri(String name) {
    String addr;
    for (final client in _clients) {
      if (client.name == name) {
        addr = client.address;
        break;
      }
    }
    return addr;
  }

  
}