// SlowPick 챗봇 채팅 화면 예시 코드입니다.
//
// 이 화면은 사용자가 메시지를 입력하면 백엔드의 /chat 출입구로
// 요청을 보내고, 받은 답변을 채팅 목록에 표시합니다.
//
// 실제 프로젝트에서는 baseUrl 부분을 SlowPick 서버 주소로 바꾸고,
// 로그인된 사용자의 아이디(userId)를 실제 값으로 전달해야 합니다.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 채팅 메시지 하나를 표현하는 클래스입니다.
class ChatMessage {
  final String text;
  final bool isUser; // true면 사용자가 보낸 메시지, false면 챗봇의 답변

  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  // 로그인된 사용자의 아이디입니다. 실제 사용 시 상위 화면에서 전달받으세요.
  final int userId;

  // 사용자가 특정 음료를 보다가 채팅으로 진입한 경우, 해당 음료의 아이디입니다.
  // 일반적인 채팅 진입이라면 null을 전달하면 됩니다.
  final int? menuId;

  const ChatScreen({super.key, required this.userId, this.menuId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 실제 서버 주소로 변경해야 합니다.
  final String baseUrl = "http://3.34.7.133:8000";

  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 화면에 처음 들어왔을 때 보여줄 안내 메시지입니다.
    _messages.add(
      ChatMessage(text: "안녕하세요! 음료나 혈당 관리에 대해 궁금한 점을 물어보세요.", isUser: false),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "message": text,
          "menu_id": widget.menuId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _messages.add(ChatMessage(text: data["reply"], isUser: false));
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "답변을 받아오는 중에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.",
              isUser: false,
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: "서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.", isUser: false),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('슬로우픽 챗봇'),
        centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: -1.30,
        ),
      ),
      body: Column(
        children: [
          // 채팅 메시지 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? Color(0XFFB5F369)
                          : Color(0XFFF8E76C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(message.text),
                  ),
                );
              },
            ),
          ),

          // 답변을 기다리는 동안 보여주는 표시
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("답변을 작성하고 있습니다..."),
            ),

          // 입력창과 보내기 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요",
                      hintStyle: TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 14,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Color(0xFFD7D7D7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Color(0xFF187100)),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                // IconButton(
                //   icon: Icon(Icons.send, color: Color(0xFF187100)),
                //   onPressed: _isLoading ? null : _sendMessage,
                // ),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF187100),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
