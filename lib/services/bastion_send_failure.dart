/// Why a direct message failed, in terms a person can act on, read from the
/// firmware's routing error code (Routing.Error in mesh.proto).
enum BastionSendFailure {
  /// Our radio has no public key for the recipient, so it can't encrypt.
  noKey,

  /// The recipient's radio doesn't have our public key.
  theyLackYourKey,

  /// The recipient's radio couldn't decrypt it (a key changed).
  keyMismatch,

  /// Our radio knows no way to reach them.
  noRoute,

  /// Sent, but nothing answered after the radio's retries.
  noReply,

  /// Too long for one packet.
  tooLong,

  /// Our radio reached its legal airtime limit.
  airtimeLimit,

  /// The channel doesn't exist on one of the radios.
  noChannel,

  /// Sent too often in a short time.
  rateLimited,

  /// The other radio refused it.
  rejected,

  /// Our radio couldn't transmit at all.
  radioError,

  /// A code this build doesn't know, e.g. from newer firmware.
  unknown;

  /// The cause for [code]; [unknown] for codes this build doesn't know.
  static BastionSendFailure fromCode(int code) => switch (code) {
        1 => noRoute, // NO_ROUTE
        2 => rejected, // GOT_NAK
        3 || 5 || 8 => noReply, // TIMEOUT, MAX_RETRANSMIT, NO_RESPONSE
        4 => radioError, // NO_INTERFACE
        6 => noChannel, // NO_CHANNEL
        7 => tooLong, // TOO_LARGE
        9 => airtimeLimit, // DUTY_CYCLE_LIMIT
        32 || 33 || 36 || 37 => rejected, // BAD_REQUEST, NOT_AUTHORIZED, admin
        34 => keyMismatch, // PKI_FAILED
        35 => theyLackYourKey, // PKI_UNKNOWN_PUBKEY
        38 => rateLimited, // RATE_LIMIT_EXCEEDED
        39 => noKey, // PKI_SEND_FAIL_PUBLIC_KEY
        _ => unknown,
      };
}
