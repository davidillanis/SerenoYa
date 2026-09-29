class PageResponse<T> {
  const PageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory PageResponse.fromJson(
    Object? value,
    T Function(Map<String, dynamic> json) decodeItem,
  ) {
    if (value is! Map) {
      throw const FormatException('La API devolvió una página inválida.');
    }

    final json = Map<String, dynamic>.from(value);
    final rawContent = json['content'];
    if (rawContent is! List) {
      throw const FormatException('La página no contiene una lista válida.');
    }

    return PageResponse<T>(
      content: rawContent
          .map((item) {
            if (item is! Map) {
              throw const FormatException(
                'La página contiene un elemento inválido.',
              );
            }
            return decodeItem(Map<String, dynamic>.from(item));
          })
          .toList(growable: false),
      page: _readInt(json['page']),
      size: _readInt(json['size']),
      totalElements: _readInt(json['totalElements']),
      totalPages: _readInt(json['totalPages']),
    );
  }

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
