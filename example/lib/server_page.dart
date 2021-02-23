import 'package:client_server_lan/client_server_lan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'city.dart';

class ServerPage extends StatefulWidget {
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
  _ServerPageState createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  City city;

  @override
  void initState() {
    super.initState();

    city = City(
      name: 'Turin',
      province: 'Piedmont',
      country: 'Italy',
    );
  }

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
                  widget.isRunning
                      ? Container(
                          height: 47,
                          child: OutlinedButton(
                            onPressed: widget.onDisposePressed,
                            child: Text('Disconnect Server'),
                          ),
                        )
                      : Container(
                          height: 47,
                          child: ElevatedButton(
                            onPressed: widget.onStartPressed,
                            child: Text('Start Server'),
                          ),
                        ),
                  SizedBox(width: 20),
                  Expanded(child: Text(widget.status)),
                ],
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Container(
                height: 47,
                child: ElevatedButton(
                  onPressed:
                      widget.isRunning ? widget.onFindClientsPressed : null,
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
                itemCount: widget.connectedClientNodes.length,
                itemBuilder: (context, index) {
                  return _buildClientListItem(
                    context,
                    index,
                    onSendPressed: (clientName, message) =>
                        widget.onSendToClient(clientName, message),
                  );
                },
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Text(
                  'Data Received: ${widget.dataReceived.isEmpty ? '-' : widget.dataReceived}'),
            ],
          ),
        ),
        if (widget.isLoading) CircularProgressIndicator.adaptive(),
      ],
    );
  }

  Widget _buildClientListItem(
    BuildContext context,
    int index, {
    Function(String, String) onSendPressed,
  }) {
    var lastSeen = DateFormat.yMd()
        .add_jm()
        .format(widget.connectedClientNodes[index].lastSeen);
    return ListTile(
      title: Text(
        widget.connectedClientNodes[index].name,
      ),
      subtitle: Text('Last seen: $lastSeen'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            icon: Icon(Icons.send_outlined),
            label: Text('JSON'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                        'Send to ${widget.connectedClientNodes[index].name}'),
                    actions: [
                      ElevatedButton(
                        child: Text('SEND'),
                        onPressed: () {
                          Navigator.pop(context);
                          onSendPressed(
                            widget.connectedClientNodes[index].name,
                            city.toJson(),
                          );
                        },
                      ),
                    ],
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Sample JSON to send:'),
                        SizedBox(height: 12),
                        Text('${city.toJson()}'),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          TextButton.icon(
            icon: Icon(Icons.send_outlined),
            label: Text('Text'),
            onPressed: () {
              var controller = TextEditingController();
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(
                        'Send to ${widget.connectedClientNodes[index].name}'),
                    actions: [
                      ElevatedButton(
                        child: Text('SEND'),
                        onPressed: () {
                          Navigator.pop(context);
                          onSendPressed(
                            widget.connectedClientNodes[index].name,
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
        ],
      ),
    );
  }
}
