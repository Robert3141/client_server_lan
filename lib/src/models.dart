part of 'basenode.dart';

/// The data stored about the specific that is connected. This includes the name, IP address and time last seen. Most useful for indexing the client names rather than displaying than getting the user to enter raw IP adresses.
class ConnectedClientNode {
  ConnectedClientNode(
      {@required String name, @required String address, DateTime lastSeen})
      : this.name = name,
        this.address = address,
        this.lastSeen = lastSeen ?? DateTime.now();

  /// The user assigned name of the connected client
  final String name;

  /// The IP address of the connected client (includes the port)
  final String address;

  /// The Host of the connected client (excludes the port)
  String get host => this.address.split(":")[0];

  /// The time the connected client was last seen
  DateTime lastSeen;
}

/// The type of data that is sent and received. It includes all the neccessary information for that specific communication. The most useful data is the payload, then packet title and the name/host of the sender.
class DataPacket {
  DataPacket(
      {@required this.name,
      @required this.host,
      @required this.port,
      @required this.title,
      Object payload,
      this.to}) {
    this._payload = payload;
  }

  DataPacket.fromJson(Map<String, Object> json)
      : this.host = json["host"],
        this.port = int.parse(json["port"]),
        this.name = json["name"],
        this.title = json["title"],
        this._payload = json["payload"],
        this.to = json["to"];

  /// The IP adress of the sender
  final String host;

  /// The Port being used by the sender (and reciever)
  final int port;

  /// The name of the sender
  final String name;

  /// The title of the packet
  final String title;

  Object _payload;

  /// The destination IP of the packet
  final String to;

  /// The actual data being ditributed
  String get payload => _payload.toString();

  /// Encodes the packet data into a json ready for transmitting
  String encodeToString() =>
      '{"host":"$host", "port": "$port", "name": "$name", "title": "$title", "payload": "$payload", "to": "$to"}';

  @override
  String toString() => encodeToString();
}

Future<HttpResponse> _responseHandler(
    HttpRequest request, IsoLogger log) async {
  final content = await utf8.decoder.bind(request).join();
  Object c = content;
  try {
    c = json.decode(c);
  } catch (e) {
    print("Json not decoded: $e");
  }
  log.push(c);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}
