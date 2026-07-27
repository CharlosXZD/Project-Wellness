import 'dart:convert';
import 'dart:io';

/// Thrown when a pasted share code can't be decoded — always carries a
/// message safe to show directly to the user.
class ShareCodeException implements Exception {
  final String message;
  const ShareCodeException(this.message);

  @override
  String toString() => message;
}

/// Version prefixes so a decoder can tell what kind of code it received
/// (and reject garbage) before attempting the expensive decode.
class SharePrefix {
  static const day = 'PWD1.';
  static const split = 'PWS1.';
  static const fullBackup = 'PWF1.';
  static const combo = 'PWC1.';
  static const exercise = 'PWE1.';
  static const library = 'PWL1.';
}

/// Packs [json] into a compact, copy-paste-friendly string: JSON -> gzip ->
/// base64url (no padding), with a short prefix identifying the payload kind.
String encodePayload(Map<String, dynamic> json, String prefix) {
  final bytes = utf8.encode(jsonEncode(json));
  final compressed = GZipCodec().encode(bytes);
  return '$prefix${base64Url.encode(compressed)}';
}

/// Reverses [encodePayload]. Returns the prefix that was found and the
/// decoded JSON map. Throws [ShareCodeException] with a friendly message on
/// any malformed input.
({String prefix, Map<String, dynamic> json}) decodePayload(String code) {
  final trimmed = code.trim();
  final dotIndex = trimmed.indexOf('.');
  if (dotIndex == -1 || dotIndex + 1 >= trimmed.length) {
    throw const ShareCodeException('That code looks invalid or corrupted.');
  }

  final prefix = trimmed.substring(0, dotIndex + 1);
  final body = trimmed.substring(dotIndex + 1);

  try {
    final compressed = base64Url.decode(body);
    final bytes = GZipCodec().decode(compressed);
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    return (prefix: prefix, json: json);
  } catch (_) {
    throw const ShareCodeException('That code looks invalid or corrupted.');
  }
}
