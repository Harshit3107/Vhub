import 'package:flutter/material.dart';
import 'package:vhub/data/constants.dart';
import 'package:vhub/models/appBarWidget.dart';
import '../widgets/messageField.dart';
import 'dart:typed_data';
import '../models/message.dart';
import '../data/messageList.dart';

const routeName = '/P2PChatScreen';

class P2PServerScreen extends StatelessWidget {
  late final clientSocket;

  Future<String> getData() {
    return Future.delayed(Duration(seconds: 2), () {
      return 'Successful';
    });
  }

  @override
  Widget build(BuildContext context) {
    print('running chat screen');
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    String username = args['username'];
    clientSocket = args['socket'];
    print(clientSocket.socket);
    print(username);
    return Scaffold(
      appBar: AppBarWidget(
        title: 'P2P server',
      ),
      body: FutureBuilder(
        future: getData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
          } else if (snapshot.hasError) {
          } else {
            return Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: const <Widget>[
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    child: CircularProgressIndicator(),
                    width: 60,
                    height: 60,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text('Initialising server',
                        style: TextStyle(
                          fontSize: 20,
                        )),
                  )
                ],
              ),
            );
          }
          return MyHomePage(clientSocket: clientSocket, username: username);
        },
      ),
    );
  }
}

// MyHomePage(
//         clientSocket: clientSocket,
//         username: username,
//       )

class MyHomePage extends StatefulWidget {
  final clientSocket;
  final username;
  List<Message> userMessageList = [];
  MyHomePage({required this.clientSocket, required this.username});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void startListening() {
    try {
      widget.clientSocket.socket.listen(
        // handle data from the server
        (Uint8List data) {
          final serverResponse = String.fromCharCodes(data);
          Map<String, dynamic> m =
              widget.clientSocket.convertStringToMap(serverResponse);
          setState(() {
            widget.userMessageList.add(Message(
                username: m['username'], message: m['text'], isLeft: true));
          });
          print('${m['username']}: ${m['text']}');
        },

        // handle errors
        onError: (error) {
          print(error);
          try {
            widget.clientSocket.socket.close();
          } catch (e) {
            print('running error');
          }
        },

        // handle server ending connection
        onDone: () {
          print('Server left.');
          //widget.clientSocket.socket.close();
        },
      );
    } catch (e) {
      print("showing error in funtion");
      throw 'error';
    }
  }

  bool flag = true;
  @override
  void initState() {
    print('running initstate again');
    try {
      startListening();
    } catch (e) {
      print(e);
    }
    widget.clientSocket.sendMessage('serverStart');
    // TODO: implement initState
    super.initState();
  }

  final TextEditingController _controller = new TextEditingController();

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      widget.clientSocket.sendMessage(_controller.text);
    }
  }

  late String textFieldText;
  @override
  void dispose() {
    widget.userMessageList.clear();
    print('dispose called');
    _controller.dispose();
    // widget.clientSocket.socket.close();
    super.dispose();
  }

  void onSubmittedFunction() {
    _sendMessage();
    widget.userMessageList.add(Message(
        username: widget.username, message: textFieldText, isLeft: false));
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.userMessageList.length,
              itemBuilder: (context, index) {
                return MessageField(
                  username: widget.userMessageList[index].username,
                  message: widget.userMessageList[index].message,
                  isLeft: widget.userMessageList[index].isLeft,
                );
              },
            ),
          ),
          Container(
            child: Row(
              children: [
                Flexible(
                  child: TextField(
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        labelText: 'Message: '),
                    controller: _controller,
                    onSubmitted: (text) {
                      textFieldText = text;
                      onSubmittedFunction();
                    },
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () {
                    onSubmittedFunction();
                  },
                  child: Container(
                    height: 60,
                    width: 60,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color1),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 35,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
