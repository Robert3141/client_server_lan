part of 'basenode.dart';

/// The Node for if the device is to act as a server (i.e connect to all the clients). It can communicate with all the clients it's connected to.
class ServerNode extends _BaseServerNode {
  ServerNode(
      {@required this.name,
      this.port = 8084,
      this.verbose = false,
      this.onDispose,
      this.clientDispose}) {
    if (name == null || name == "") throw _e.nameNull;
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

  /// This function is called when this server has been disposed. The clients are also forced to dispose as there is no server.
  @override
  Function() onDispose;

  /// This function is called when a client has been disposed. They are removed from the connected clients list.
  @override
  Function(ConnectedClientNode c) clientDispose;

  /// Used to setup the Node ready for use
  Future<void> init() async {
    //change host
    if (Platform.isAndroid || Platform.isIOS) {
      this.host = await Wifi.ip;
    } else {
      try {
        this.host = await _getHost();
      } catch (e) {
        if (_debug) print("$e");
        throw _e.platformNotSupported;
      }
    }
    await _initServerNode(this.host, start: true);
  }
}

abstract class _BaseServerNode with _BaseNode {
  _BaseServerNode() {
    _isServer = true;
  }

  /// Returns a list of clients connected in the form of Connected Client Node (an object which contains info such as last seen, name and address)
  List<ConnectedClientNode> get clientsConnected => _clients;

  /// Used to scan for client Nodes
  Future<void> discoverNodes() async => _broadcastForDiscovery();

  Function(ConnectedClientNode c) clientDispose = (ConnectedClientNode c) {};

  Future<void> _initServerNode(String host, {@required bool start}) async {
    await _initNode(host, true, start: start);
    if (verbose) {
      _.ok(_e.nodeReady);
    }
    _readyCompleter.complete();
  }

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

  Future<void> _broadcastForDiscovery() async {
    assert(host != null);
    assert(_isServer);
    await _socketReady.future;
    final payload =
        DataPacket(host: host, port: port, name: name, title: _s.clientConnect)
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

  @override
  void dispose() async {
    //tell all the clients to dispose
    if (_clients != null && _isRunning)
      for (ConnectedClientNode c in _clients) {
        await _sendInfo(_s.clientDispose, c.address);
      }
    super.dispose();
  }

  @override
  void _handleDisconnect(DataPacket data) {
    //locals
    ConnectedClientNode client;
    //should occur
    //remove from client list
    for (int i = 0; i < _clients.length; i++) {
      if (_clients[i].host == data.host) {
        //remove
        client = _clients.removeAt(i);
        i = _clients.length;
      }
    }
    if (_debug) print("disconnected client $client");
    if (_debug) print("clients connected ${_clients.length}");

    //tell the programmer that it's been removed
    clientDispose(client);
  }
}
