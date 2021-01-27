part of 'basenode.dart';

class ConnectedClientNode {
  ConnectedClientNode(
      {@required this.name, @required this.address, this.lastSeen});

  final String name;
  final String address;
  DateTime lastSeen;
}

/// The type of data that is sent and received. It includes all the neccessary information for that specific communication. The most useful data is the payload, then packet title and the name/host of the sender.
class DataPacket {
  DataPacket(
      {@required this.name,
      @required this.host,
      @required this.port,
      @required this.title,
      this.payload});

  DataPacket.fromJson(Map<String, Object> json)
      : this.host = json["host"],
        this.port = int.parse(json["port"]),
        this.name = json["name"],
        this.title = json["title"],
        this.payload = json["payload"];

  /// The IP adress of the sender
  final String host;

  /// The Port being used by the sender (and reciever)
  final int port;

  /// The name of the sender
  final String name;

  /// The title of the packet
  final String title;

  /// The actual data being ditributed
  final Object payload;

  /// Encodes the packet data into a json ready for transmitting
  String encodeToString() =>
      '{"host":"$host", "port": "$port", "name": "$name", "title": "$title", "payload": "$payload"}';

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
