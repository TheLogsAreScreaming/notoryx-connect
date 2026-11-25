import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/meshtastic_traceroute.dart';
import 'package:bastion/traceroute_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a route reads as one sentence, each step with its signal as a word', () async {
    final l = await AppLocalizations.delegate.load(const Locale('en'));
    String name(int n) => {1: 'Ridge Relay', 2: 'Camp'}[n]!;
    final text = routeInWords(l, 'Route there', 'This radio',
        const [TracerouteHop(1, 5), TracerouteHop(2, -12.5)], name);
    expect(text,
        'Route there: This radio to Ridge Relay, signal 5.0 dB, strong; Ridge Relay to Camp, signal -12.5 dB, weak.');
    expect(snrInWords(l, -4), '-4.0 dB, fair');
    expect(snrInWords(l, null), l.trcSnrUnknown);
    expect(routeInWords(l, 'Route back', 'Camp', const [], name), 'Route back: Camp.');
  });
}
