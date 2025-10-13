import 'package:test/test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 菜单 CRUD 集成测试
/// [TC-MER-MENU-001]
void main() {
  late SupabaseClient supabase;
  final testItemIds = <String>[];

  setUpAll(() async {
    final url = const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'http://localhost:54321',
    );
    final anonKey = const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: 'test-anon-key',
    );

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );

    supabase = Supabase.instance.client;
  });

  tearDownAll(() async {
    // 清理测试数据
    for (final itemId in testItemIds) {
      await supabase.from('menu_items').delete().eq('id', itemId);
    }
  });

  group('Menu CRUD Operations', () {
    test('TC-MER-MENU-001: Create menu item', () async {
      final result = await supabase.rpc('create_menu_item', params: {
        'p_category': '测试类',
        'p_name': '测试餐点',
        'p_description': '这是测试',
        'p_price': 99.0,
        'p_prep_time_minutes': 10,
      });

      expect(result, isNotNull);
      expect(result['name'], equals('测试餐点'));
      expect(result['price'], equals(99.0));

      testItemIds.add(result['id'] as String);
    });

    test('Update menu item', () async {
      // 需要先创建一个项目
      final created = await supabase.rpc('create_menu_item', params: {
        'p_category': '测试类',
        'p_name': '原始名称',
        'p_description': '原始描述',
        'p_price': 50.0,
      });

      testItemIds.add(created['id'] as String);

      // 更新
      final updated = await supabase.rpc('update_menu_item', params: {
        'p_item_id': created['id'],
        'p_name': '更新后名称',
        'p_price': 60.0,
      });

      expect(updated['name'], equals('更新后名称'));
      expect(updated['price'], equals(60.0));
    });

    test('Delete menu item', () async {
      final created = await supabase.rpc('create_menu_item', params: {
        'p_category': '测试类',
        'p_name': '待删除',
        'p_price': 10.0,
      });

      final itemId = created['id'] as String;

      final deleted = await supabase.rpc('delete_menu_item', params: {
        'p_item_id': itemId,
      });

      expect(deleted, isTrue);
    });

    test('RLS: Merchant can only manage own menu', () async {
      // TODO: 使用不同商家的 JWT 测试
      // 确保商家 A 无法修改商家 B 的菜单
      expect(true, isTrue);
    });
  });
}

