import 'dart:math';

/// A user-defined folder that groups photos (e.g. a job site or inspection).
class Project {
  final String id;
  final String name;
  final int color; // ARGB
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  /// Palette offered when creating a project (ARGB).
  static const List<int> palette = [
    0xFF38BDF8, // sky (AppColors.primary)
    0xFF22C55E, // green
    0xFFF59E0B, // amber
    0xFFEF4444, // red
    0xFFA855F7, // purple
    0xFFEC4899, // pink
    0xFF14B8A6, // teal
    0xFFF97316, // orange
  ];

  /// Unique, sortable id without pulling in a uuid package.
  static String generateId() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = Random().nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
    return '$time$rand';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'color': color,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Project.fromMap(Map<String, dynamic> map) => Project(
        id: map['id'] as String,
        name: map['name'] as String,
        color: map['color'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Project copyWith({String? name, int? color}) => Project(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        createdAt: createdAt,
      );
}
