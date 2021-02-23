part of 'basenode.dart';

/// The Node for if the device is to act as a client (i.e wait for server to connect to it).
/// It can only communicate with the server.
/// Additional work needs to be added in order to facilitate data forwarding.
class ClientNode extends _BaseClientNode {
  ClientNode({
    @required this.name,
    this.port = 8084,
    this.verbose = false,
    this.onDispose,
    this.onServerAlreadyExist,
    this.onError,
  }) {
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

  /// This function is called when the node has been force disposed (usually as a result of dispose being called on the server)
  @override
  Function() onDispose;

  /// This function is called when client check the existing server and server is already exist.
  @override
  Function(DataPacket) onServerAlreadyExist;

  /// This function is called when error is occured.
  @override
  Function(String) onError;

  /// Used to setup the Node ready for use
  Future<void> init() async {
    //change host
    if (Platform.isAndroid || Platform.isIOS) {
      this.host = await GetIp.ipAddress;
    } else {
      try {
        this.host = await _getHost();
      } catch (e) {
        if (_debug) print("$e");
        throw _e.platformNotSupported;
      }
    }
    await _initClientNode(this.host, start: true);
  }
}

abstract class _BaseClientNode with _BaseNode {
  _BaseClientNode() {
    _isServer = false;
  }

  ConnectedClientNode _server;

  /// Provides information about the server if one is connected
  ConnectedClientNode get serverDetails => _server;

  Future<void> discoverServerNode() async => _broadcastCheckServerExistance();

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
      final DataPacket data = DataPacket.fromJson(json.decode(message));

      // Listen only from other adresses.
      if (data.host != host) {
        _server = ConnectedClientNode(
          address: "${data.host}:${data.port}",
          name: data.name,
          lastSeen: DateTime.now(),
        );
        if (verbose) {
          print("Received connection request from Client $data");
        }
        final String addr = "${data.host}:${data.port}";

        if (data.title == _s.imAlreadyServer) {
          onServerAlreadyExist(data);
        } else {
          await _sendInfo(_s.clientConnect, addr);
        }
      }
    });
  }

  Future<void> _broadcastCheckServerExistance() async {
    assert(host != null);
    await _socketReady.future;
    final payload = DataPacket(
            host: host, port: port, name: name, title: _s.checkServerExist)
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

  Future<List<ConnectedClientNode>> getConnectedClients() async {
    _sendInfo(_s.getClientNames, serverDetails.address);
    return await _connectedClients.stream.first;
  }

  @override
  Future<void> sendData(Object data, [String title = "no name", String to]) {
    if (this.serverDetails == null) {
      onError(_e.serverError);
      return null;
    }
    return super.sendData(data, title, to ?? this.serverDetails.address);
  }

  @override
  void dispose() async {
    // tell server client has been disposed
    if (isRunning && _server != null)
      await _sendInfo(_s.clientDisconnect, _server.address);
    super.dispose();
  }
}
