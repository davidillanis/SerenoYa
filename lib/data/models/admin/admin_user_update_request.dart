class AdminUserUpdateRequest {
  const AdminUserUpdateRequest({
    required this.name,
    required this.lastName,
    required this.dni,
    required this.phone,
    required this.address,
    required this.enabled,
    required this.notificationsEnabled,
    this.birthDate,
    this.imageUrl,
  });

  final String name;
  final String lastName;
  final String dni;
  final String phone;
  final DateTime? birthDate;
  final String address;
  final String? imageUrl;
  final bool enabled;
  final bool notificationsEnabled;

  Map<String, dynamic> toJson() => {
    'name': _emptyToNull(name),
    'lastName': _emptyToNull(lastName),
    'dni': _emptyToNull(dni),
    'phone': _emptyToNull(phone),
    'birthDate': birthDate == null ? null : _dateOnly(birthDate!),
    'address': _emptyToNull(address),
    'imageUrl': _emptyToNull(imageUrl),
    'enabled': enabled,
    'notificationsEnabled': notificationsEnabled,
  };

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
