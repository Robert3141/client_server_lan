part of 'basenode.dart';

class ServerNode extends BaseServerNode {
  ServerNode(
      {@required this.name, this.host, this.port = 8084, this.verbose = false})
      : assert(name != null) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (host == null) {
        throw ArgumentError("Please provide a host for the node");
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

  /// Used to scan for client Nodes
  Future<void> discoverNodes() async => _broadcastForDiscovery();
  Future<void> _initServerNode(String host, {@required bool start}) async =>
      await _initNode(host, true, start: start);

  /// retrurns whether the client of name has been discovered
  bool hasClient(String name) {
    for (final client in _clients) {
      if (client.name == name) {
        return true;
      }
    }
    return false;
  }

  /// Gets the IP address of a discovered client from their name
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
