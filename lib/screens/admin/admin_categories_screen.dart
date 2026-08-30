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

  // Predefined color options
  static const List<Color> _colorOptions = [
    Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFFE65100),
    Color(0xFFAD1457), Color(0xFF4527A0), Color(0xFF00695C),
    Color(0xFFF57F17), Color(0xFF4E342E), Color(0xFFBF360C),
    Color(0xFF546E7A), Color(0xFF00897B), Color(0xFF6D4C41),
  ];

  // Icon options
  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'salary', 'icon': Icons.work_outline},
    {'name': 'freelance', 'icon': Icons.laptop_mac},
    {'name': 'business', 'icon': Icons.business_center_outlined},
    {'name': 'investment', 'icon': Icons.trending_up},
    {'name': 'food', 'icon': Icons.restaurant_outlined},
    {'name': 'transport', 'icon': Icons.directions_car_outlined},
    {'name': 'shopping', 'icon': Icons.shopping_bag_outlined},
    {'name': 'utilities', 'icon': Icons.electrical_services_outlined},
    {'name': 'health', 'icon': Icons.health_and_safety_outlined},
    {'name': 'education', 'icon': Icons.school_outlined},
    {'name': 'rent', 'icon': Icons.home_outlined},
    {'name': 'entertainment', 'icon': Icons.movie_outlined},
    {'name': 'savings', 'icon': Icons.savings_outlined},
    {'name': 'other', 'icon': Icons.more_horiz},
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
    String selectedColor = cat?.color ?? '#1565C0';
    String selectedIcon = cat?.iconName ?? 'category';
    bool saving = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(cat == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (cat == null) ...[
                  const Text('Type:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _TypeBtn(
                          label: 'Income',
                          selected: type == 'income',
                          color: AppTheme.incomeColor,
                          onTap: () => setS(() => type = 'income')),
                      const SizedBox(width: 8),
                      _TypeBtn(
                          label: 'Expense',
                          selected: type == 'expense',
                          color: AppTheme.expenseColor,
                          onTap: () => setS(() => type = 'expense')),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                const Text('Color:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colorOptions.map((c) {
                    final hex =
                        '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
                    final isSel = selectedColor.toUpperCase() == hex;
                    return GestureDetector(
                      onTap: () => setS(() => selectedColor = hex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(
                                  color: Colors.black, width: 2.5)
                              : null,
                        ),
                        child: isSel
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Icon:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _iconOptions.map((opt) {
                    final isSel = selectedIcon == opt['name'];
                    return GestureDetector(
                      onTap: () =>
                          setS(() => selectedIcon = opt['name'] as String),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.primary.withOpacity(0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: isSel
                                  ? AppTheme.primary
                                  : Colors.grey.shade300),
                        ),
                        child: Icon(opt['icon'] as IconData,
                            size: 20,
                            color: isSel
                                ? AppTheme.primary
                                : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!,
                      style:
                          const TextStyle(color: AppTheme.expenseColor)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        setS(() => error = 'Name is required');
                        return;
                      }
                      setS(() { saving = true; error = null; });
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
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
        title: const Text('Delete Category'),
        content:
            Text('Delete "${cat.name}"? Existing transactions will be unlinked.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseColor),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.label_outline, size: 48, color: AppTheme.textSecondary),
              SizedBox(height: 8),
              Text('No categories yet',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: cats.length,
      itemBuilder: (ctx, i) {
        final cat = cats[i];
        final color = AppTheme.hexToColor(cat.color);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child:
                  Icon(AppTheme.getIcon(cat.iconName), color: color, size: 20),
            ),
            title: Text(cat.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: AppTheme.primary, size: 20),
                  onPressed: () => _showCategoryDialog(cat),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.expenseColor, size: 20),
                  onPressed: () => _deleteCategory(cat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        backgroundColor: AppTheme.primaryDark,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_upward), text: 'Income'),
            Tab(icon: Icon(Icons.arrow_downward), text: 'Expense'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _familyId == null
              ? const Center(
                  child: Text(
                      'No family set up. Create a family first.',
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
              backgroundColor: AppTheme.accent,
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}
