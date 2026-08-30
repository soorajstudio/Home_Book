import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final _supabase = Supabase.instance.client;

  static const List<Map<String, String>> defaultCategories = [
    // Income
    {'name': 'Salary', 'type': 'income', 'color': '#2E7D32', 'icon': 'salary'},
    {'name': 'Freelance', 'type': 'income', 'color': '#00897B', 'icon': 'freelance'},
    {'name': 'Business', 'type': 'income', 'color': '#1565C0', 'icon': 'business'},
    {'name': 'Investment', 'type': 'income', 'color': '#4527A0', 'icon': 'investment'},
    {'name': 'Other Income', 'type': 'income', 'color': '#558B2F', 'icon': 'other'},
    // Expense
    {'name': 'Food & Dining', 'type': 'expense', 'color': '#E65100', 'icon': 'food'},
    {'name': 'Transport', 'type': 'expense', 'color': '#1565C0', 'icon': 'transport'},
    {'name': 'Shopping', 'type': 'expense', 'color': '#AD1457', 'icon': 'shopping'},
    {'name': 'Utilities', 'type': 'expense', 'color': '#F57F17', 'icon': 'utilities'},
    {'name': 'Health', 'type': 'expense', 'color': '#C62828', 'icon': 'health'},
    {'name': 'Education', 'type': 'expense', 'color': '#6A1B9A', 'icon': 'education'},
    {'name': 'Rent', 'type': 'expense', 'color': '#4E342E', 'icon': 'rent'},
    {'name': 'Entertainment', 'type': 'expense', 'color': '#BF360C', 'icon': 'entertainment'},
    {'name': 'Savings', 'type': 'expense', 'color': '#00695C', 'icon': 'savings'},
    {'name': 'Other Expense', 'type': 'expense', 'color': '#546E7A', 'icon': 'other'},
  ];

  Future<void> ensureDefaultCategories(String familyId) async {
    try {
      final existing = await _supabase
          .from('categories')
          .select('id')
          .eq('family_id', familyId)
          .limit(1);

      if ((existing as List).isEmpty) {
        final userId = _supabase.auth.currentUser?.id;
        final cats = defaultCategories.map((c) => {
              'family_id': familyId,
              'name': c['name']!,
              'type': c['type']!,
              'color': c['color']!,
              'icon_name': c['icon']!,
              'created_by': userId,
            }).toList();
        await _supabase.from('categories').insert(cats);
      }
    } catch (_) {}
  }

  Future<List<CategoryModel>> getCategories(String familyId) async {
    try {
      await ensureDefaultCategories(familyId);
      final result = await _supabase
          .from('categories')
          .select()
          .eq('family_id', familyId)
          .order('type')
          .order('name');
      return (result as List)
          .map((m) => CategoryModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CategoryModel>> getCategoriesByType(
      String familyId, String type) async {
    try {
      await ensureDefaultCategories(familyId);
      final result = await _supabase
          .from('categories')
          .select()
          .eq('family_id', familyId)
          .eq('type', type)
          .order('name');
      return (result as List)
          .map((m) => CategoryModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<CategoryModel> addCategory({
    required String familyId,
    required String name,
    required String type,
    required String color,
    required String iconName,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final result = await _supabase.from('categories').insert({
      'family_id': familyId,
      'name': name,
      'type': type,
      'color': color,
      'icon_name': iconName,
      'created_by': userId,
    }).select().single();
    return CategoryModel.fromMap(result);
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String type,
    required String color,
    required String iconName,
  }) async {
    await _supabase.from('categories').update({
      'name': name,
      'type': type,
      'color': color,
      'icon_name': iconName,
    }).eq('id', id);
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
  }
}
