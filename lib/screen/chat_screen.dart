import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:slowpick/service/auth_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  // 사용자가 특정 음료를 보다가 채팅으로 진입한 경우, 해당 음료의 아이디입니다.
  // 일반적인 채팅 진입이라면 null을 전달하면 됩니다.
  final int? menuId;

  const ChatScreen({super.key, this.menuId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String baseUrl = "http://3.34.7.133:8000";

  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Cognito에서 가져온 사용자 고유 아이디입니다.
  String? _userId;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: "안녕하세요! 음료나 혈당 관리에 대해 궁금한 점을 물어보세요. \n\n*정확한 메뉴명을 입력해주셔야 합니다.",
        isUser: false,
      ),
    );

    // 화면이 시작될 때 로그인된 사용자의 아이디를 가져옵니다.
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await AuthService.instance.fetchUserId();
    setState(() {
      _userId = userId;
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 아직 사용자 아이디를 가져오지 못한 경우 잠깐 기다립니다.
    if (_userId == null) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "로그인 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.",
            isUser: false,
          ),
        );
      });
      return;
    }

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
          "user_id": _userId,
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
                          ? const Color(0XFFB5F369)
                          : const Color(0XFFF8E76C),
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

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text("답변을 작성하고 있습니다..."),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "메시지를 입력하세요",
                      hintStyle: const TextStyle(
                        color: Color(0xFFB0B0B0),
                        fontSize: 14,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFFD7D7D7)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF187100)),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
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
