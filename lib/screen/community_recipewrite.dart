import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/service/community_service.dart';

class CommunityRecipewrite extends StatefulWidget {
  const CommunityRecipewrite({super.key});

  @override
  State<CommunityRecipewrite> createState() => _CommunityRecipewriteState();
}

class _CommunityRecipewriteState extends State<CommunityRecipewrite> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  Uint8List? _imageBytes;
  String _imageContentType = 'image/jpeg';
  final List<String> _tags = [];
  bool _submitting = false;
  bool _pickingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    _pickingImage = true;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      setState(() {
        _imageBytes = bytes;
        _imageContentType = contentType;
      });
    } finally {
      _pickingImage = false;
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;
    if (_tags.length >= 10) {
      _snack('태그는 최대 10개까지 추가할 수 있습니다.');
      return;
    }
    if (_tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) {
      _snack('제목과 내용을 입력해주세요.');
      return;
    }
    setState(() => _submitting = true);
    try {
      String? thumbnailUrl;
      if (_imageBytes != null) {
        try {
          thumbnailUrl = await CommunityService.uploadImage(
              _imageBytes!, _imageContentType);
        } catch (uploadErr) {
          final cont = await _confirmSkipImage('$uploadErr');
          if (!cont) {
            setState(() => _submitting = false);
            return;
          }
        }
      }
      await CommunityService.createRecipe(
        title: title,
        content: content,
        thumbnailUrl: thumbnailUrl,
        tags: _tags.isEmpty ? null : _tags,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _confirmSkipImage(String errorDetail) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('이미지 업로드 실패'),
            content: Text(
              '이미지를 업로드하지 못했습니다.\n이미지 없이 등록할까요?\n\n($errorDetail)',
              style: const TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('이미지 없이 등록'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
              Container(height: 1.5, color: const Color(0xFFD7D7D7)),
              Expanded(
                child: SingleChildScrollView(
                  child: _form(),
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

  Widget _form() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대표 이미지
          const Text('대표 이미지',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.50)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD7D7D7)),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.add_box,
                      color: Color(0xFFBBBBBB), size: 48),
            ),
          ),

          const SizedBox(height: 20),

          // 제목
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

          // 태그
          const Text('태그',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.50)),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _tagController,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(fontSize: 14, height: 1.2),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: '태그 입력 후 추가',
                      hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 1.5, color: Color(0xFFC6C6C6))),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF187100))),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addTag,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF187100),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('추가',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _tags
                  .map((tag) => Chip(
                        label: Text('#$tag',
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF187100))),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () =>
                            setState(() => _tags.remove(tag)),
                        backgroundColor: const Color(0xFFE8F5E9),
                        side: const BorderSide(
                            color: Color(0xFF187100), width: 0.5),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),

          // 내용
          const Text('내용',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.50)),
          const SizedBox(height: 5),
          TextField(
            controller: _contentController,
            maxLines: 10,
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
