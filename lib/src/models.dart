part of 'basenode.dart';

/// The data stored about the specific that is connected. This includes the name, IP address and time last seen. Most useful for indexing the client names rather than displaying than getting the user to enter raw IP adresses.
class ConnectedClientNode {
  ConnectedClientNode(
      {@required String name, @required String address, DateTime lastSeen})
      : name = name,
        address = address,
        lastSeen = lastSeen ?? DateTime.now();

  /// The user assigned name of the connected client
  final String name;

  /// The IP address of the connected client (includes the port)
  final String address;

  /// The Host of the connected client (excludes the port)
  String get host => address.split(':')[0];

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
      dynamic payload,
      this.to}) {
    _payload = payload;
  }

  DataPacket.fromJson(Map<String, Object> json)
      : host = json['host'],
        port = int.parse(json['port']),
        name = json['name'],
        title = json['title'],
        _payload = json['payload'],
        to = json['to'];

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
  dynamic get payload => _payload;

  /// Encodes the packet data into a json ready for transmitting
  String encodeToString() {
    try {
      // if its a json then doesn't need string around it
      json.decode(payload) as Map<String, dynamic>;
      return '{"host":"$host", "port": "$port", "name": "$name", "title": "$title", "payload": $payload, "to": "$to"}';
    } catch (e) {
      return '{"host":"$host", "port": "$port", "name": "$name", "title": "$title", "payload": "$payload", "to": "$to"}';
    }
  }

  @override
  String toString() => encodeToString();
}

Future<HttpResponse> _responseHandler(
    HttpRequest request, IsoLogger log) async {
  final content = await utf8.decoder.bind(request).join();
  Map<String, dynamic> jsonFormat;
  try {
    jsonFormat = json.decode(content);
  } catch (e) {
    debugPrint('Json not decoded: $e');
  }
  log.push(jsonFormat);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}
