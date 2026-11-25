/// Where something goes when it leaves this phone.
enum PrivacyRoute { internet, mesh, otherApps }

/// Whether it can leave right now.
enum PrivacyState { on, off, whenAsked }

/// Things the app can send off this phone.
enum PrivacyThing {
  mapTiles,
  placeSearch,
  terrain,
  trails,
  linkPreviews,
  mqttProxy,
  moderation,
  webhooks,
  location,
  tak,
  sms,
}

/// One row of the privacy dashboard.
class PrivacyItem {
  const PrivacyItem(this.thing, this.route, this.state, {this.canSwitch = false});
  final PrivacyThing thing;
  final PrivacyRoute route;
  final PrivacyState state;

  /// Whether the dashboard can turn it on or off directly.
  final bool canSwitch;
}

/// Everything that can leave the phone, with its current state. [sms] is
/// null in builds without the SMS relay.
List<PrivacyItem> privacyItems({
  required bool shareLocation,
  required bool mqttProxy,
  required bool linkPreviews,
  required bool moderation,
  required bool tak,
  bool? sms,
}) {
  PrivacyState s(bool on) => on ? PrivacyState.on : PrivacyState.off;
  return [
    const PrivacyItem(PrivacyThing.mapTiles, PrivacyRoute.internet, PrivacyState.whenAsked),
    const PrivacyItem(PrivacyThing.placeSearch, PrivacyRoute.internet, PrivacyState.whenAsked),
    const PrivacyItem(PrivacyThing.terrain, PrivacyRoute.internet, PrivacyState.whenAsked),
    const PrivacyItem(PrivacyThing.trails, PrivacyRoute.internet, PrivacyState.whenAsked),
    PrivacyItem(PrivacyThing.linkPreviews, PrivacyRoute.internet, s(linkPreviews), canSwitch: true),
    PrivacyItem(PrivacyThing.mqttProxy, PrivacyRoute.internet, s(mqttProxy), canSwitch: true),
    PrivacyItem(PrivacyThing.moderation, PrivacyRoute.internet, s(moderation), canSwitch: true),
    const PrivacyItem(PrivacyThing.webhooks, PrivacyRoute.internet, PrivacyState.whenAsked),
    PrivacyItem(PrivacyThing.location, PrivacyRoute.mesh, s(shareLocation), canSwitch: true),
    PrivacyItem(PrivacyThing.tak, PrivacyRoute.otherApps, s(tak)),
    if (sms != null) PrivacyItem(PrivacyThing.sms, PrivacyRoute.otherApps, s(sms), canSwitch: true),
  ];
}
