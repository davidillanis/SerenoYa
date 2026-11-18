class PoliceStation {
  const PoliceStation({
    required this.id,
    required this.name,
    required this.type,
    required this.district,
    required this.address,
    required this.mapQuery,
  });

  final String id;
  final String name;
  final String type;
  final String district;
  final String address;
  final String mapQuery;
}
