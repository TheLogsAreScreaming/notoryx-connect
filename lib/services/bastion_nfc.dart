import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';

/// Writes an NDEF URI to the next NFC tag the user taps.
///
/// Only available on Android when NFC is enabled. On other platforms (or when
/// NFC is off), all calls are no-ops and [isAvailable] returns `false`.
abstract final class BastionNfc {
  static Future<bool> isAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final a = await NfcManager.instance.checkAvailability();
      return a == NfcAvailability.enabled;
    } catch (_) {
      return false;
    }
  }

  /// Puts the NFC stack into foreground-dispatch mode and writes [url] as a
  /// URI NDEF record to the first tag tapped. Calls [onDone] on success or
  /// [onError] with a reason string on failure. The session is stopped
  /// automatically on both outcomes.
  static Future<void> writeUri(
    String url, {
    required void Function(String reason) onError,
    required void Function() onDone,
  }) async {
    if (!await isAvailable()) {
      onError('unavailable');
      return;
    }
    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          try {
            final message = NdefMessage(records: [_uriRecord(url)]);
            final ndef = NdefAndroid.from(tag);
            if (ndef != null) {
              if (!ndef.isWritable) {
                await NfcManager.instance.stopSession();
                onError('readOnly');
                return;
              }
              await ndef.writeNdefMessage(message);
              await NfcManager.instance.stopSession();
              onDone();
              return;
            }
            final formatable = NdefFormatableAndroid.from(tag);
            if (formatable != null) {
              await formatable.format(message);
              await NfcManager.instance.stopSession();
              onDone();
              return;
            }
            await NfcManager.instance.stopSession();
            onError('notSupported');
          } catch (e) {
            await NfcManager.instance.stopSession();
            onError('$e');
          }
        },
      );
    } catch (e) {
      onError('$e');
    }
  }

  /// Cancels an in-progress write session without error.
  static Future<void> cancel() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}
  }

  // Encodes [url] as an NDEF URI (Well-Known / 'U') record.
  static NdefRecord _uriRecord(String url) {
    // URI identifier codes from NDEF URI Record Type Definition §3.2.2.
    const prefixes = [
      '', 'http://www.', 'https://www.', 'http://', 'https://',
      'tel:', 'mailto:', 'ftp://anonymous:anonymous@', 'ftp://ftp.',
      'ftps://', 'sftp://', 'smb://', 'nfs://', 'ftp://', 'dav://',
      'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:', 'pop:',
      'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://',
      'btgoep://', 'tcpobex://', 'irdaobex://', 'file://',
      'urn:epc:id:', 'urn:epc:tag:', 'urn:epc:pat:', 'urn:epc:raw:',
      'urn:epc:', 'urn:nfc:',
    ];
    int code = 0;
    String remaining = url;
    for (int i = 1; i < prefixes.length; i++) {
      if (url.startsWith(prefixes[i])) {
        code = i;
        remaining = url.substring(prefixes[i].length);
        break;
      }
    }
    final payload = Uint8List.fromList([code, ...utf8.encode(remaining)]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x55]), // 'U'
      identifier: Uint8List(0),
      payload: payload,
    );
  }
}
