import 'package:client_server_lan/client_server_lan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ServerPage extends StatelessWidget {
  final bool isRunning;
  final bool isLoading;
  final VoidCallback onDisposePressed;
  final VoidCallback onStartPressed;
  final VoidCallback onFindClientsPressed;
  final String status;
  final String dataReceived;
  final List<ConnectedClientNode> connectedClientNodes;
  final Function(String, String) onSendToClient;

  const ServerPage({
    Key key,
    this.isRunning = false,
    this.isLoading = false,
    @required this.onStartPressed,
    @required this.onDisposePressed,
    @required this.onFindClientsPressed,
    @required this.connectedClientNodes,
    @required this.onSendToClient,
    this.status = '',
    this.dataReceived = '-',
  })  : assert(onStartPressed != null),
        assert(onDisposePressed != null),
        assert(onFindClientsPressed != null),
        assert(connectedClientNodes != null),
        assert(onSendToClient != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [
              Row(
                children: [
                  isRunning
                      ? Container(
                          height: 47,
                          child: OutlinedButton(
                            onPressed: onDisposePressed,
                            child: Text('Disconnect Server'),
                          ),
                        )
                      : Container(
                          height: 47,
                          child: ElevatedButton(
                            onPressed: onStartPressed,
                            child: Text('Start Server'),
                          ),
                        ),
                  SizedBox(width: 20),
                  Expanded(child: Text(status)),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Container(
                height: 47,
                child: ElevatedButton(
                  onPressed: isRunning ? onFindClientsPressed : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.search_rounded),
                      Text('Scan Clients'),
                      Opacity(
                        opacity: 0,
                        child: Icon(Icons.search_rounded),
                      ),
                    ],
                  ),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (states) {
                        if (!states.contains(MaterialState.disabled)) {
                          return Colors.amber[900];
                        }
                        return null;
                      },
                    ),
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: connectedClientNodes.length,
                itemBuilder: (context, index) {
                  return _buildClientListItem(
                    context,
                    index,
                    onSendPressed: (clientName, message) =>
                        onSendToClient(clientName, message),
                  );
                },
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Text(
                  'Data Received: ${dataReceived.isEmpty ? '-' : dataReceived}'),
            ],
          ),
        ),
        if (isLoading) CircularProgressIndicator.adaptive(),
      ],
    );
  }

  Widget _buildClientListItem(
    BuildContext context,
    int index, {
    Function(String, String) onSendPressed,
  }) {
    return ListTile(
      title: Text(
        connectedClientNodes[index].name,
      ),
      subtitle: Text(
        DateFormat.yMd().add_jm().format(connectedClientNodes[index].lastSeen),
      ),
      trailing: IconButton(
        icon: Icon(Icons.send_outlined),
        onPressed: () {
          TextEditingController controller = TextEditingController();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Send to ${connectedClientNodes[index].name}'),
                actions: [
                  ElevatedButton(
                    child: Text('SEND'),
                    onPressed: () {
                      Navigator.pop(context);
                      onSendPressed(
                        connectedClientNodes[index].name,
                        controller.text,
                      );
                    },
                  ),
                ],
                content: TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: 'Text to send'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
