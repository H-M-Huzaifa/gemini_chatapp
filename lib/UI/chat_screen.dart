import 'dart:io';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final Gemini gemini =Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "user");
  ChatUser geminiUser = ChatUser(
      id: "1",
      firstName: "Gemini",
      profileImage:
          "https://static.vecteezy.com/system/resources/previews/046/861/646/non_2x/gemini-icon-on-a-transparent-background-free-png.png");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Gemini Chatbot"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(onPressed: (){
          _sendMediaMessage();

        }, icon: Icon(Icons.image))
      ]),
        currentUser: currentUser, onSend: _sendMessage, messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String prompt = chatMessage.text;
      List<Uint8List>? images;
      if(chatMessage.medias?.isNotEmpty ?? false){
        images=[
          //if this makes issue, import this library "import 'dart:typed_data';"
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }
      gemini.streamGenerateContent(prompt,images: images).listen((event){
        ChatMessage? lastMessage=messages.firstOrNull;

        if(lastMessage !=null && lastMessage.user==geminiUser){


          lastMessage=messages.removeAt(0);
          String response =event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}",) ?? "";
          ChatMessage message=ChatMessage(user: geminiUser, createdAt: DateTime.now(),text: response);
          lastMessage.text += response;
          setState(() {
            messages=[lastMessage!,...messages];
          });


        }else{


          String response =event.content?.parts?.fold("", (previous, current) => "$previous ${current.text}",) ?? "";
          ChatMessage message=ChatMessage(user: geminiUser, createdAt: DateTime.now(),text: response);
          setState(() {
            messages=[message,...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _sendMediaMessage ()async{
    ImagePicker picker =ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);


    if(file!=null){
      ChatMessage chatMessage = ChatMessage(user: currentUser, createdAt: DateTime.now(),text: "Describe this picture",medias: [
        ChatMedia(url: file.path, fileName: "", type: MediaType.image),
      ]);
      _sendMessage(chatMessage);

    }
  }
}
