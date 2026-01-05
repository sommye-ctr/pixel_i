class PhotoShareResponse {
  final String token;
  final String photoId;
  final String variantKey;
  final DateTime? expiresAt;
  final String shareUrl;

  PhotoShareResponse({
    required this.token,
    required this.photoId,
    required this.variantKey,
    required this.expiresAt,
    required this.shareUrl,
  });

  factory PhotoShareResponse.fromMap(Map<String, dynamic> map) {
    return PhotoShareResponse(
      token: map['token'] as String,
      photoId: map['photo'] as String,
      variantKey: map['variant_key'] as String,
      expiresAt: map['expires_at'] != null
          ? DateTime.parse(map['expires_at'] as String)
          : null,
      shareUrl: map['share_url'] as String,
    );
  }
}
