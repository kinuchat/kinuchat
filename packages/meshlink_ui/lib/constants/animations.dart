/// Animation duration constants
/// Based on Section 7.4 of the specification
class MeshLinkAnimations {
  MeshLinkAnimations._();

  /// Message send: bubble scales up slightly then settles
  static const Duration messageSend = Duration(milliseconds: 150);

  /// Status change: smooth crossfade between states
  static const Duration statusTransition = Duration(milliseconds: 200);

  /// Mesh activation: ripple effect from status bar
  static const Duration meshActivate = Duration(milliseconds: 400);

  /// New message: slide in from bottom with subtle bounce
  static const Duration messageReceive = Duration(milliseconds: 250);

  /// Transport switch: icon morphs with rotation
  static const Duration transportSwitch = Duration(milliseconds: 300);

  /// Rally mode: pulse effect on participant count
  static const Duration rallyPulse = Duration(milliseconds: 1500);
}
