/// Tracks whether RevenueCat was successfully configured at startup.
/// Only true if Purchases.configure() completed — guards all RC API calls.
class RevenueCatState {
  RevenueCatState._();
  static bool configured = false;
}
