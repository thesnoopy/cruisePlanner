
import 'dart:convert';
import 'package:equatable/equatable.dart';

class WebDavSettings extends Equatable {
  /// z.B. https://host/remote.php/dav/files/USER/
  final String baseUrl;

  final String username;

  /// Wird verschlüsselt gespeichert (im Store), aber hier im Klartext gehalten.
  final String password;

  /// z.B. /CruiseApp/cruises.json
  final String remotePath;

  const WebDavSettings({
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.remotePath,
  });

  WebDavSettings copyWith({
    String? baseUrl,
    String? username,
    String? password,
    String? remotePath,
  }) {
    return WebDavSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'baseUrl': baseUrl,
      'username': username,
      'password': password,
      'remotePath': remotePath,
    };
  }

  factory WebDavSettings.fromMap(Map<String, dynamic> map) {
    return WebDavSettings(
      baseUrl: map['baseUrl'] as String? ?? '',
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      remotePath: map['remotePath'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WebDavSettings.fromJson(String s) =>
      WebDavSettings.fromMap(jsonDecode(s) as Map<String, dynamic>);

  bool get isEmpty =>
      baseUrl.isEmpty && username.isEmpty && password.isEmpty && remotePath.isEmpty;

  bool get isValid =>
      baseUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty && remotePath.isNotEmpty;

  @override
  List<Object?> get props => [baseUrl, username, password, remotePath];

  @override
  String toString() =>
      'WebDavSettings(baseUrl: $baseUrl, username: $username, remotePath: $remotePath, password: ***hidden***)';
}
