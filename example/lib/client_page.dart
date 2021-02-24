import 'package:flutter/material.dart';

class ClientPage extends StatelessWidget {
  final bool isRunning;
  final bool isLoading;
  final VoidCallback onDisposePressed;
  final VoidCallback onStartPressed;
  final String status;
  final Function(String) onSendToServer;
  final VoidCallback onCheckServerPressed;
  final String dataReceived;

  const ClientPage({
    Key key,
    this.isRunning,
    this.isLoading,
    @required this.onStartPressed,
    @required this.onDisposePressed,
    @required this.onSendToServer,
    @required this.onCheckServerPressed,
    this.status,
    this.dataReceived,
  })  : assert(onStartPressed != null),
        assert(onDisposePressed != null),
        assert(onSendToServer != null),
        assert(onCheckServerPressed != null),
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
                            child: Text('Disconnect Client'),
                          ),
                        )
                      : Container(
                          height: 47,
                          child: ElevatedButton(
                            onPressed: onStartPressed,
                            child: Text('Start Client'),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Check is Server Exist'),
                      Icon(Icons.cloud_rounded),
                    ],
                  ),
                  onPressed: isRunning ? onCheckServerPressed : null,
                ),
              ),
              SizedBox(height: 12),
              Divider(),
              SizedBox(height: 12),
              Container(
                height: 47,
                child: ElevatedButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Send to Server'),
                      Icon(Icons.send_outlined),
                    ],
                  ),
                  onPressed: isRunning
                      ? () {
                          var controller = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Send to Server'),
                                actions: [
                                  ElevatedButton(
                                    child: Text('SEND'),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onSendToServer(controller.text);
                                    },
                                  ),
                                ],
                                content: TextField(
                                  controller: controller,
                                  decoration:
                                      InputDecoration(hintText: 'Text to send'),
                                ),
                              );
                            },
                          );
                        }
                      : null,
                ),
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
}
