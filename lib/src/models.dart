part of 'basenode.dart';

Uuid uuid = Uuid();

enum CommandStatus {
  pending,
  authorizedToRun,
  unauthorizedToRun,
  success,
  executionError
}

class ConnectedClientNode {
  ConnectedClientNode(
      {@required this.name, @required this.address, this.lastSeen});

  final String name;
  final String address;
  DateTime lastSeen;
}

Future<HttpResponse> _sendHandler(HttpRequest request, IsoLogger log) async {
  print("Begin sendHandler");
  final content = await utf8.decoder.bind(request).join();
  final dynamic c = json.decode(content);
  print("send handler running");
  log.push(c);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}

Future<HttpResponse> _responseHandler(HttpRequest request, IsoLogger log) async {
  print("BEGIN responseHandler");
  final content = await utf8.decoder.bind(request).join();
  print("content received");
  dynamic c = content;
  try {
    c = json.decode(c);
  } catch (e) {
    print("not a json");
  }
  print("response handler running");
  //_.input(c, "response cmd");
  log.push(c);
  request.response.statusCode = HttpStatus.ok;
  return request.response;
}
