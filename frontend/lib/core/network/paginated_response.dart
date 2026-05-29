class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromMap(
    Map<String, dynamic> map,
    T Function(Map<String, dynamic>) mapper,
  ) {
    return PaginatedResponse<T>(
      count: map['count'] as int? ?? 0,
      next: map['next'] as String?,
      previous: map['previous'] as String?,
      results:
          (map['results'] as List<dynamic>?)
              ?.map((item) => mapper(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
