import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/category_service.dart';
import '../../services/family_service.dart';
import '../../models/category_model.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen>
    with SingleTickerProviderStateMixin {
  final _catService = CategoryService();
  final _familyService = FamilyService();
  late TabController _tabController;

  String? _familyId;
  List<CategoryModel> _income = [];
  List<CategoryModel> _expense = [];
  bool _loading = true;

  // Predefined color options — refreshed to match the new warm palette.
  static const List<Color> _colorOptions = [
    Color(0xFFFF6B4A), Color(0xFF0F766E), Color(0xFFF2B84B),
    Color(0xFF6D5DD3), Color(0xFFE8544A), Color(0xFF2E9DA6),
    Color(0xFFD98A3D), Color(0xFF9C6ADE), Color(0xFF4C7A5A),
    Color(0xFF3E6DA8), Color(0xFFB5556B), Color(0xFF6D4C41),
  ];

  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'salary', 'icon': Icons.work_outline_rounded},
    {'name': 'freelance', 'icon': Icons.laptop_mac_rounded},
    {'name': 'business', 'icon': Icons.business_center_outlined},
    {'name': 'investment', 'icon': Icons.trending_up_rounded},
    {'name': 'food', 'icon': Icons.restaurant_outlined},
    {'name': 'transport', 'icon': Icons.directions_car_filled_outlined},
    {'name': 'shopping', 'icon': Icons.shopping_bag_outlined},
    {'name': 'utilities', 'icon': Icons.bolt_outlined},
    {'name': 'health', 'icon': Icons.favorite_border_rounded},
    {'name': 'education', 'icon': Icons.school_outlined},
    {'name': 'rent', 'icon': Icons.home_outlined},
    {'name': 'entertainment', 'icon': Icons.movie_outlined},
    {'name': 'savings', 'icon': Icons.savings_outlined},
    {'name': 'other', 'icon': Icons.more_horiz_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fid = await _familyService.getMyFamilyId();
      if (fid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final income = await _catService.getCategoriesByType(fid, 'income');
      final expense = await _catService.getCategoriesByType(fid, 'expense');
      if (mounted) {
        setState(() {
          _familyId = fid;
          _income = income;
          _expense = expense;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCategoryDialog([CategoryModel? cat]) {
    final nameCtrl = TextEditingController(text: cat?.name ?? '');
    String type = cat?.type ?? 'expense';
    String selectedColor = cat?.color ?? '#FF6B4A';
    String selectedIcon = cat?.iconName ?? 'category';
    bool saving = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(cat == null ? 'Add category' : 'Edit category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Category name'),
                ),
                const SizedBox(height: 14),
                if (cat == null) ...[
                  const Text('Type', style: AppTheme.eyebrow),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _TypeBtn(
                          label: 'Income',
                          selected: type == 'income',
                          color: AppTheme.teal,
                          onTap: () => setS(() => type = 'income')),
                      const SizedBox(width: 8),
                      _TypeBtn(
                          label: 'Expense',
                          selected: type == 'expense',
                          color: AppTheme.rose,
                          onTap: () => setS(() => type = 'expense')),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                const Text('Color', style: AppTheme.eyebrow),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: _colorOptions.map((c) {
                    final hex = '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                    final isSel = selectedColor.toUpperCase() == hex;
                    return GestureDetector(
                      onTap: () => setS(() => selectedColor = hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(color: AppTheme.textPrimary, width: 2.5)
                              : null,
                        ),
                        child: isSel
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Icon', style: AppTheme.eyebrow),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((opt) {
                    final isSel = selectedIcon == opt['name'];
                    return GestureDetector(
                      onTap: () => setS(() => selectedIcon = opt['name'] as String),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: isSel ? AppTheme.coralSoft : AppTheme.sand,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? AppTheme.coral : Colors.transparent, width: 1.4),
                        ),
                        child: Icon(opt['icon'] as IconData,
                            size: 19, color: isSel ? AppTheme.coralDeep : AppTheme.textMuted),
                      ),
                    );
                  }).toList(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppTheme.rose, fontSize: 12.5)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        setS(() => error = 'Name is required');
                        return;
                      }
                      setS(() {
                        saving = true;
                        error = null;
                      });
                      try {
                        if (cat == null) {
                          await _catService.addCategory(
                            familyId: _familyId!,
                            name: name,
                            type: type,
                            color: selectedColor,
                            iconName: selectedIcon,
                          );
                        } else {
                          await _catService.updateCategory(
                            id: cat.id,
                            name: name,
                            type: cat.type,
                            color: selectedColor,
                            iconName: selectedIcon,
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      } catch (e) {
                        setS(() {
                          saving = false;
                          error = e.toString();
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete "${cat.name}"? Existing transactions will be unlinked.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.rose),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _catService.deleteCategory(cat.id);
      _load();
    }
  }

  Widget _buildList(List<CategoryModel> cats) {
    if (cats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.label_outline_rounded, size: 26, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              const Text('No categories yet', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: cats.length,
      itemBuilder: (ctx, i) {
        final cat = cats[i];
        final color = AppTheme.hexToColor(cat.color);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(13)),
                child: Icon(AppTheme.getIcon(cat.iconName), color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.coral, size: 19),
                onPressed: () => _showCategoryDialog(cat),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.rose, size: 19),
                onPressed: () => _deleteCategory(cat),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: const Text('Categories'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.sand, borderRadius: BorderRadius.circular(14)),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(borderRadius: BorderRadius.circular(11), color: AppTheme.ink),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(icon: Icon(Icons.arrow_downward_rounded, size: 17), text: 'Income'),
                  Tab(icon: Icon(Icons.arrow_upward_rounded, size: 17), text: 'Expense'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)))
          : _familyId == null
              ? const Center(
                  child: Text('No family set up. Create a family first.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_income),
                    _buildList(_expense),
                  ],
                ),
      floatingActionButton: _familyId == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'admin_categories_fab',
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category'),
            ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        ),
        child: Text(label,
            style: TextStyle(color: selected ? Colors.white : color, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}
