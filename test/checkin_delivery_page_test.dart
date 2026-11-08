import 'package:bastion/checkin_delivery_page.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every delivery state has its own word and icon', () {
    final looks = [
      for (final s in [
        BastionDeliveryState.delivered,
        BastionDeliveryState.failed,
        BastionDeliveryState.sent,
        BastionDeliveryState.queued,
      ])
        deliveryLook(s),
    ];
    expect(looks.map((l) => l.word).toSet(), hasLength(4));
    expect(looks.map((l) => l.icon).toSet(), hasLength(4));
    expect(looks.first.tone, NxTone.success);
    expect(looks[1].tone, NxTone.danger);
    expect(Icons.check_circle, looks.first.icon);
  });
}
