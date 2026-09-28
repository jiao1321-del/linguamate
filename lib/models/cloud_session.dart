class CloudSession {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;

  const CloudSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
  });

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'email': email,
      };

  factory CloudSession.fromJson(Map<String, dynamic> json) {
    return CloudSession(
      accessToken: (json['accessToken'] as String? ?? '').trim(),
      refreshToken: (json['refreshToken'] as String? ?? '').trim(),
      userId: (json['userId'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
    );
  }

  bool get isValid =>
      accessToken.isNotEmpty &&
      refreshToken.isNotEmpty &&
      userId.isNotEmpty;
}
