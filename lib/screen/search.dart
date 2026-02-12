import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/widget/menu_cards.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialBrand;

  const SearchScreen({
    super.key, 
    this.initialQuery, 
    this.initialBrand
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isGridView = true;
  late TextEditingController _searchController;
  String _searchText = "";
  

  // 정렬 옵션
  final List<String> _sortOptions = ['모든 메뉴', '최신순', '당류 낮은순', '칼로리 낮은순'];
  String _selectedSort = '모든 메뉴';

  // [추가] 브랜드 필터링 옵션
  final List<String> _brandList = [
    '전체', // '전체' 옵션 추가 (필터 해제용)
    '더벤티',
    '매머드 익스프레스',
    '매머드커피',
    '메가MGC커피',
    '빽다방',
    '스타벅스',
    '엔제리너스',
    '요거프레소',
    '이디야커피',
    '컴포즈커피',
    '탐앤탐스',
    '투썸플레이스',
    '폴 바셋'
  ];
  String _selectedBrand = '전체'; // 기본값

  @override
  void initState() {
    super.initState();
    String initialText = widget.initialQuery ?? "";
    _searchController = TextEditingController(text: initialText);
    _searchText = initialText;

    _selectedBrand = widget.initialBrand ?? '전체';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBrandBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // 모서리 둥글게 하기 위해 투명 처리
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // 화면 절반 높이
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 바텀 시트 헤더
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '브랜드 선택',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'KoPubDotum',
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.black26),
              // 브랜드 리스트
              Expanded(
                child: ListView.builder(
                  itemCount: _brandList.length,
                  itemBuilder: (context, index) {
                    final brand = _brandList[index];
                    final isSelected = brand == _selectedBrand;
                    return ListTile(
                      title: Text(
                        brand,
                        style: TextStyle(
                          color: isSelected ? Colors.green : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontFamily: 'KoPubDotum',
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedBrand = brand;
                        });
                        Navigator.pop(context); // 창 닫기
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double gridAspectRatio = (screenWidth / 2) / (screenHeight * 0.37);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: Container(
        color: const Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                stops: [0.2, 0.6],
                colors: [Color(0xFFA2F43D), Color(0xFFD5FF72)],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.02),
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
                        // 상단 검색 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new,
                                    color: Colors.black54),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEEEEE),
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
                                          color: Colors.black38, fontSize: 16),
                                      border: InputBorder.none,
                                      prefixIcon: const Icon(Icons.search,
                                          color: Colors.grey, size: 20),
                                      suffixIcon: _searchText.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.cancel,
                                                  color: Colors.grey, size: 18),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchText = "";
                                                });
                                              },
                                            )
                                          : null,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.mic, color: Colors.black54),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('음성 인식 기능 준비 중입니다.')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text('검색 옵션', style: TextStyle(fontWeight: FontWeight.w600),),
                            ],
                          ),
                        ),
                        
                        // === 필터 및 뷰 전환 버튼 영역 ===
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20,0,12,0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // [수정] 정렬 버튼과 브랜드 버튼을 함께 배치
                              Row(
                                children: [
                                  _buildSortDropdown(),
                                  const SizedBox(width: 8), // 버튼 사이 간격
                                  _buildBrandFilterButton(), // 브랜드 버튼
                                ],
                              ),

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

                        // === 검색 결과 리스트 ===
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
                                        color: Colors.greenAccent));
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text('저장된 메뉴가 없습니다.'));
                              }

                              final allDocs = snapshot.data!.docs;

                              var filteredDocs = allDocs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['menu_name'] as String? ?? '';
                                final brand = data['brand_name'] as String? ?? '';

                                // 1. 검색어 필터
                                if (_searchText.isNotEmpty &&
                                    !name
                                        .toLowerCase()
                                        .contains(_searchText.toLowerCase())) {
                                  return false;
                                }

                                // [추가] 2. 브랜드 필터
                                if (_selectedBrand != '전체' &&
                                    brand != _selectedBrand) {
                                  return false;
                                }

                                return true;
                              }).toList();

                              // 3. 정렬 로직
                              if (_selectedSort == '당류 낮은순') {
                                filteredDocs.sort((a, b) {
                                  final aData = a.data() as Map<String, dynamic>;
                                  final bData = b.data() as Map<String, dynamic>;
                                  final num aSugar =
                                      aData['nutrition']?['sugar_g'] ?? 0;
                                  final num bSugar =
                                      bData['nutrition']?['sugar_g'] ?? 0;
                                  return aSugar.compareTo(bSugar);
                                });
                              } else if (_selectedSort == '칼로리 낮은순') {
                                filteredDocs.sort((a, b) {
                                  final aData = a.data() as Map<String, dynamic>;
                                  final bData = b.data() as Map<String, dynamic>;
                                  final num aCal =
                                      aData['nutrition']?['calories_kcal'] ?? 0;
                                  final num bCal =
                                      bData['nutrition']?['calories_kcal'] ?? 0;
                                  return aCal.compareTo(bCal);
                                });
                              }

                              if (filteredDocs.isEmpty) {
                                return Center(
                                    child: Text('검색 결과가 없습니다.'));
                              }

                              if (_isGridView) {
                                return GridView.builder(
                                  padding: EdgeInsets.fromLTRB(
                                      screenWidth * 0.04,
                                      10,
                                      screenWidth * 0.04,
                                      18),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: gridAspectRatio,
                                    crossAxisSpacing: screenWidth * 0.04,
                                    mainAxisSpacing: screenWidth * 0.04,
                                  ),
                                  itemCount: filteredDocs.length,
                                  itemBuilder: (context, index) {
                                    final data = filteredDocs[index].data()
                                        as Map<String, dynamic>;
                                    return MenuGridCard(data: data);
                                  },
                                );
                              } else {
                                return ListView.separated(
                                  padding: EdgeInsets.fromLTRB(
                                      screenWidth * 0.04,
                                      10,
                                      screenWidth * 0.04,
                                      16),
                                  itemCount: filteredDocs.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: screenHeight * 0.02),
                                  itemBuilder: (context, index) {
                                    final data = filteredDocs[index].data()
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

  // 정렬 드롭다운
  Widget _buildSortDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black12, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontFamily: 'KoPubDotum',
            fontWeight: FontWeight.bold,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSort = newValue;
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

  // 브랜드 필터 버튼
  Widget _buildBrandFilterButton() {
    return GestureDetector(
      onTap: _showBrandBottomSheet,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _selectedBrand == '전체'
              ? Colors.white
              : const Color(0xFFE8F5E9), // 선택되면 초록빛 배경
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedBrand == '전체'
                ? Colors.black12
                : Colors.green, // 선택되면 초록 테두리
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: const Offset(0, 1))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedBrand == '전체' ? '브랜드' : _selectedBrand,
              style: TextStyle(
                color: _selectedBrand == '전체' ? Colors.black87 : Colors.green,
                fontSize: 13,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.filter_list,
              color: _selectedBrand == '전체' ? Colors.black54 : Colors.green,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}