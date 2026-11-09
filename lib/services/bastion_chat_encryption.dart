import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'bastion_chat_store.dart';

/// Where the chat key is kept. Separate so tests avoid the platform.
abstract interface class BastionKeyVault {
  Future<List<int>?> read();
  Future<void> write(List<int> key);
  Future<void> delete();
}

/// The phone's secure storage: Android Keystore or the Apple keychain.
class BastionSecureKeyVault implements BastionKeyVault {
  static const _name = 'bastion.chat_key';
  final _storage = const FlutterSecureStorage();

  @override
  Future<List<int>?> read() async {
    final value = await _storage.read(key: _name);
    return value == null ? null : base64Decode(value);
  }

  @override
  Future<void> write(List<int> key) => _storage.write(key: _name, value: base64Encode(key));

  @override
  Future<void> delete() => _storage.delete(key: _name);
}

/// Encrypts each archive with AES-256-GCM before it reaches [inner].
///
/// An encrypted archive is not JSON, so the SQLite store keeps it as one
/// opaque value and no message text or sender is left in a column. Archives
/// not yet encrypted still read normally, so an interrupted change is safe.
class EncryptedChatArchiveStore implements ChatArchiveStore {
  EncryptedChatArchiveStore(this.inner, List<int> key) : _key = SecretKey(key);

  static const marker = 'nxenc1:';
  static final _cipher = AesGcm.with256bits();

  final ChatArchiveStore inner;
  final SecretKey _key;

  static bool isEncrypted(String value) => value.startsWith(marker);

  // The archive name is authenticated, so one archive can't be swapped for another.
  @override
  Future<String?> read(String key) async {
    final stored = await inner.read(key);
    if (stored == null || !isEncrypted(stored)) return stored;
    final box = SecretBox.fromConcatenation(base64Decode(stored.substring(marker.length)),
        nonceLength: _cipher.nonceLength, macLength: _cipher.macAlgorithm.macLength);
    return utf8.decode(await _cipher.decrypt(box, secretKey: _key, aad: utf8.encode(key)));
  }

  @override
  Future<void> write(String key, String value) async {
    final box = await _cipher.encrypt(utf8.encode(value), secretKey: _key, aad: utf8.encode(key));
    await inner.write(key, '$marker${base64Encode(box.concatenation())}');
  }

  @override
  Future<void> remove(String key) => inner.remove(key);

  @override
  Future<Set<String>> keys() => inner.keys();
}

/// Used when history is encrypted but its key can't be read. Reads and
/// writes fail, so existing data is never replaced by an empty history.
class UnavailableChatArchiveStore implements ChatArchiveStore {
  const UnavailableChatArchiveStore();
  static Never _fail() => throw StateError('The key for encrypted chat history could not be read.');
  @override
  Future<String?> read(String key) async => _fail();
  @override
  Future<void> write(String key, String value) async => _fail();
  @override
  Future<void> remove(String key) async => _fail();
  @override
  Future<Set<String>> keys() async => _fail();
}
