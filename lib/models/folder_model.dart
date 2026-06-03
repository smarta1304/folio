import 'package:equatable/equatable.dart';

class Folder extends Equatable {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const Folder({
    this.id,
    required this.name,
    required this.createdAt,
    this.expiresAt,
  });

  Folder copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, expiresAt];
}