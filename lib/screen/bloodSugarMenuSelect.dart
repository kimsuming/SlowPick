import 'package:flutter/material.dart';
import 'package:slowpick/screen/blood_sugar_check_record.dart';
import 'package:slowpick/service/menu_service.dart';
import 'package:slowpick/widget/menu_cards.dart';

class BloodSugarMenuSelect extends StatefulWidget {
  const BloodSugarMenuSelect({super.key});

  @override
  State<BloodSugarMenuSelect> createState() => _BloodSugarMenuSelectState();
}

class _BloodSugarMenuSelectState extends State<BloodSugarMenuSelect> {
  bool _isGridView = true;
  late TextEditingController _searchController;
  String _searchText = '';

  List<Map<String, dynamic>> _allMenus = [];
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _selectedMenu;

  final List<String> _sortOptions = ['모든 메뉴', '최신순', '당류 낮은순', '칼로리 낮은순'];
  String _selectedSort = '모든 메뉴';

  final List<String> _brandList = [
    '더벤티', '매머드 익스프레스', '매머드커피', '메가MGC커피', '빽다방',
    '스타벅스', '엔제리너스', '요거프레소', '이디야커피', '컴포즈커피',
    '탐앤탐스', '투썸플레이스', '폴 바셋',
  ];
  Set<String> _selectedBrands = {};

  String _getBrandButtonText() {
    if (_selectedBrands.isEmpty) return '브랜드';
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
      filtered.sort((a, b) =>
          ((a['sugar'] as num?) ?? 0).compareTo((b['sugar'] as num?) ?? 0));
    } else if (_selectedSort == '칼로리 낮은순') {
      filtered.sort((a, b) =>
          ((a['calories'] as num?) ?? 0).compareTo((b['calories'] as num?) ?? 0));
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    try {
      final menus = await MenuService.fetchMenus();
      if (!mounted) return;
      setState(() {
        _allMenus = menus;
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showBrandBottomSheet() {
    Set<String> tempSelectedBrands = Set.from(_selectedBrands);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          tempSelectedBrands.addAll(_brandList);
                        } else {
                          tempSelectedBrands.clear();
                        }
                      });
                    },
                  ),
                  const Divider(height: 1, color: Colors.black12),
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
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedBrands = tempSelectedBrands);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
                        // 검색 헤더
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.black54,
                                ),
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
                                    onChanged: (value) =>
                                        setState(() => _searchText = value),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: '메뉴를 검색해보세요!',
                                      hintStyle: const TextStyle(
                                          color: Colors.black38, fontSize: 16),
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
                                                setState(() => _searchText = '');
                                              },
                                            )
                                          : null,
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(30, 0, 0, 0),
                          child: Row(
                            children: [
                              Text(
                                '검색 옵션',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

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
                                onPressed: () =>
                                    setState(() => _isGridView = !_isGridView),
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

                        Expanded(
                          child: _buildMenuList(
                              screenWidth, screenHeight, gridAspectRatio),
                        ),

                        // 선택 버튼
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: GestureDetector(
                              onTap: _selectedMenu != null
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BloodSugarCheckRecord(
                                                  menuData: _selectedMenu!),
                                        ),
                                      )
                                  : null,
                              child: Container(
                                width: double.infinity,
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: _selectedMenu != null
                                      ? const LinearGradient(
                                          begin: Alignment(0.00, 0.50),
                                          end: Alignment(1.00, 0.50),
                                          colors: [
                                            Color(0xFFB5F369),
                                            Color(0xFF7BF15B)
                                          ],
                                        )
                                      : null,
                                  color: _selectedMenu == null
                                      ? const Color(0xFFE0E0E0)
                                      : null,
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

  Widget _buildMenuList(
      double screenWidth, double screenHeight, double gridAspectRatio) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.greenAccent));
    }
    if (_errorMessage != null) {
      return Center(child: Text('오류: $_errorMessage'));
    }

    final menus = _filteredMenus;
    if (menus.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    if (_isGridView) {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(
            screenWidth * 0.04, 10, screenWidth * 0.04, 18),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: gridAspectRatio,
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenWidth * 0.04,
        ),
        itemCount: menus.length,
        itemBuilder: (context, index) => MenuGridCard(
          data: menus[index],
          isLiked: menus[index]['is_liked'] as bool? ?? false,
          isSelected: _selectedMenu?['id'] == menus[index]['id'],
          onSelectTap: () => setState(() {
            _selectedMenu = _selectedMenu?['id'] == menus[index]['id']
                ? null
                : menus[index];
          }),
        ),
      );
    } else {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(
            screenWidth * 0.04, 10, screenWidth * 0.04, 16),
        itemCount: menus.length,
        separatorBuilder: (context, index) =>
            SizedBox(height: screenHeight * 0.02),
        itemBuilder: (context, index) => MenuListCard(
          data: menus[index],
          isLiked: menus[index]['is_liked'] as bool? ?? false,
          isSelected: _selectedMenu?['id'] == menus[index]['id'],
          onSelectTap: () => setState(() {
            _selectedMenu = _selectedMenu?['id'] == menus[index]['id']
                ? null
                : menus[index];
          }),
        ),
      );
    }
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
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
            if (newValue != null) setState(() => _selectedSort = newValue);
          },
          items: _sortOptions
              .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
              .toList(),
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
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
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
