import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  // 메인에서 전달받을 초기 검색어 (없을 수도 있으므로 nullable)
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isGridView = true;
  late TextEditingController _searchController; // late로 변경
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    // 전달받은 초기 검색어가 있으면 설정, 없으면 빈 문자열
    String initialText = widget.initialQuery ?? "";
    _searchController = TextEditingController(text: initialText);
    _searchText = initialText;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double gridAspectRatio = (screenWidth / 2) / (screenHeight * 0.38);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('메뉴 검색'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
        ),
        // 뒤로가기 버튼 색상 (메인에서 넘어왔으므로 필요)
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: '메뉴 이름을 검색해보세요',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchText = "";
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('menus').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.greenAccent),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('저장된 메뉴가 없습니다.'));
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['menu_name'] as String? ?? '';
                  if (_searchText.isEmpty) return true;
                  return name.toLowerCase().contains(_searchText.toLowerCase());
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text('\'$_searchText\' 검색 결과가 없습니다.'),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.04, 0, screenWidth * 0.04, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: gridAspectRatio,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenWidth * 0.04,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      return _buildGridCard(context, data);
                    },
                  );
                } else {
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.04, 0, screenWidth * 0.04, 16),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: screenHeight * 0.02),
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
                      return _buildListCard(context, data);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, Map<String, dynamic> data) {
    // (기존 코드와 동일하므로 생략하지 않고 전체 코드 유지를 위해 포함)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final String name = data['menu_name'] ?? '이름 없음';
    final String imageUrl = data['menu_image_url'] ?? '';
    final int kcal = data['nutrition']?['calories_kcal'] ?? 0;
    final num sugar = data['nutrition']?['sugar_g'] ?? 0;
    final String allergy = "정보 없음";

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey,
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.2,
                color: const Color(0xFFF1F1F1),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.coffee, size: 50, color: Colors.grey),
              ),
              Positioned(right: 8, top: 8, child: _buildHeartIcon()),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'KoPubDotum')),
                      SizedBox(height: screenHeight * 0.005),
                      Text('[ ${kcal}Kcal ]  8,700~',
                          style: TextStyle(
                              color: Colors.black54,
                              fontSize: screenWidth * 0.032,
                              fontFamily: 'KoPubDotum')),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNutritionBadge(screenWidth, '당 ${sugar}g',
                          const Color(0xFFFFE0E1), const Color(0xFFEF4444)),
                      SizedBox(height: screenHeight * 0.005),
                      Text('알레르기: $allergy',
                          style: TextStyle(
                              color: const Color(0xFF7B7B7B),
                              fontSize: screenWidth * 0.028,
                              fontFamily: 'KoPubDotum'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context, Map<String, dynamic> data) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = 110.0;
    final String name = data['menu_name'] ?? '이름 없음';
    final String imageUrl = data['menu_image_url'] ?? '';
    final int kcal = data['nutrition']?['calories_kcal'] ?? 0;
    final num sugar = data['nutrition']?['sugar_g'] ?? 0;
    final num protein = 12;
    final num fat = 5;

    return Container(
      height: cardHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey,
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: cardHeight,
            height: cardHeight,
            color: const Color(0xFFF1F1F1),
            child: imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  )
                : const Icon(Icons.coffee, size: 40, color: Colors.grey),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: screenWidth * 0.042,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'KoPubDotum')),
                            const SizedBox(height: 4),
                            Text('8,700원  |  ${kcal}Kcal',
                                style: TextStyle(
                                    fontSize: screenWidth * 0.032,
                                    color: Colors.black54,
                                    fontFamily: 'KoPubDotum')),
                          ],
                        ),
                      ),
                      _buildHeartIcon(size: 24),
                    ],
                  ),
                  Row(
                    children: [
                      _buildMiniBadge('당 ${sugar}g'),
                      const SizedBox(width: 6),
                      _buildMiniBadge('단백질 ${protein}g'),
                      const SizedBox(width: 6),
                      _buildMiniBadge('지방 ${fat}g'),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartIcon({double size = 30}) {
    return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: Colors.white70, shape: BoxShape.circle),
        child: Icon(Icons.favorite_border,
            size: size * 0.6, color: Colors.black54));
  }

  Widget _buildNutritionBadge(
      double screenWidth, String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
          color: bgColor,
          shape: RoundedRectangleBorder(
              side: BorderSide(width: 1, color: textColor),
              borderRadius: BorderRadius.circular(30))),
      child: Text(text,
          style: TextStyle(
              color: textColor,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
              fontFamily: 'KoPubDotum')),
    );
  }

  Widget _buildMiniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(4)),
      child: Text(text,
          style: const TextStyle(
              color: Color(0xFF555555), fontSize: 11, fontFamily: 'KoPubDotum')),
    );
  }
}