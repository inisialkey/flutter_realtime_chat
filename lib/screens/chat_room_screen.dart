import 'package:flutter/material.dart';
import 'package:models/models.dart';

import '../main.dart';
import '../widgets/avatar.dart';
import '../widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.chatRoom});

  final ChatRoom chatRoom;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final messageController = TextEditingController();
  final List<Message> messages = [];

  @override
  void initState() {
    _loadMessages();
    _startWebSocket();

    messageRepository.subscribeToMessageUpdates((messageData) {
      print('jalan');
      final message = Message.fromJson(messageData);
      if (message.chatRoomId == widget.chatRoom.id) {
        messages.add(message);
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = Message(
      chatRoomId: widget.chatRoom.id,
      senderUserId: userId1,
      receiverUserId: userId2,
      content: messageController.text,
      createdAt: DateTime.now(),
    );

    await messageRepository.createMessage(message);
    messageController.clear();
  }

  _loadMessages() async {
    final messages = await messageRepository.fetchMessages(widget.chatRoom.id);

    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    setState(() {
      this.messages.addAll(messages);
      print(messages);
    });
  }

  _startWebSocket() {
    webSocketClient.connect(
      'ws://192.168.244.221:8080/ws',
      {
        'Authorization': 'Bearer ....',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final currentParticipant = widget.chatRoom.participants.firstWhere(
      (user) => user.id == userId1,
    );

    final otherParticipant = widget.chatRoom.participants.firstWhere(
      (user) => user.id != currentParticipant.id,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Avatar(
              imageUrl: otherParticipant.avatarUrl,
              radius: 18,
            ),
            // const SizedBox(height: 2.0),
            Text(
              otherParticipant.username,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 8.0,
            bottom: (viewInsets.bottom > 0) ? 8.0 : 0.0,
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];

                    final showImage = index + 1 == messages.length ||
                        messages[index + 1].senderUserId !=
                            message.senderUserId;

                    return Row(
                      mainAxisAlignment: (message.senderUserId != userId1)
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (showImage && message.senderUserId == userId1)
                          Avatar(
                            imageUrl: otherParticipant.avatarUrl,
                            radius: 12,
                          ),
                        MessageBubble(message: message),
                        if (showImage && message.senderUserId != userId1)
                          Avatar(
                            imageUrl: otherParticipant.avatarUrl,
                            radius: 12,
                          ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // TODO: Send an image
                    },
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: messageController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(100),
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            _sendMessage();
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
