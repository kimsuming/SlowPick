import 'package:flutter/material.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/service/community_service.dart';

class CommunityWrite extends StatefulWidget {
  const CommunityWrite({super.key});

  @override
  State<CommunityWrite> createState() => _CommunityWriteState();
}

class _CommunityWriteState extends State<CommunityWrite> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('제목과 내용을 입력해주세요.')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await CommunityService.createPost(title, content);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('슬로우 커뮤니티',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -1.70)),
            Text('Slow Community',
                style: TextStyle(
                    color: Color(0xFF718F74),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.50)),
          ],
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(1, .5),
              end: Alignment(0, .5),
              colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
            ),
          ),
        ),
        toolbarHeight: 76,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 50),
              onPressed: () {}),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1, .5),
            end: Alignment(0, .5),
            colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              Container(height: 1.5, color: const Color(0xFFE2E2E2)),
              Expanded(
                child: SingleChildScrollView(
                  child: _communityTextField(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Container(
                decoration: const BoxDecoration(
                    color: Color(0xFF197100), shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
          GestureDetector(
            onTap: _submitting ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF73AD31)))
                  : const Text('등록',
                      style: TextStyle(
                          color: Color(0xFF73AD31),
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.24)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityTextField() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('제목',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.50)),
          const SizedBox(height: 5),
          SizedBox(
            height: 40,
            child: TextField(
              controller: _titleController,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(fontSize: 14, height: 1.2),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '제목을 입력해주세요',
                hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(width: 1.5, color: Color(0xFFC6C6C6))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF187100))),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('내용',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.50)),
          const SizedBox(height: 5),
          TextField(
            controller: _contentController,
            maxLines: 12,
            decoration: const InputDecoration(
              isDense: true,
              hintText: '내용을 입력해주세요',
              hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(width: 1.5, color: Color(0xFFC6C6C6))),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF187100))),
            ),
          ),
        ],
      ),
    );
  }
}
