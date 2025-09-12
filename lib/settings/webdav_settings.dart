import 'dart:convert';
import 'package:equatable/equatable.dart';

class WebDavSettings extends Equatable {
  final String baseUrl;    // z.B. https://host/remote.php/dav/files/USER/
  final String username;
  final String password;
  final String remotePath; // z.B. /CruiseApp/cruises.json

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

  Map<String, dynamic> toMap() => {
    'baseUrl': baseUrl,
    'username': username,
    'password': password,
    'remotePath': remotePath,
  };

  factory WebDavSettings.fromMap(Map<String, dynamic> map) {
    return WebDavSettings(
      baseUrl: (map['baseUrl'] as String).trim(),
      username: (map['username'] as String).trim(),
      password: map['password'] as String,
      remotePath: (map['remotePath'] as String).trim(),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory WebDavSettings.fromJson(String s) =>
      WebDavSettings.fromMap(jsonDecode(s) as Map<String, dynamic>);

  @override
  List<Object?> get props => [baseUrl, username, password, remotePath];

  @override
  String toString() =>
      'WebDavSettings(baseUrl: $baseUrl, username: $username, remotePath: $remotePath, password: ***hidden***)';
}
