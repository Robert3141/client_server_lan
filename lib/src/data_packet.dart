import 'dart:convert';

/// The type of data that is sent and received.
/// It includes all the neccessary information for that specific communication.
/// The most useful data is the payload, then packet title and the name/host of the sender.
class DataPacket {
  final String host;

  /// The Port being used by the sender (and reciever)
  final int port;

  /// The name of the sender
  final String name;

  /// The title of the packet
  final String title;

  dynamic payload;

  /// The destination IP of the packet
  final String to;
  DataPacket({
    this.host,
    this.port,
    this.name,
    this.title,
    this.payload,
    this.to,
  });

  DataPacket copyWith({
    String host,
    int port,
    String name,
    String title,
    dynamic payload,
    String to,
  }) {
    return DataPacket(
      host: host ?? this.host,
      port: port ?? this.port,
      name: name ?? this.name,
      title: title ?? this.title,
      payload: payload ?? this.payload,
      to: to ?? this.to,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'host': host,
      'port': port,
      'name': name,
      'title': title,
      'payload': payload,
      'to': to,
    };
  }

  factory DataPacket.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return DataPacket(
      host: map['host'],
      port: map['port'],
      name: map['name'],
      title: map['title'],
      payload: map['payload'],
      to: map['to'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DataPacket.fromJson(String source) =>
      DataPacket.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DataPacket(host: $host, port: $port, name: $name, title: $title, payload: $payload, to: $to)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is DataPacket &&
        o.host == host &&
        o.port == port &&
        o.name == name &&
        o.title == title &&
        o.payload == payload &&
        o.to == to;
  }

  @override
  int get hashCode {
    return host.hashCode ^
        port.hashCode ^
        name.hashCode ^
        title.hashCode ^
        payload.hashCode ^
        to.hashCode;
  }
}
