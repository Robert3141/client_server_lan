part of 'basenode.dart';

Future<String> _getHost() async {
  final interfaces = await NetworkInterface.list(
      includeLoopback: false, type: InternetAddressType.any);
  final host = interfaces.first.addresses.first.address;
  return host;
}
