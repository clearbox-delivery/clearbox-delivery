import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_data/core_data.dart';

/// Selected address state for current session
/// [customer_app_whitepaper.md Section 4.5] Address-based H3 ring filtering
class SelectedAddressNotifier extends StateNotifier<UserAddress?> {
  SelectedAddressNotifier() : super(null);

  void selectAddress(UserAddress address) {
    state = address;
  }

  void clearAddress() {
    state = null;
  }
}

final selectedAddressProvider =
    StateNotifierProvider<SelectedAddressNotifier, UserAddress?>((ref) {
  return SelectedAddressNotifier();
});

