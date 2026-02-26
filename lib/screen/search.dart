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
                              Visibility(
                                visible: Navigator.canPop(context),
                                maintainSize: true,
                                maintainAnimation: true,
                                maintainState: true,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.black54,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
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
                              IconButton(
                                icon: const Icon(
                                  Icons.mic,
                                  color: Colors.black54,
                                ),
                                onPressed: () {
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

                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Text(
                                '검색 옵션',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        // === 필터 및 뷰 전환 버튼 영역 ===
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _buildSortDropdown(),
                                  const SizedBox(width: 8),
                                  _buildBrandFilterButton(),
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

                              var filteredDocs = allDocs.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final name = data['menu_name'] as String? ?? '';
                                final brand =
                                    data['brand_name'] as String? ?? '';

                                // 1. 검색어 필터
                                if (_searchText.isNotEmpty &&
                                    !name.toLowerCase().contains(
                                      _searchText.toLowerCase(),
                                    )) {
                                  return false;
                                }

                                // [수정] 2. 브랜드 필터 (다중 선택 로직 반영)
                                // 선택된 브랜드가 1개 이상 존재하고, 현재 메뉴의 브랜드가 선택 목록에 없다면 필터링
                                if (_selectedBrands.isNotEmpty &&
                                    !_selectedBrands.contains(brand)) {
                                  return false;
                                }

                                return true;
                              }).toList();

                              // 3. 정렬 로직
                              if (_selectedSort == '당류 낮은순') {
                                filteredDocs.sort((a, b) {
                                  final aData =
                                      a.data() as Map<String, dynamic>;
                                  final bData =
                                      b.data() as Map<String, dynamic>;
                                  final num aSugar =
                                      aData['nutrition']?['sugar_g'] ?? 0;
                                  final num bSugar =
                                      bData['nutrition']?['sugar_g'] ?? 0;
                                  return aSugar.compareTo(bSugar);
                                });
                              } else if (_selectedSort == '칼로리 낮은순') {
                                filteredDocs.sort((a, b) {
                                  final aData =
                                      a.data() as Map<String, dynamic>;
                                  final bData =
                                      b.data() as Map<String, dynamic>;
                                  final num aCal =
                                      aData['nutrition']?['calories_kcal'] ?? 0;
                                  final num bCal =
                                      bData['nutrition']?['calories_kcal'] ?? 0;
                                  return aCal.compareTo(bCal);
                                });
                              }

                              if (filteredDocs.isEmpty) {
                                return const Center(child: Text('검색 결과가 없습니다.'));
                              }

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

  // 정렬 드롭다운
  Widget _buildSortDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black12, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 1),
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

  Widget _buildBrandFilterButton() {
    final bool isFiltered = _selectedBrands.isNotEmpty;

    return GestureDetector(
      onTap: _showBrandBottomSheet,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: !isFiltered
              ? Colors.white
              : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !isFiltered
                ? Colors.black12
                : Colors.green,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getBrandButtonText(),
              style: TextStyle(
                color: !isFiltered ? Colors.black87 : Colors.green,
                fontSize: 13,
                fontFamily: 'KoPubDotum',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.filter_list,
              color: !isFiltered ? Colors.black54 : Colors.green,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}