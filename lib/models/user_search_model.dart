class UserSearchResult {
  final int id;
  final String name;
  final String email;

  UserSearchResult({
    required this.id,
    required this.name,
    required this.email,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}
