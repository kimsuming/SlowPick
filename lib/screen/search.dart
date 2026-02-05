import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/widget/menu_cards.dart'; // 메뉴 카드 위젯 import 확인 필요

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isGridView = true;
  late TextEditingController _searchController;
  String _searchText = "";

  // 정렬 옵션 관리
  final List<String> _sortOptions = ['모든 메뉴', '최신순', '당류 낮은순', '칼로리 낮은순'];
  String _selectedSort = '모든 메뉴';

  @override
  void initState() {
    super.initState();
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
    final double gridAspectRatio = (screenWidth / 2) / (screenHeight * 0.37);

    return Scaffold(
      // 키보드가 올라올 때 화면이 찌그러지는 것 방지
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: Stack(
        children: [
          // 1. 배경 그라디언트
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                stops: [0.2, 0.6],
                colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
              ),
            ),
          ),
          // 2. 메인 컨텐츠 (SafeArea 적용)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.02),
                // === 흰색 라운드 컨테이너 (결과 영역) ===
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Column(
                      children: [
                        // === 상단 헤더 영역 (뒤로가기, 검색창, 음성버튼) ===
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          child: Row(
                            children: [
                              // 1. 뒤로 가기 버튼
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.black54,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),

                              // 2. 검색창
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEEEE), // Figma 색상
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: const TextStyle(fontSize: 16),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchText = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: '메뉴를 검색해보세요!',
                                      hintStyle: const TextStyle(
                                        color: Colors.black38,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      suffixIcon: _searchText.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: Colors.grey,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchText = "";
                                                });
                                              },
                                            )
                                          : null,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                    ),
                                  ),
                                ),
                              ),

                              // 3. 음성 인식 버튼
                              IconButton(
                                icon: const Icon(
                                  Icons.mic,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
                                  // TODO: 음성 인식 기능 구현
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('음성 인식 기능 준비 중입니다.'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6), // 라운드 곡선 안쪽 여백
                        
                        // === 필터 및 뷰 전환 버튼 영역 ===
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 정렬 버튼
                              _buildSortDropdown(),

                              // 그리드/리스트 뷰 전환 버튼
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isGridView = !_isGridView;
                                  });
                                },
                                icon: Icon(
                                  _isGridView
                                      ? Icons.view_list_rounded
                                      : Icons.grid_view_rounded,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        // === [D] 검색 결과 리스트 ===
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('menus')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.greenAccent,
                                  ),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text('저장된 메뉴가 없습니다.'),
                                );
                              }

                              final allDocs = snapshot.data!.docs;
                              final filteredDocs = allDocs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['menu_name'] as String? ?? '';
                                if (_searchText.isEmpty) return true;
                                return name.toLowerCase().contains(
                                  _searchText.toLowerCase(),
                                );
                              }).toList();

                              if (filteredDocs.isEmpty) {
                                return Center(
                                  child: Text('\'$_searchText\' 검색 결과가 없습니다.'),
                                );
                              }

                              // 그리드 뷰
                              if (_isGridView) {
                                return GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                    screenWidth * 0.04,
                                    10,
                                    screenWidth * 0.04,
                                    18,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: gridAspectRatio,
                                        crossAxisSpacing: screenWidth * 0.04,
                                        mainAxisSpacing: screenWidth * 0.04,
                                      ),
                                  itemCount: filteredDocs.length,
                                  itemBuilder: (context, index) {
                                    final data =
                                        filteredDocs[index].data()
                                            as Map<String, dynamic>;
                                    return MenuGridCard(data: data);
                                  },
                                );
                              } else {
                                // 리스트 뷰
                                return ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                    screenWidth * 0.04,
                                    10,
                                    screenWidth * 0.04,
                                    16,
                                  ),
                                  itemCount: filteredDocs.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: screenHeight * 0.02),
                                  itemBuilder: (context, index) {
                                    final data =
                                        filteredDocs[index].data()
                                            as Map<String, dynamic>;
                                    return MenuListCard(data: data);
                                  },
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.withOpacity(
            0.3,
          ), // Figma: Colors.black.withValues(alpha: 0.05)
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Colors.black,
            size: 20,
          ),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontFamily: 'KoPubDotum', // Figma 폰트 반영
            fontWeight: FontWeight.bold,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSort = newValue;
                // TODO: 여기서 실제 정렬 로직 연결 (Firebase query orderBy 등)
              });
            }
          },
          items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ),
    );
  }
}
