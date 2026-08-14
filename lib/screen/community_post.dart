import 'package:flutter/material.dart';
import 'package:slowpick/service/community_service.dart';

class CommunityPost extends StatefulWidget {
  const CommunityPost({super.key, required this.postId});
  final int postId;

  @override
  State<CommunityPost> createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  final TextEditingController _commentCtrl = TextEditingController();

  Map<String, dynamic>? _post;
  List<dynamic> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  // 답글 모드
  int? _replyToId;
  String? _replyToNick;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        CommunityService.fetchPost(widget.postId),
        CommunityService.fetchComments(widget.postId),
      ]);
      setState(() {
        _post = results[0] as Map<String, dynamic>;
        _comments = results[1] as List<dynamic>;
      });
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(String type) async {
    try {
      final voted = await CommunityService.votePost(widget.postId, type);
      setState(() {
        final p = _post!;
        final prev = p['my_vote'] as String?;
        if (prev == type) {
          p['my_vote'] = null;
          if (type == 'like') {
            p['like_count'] = (p['like_count'] as int) - 1;
          } else {
            p['dislike_count'] = (p['dislike_count'] as int) - 1;
          }
        } else {
          if (prev != null) {
            if (prev == 'like') {
              p['like_count'] = (p['like_count'] as int) - 1;
            } else {
              p['dislike_count'] = (p['dislike_count'] as int) - 1;
            }
          }
          p['my_vote'] = voted;
          if (type == 'like') {
            p['like_count'] = (p['like_count'] as int) + 1;
          } else {
            p['dislike_count'] = (p['dislike_count'] as int) + 1;
          }
        }
      });
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _bookmark() async {
    try {
      final bookmarked = await CommunityService.bookmarkPost(widget.postId);
      setState(() => _post!['is_bookmarked'] = bookmarked);
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _likeComment(Map<String, dynamic> comment) async {
    try {
      final liked = await CommunityService.likeComment(comment['id'] as int);
      setState(() {
        comment['my_like'] = liked;
        comment['like_count'] = (comment['like_count'] as int) + (liked ? 1 : -1);
      });
    } catch (e) {
      _snack('$e');
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await CommunityService.createComment(
        widget.postId,
        content: text,
        parentId: _replyToId,
      );
      _commentCtrl.clear();
      setState(() {
        _replyToId = null;
        _replyToNick = null;
        _post!['comment_count'] = (_post!['comment_count'] as int) + 1;
      });
      await _loadAll();
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
      // 댓글 입력창을 bottomNavigationBar로 사용 (키보드 위에 고정)
      bottomNavigationBar: _buildCommentInput(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(1, .5),
            end: Alignment(0, .5),
            colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
          ),
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF187100)))
              : _post == null
                  ? const Center(child: Text('게시글을 불러올 수 없습니다.'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topBar(),
                          Container(
                              height: 1.5,
                              color: const Color(0xFFE2E2E2)),
                          _postContent(),
                          const SizedBox(height: 40),
                          _voteButtons(),
                          const SizedBox(height: 8),
                          _commentHeader(),
                          ..._buildCommentList(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final post = _post!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, right: 4),
                  child: Icon(Icons.arrow_back_ios, color: Colors.black, size: 25),
                ),
              ),
              Expanded(
                child: Text(
                  post['title'] as String? ?? '',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              '${post['nickname'] ?? ''}  l  조회 ${post['view_count'] ?? 0}  l  추천 ${post['like_count'] ?? 0}  l  ${CommunityService.fmtDate(post['created_at'] as String?)}',
              style: const TextStyle(
                  color: Color(0xFF73AD31),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _post!['content'] as String? ?? '',
        style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'KoPubDotum Medium',
            fontWeight: FontWeight.w400,
            letterSpacing: -1,
            height: 1.6),
      ),
    );
  }

  Widget _voteButtons() {
    final post = _post!;
    final myVote = post['my_vote'] as String?;
    final isBookmarked = post['is_bookmarked'] as bool? ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
          color: const Color(0xFF74AE31),
          label: '북마크',
          onTap: _bookmark,
        ),
        const SizedBox(width: 4),
        _actionButton(
          icon: Icons.thumb_up_outlined,
          color: myVote == 'like'
              ? const Color(0xFFEECC55)
              : const Color(0xFFCCCCCC),
          label: '추천 ${post['like_count'] ?? 0}',
          onTap: () => _vote('like'),
        ),
        const SizedBox(width: 4),
        _actionButton(
          icon: Icons.thumb_down_outlined,
          color: myVote == 'dislike'
              ? const Color(0xFF906BDA)
              : const Color(0xFFCCCCCC),
          label: '싫어요 ${post['dislike_count'] ?? 0}',
          onTap: () => _vote('dislike'),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFBBBBBB)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF3F3F3F),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1)),
          ],
        ),
      ),
    );
  }

  Widget _commentHeader() {
    final count = _post!['comment_count'] as int? ?? 0;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(width: 1.5, color: const Color(0xFFE2E2E2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Text('댓글',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(
                  color: Color(0xFFAD5C31),
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  List<Widget> _buildCommentList() {
    final widgets = <Widget>[];
    for (final c in _comments) {
      final comment = c as Map<String, dynamic>;
      widgets.add(_commentItem(comment, isReply: false));
      for (final r in (comment['replies'] as List? ?? [])) {
        widgets.add(_commentItem(r as Map<String, dynamic>, isReply: true));
      }
    }
    return widgets;
  }

  Widget _commentItem(Map<String, dynamic> c, {required bool isReply}) {
    final myLike = c['my_like'] as bool? ?? false;
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Color(0xFFD7D7D7), width: 1.3)),
      ),
      padding: EdgeInsets.only(left: isReply ? 24 : 0, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isReply)
            const Padding(
              padding: EdgeInsets.only(right: 4, top: 2),
              child: Icon(Icons.subdirectory_arrow_right,
                  color: Color(0xFFBBBBBB), size: 18),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    c['content'] as String? ?? '',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    '${c['nickname'] ?? ''}  l  ${CommunityService.fmtDate(c['created_at'] as String?)}',
                    style: const TextStyle(
                        color: Color(0xFFA7A7A7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(5)),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  if (!isReply)
                    GestureDetector(
                      onTap: () => setState(() {
                        _replyToId = c['id'] as int;
                        _replyToNick = c['nickname'] as String?;
                      }),
                      child: const Icon(Icons.subdirectory_arrow_right,
                          color: Color(0xFFBBBBBB), size: 20),
                    ),
                  if (!isReply) const SizedBox(width: 6),
                  if (!isReply)
                    Container(
                        width: 1, height: 16, color: const Color(0xFFCCCCCC)),
                  if (!isReply) const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _likeComment(c),
                    child: Icon(
                      myLike ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: myLike
                          ? const Color(0xFF73AD31)
                          : const Color(0xFFBBBBBB),
                      size: 20,
                    ),
                  ),
                  if ((c['like_count'] as int? ?? 0) > 0) ...[
                    const SizedBox(width: 2),
                    Text('${c['like_count']}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF73AD31))),
                  ],
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E2E2))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyToNick != null)
              Container(
                color: const Color(0xFFF5F5F5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Text('답글: @$_replyToNick',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF666666))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setState(() {
                            _replyToId = null;
                            _replyToNick = null;
                          }),
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: InputDecoration(
                        hintText: _replyToNick != null ? '답글을 입력해주세요' : '댓글을 입력해주세요',
                        hintStyle:
                            const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFFD7D7D7))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: Color(0xFF187100))),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _submitting ? null : _submitComment,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Color(0xFF187100), shape: BoxShape.circle),
                      padding: const EdgeInsets.all(10),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
