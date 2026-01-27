import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:slowpick/widget/bottomBar_new.dart';

import 'package:slowpick/widget/menu_cards.dart'; 

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

      bottomNavigationBar: Container(
        color: Color(0xFFFCFCFC),
        child: SafeArea(top: false, child: BottomBarNew()),
      ),

      body: Column(
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
                hintStyle: TextStyle(
                color: Colors.black38,
                ),
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
                      0,
                      screenWidth * 0.04,
                      16,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: gridAspectRatio,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenWidth * 0.04,
                    ),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
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
                      final data = filteredDocs[index].data() as Map<String, dynamic>;
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