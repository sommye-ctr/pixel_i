class Validators {
  /// Validate email - Django RFC 5321 compliant pattern
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final pattern =
        r'^[a-zA-Z0-9.!#$%&'
        "'"
        r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$';
    final regex = RegExp(pattern);

    if (!regex.hasMatch(value)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Validate username - Django alphanumeric + underscore/hyphen
  /// Max 150 chars, must start with letter/underscore, no spaces
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length > 150) {
      return 'Username must be 150 characters or fewer';
    }

    const pattern = r'^[a-zA-Z_][a-zA-Z0-9_-]*$';
    final regex = RegExp(pattern);

    if (!regex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }

    return null;
  }

  /// Validate password - minimum 8 characters
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  /// Validate name - non-empty, reasonable length
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    if (value.length > 150) {
      return 'Name must be 150 characters or fewer';
    }

    return null;
  }
}
