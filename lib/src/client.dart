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

  ConnectedClientNode get serverDetails => _server;
  Future<void> _initClientNode(String host, {@required bool start}) async =>
      await _initNode(host, false, start: start);
}
