import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

import 'package:slowpick/widget/menu_cards.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialBrand;

  const SearchScreen({super.key, this.initialQuery, this.initialBrand});

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

  final List<String> _brandList = [
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
    '폴 바셋',
  ];
  
  Set<String> _selectedBrands = {};

  // 선택된 브랜드 수에 따라 버튼 텍스트를 다르게 보여주는 함수
  String _getBrandButtonText() {
    if (_selectedBrands.isEmpty) return '브랜드';
    
    // [추가] 모든 브랜드가 선택된 경우 '전체'로 표시
    if (_selectedBrands.length == _brandList.length) return '전체'; 
    
    if (_selectedBrands.length == 1) return _selectedBrands.first;
    return '${_selectedBrands.first} 외 ${_selectedBrands.length - 1}';
  }

  @override
  void initState() {
    super.initState();
    String initialText = widget.initialQuery ?? "";
    _searchController = TextEditingController(text: initialText);
    _searchText = initialText;
    
    if (widget.initialBrand != null && widget.initialBrand != '전체') {
      _selectedBrands.add(widget.initialBrand!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  // [수정] 다중 선택 및 하단 '적용' 버튼이 있는 바텀 시트로 변경
  void _showBrandBottomSheet() {
    // 바텀 시트 내부에서만 임시로 사용할 선택 상태
    Set<String> tempSelectedBrands = Set.from(_selectedBrands);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, 
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // [추가] 모든 브랜드가 선택되었는지 확인하는 변수
            bool isAllSelected = tempSelectedBrands.length == _brandList.length;

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        const Text(
                          '브랜드 선택',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'KoPubDotum',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black26),
                  
                  // '전체 선택' 마스터 체크박스
                  CheckboxListTile(
                    title: Text(
                      '전체 선택',
                      style: TextStyle(
                        color: isAllSelected ? Colors.green : Colors.black,
                        fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
                        fontFamily: 'KoPubDotum',
                      ),
                    ),
                    value: isAllSelected,
                    activeColor: Colors.green,
                    onChanged: (bool? value) {
                      setModalState(() {
                        if (value == true) {
                          // 활성화: 모든 브랜드를 임시 Set에 추가
                          tempSelectedBrands.addAll(_brandList);
                        } else {
                          // 비활성화: 임시 Set 초기화 (모두 해제)
                          tempSelectedBrands.clear();
                        }
                      });
                    },
                  ),
                  const Divider(height: 1, color: Colors.black12), // 구분선 추가

                  // 개별 브랜드 리스트
                  Expanded(
                    child: ListView.builder(
                      itemCount: _brandList.length,
                      itemBuilder: (context, index) {
                        final brand = _brandList[index];
                        final isSelected = tempSelectedBrands.contains(brand);

                        return CheckboxListTile(
                          title: Text(
                            brand,
                            style: TextStyle(
                              color: isSelected ? Colors.green : Colors.black,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontFamily: 'KoPubDotum',
                            ),
                          ),
                          value: isSelected,
                          activeColor: Colors.green,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                tempSelectedBrands.add(brand);
                              } else {
                                tempSelectedBrands.remove(brand);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  
                  // 하단 적용 버튼
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          // 임시 상태를 실제 상태에 반영하고 화면 리빌드
                          setState(() {
                            _selectedBrands = tempSelectedBrands;
                          });
                          Navigator.pop(context); // 창 닫기
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          '적용하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'KoPubDotum',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: '메뉴를 검색해보세요!',
                hintStyle: TextStyle(color: Colors.black38),
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
              stream: FirebaseFirestore.instance
                  .collection('menus')
                  .snapshots(),
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
                  return Center(child: Text('\'$_searchText\' 검색 결과가 없습니다.'));
                }
                // 그리드뷰
                if (_isGridView) {
                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.04,
                      18,
                      screenWidth * 0.04,
                      18,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: gridAspectRatio,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenWidth * 0.04,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      return MenuGridCard(data: data);
                    },
                  );
                } else {
                  // 리스트뷰
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.04,
                      0,
                      screenWidth * 0.04,
                      16,
                    ),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: screenHeight * 0.02),
                    itemBuilder: (context, index) {
                      final data =
                          filteredDocs[index].data() as Map<String, dynamic>;
                      return MenuListCard(data: data);
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
}
