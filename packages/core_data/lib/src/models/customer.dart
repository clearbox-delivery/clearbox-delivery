import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String name,
    String? email,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    
    /// Default delivery address
    @JsonKey(name: 'default_address') String? defaultAddress,
    
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) => 
    _$CustomerFromJson(json);
}


