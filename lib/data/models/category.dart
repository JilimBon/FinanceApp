class CategoryModel {
  final int? id;
  final String name;
  final int type; // 0 - доход, 1 - расход

  CategoryModel({this.id, required this.name, required this.type});

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id: map['id'] as int?,
    name: map['name'] as String,
    type: map['type'] as int,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
  };
}