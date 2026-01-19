import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact.freezed.dart';
part 'contact.g.dart';

/// Contact model (placeholder for Phase 1)
@freezed
class Contact with _$Contact {
  const factory Contact({
    required String id,
    required String displayName,
    String? avatar,
  }) = _Contact;

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);
}
