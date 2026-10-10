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

// ignore: constant_identifier_names
enum EDirection { ASC, DESC }

class PageRequestDTO {
  static const int defaultPage = 0;
  static const int defaultSize = 10;
  static const int maxSize = 100;

  final int? page;
  final int? size;
  final String? sortBy;
  final EDirection? direction;

  const PageRequestDTO({this.page, this.size, this.sortBy, this.direction});

  int get validPage {
    return page != null && page! >= 0 ? page! : defaultPage;
  }

  int get validSize {
    return size != null && size! > 0 && size! <= maxSize ? size! : defaultSize;
  }

  String get sortDirection {
    return direction == EDirection.DESC ? 'DESC' : 'ASC';
  }

  bool get hasSorting {
    return sortBy != null && sortBy!.trim().isNotEmpty;
  }

  Map<String, dynamic> toMap() {
    return {
      'page': validPage,
      'size': validSize,
      if (hasSorting) 'sortBy': sortBy,
      if (hasSorting) 'direction': sortDirection,
    };
  }
}
