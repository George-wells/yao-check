import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/medicine_provider.dart';
import '../../models/medicine.dart';

/// 药品搜索页（增强版）
/// 支持：防抖搜索、结果列表、热门搜索、最近搜索、扫码入口
class MedicineSearchPage extends StatefulWidget {
  const MedicineSearchPage({super.key});

  @override
  State<MedicineSearchPage> createState() => _MedicineSearchPageState();
}

class _MedicineSearchPageState extends State<MedicineSearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<MedicineProvider>().init();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) async {
    if (keyword.isEmpty) return;
    final provider = context.read<MedicineProvider>();
    await provider.getMedicineByName(keyword);
    if (mounted) {
      Navigator.pushNamed(context, AppConstants.routeMedicineDetail);
    }
  }

  void _onMedicineTap(Medicine medicine) async {
    final provider = context.read<MedicineProvider>();
    await provider.getMedicineDetail(medicine.id);
    if (mounted) {
      Navigator.pushNamed(context, AppConstants.routeMedicineDetail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final medicine = context.watch<MedicineProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('药物信息查询'),
      ),
      body: Column(
        children: [
          // 搜索框
          Container(
            padding: EdgeInsets.all(isElderly ? 24 : 16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '搜索药品名称或成分...',
                prefixIcon: Icon(Icons.search, color: theme.primary),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          medicine.clearSearch();
                          _focusNode.requestFocus();
                        },
                      ),
                    IconButton(
                      icon: Icon(Icons.qr_code_scanner, color: theme.primary),
                      onPressed: () {
                        // 扫码入口
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('扫码功能需设备支持')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              onChanged: (value) {
                medicine.searchDebounced(value);
              },
              onSubmitted: _onSearch,
            ),
          ),

          // 内容区域
          Expanded(
            child: _buildContent(theme, medicine, isElderly),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeProvider theme, MedicineProvider medicine, bool isElderly) {
    // 搜索中
    if (medicine.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    // 有搜索结果
    if (medicine.searchResults.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: () async => medicine.searchMedicine(_searchController.text),
        child: ListView.separated(
          padding: EdgeInsets.all(isElderly ? 20 : 16),
          itemCount: medicine.searchResults.length,
          separatorBuilder: (_, __) => SizedBox(height: isElderly ? 12 : 8),
          itemBuilder: (context, index) {
            final med = medicine.searchResults[index];
            return _buildSearchResultCard(theme, med, isElderly);
          },
        ),
      );
    }

    // 搜索无结果
    if (_searchController.text.isNotEmpty && !medicine.isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.textDisabled),
            SizedBox(height: theme.spaceLG),
            Text(
              '未找到相关药品',
              style: TextStyle(
                fontSize: theme.fontSizeH3,
                color: theme.textPrimary,
              ),
            ),
            SizedBox(height: theme.spaceSM),
            Text(
              '试试其他关键词或使用扫码查询',
              style: TextStyle(
                fontSize: theme.fontSizeBodySmall,
                color: theme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 默认状态 - 热门搜索 + 最近搜索
    return SingleChildScrollView(
      padding: EdgeInsets.all(isElderly ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 最近搜索
          if (medicine.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近搜索',
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => medicine.clearRecentSearches(),
                  child: Text(
                    '清除',
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: theme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: theme.spaceSM),
            Wrap(
              spacing: theme.spaceSM,
              runSpacing: theme.spaceSM,
              children: medicine.recentSearches.map((keyword) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = keyword;
                    _onSearch(keyword);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spaceLG,
                      vertical: theme.spaceSM,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(theme.radiusLG),
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: theme.textDisabled),
                        SizedBox(width: theme.spaceSM),
                        Text(
                          keyword,
                          style: TextStyle(
                            fontSize: theme.fontSizeBodySmall,
                            color: theme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: theme.spaceLG),
          ],

          // 热门搜索
          Text(
            '热门搜索',
            style: TextStyle(
              fontSize: theme.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
          SizedBox(height: theme.spaceSM),
          Wrap(
            spacing: theme.spaceSM,
            runSpacing: theme.spaceSM,
            children: [
              '硝苯地平', '二甲双胍', '阿司匹林',
              '阿托伐他汀', '氯沙坦', '厄贝沙坦',
            ].map((name) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = name;
                  _onSearch(name);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.spaceLG,
                    vertical: theme.spaceSM,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(theme.radiusLG),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: theme.fontSizeBodySmall,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: isElderly ? 24 : 20),

          // 功能入口
          _buildFunctionEntry(
            theme,
            icon: Icons.swap_horiz,
            title: '药物相互作用检查',
            onTap: () => Navigator.pushNamed(context, AppConstants.routeInteractions),
          ),
          SizedBox(height: theme.spaceMD),
          _buildFunctionEntry(
            theme,
            icon: Icons.warning_amber_outlined,
            title: '我的药物副作用提示',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(ThemeProvider theme, Medicine med, bool isElderly) {
    return GestureDetector(
      onTap: () => _onMedicineTap(med),
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          boxShadow: theme.shadowLight,
        ),
        child: Row(
          children: [
            Container(
              width: isElderly ? 52 : 44,
              height: isElderly ? 52 : 44,
              decoration: BoxDecoration(
                color: theme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.medication, color: theme.primary, size: isElderly ? 28 : 22),
            ),
            SizedBox(width: theme.spaceMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: isElderly ? 22 : 16,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  if (med.genericName != null)
                    Text(
                      '通用名：${med.genericName}',
                      style: TextStyle(
                        fontSize: isElderly ? 18 : 13,
                        color: theme.textSecondary,
                      ),
                    ),
                  if (med.category != null)
                    Text(
                      med.category!,
                      style: TextStyle(
                        fontSize: isElderly ? 16 : 12,
                        color: theme.textDisabled,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.textDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildFunctionEntry(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          boxShadow: theme.shadowLight,
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.primary, size: theme.iconStandard),
            SizedBox(width: theme.spaceMD),
            Text(
              title,
              style: TextStyle(
                fontSize: theme.fontSizeBody,
                fontWeight: FontWeight.w500,
                color: theme.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: theme.textDisabled),
          ],
        ),
      ),
    );
  }
}
