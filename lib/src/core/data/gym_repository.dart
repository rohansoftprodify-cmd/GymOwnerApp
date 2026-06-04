import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GymRepository {
  GymRepository(this._client);
  final SupabaseClient _client;

  Future<T> _logApiCall<T>({
    required String action,
    required Object? request,
    required Future<T> Function() run,
  }) async {
    final startedAt = DateTime.now();
    debugPrint('[API][REQ] $action -> ${_stringify(request)}');
    try {
      final response = await run();
      final duration = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint('[API][RES] $action <- ${_stringify(response)} (${duration}ms)');
      return response;
    } catch (error, stackTrace) {
      final duration = DateTime.now().difference(startedAt).inMilliseconds;
      debugPrint('[API][ERR] $action <- $error (${duration}ms)');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  String _stringify(Object? value) {
    if (value == null) return 'null';
    if (value is Map || value is List) {
      final encoded = jsonEncode(value);
      return encoded.length > 1200 ? '${encoded.substring(0, 1200)}...(truncated)' : encoded;
    }
    final text = value.toString();
    return text.length > 1200 ? '${text.substring(0, 1200)}...(truncated)' : text;
  }

  /// Omit null `id` so Postgres can apply `default gen_random_uuid()` on insert.
  Map<String, dynamic> _upsertPayload(Map<String, dynamic> row) {
    if (row['id'] != null) return row;
    final payload = Map<String, dynamic>.from(row);
    payload.remove('id');
    return payload;
  }

  Future<void> upsertMember({
    required String gymId,
    String? memberId,
    required String fullName,
    required String phone,
    String? email,
    String? status,
    String? emergencyContact,
    String? notes,
    DateTime? dateOfBirth,
  }) async {
    await _logApiCall(
      action: 'members.upsert',
      request: {'id': memberId, 'gym_id': gymId, 'full_name': fullName, 'phone': phone, 'email': email},
      run: () => _client.from('members').upsert(_upsertPayload({
        'id': memberId,
        'gym_id': gymId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        if (status != null) 'status': status,
        if (emergencyContact != null) 'emergency_contact': emergencyContact,
        if (notes != null) 'notes': notes,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
      })),
    );
  }

  Future<Map<String, dynamic>> memberDetail(String gymId, String memberId) async {
    final row = await _logApiCall(
      action: 'members.select.detail',
      request: {'gym_id': gymId, 'id': memberId},
      run: () => _client
          .from('members')
          .select(
            'id, full_name, email, phone, status, joined_on, user_id, date_of_birth, emergency_contact, notes, member_subscriptions(id, plan_id, start_date, end_date, payment_status, amount_paid, status, subscription_plans(id, name, price, duration_days))',
          )
          .eq('gym_id', gymId)
          .eq('id', memberId)
          .single(),
    );
    return row;
  }

  Future<List<Map<String, dynamic>>> members(String gymId) async {
    final rows = await _logApiCall(
      action: 'members.select',
      request: {'gym_id': gymId},
      run: () => _client.from('members').select().eq('gym_id', gymId).order('created_at'),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> membersWithSubscriptions(String gymId) async {
    final rows = await _logApiCall(
      action: 'members.select_with_subscriptions',
      request: {'gym_id': gymId},
      run: () => _client
          .from('members')
          .select(
            'id, full_name, email, phone, status, joined_on, user_id, member_subscriptions(id, start_date, end_date, payment_status, status, subscription_plans(name, price))',
          )
          .eq('gym_id', gymId)
          .order('created_at', ascending: false),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createMemberAccount({
    required String gymId,
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String planId,
    required DateTime startDate,
    String paymentStatus = 'due',
    double amountPaid = 0,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? notes,
  }) async {
    final response = await _logApiCall(
      action: 'functions.create-gym-member',
      request: {
        'gym_id': gymId,
        'full_name': fullName,
        'email': email,
        'plan_id': planId,
      },
      run: () => _client.functions.invoke(
        'create-gym-member',
        body: {
          'gym_id': gymId,
          'full_name': fullName,
          'phone': phone,
          'email': email.trim().toLowerCase(),
          'password': password,
          'plan_id': planId,
          'start_date': startDate.toIso8601String().substring(0, 10),
          'payment_status': paymentStatus,
          'amount_paid': amountPaid,
          if (dateOfBirth != null)
            'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
          'emergency_contact': emergencyContact,
          'notes': notes,
        },
      ),
    );

    final data = response.data;
    if (response.status != 200 || data is! Map<String, dynamic>) {
      final message = data is Map<String, dynamic>
          ? data['error'] as String? ?? 'Failed to create member account.'
          : 'Failed to create member account.';
      throw Exception(message);
    }
    return data;
  }

  Future<Map<String, dynamic>> resetMemberPassword({
    required String gymId,
    required String memberId,
    required String password,
  }) async {
    return _invokeFunction(
      functionName: 'reset-gym-member-password',
      action: 'functions.reset-gym-member-password',
      body: {
        'gym_id': gymId,
        'member_id': memberId,
        'password': password,
      },
      defaultError: 'Failed to reset password.',
    );
  }

  Future<Map<String, dynamic>> provisionMemberLogin({
    required String gymId,
    required String memberId,
    required String password,
    String? email,
  }) async {
    return _invokeFunction(
      functionName: 'provision-gym-member-login',
      action: 'functions.provision-gym-member-login',
      body: {
        'gym_id': gymId,
        'member_id': memberId,
        'password': password,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim().toLowerCase(),
      },
      defaultError: 'Failed to create app login.',
    );
  }

  Future<Map<String, dynamic>> _invokeFunction({
    required String functionName,
    required String action,
    required Map<String, dynamic> body,
    required String defaultError,
  }) async {
    final response = await _logApiCall(
      action: action,
      request: body,
      run: () => _client.functions.invoke(functionName, body: body),
    );

    final data = response.data;
    if (response.status != 200 || data is! Map<String, dynamic>) {
      final message = data is Map<String, dynamic>
          ? data['error'] as String? ?? defaultError
          : defaultError;
      throw Exception(message);
    }
    return data;
  }

  Future<List<Map<String, dynamic>>> attendance(String gymId, {int limit = 100}) async {
    final rows = await _logApiCall(
      action: 'attendance_records.select',
      request: {'gym_id': gymId, 'limit': limit},
      run: () => _client
          .from('attendance_records')
          .select('id, member_id, check_in_at, check_out_at, members(full_name, phone)')
          .eq('gym_id', gymId)
          .order('check_in_at', ascending: false)
          .limit(limit),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> markAttendance({
    required String gymId,
    required String memberId,
    required String action,
  }) async {
    await _logApiCall(
      action: 'rpc.mark_attendance',
      request: {'p_member_id': memberId, 'p_gym_id': gymId, 'p_action': action},
      run: () => _client.rpc('mark_attendance', params: {
        'p_member_id': memberId,
        'p_gym_id': gymId,
        'p_action': action,
      }),
    );
  }

  Future<void> upsertPlan({
    required String gymId,
    String? id,
    required String name,
    String? description,
    required int durationDays,
    required double price,
    bool isActive = true,
  }) async {
    await _logApiCall(
      action: 'subscription_plans.upsert',
      request: {
        'id': id,
        'gym_id': gymId,
        'name': name,
        'description': description,
        'duration_days': durationDays,
        'price': price,
        'is_active': isActive,
      },
      run: () => _client.from('subscription_plans').upsert(_upsertPayload({
        'id': id,
        'gym_id': gymId,
        'name': name,
        'description': description,
        'duration_days': durationDays,
        'price': price,
        'is_active': isActive,
      })),
    );
  }

  Future<void> setPlanActive({
    required String gymId,
    required String planId,
    required bool isActive,
  }) async {
    await _logApiCall(
      action: 'subscription_plans.update.is_active',
      request: {'gym_id': gymId, 'id': planId, 'is_active': isActive},
      run: () => _client
          .from('subscription_plans')
          .update({'is_active': isActive})
          .eq('gym_id', gymId)
          .eq('id', planId),
    );
  }

  Future<List<Map<String, dynamic>>> plans(String gymId) async {
    final rows = await _logApiCall(
      action: 'subscription_plans.select',
      request: {'gym_id': gymId},
      run: () => _client
          .from('subscription_plans')
          .select('id, name, description, duration_days, price, is_active, created_at')
          .eq('gym_id', gymId)
          .order('is_active', ascending: false)
          .order('created_at', ascending: false),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> createSubscription({
    required String gymId,
    required String memberId,
    required String planId,
    required DateTime startDate,
    String paymentStatus = 'due',
    double amountPaid = 0,
  }) async {
    final plans = await _logApiCall(
      action: 'subscription_plans.select.single',
      request: {'gym_id': gymId, 'id': planId},
      run: () => _client.from('subscription_plans').select('duration_days').eq('gym_id', gymId).eq('id', planId).single(),
    );
    final duration = plans['duration_days'] as int;
    final endDate = startDate.add(Duration(days: duration));
    await _logApiCall(
      action: 'member_subscriptions.insert',
      request: {
        'gym_id': gymId,
        'member_id': memberId,
        'plan_id': planId,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'end_date': endDate.toIso8601String().substring(0, 10),
        'payment_status': paymentStatus,
        'amount_paid': amountPaid,
      },
      run: () => _client.from('member_subscriptions').insert({
        'gym_id': gymId,
        'member_id': memberId,
        'plan_id': planId,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'end_date': endDate.toIso8601String().substring(0, 10),
        'payment_status': paymentStatus,
        'amount_paid': amountPaid,
      }),
    );
  }

  Future<void> upsertMemberSubscription({
    required String gymId,
    required String memberId,
    String? subscriptionId,
    required String planId,
    required DateTime startDate,
    required String paymentStatus,
    required double amountPaid,
    String subscriptionStatus = 'active',
  }) async {
    final plan = await _logApiCall(
      action: 'subscription_plans.select.single',
      request: {'gym_id': gymId, 'id': planId},
      run: () => _client
          .from('subscription_plans')
          .select('duration_days')
          .eq('gym_id', gymId)
          .eq('id', planId)
          .single(),
    );
    final duration = plan['duration_days'] as int;
    final endDate = startDate.add(Duration(days: duration));
    final payload = {
      'gym_id': gymId,
      'member_id': memberId,
      'plan_id': planId,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'payment_status': paymentStatus,
      'amount_paid': amountPaid,
      'status': subscriptionStatus,
    };

    if (subscriptionId != null) {
      await _logApiCall(
        action: 'member_subscriptions.update',
        request: {'id': subscriptionId, 'plan_id': planId},
        run: () => _client
            .from('member_subscriptions')
            .update(payload)
            .eq('gym_id', gymId)
            .eq('id', subscriptionId),
      );
    } else {
      await _logApiCall(
        action: 'member_subscriptions.insert',
        request: payload,
        run: () => _client.from('member_subscriptions').insert(payload),
      );
    }
  }

  Future<List<Map<String, dynamic>>> subscriptions(String gymId) async {
    final rows = await _logApiCall(
      action: 'member_subscriptions.select',
      request: {'gym_id': gymId},
      run: () => _client
          .from('member_subscriptions')
          .select(
            'id, start_date, end_date, payment_status, amount_paid, members(full_name), subscription_plans(name, price)',
          )
          .eq('gym_id', gymId)
          .order('created_at', ascending: false),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> upsertCategory({
    required String gymId,
    String? id,
    required String name,
    int sortOrder = 0,
  }) async {
    await _logApiCall(
      action: 'product_categories.upsert',
      request: {'id': id, 'gym_id': gymId, 'name': name, 'sort_order': sortOrder},
      run: () => _client.from('product_categories').upsert(_upsertPayload({
        'id': id,
        'gym_id': gymId,
        'name': name,
        'sort_order': sortOrder,
      })),
    );
  }

  Future<List<Map<String, dynamic>>> categories(String gymId) async {
    final rows = await _logApiCall(
      action: 'product_categories.select',
      request: {'gym_id': gymId},
      run: () => _client
          .from('product_categories')
          .select()
          .eq('gym_id', gymId)
          .order('sort_order')
          .order('name'),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> upsertProduct({
    required String gymId,
    required String categoryId,
    String? id,
    required String name,
    required double price,
    required int stockQty,
  }) async {
    await _logApiCall(
      action: 'products.upsert',
      request: {
        'id': id,
        'gym_id': gymId,
        'category_id': categoryId,
        'name': name,
        'price': price,
        'stock_qty': stockQty,
      },
      run: () => _client.from('products').upsert(_upsertPayload({
        'id': id,
        'gym_id': gymId,
        'category_id': categoryId,
        'name': name,
        'price': price,
        'stock_qty': stockQty,
      })),
    );
  }

  Future<List<Map<String, dynamic>>> products(String gymId, {String? categoryId}) async {
    var query = _client.from('products').select().eq('gym_id', gymId);
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    final rows = await _logApiCall(
      action: 'products.select',
      request: {'gym_id': gymId, 'category_id': categoryId},
      run: () => query.order('name'),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> createSale({
    required String gymId,
    String? memberId,
    required String soldBy,
    required String productId,
    required int qty,
  }) async {
    final product = await _logApiCall(
      action: 'products.select.single',
      request: {'id': productId},
      run: () => _client.from('products').select('price, stock_qty').eq('id', productId).single(),
    );
    final unitPrice = (product['price'] as num).toDouble();
    final stockQty = product['stock_qty'] as int;
    if (qty > stockQty) {
      throw Exception('Not enough stock');
    }
    final total = qty * unitPrice;
    final order = await _logApiCall(
      action: 'sales_orders.insert',
      request: {'gym_id': gymId, 'member_id': memberId, 'sold_by': soldBy, 'total_amount': total},
      run: () => _client
          .from('sales_orders')
          .insert({'gym_id': gymId, 'member_id': memberId, 'sold_by': soldBy, 'total_amount': total})
          .select('id')
          .single(),
    );
    await _logApiCall(
      action: 'sales_order_items.insert',
      request: {
        'gym_id': gymId,
        'order_id': order['id'],
        'product_id': productId,
        'qty': qty,
        'unit_price': unitPrice,
        'line_total': total,
      },
      run: () => _client.from('sales_order_items').insert({
        'gym_id': gymId,
        'order_id': order['id'],
        'product_id': productId,
        'qty': qty,
        'unit_price': unitPrice,
        'line_total': total,
      }),
    );
    await _logApiCall(
      action: 'products.update.stock_qty',
      request: {'id': productId, 'stock_qty': stockQty - qty},
      run: () => _client.from('products').update({'stock_qty': stockQty - qty}).eq('id', productId),
    );
  }

  Future<void> upsertPromotion({
    required String gymId,
    String? id,
    required String title,
    required String description,
    required DateTime startAt,
    required DateTime endAt,
    bool isActive = true,
  }) async {
    await _logApiCall(
      action: 'promotions.upsert',
      request: {
        'id': id,
        'gym_id': gymId,
        'title': title,
        'description': description,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'is_active': isActive,
      },
      run: () => _client.from('promotions').upsert(_upsertPayload({
        'id': id,
        'gym_id': gymId,
        'title': title,
        'description': description,
        'start_at': startAt.toIso8601String(),
        'end_at': endAt.toIso8601String(),
        'is_active': isActive,
      })),
    );
  }

  Future<void> setPromotionActive({
    required String gymId,
    required String promotionId,
    required bool isActive,
  }) async {
    await _logApiCall(
      action: 'promotions.update.is_active',
      request: {'gym_id': gymId, 'id': promotionId, 'is_active': isActive},
      run: () => _client
          .from('promotions')
          .update({'is_active': isActive})
          .eq('gym_id', gymId)
          .eq('id', promotionId),
    );
  }

  Future<Map<String, dynamic>?> gymById(String gymId) async {
    final row = await _logApiCall(
      action: 'gyms.select.single',
      request: {'id': gymId},
      run: () => _client
          .from('gyms')
          .select('id, name, email, phone, address, timezone, currency_code')
          .eq('id', gymId)
          .maybeSingle(),
    );
    if (row == null) return null;
    return row;
  }

  Future<Map<String, dynamic>?> currentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _logApiCall(
      action: 'profiles.select.single',
      request: {'id': userId},
      run: () => _client.from('profiles').select('full_name, phone').eq('id', userId).maybeSingle(),
    );
    if (row == null) return null;
    return row;
  }

  Future<List<Map<String, dynamic>>> operatingHours(String gymId) async {
    final rows = await _logApiCall(
      action: 'gym_operating_hours.select',
      request: {'gym_id': gymId},
      run: () => _client
          .from('gym_operating_hours')
          .select('id, day_of_week, is_closed, open_time, close_time')
          .eq('gym_id', gymId)
          .order('day_of_week', ascending: true),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> saveOperatingHours({
    required String gymId,
    required List<Map<String, dynamic>> rows,
  }) async {
    await _logApiCall(
      action: 'gym_operating_hours.upsert',
      request: {'gym_id': gymId, 'count': rows.length},
      run: () => _client.from('gym_operating_hours').upsert(
            rows,
            onConflict: 'gym_id,day_of_week',
          ),
    );
  }

  Future<void> updateGymTimezone({
    required String gymId,
    required String timezone,
  }) async {
    await _logApiCall(
      action: 'gyms.update.timezone',
      request: {'id': gymId, 'timezone': timezone},
      run: () => _client.from('gyms').update({'timezone': timezone}).eq('id', gymId),
    );
  }

  Future<List<Map<String, dynamic>>> promotions(String gymId) async {
    final rows = await _logApiCall(
      action: 'promotions.select',
      request: {'gym_id': gymId},
      run: () => _client
          .from('promotions')
          .select('id, title, description, start_at, end_at, is_active, created_at')
          .eq('gym_id', gymId)
          .order('is_active', ascending: false)
          .order('start_at', ascending: false),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  /// Offers visible on home: active flag set and current time within start/end.
  Future<List<Map<String, dynamic>>> activePromotions(String gymId) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = await _logApiCall(
      action: 'promotions.select.active',
      request: {'gym_id': gymId, 'now': now},
      run: () => _client
          .from('promotions')
          .select('id, title, description, start_at, end_at, is_active')
          .eq('gym_id', gymId)
          .eq('is_active', true)
          .lte('start_at', now)
          .gte('end_at', now)
          .order('end_at', ascending: true),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  static const String exerciseImagesBucket = 'exercise-images';

  Future<List<Map<String, dynamic>>> exerciseCategories(String gymId) async {
    final rows = await _logApiCall(
      action: 'exercise_categories.select',
      request: {'gym_id': gymId},
      run: () => _client
          .from('exercise_categories')
          .select('id, name, sort_order')
          .eq('gym_id', gymId)
          .order('sort_order', ascending: true)
          .order('name', ascending: true),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> upsertExerciseCategory({
    required String gymId,
    required String name,
    int sortOrder = 0,
  }) async {
    await _logApiCall(
      action: 'exercise_categories.upsert',
      request: {'gym_id': gymId, 'name': name, 'sort_order': sortOrder},
      run: () => _client.from('exercise_categories').upsert({
        'gym_id': gymId,
        'name': name,
        'sort_order': sortOrder,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> exercises(
    String gymId, {
    String? categoryId,
  }) async {
    var query = _client
        .from('exercises')
        .select(
          'id, name, image_path, benefits, precautions, default_sets, default_reps, is_active, category_id, exercise_categories(name)',
        )
        .eq('gym_id', gymId);
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    final rows = await _logApiCall(
      action: 'exercises.select',
      request: {'gym_id': gymId, 'category_id': categoryId},
      run: () => query.order('is_active', ascending: false).order('name', ascending: true),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upsertExercise({
    required String gymId,
    String? id,
    required String categoryId,
    required String name,
    String? imagePath,
    String? benefits,
    String? precautions,
    required int defaultSets,
    required int defaultReps,
    bool isActive = true,
  }) async {
    final row = await _logApiCall(
      action: 'exercises.upsert',
      request: {'gym_id': gymId, 'id': id, 'name': name},
      run: () => _client
          .from('exercises')
          .upsert(_upsertPayload({
            'id': id,
            'gym_id': gymId,
            'category_id': categoryId,
            'name': name,
            'image_path': imagePath,
            'benefits': benefits,
            'precautions': precautions,
            'default_sets': defaultSets,
            'default_reps': defaultReps,
            'is_active': isActive,
          }))
          .select('id')
          .single(),
    );
    return row;
  }

  Future<void> setExerciseActive({
    required String gymId,
    required String exerciseId,
    required bool isActive,
  }) async {
    await _logApiCall(
      action: 'exercises.update.is_active',
      request: {'gym_id': gymId, 'id': exerciseId, 'is_active': isActive},
      run: () => _client
          .from('exercises')
          .update({'is_active': isActive})
          .eq('gym_id', gymId)
          .eq('id', exerciseId),
    );
  }

  Future<String> uploadExerciseImage({
    required String gymId,
    required String exerciseId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = '$gymId/$exerciseId.jpg';
    await _logApiCall(
      action: 'storage.exercise-images.upload',
      request: {'path': path, 'bytes': bytes.length},
      run: () => _client.storage.from(exerciseImagesBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          ),
    );
    return path;
  }

  String? exerciseImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    return _client.storage.from(exerciseImagesBucket).getPublicUrl(imagePath);
  }

  static const String dietImagesBucket = 'diet-images';

  Future<List<Map<String, dynamic>>> dietPlanCategories(String gymId) async {
    final rows = await _logApiCall(
      action: 'diet_plan_categories.select',
      request: {'gym_id': gymId},
      run: () => _client
          .from('diet_plan_categories')
          .select('id, goal_key, name, description, nutrition_tips, sort_order')
          .eq('gym_id', gymId)
          .order('sort_order', ascending: true),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> upsertDietPlanCategory({
    required String gymId,
    required String goalKey,
    required String name,
    String? description,
    String? nutritionTips,
    int sortOrder = 0,
  }) async {
    await _logApiCall(
      action: 'diet_plan_categories.upsert',
      request: {'gym_id': gymId, 'goal_key': goalKey},
      run: () => _client.from('diet_plan_categories').upsert({
        'gym_id': gymId,
        'goal_key': goalKey,
        'name': name,
        'description': description,
        'nutrition_tips': nutritionTips,
        'sort_order': sortOrder,
      }, onConflict: 'gym_id,goal_key'),
    );
  }

  Future<void> ensureDefaultDietCategories(String gymId) async {
    const defaults = [
      (
        'weight_loss',
        'Weight Loss',
        'Fat loss with muscle preservation — moderate deficit and high protein.',
        'Aim ~300–500 kcal below maintenance; protein ~1.6–2.2 g/kg.',
        1,
      ),
      (
        'muscle_gain',
        'Muscle Gain',
        'Lean mass focus — controlled surplus with training-aligned carbs.',
        'Aim ~250–500 kcal above maintenance; protein ~1.8–2.4 g/kg.',
        2,
      ),
      (
        'healthy',
        'Healthy Lifestyle',
        'Balanced maintenance nutrition for energy and long-term health.',
        'Eat near maintenance; protein ~1.2–1.6 g/kg; whole foods first.',
        3,
      ),
    ];
    for (final (key, name, description, tips, order) in defaults) {
      await upsertDietPlanCategory(
        gymId: gymId,
        goalKey: key,
        name: name,
        description: description,
        nutritionTips: tips,
        sortOrder: order,
      );
    }
  }

  Future<List<Map<String, dynamic>>> dietPlans(
    String gymId, {
    String? categoryId,
  }) async {
    var query = _client
        .from('diet_plans')
        .select(
          'id, name, description, image_path, target_calories, target_protein_g, target_carbs_g, target_fat_g, hydration_liters, duration_days, is_active, category_id, diet_plan_categories(name, goal_key)',
        )
        .eq('gym_id', gymId);
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    final rows = await _logApiCall(
      action: 'diet_plans.select',
      request: {'gym_id': gymId, 'category_id': categoryId},
      run: () => query.order('is_active', ascending: false).order('name', ascending: true),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upsertDietPlan({
    required String gymId,
    String? id,
    required String categoryId,
    required String name,
    String? description,
    String? imagePath,
    int? targetCalories,
    double? targetProteinG,
    double? targetCarbsG,
    double? targetFatG,
    double? hydrationLiters,
    int durationDays = 7,
    bool isActive = true,
  }) async {
    final row = await _logApiCall(
      action: 'diet_plans.upsert',
      request: {'gym_id': gymId, 'name': name},
      run: () => _client
          .from('diet_plans')
          .upsert(_upsertPayload({
            'id': id,
            'gym_id': gymId,
            'category_id': categoryId,
            'name': name,
            'description': description,
            'image_path': imagePath,
            'target_calories': targetCalories,
            'target_protein_g': targetProteinG,
            'target_carbs_g': targetCarbsG,
            'target_fat_g': targetFatG,
            'hydration_liters': hydrationLiters,
            'duration_days': durationDays,
            'is_active': isActive,
          }))
          .select('id')
          .single(),
    );
    return row;
  }

  Future<void> setDietPlanActive({
    required String gymId,
    required String planId,
    required bool isActive,
  }) async {
    await _logApiCall(
      action: 'diet_plans.update.is_active',
      request: {'gym_id': gymId, 'id': planId},
      run: () => _client
          .from('diet_plans')
          .update({'is_active': isActive})
          .eq('gym_id', gymId)
          .eq('id', planId),
    );
  }

  Future<List<Map<String, dynamic>>> dietMeals(String gymId, String planId) async {
    final rows = await _logApiCall(
      action: 'diet_meals.select',
      request: {'gym_id': gymId, 'diet_plan_id': planId},
      run: () => _client
          .from('diet_meals')
          .select('id, meal_label, meal_time, guidance, sort_order, diet_food_items(*)')
          .eq('gym_id', gymId)
          .eq('diet_plan_id', planId)
          .order('sort_order', ascending: true),
    );
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> upsertDietMeal({
    required String gymId,
    required String planId,
    String? id,
    required String mealLabel,
    String? mealTime,
    String? guidance,
    int sortOrder = 0,
  }) async {
    final row = await _logApiCall(
      action: 'diet_meals.upsert',
      request: {'diet_plan_id': planId, 'meal_label': mealLabel},
      run: () => _client
          .from('diet_meals')
          .upsert(_upsertPayload({
            'id': id,
            'gym_id': gymId,
            'diet_plan_id': planId,
            'meal_label': mealLabel,
            'meal_time': mealTime,
            'guidance': guidance,
            'sort_order': sortOrder,
          }))
          .select('id')
          .single(),
    );
    return row;
  }

  Future<void> deleteDietMeal({
    required String gymId,
    required String mealId,
  }) async {
    await _logApiCall(
      action: 'diet_meals.delete',
      request: {'id': mealId},
      run: () => _client.from('diet_meals').delete().eq('gym_id', gymId).eq('id', mealId),
    );
  }

  Future<void> upsertDietFoodItem(Map<String, dynamic> row) async {
    await _logApiCall(
      action: 'diet_food_items.upsert',
      request: row,
      run: () => _client.from('diet_food_items').upsert(_upsertPayload(row)),
    );
  }

  Future<void> deleteDietFoodItem({
    required String gymId,
    required String foodId,
  }) async {
    await _logApiCall(
      action: 'diet_food_items.delete',
      request: {'id': foodId},
      run: () => _client.from('diet_food_items').delete().eq('gym_id', gymId).eq('id', foodId),
    );
  }

  Future<String> uploadDietImage({
    required String gymId,
    required String planId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = '$gymId/$planId.jpg';
    await _logApiCall(
      action: 'storage.diet-images.upload',
      request: {'path': path},
      run: () => _client.storage.from(dietImagesBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          ),
    );
    return path;
  }

  String? dietImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    return _client.storage.from(dietImagesBucket).getPublicUrl(imagePath);
  }

  Future<Map<String, dynamic>> reports(String gymId) async {
    final attendanceRows = await _logApiCall(
      action: 'report_attendance_daily.select',
      request: {'gym_id': gymId, 'limit': 30},
      run: () => _client.from('report_attendance_daily').select().eq('gym_id', gymId).limit(30),
    );
    final duesRows = await _logApiCall(
      action: 'report_dues_summary.select',
      request: {'gym_id': gymId, 'limit': 1},
      run: () => _client.from('report_dues_summary').select().eq('gym_id', gymId).limit(1),
    );
    final salesRows = await _logApiCall(
      action: 'report_sales_daily.select',
      request: {'gym_id': gymId, 'limit': 30},
      run: () => _client.from('report_sales_daily').select().eq('gym_id', gymId).limit(30),
    );
    return {
      'attendance': attendanceRows,
      'dues': duesRows.isEmpty ? null : duesRows.first,
      'sales': salesRows,
    };
  }
}
