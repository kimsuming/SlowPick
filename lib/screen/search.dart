import 'package:flutter/material.dart';
import 'package:slowpick/service/menu_service.dart';
import 'package:slowpick/service/settings_service.dart';
import 'package:slowpick/widget/bottomBar_new.dart';
import 'package:slowpick/widget/menu_cards.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialBrand;

  // true면 메뉴를 찜하는 검색 화면 대신, 하나를 골라 [onMenuSelected]로 넘기는
  // 선택 화면으로 동작한다 (혈당 기록 등에서 재사용).
  final bool selectionMode;
  final ValueChanged<Map<String, dynamic>>? onMenuSelected;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialBrand,
    this.selectionMode = false,
    this.onMenuSelected,
  }) : assert(!selectionMode || onMenuSelected != null);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool _isGridView = true;
  late TextEditingController _searchController;
  String _searchText = "";

  List<Map<String, dynamic>> _allMenus = [];
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _selectedMenu;

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

  // 카드 미리보기에 표시할 영양 성분 (설정 버튼으로 변경, SharedPreferences에 저장)
  List<String> _previewNutrients = SettingsService.defaultPreviewNutrients;

  // 선택된 브랜드 수에 따라 버튼 텍스트를 다르게 보여주는 함수
  String _getBrandButtonText() {
    if (_selectedBrands.isEmpty) return '브랜드';

    // [추가] 모든 브랜드가 선택된 경우 '전체'로 표시
    if (_selectedBrands.length == _brandList.length) return '전체';

    if (_selectedBrands.length == 1) return _selectedBrands.first;
    return '${_selectedBrands.first} 외 ${_selectedBrands.length - 1}';
  }

  List<Map<String, dynamic>> get _filteredMenus {
    var filtered = _allMenus.where((m) {
      final name = m['menu_name'] as String? ?? '';
      final brand = m['brand_name'] as String? ?? '';
      if (_searchText.isNotEmpty &&
          !name.toLowerCase().contains(_searchText.toLowerCase())) return false;
      if (_selectedBrands.isNotEmpty && !_selectedBrands.contains(brand)) return false;
      return true;
    }).toList();

    if (_selectedSort == '당류 낮은순') {
      filtered.sort((a, b) => ((a['sugar'] as num?) ?? 0).compareTo((b['sugar'] as num?) ?? 0));
    } else if (_selectedSort == '칼로리 낮은순') {
      filtered.sort((a, b) => ((a['calories'] as num?) ?? 0).compareTo((b['calories'] as num?) ?? 0));
    }
    return filtered;
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
    _loadMenus();
    _loadPreviewNutrients();
  }

  Future<void> _loadPreviewNutrients() async {
    final saved = await SettingsService.loadPreviewNutrients();
    if (!mounted) return;
    setState(() => _previewNutrients = saved);
  }

  Future<void> _loadMenus() async {
    try {
      final menus = await MenuService.fetchMenus();
      if (!mounted) return;
      setState(() {
        // 선택 모드(혈당 기록 등)에서는 사이즈/온도별로 당류·칼로리가 다르므로
        // 대표 변형으로 묶지 않고 각 변형을 그대로 보여준다.
        _allMenus = widget.selectionMode ? menus : MenuService.groupVariants(menus);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike(int menuId) async {
    final idx = _allMenus.indexWhere((m) => m['id'] as int == menuId);
    if (idx == -1) return;
    final currently = _allMenus[idx]['is_liked'] as bool? ?? false;
    setState(() => _allMenus[idx]['is_liked'] = !currently);
    try {
      await MenuService.likeMenu(menuId);
    } catch (e) {
      setState(() => _allMenus[idx]['is_liked'] = currently);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
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
                        fontWeight: isAllSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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

  // 카드 미리보기 성분 선택 바텀 시트 (최대 _kMaxPreviewNutrients개)
  void _showPreviewSettingsBottomSheet() {
    List<String> tempSelected = List.from(_previewNutrients);
    // 당류는 항상 고정 표시되므로 선택 목록에서 제외
    final selectableOptions =
        kPreviewNutrientOptions.where((option) => option.key != 'sugar').toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 24),
                        const Text(
                          '미리보기 성분 설정',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '당류는 항상 표시돼요. 추가로 보고 싶은 성분을 골라주세요.',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          fontFamily: 'KoPubDotum',
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.black26),
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectableOptions.length,
                      itemBuilder: (context, index) {
                        final option = selectableOptions[index];
                        final isSelected = tempSelected.contains(option.key);

                        return CheckboxListTile(
                          title: Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected ? Colors.green : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontFamily: 'KoPubDotum',
                            ),
                          ),
                          value: isSelected,
                          activeColor: Colors.green,
                          onChanged: (bool? value) {
                            setModalState(() {
                              if (value == true) {
                                tempSelected.add(option.key);
                              } else {
                                tempSelected.remove(option.key);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _previewNutrients = tempSelected);
                          await SettingsService.savePreviewNutrients(tempSelected);
                          if (context.mounted) Navigator.pop(context);
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

    return Scaffold(
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: widget.selectionMode
          ? null
          : Container(
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
                                  Icons.tune,
                                  color: Colors.black54,
                                ),
                                tooltip: '미리보기 성분 설정',
                                onPressed: _showPreviewSettingsBottomSheet,
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
                          child: _buildMenuList(screenWidth, screenHeight),
                        ),

                        if (widget.selectionMode) _buildSelectButton(),
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

  Widget _buildMenuList(double screenWidth, double screenHeight) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
    }
    if (_errorMessage != null) {
      return Center(child: Text('오류: $_errorMessage'));
    }

    final menus = _filteredMenus;
    if (menus.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    if (_isGridView) {
      // 카드마다 미리보기 성분 개수나 알러지 텍스트 길이가 달라 필요한 높이가
      // 제각각이라, 그리드 전체를 같은 비율로 고정하면 카드 하나가 길어질 때
      // 화면의 모든 카드가 함께 늘어나 버린다. 그래서 GridView 대신 두 장씩
      // Row로 묶어 IntrinsicHeight로 감싸고, 그 줄(Row) 안에서만 높이를
      // 맞추도록 한다 — 다른 줄에는 영향이 없다.
      final rowCount = (menus.length / 2).ceil();
      final horizontalPadding = screenWidth * 0.04;
      final gap = screenWidth * 0.04;

      return ListView.separated(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 18),
        itemCount: rowCount,
        separatorBuilder: (context, index) => SizedBox(height: gap),
        itemBuilder: (context, rowIndex) {
          final firstIndex = rowIndex * 2;
          final secondIndex = firstIndex + 1;
          final hasSecond = secondIndex < menus.length;

          Widget buildCard(int index) => MenuGridCard(
                data: menus[index],
                isLiked: menus[index]['is_liked'] as bool? ?? false,
                onLikeTap: widget.selectionMode
                    ? null
                    : () => _toggleLike(menus[index]['id'] as int),
                isSelected: widget.selectionMode &&
                    _selectedMenu?['id'] == menus[index]['id'],
                onSelectTap:
                    widget.selectionMode ? () => _onCardTap(menus[index]) : null,
                previewNutrients: _previewNutrients,
              );

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: buildCard(firstIndex)),
                SizedBox(width: gap),
                Expanded(
                  child: hasSecond ? buildCard(secondIndex) : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(screenWidth * 0.04, 10, screenWidth * 0.04, 16),
        itemCount: menus.length,
        separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.02),
        itemBuilder: (context, index) => MenuListCard(
          data: menus[index],
          isLiked: menus[index]['is_liked'] as bool? ?? false,
          onLikeTap: widget.selectionMode
              ? null
              : () => _toggleLike(menus[index]['id'] as int),
          isSelected: widget.selectionMode &&
              _selectedMenu?['id'] == menus[index]['id'],
          onSelectTap:
              widget.selectionMode ? () => _onCardTap(menus[index]) : null,
          previewNutrients: _previewNutrients,
        ),
      );
    }
  }

  void _onCardTap(Map<String, dynamic> menu) {
    setState(() {
      _selectedMenu = _selectedMenu?['id'] == menu['id'] ? null : menu;
    });
  }

  Widget _buildSelectButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GestureDetector(
          onTap: _selectedMenu != null
              ? () => widget.onMenuSelected!(_selectedMenu!)
              : null,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: _selectedMenu != null
                  ? const LinearGradient(
                      begin: Alignment(0.00, 0.50),
                      end: Alignment(1.00, 0.50),
                      colors: [Color(0xFFB5F369), Color(0xFF7BF15B)],
                    )
                  : null,
              color: _selectedMenu == null ? const Color(0xFFE0E0E0) : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '선택',
                style: TextStyle(
                  color: _selectedMenu != null
                      ? Colors.white
                      : const Color(0xFF9E9E9E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ),
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
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
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
          color: !isFiltered ? Colors.white : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !isFiltered ? Colors.black12 : Colors.green,
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
