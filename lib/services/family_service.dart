import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/family_model.dart';
import '../models/category_model.dart';

class FamilyService {
  final _supabase = Supabase.instance.client;

  // Default categories to seed when a family is created
  static const List<Map<String, String>> _defaultCategories = [
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

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer('FAM');
    for (int i = 0; i < 3; i++) {
      buffer.write(chars[(rand + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  /// Creates a new family, marks creator as admin, seeds default categories.
  Future<FamilyModel> createFamily(String name) async {
    final userId = _supabase.auth.currentUser!.id;
    final inviteCode = _generateInviteCode();

    Map<String, dynamic>? familyResult;

    // Attempt insert with invite_code
    try {
      familyResult = await _supabase
          .from('families')
          .insert({'name': name, 'created_by': userId, 'invite_code': inviteCode})
          .select()
          .single();
    } catch (_) {
      // Fallback if invite_code column is not in DB schema yet
      familyResult = await _supabase
          .from('families')
          .insert({'name': name, 'created_by': userId})
          .select()
          .single();
    }

    final family = FamilyModel.fromMap(familyResult);

    // Link current user's profile to the family as admin
    await _supabase
        .from('profiles')
        .update({'family_id': family.id, 'is_admin': true}).eq('id', userId);

    // Seed default categories
    final cats = _defaultCategories.map((c) => {
          'family_id': family.id,
          'name': c['name']!,
          'type': c['type']!,
          'color': c['color']!,
          'icon_name': c['icon']!,
          'created_by': userId,
        }).toList();

    try {
      await _supabase.from('categories').insert(cats);
    } catch (_) {}

    return family;
  }

  /// Joins an existing family using a 6-character invite code or ID prefix.
  Future<FamilyModel> joinFamilyByCode(String code) async {
    final cleanCode = code.trim().toUpperCase().replaceAll(' ', '');
    if (cleanCode.isEmpty) {
      throw Exception('Please enter a valid invite code');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    Map<String, dynamic>? match;

    // 1. Try finding by invite_code column
    try {
      final res = await _supabase
          .from('families')
          .select()
          .ilike('invite_code', cleanCode)
          .maybeSingle();
      if (res != null) match = res;
    } catch (_) {}

    // 2. Fallback: match by ID prefix or exact ID
    if (match == null) {
      try {
        final allFamilies = await _supabase.from('families').select();
        for (final fam in (allFamilies as List)) {
          final fMap = fam as Map<String, dynamic>;
          final id = (fMap['id'] as String? ?? '').replaceAll('-', '').toUpperCase();
          final inv = (fMap['invite_code'] as String? ?? '').toUpperCase();
          if (inv == cleanCode || id.startsWith(cleanCode) || id == cleanCode) {
            match = fMap;
            break;
          }
        }
      } catch (_) {}
    }

    if (match == null) {
      throw Exception('No family found for code "$code". Please verify and try again.');
    }

    final family = FamilyModel.fromMap(match);

    // Link current user as normal member (is_admin: false)
    await _supabase
        .from('profiles')
        .update({'family_id': family.id, 'is_admin': false}).eq('id', userId);

    return family;
  }

  /// Leaves current family and resets admin status.
  Future<void> leaveFamily() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    await _supabase
        .from('profiles')
        .update({'family_id': null, 'is_admin': false}).eq('id', userId);
  }

  /// Returns the current user's family. Returns null if not linked to any family.
  Future<FamilyModel?> getMyFamily() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final profile = await _supabase
          .from('profiles')
          .select('family_id, is_admin')
          .eq('id', userId)
          .maybeSingle();

      final familyId = profile?['family_id'] as String?;
      if (familyId == null || familyId.isEmpty) return null;

      final result = await _supabase
          .from('families')
          .select()
          .eq('id', familyId)
          .maybeSingle();
      if (result != null) return FamilyModel.fromMap(result);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns all families (for admin view).
  Future<List<FamilyModel>> getAllFamilies() async {
    final result = await _supabase.from('families').select();
    return (result as List)
        .map((m) => FamilyModel.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Returns all members belonging to the same family as the current user.
  Future<List<FamilyMemberModel>> getFamilyMembers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final profile = await _supabase
        .from('profiles')
        .select('family_id')
        .eq('id', userId)
        .maybeSingle();

    final familyId = profile?['family_id'] as String?;
    if (familyId == null) return [];

    final result = await _supabase
        .from('profiles')
        .select()
        .eq('family_id', familyId);

    return (result as List)
        .map((m) => FamilyMemberModel.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Returns all users (for admin use).
  Future<List<FamilyMemberModel>> getAllUsers() async {
    final result = await _supabase.from('profiles').select();
    return (result as List)
        .map((m) => FamilyMemberModel.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  /// Links a user (by profile id) to the given family.
  Future<void> linkUserToFamily(String profileId, String familyId) async {
    await _supabase
        .from('profiles')
        .update({'family_id': familyId}).eq('id', profileId);
  }

  /// Updates the family name.
  Future<void> updateFamilyName(String familyId, String newName) async {
    await _supabase
        .from('families')
        .update({'name': newName}).eq('id', familyId);
  }

  /// Gets family_id for current user quickly.
  Future<String?> getMyFamilyId() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;
      final p = await _supabase
          .from('profiles')
          .select('family_id')
          .eq('id', userId)
          .maybeSingle();
      return p?['family_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Fetches all categories for the given family.
  Future<List<CategoryModel>> getCategoriesForFamily(String familyId) async {
    final result = await _supabase
        .from('categories')
        .select()
        .eq('family_id', familyId)
        .order('type')
        .order('name');
    return (result as List)
        .map((m) => CategoryModel.fromMap(m as Map<String, dynamic>))
        .toList();
  }
}
