import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final _supabase = Supabase.instance.client;

  Future<List<TransactionModel>> getTransactions({
    required String familyId,
    DateTime? fromDate,
    DateTime? toDate,
    String? type, // 'income' | 'expense' | null = all
    String? categoryId,
    int limit = 200,
  }) async {
    try {
      // Primary query with categories join
      var query = _supabase
          .from('transactions')
          .select('*, categories(name, color, icon_name)')
          .eq('family_id', familyId);

      if (type != null) query = query.eq('type', type);
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (fromDate != null) {
        query = query.gte('date', _dateStr(fromDate));
      }
      if (toDate != null) {
        query = query.lte('date', _dateStr(toDate));
      }

      final result = await query.order('date', ascending: false).limit(limit);
      final rawList = List<Map<String, dynamic>>.from(result as List);
      return await _enrichTransactions(rawList);
    } catch (e) {
      // Fallback query
      try {
        var query = _supabase
            .from('transactions')
            .select()
            .eq('family_id', familyId);

        if (type != null) query = query.eq('type', type);
        if (categoryId != null) query = query.eq('category_id', categoryId);
        if (fromDate != null) {
          query = query.gte('date', _dateStr(fromDate));
        }
        if (toDate != null) {
          query = query.lte('date', _dateStr(toDate));
        }

        final result = await query.order('date', ascending: false).limit(limit);
        final rawList = List<Map<String, dynamic>>.from(result as List);
        return await _enrichTransactions(rawList);
      } catch (_) {
        return [];
      }
    }
  }

  Future<List<TransactionModel>> _enrichTransactions(
      List<Map<String, dynamic>> rawList) async {
    final missingUserIds = <String>{};
    final missingCategoryIds = <String>{};

    for (final map in rawList) {
      final prof = map['profiles'] as Map<String, dynamic>?;
      final uid = map['user_id'] as String?;
      if ((prof == null ||
              (prof['username'] == null && prof['full_name'] == null)) &&
          uid != null &&
          uid.isNotEmpty) {
        missingUserIds.add(uid);
      }

      final cat = map['categories'] as Map<String, dynamic>?;
      final catId = map['category_id'] as String?;
      if (cat == null && catId != null && catId.isNotEmpty) {
        missingCategoryIds.add(catId);
      }
    }

    final profMap = <String, Map<String, dynamic>>{};
    if (missingUserIds.isNotEmpty) {
      try {
        final profilesRes = await _supabase
            .from('profiles')
            .select('id, username, full_name')
            .filter('id', 'in', missingUserIds.toList());
        for (final p in (profilesRes as List)) {
          final pMap = p as Map<String, dynamic>;
          final id = pMap['id'] as String?;
          if (id != null) profMap[id] = pMap;
        }
      } catch (_) {}
    }

    final catMap = <String, Map<String, dynamic>>{};
    if (missingCategoryIds.isNotEmpty) {
      try {
        final catsRes = await _supabase
            .from('categories')
            .select('id, name, color, icon_name')
            .filter('id', 'in', missingCategoryIds.toList());
        for (final c in (catsRes as List)) {
          final cMap = c as Map<String, dynamic>;
          final id = cMap['id'] as String?;
          if (id != null) catMap[id] = cMap;
        }
      } catch (_) {}
    }

    return rawList.map((m) {
      final copy = Map<String, dynamic>.from(m);
      final uid = copy['user_id'] as String?;
      if (uid != null && profMap.containsKey(uid)) {
        copy['profiles'] = profMap[uid];
      }
      final catId = copy['category_id'] as String?;
      if (catId != null &&
          copy['categories'] == null &&
          catMap.containsKey(catId)) {
        copy['categories'] = catMap[catId];
      }
      return TransactionModel.fromMap(copy);
    }).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions(
      String familyId, int limit) async {
    return getTransactions(familyId: familyId, limit: limit);
  }

  Future<TransactionModel> addTransaction({
    required String familyId,
    required String type,
    required double amount,
    required DateTime date,
    String? categoryId,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser!.id;
    final data = {
      'family_id': familyId,
      'user_id': userId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description ?? '',
      'date': _dateStr(date),
    };

    final result = await _supabase
        .from('transactions')
        .insert(data)
        .select('*, categories(name, color, icon_name)')
        .maybeSingle();

    if (result != null) {
      return TransactionModel.fromMap(result);
    }

    // Fallback if select join returns null
    final fallback = await _supabase
        .from('transactions')
        .insert(data)
        .select()
        .single();
    return TransactionModel.fromMap(fallback);
  }

  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required DateTime date,
    String? categoryId,
    String? description,
  }) async {
    await _supabase.from('transactions').update({
      'type': type,
      'amount': amount,
      'date': _dateStr(date),
      'category_id': categoryId,
      'description': description ?? '',
    }).eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }

  /// Returns monthly summary for last [months] months.
  Future<List<Map<String, double>>> getMonthlySummary(
      String familyId, int months) async {
    final now = DateTime.now();
    final result = <Map<String, double>>[];

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final txns = await getTransactions(
        familyId: familyId,
        fromDate: firstDay,
        toDate: lastDay,
      );

      double income = 0;
      double expense = 0;
      for (final t in txns) {
        if (t.isIncome) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
      result.add({'income': income, 'expense': expense});
    }
    return result;
  }

  /// Returns spending by category for a date range.
  Future<Map<String, double>> getExpenseByCategory({
    required String familyId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final txns = await getTransactions(
      familyId: familyId,
      fromDate: fromDate,
      toDate: toDate,
      type: 'expense',
    );

    final map = <String, double>{};
    for (final t in txns) {
      final cat = t.displayCategory;
      map[cat] = (map[cat] ?? 0) + t.amount;
    }
    return map;
  }

  /// Total income for a given period.
  Future<double> getTotalIncome(
      String familyId, DateTime from, DateTime to) async {
    final txns = await getTransactions(
        familyId: familyId, fromDate: from, toDate: to, type: 'income');
    return txns.fold<double>(0.0, (s, t) => s + t.amount);
  }

  /// Total expense for a given period.
  Future<double> getTotalExpense(
      String familyId, DateTime from, DateTime to) async {
    final txns = await getTransactions(
        familyId: familyId, fromDate: from, toDate: to, type: 'expense');
    return txns.fold<double>(0.0, (s, t) => s + t.amount);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
