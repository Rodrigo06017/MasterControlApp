/// Xbox SmartGlass and Media Command Enums and Byte Payloads
enum XboxButton {
  dpadUp,
  dpadDown,
  dpadLeft,
  dpadRight,
  a,
  b,
  x,
  y,
  leftShoulder,
  rightShoulder,
  view,
  menu,
  nexus, // Xbox Guide Button
  leftThumbstick,
  rightThumbstick,
}

enum XboxMediaCommand {
  play,
  pause,
  playPauseToggle,
  stop,
  record,
  previous,
  next,
  rewind,
  fastForward,
  channelUp,
  channelDown,
  back,
  view,
  menu,
  volumeUp,
  volumeDown,
  mute,
}

class XboxCommandCodes {
  // Common SmartGlass / Media Key OpCodes
  static const int opDpadUp = 0x01;
  static const int opDpadDown = 0x02;
  static const int opDpadLeft = 0x04;
  static const int opDpadRight = 0x08;
  static const int opStart = 0x10;
  static const int opBack = 0x20;
  static const int opLeftThumb = 0x40;
  static const int opRightThumb = 0x80;
  static const int opLeftShoulder = 0x0100;
  static const int opRightShoulder = 0x0200;
  static const int opNexus = 0x0400;
  static const int opA = 0x1000;
  static const int opB = 0x2000;
  static const int opX = 0x4000;
  static const int opY = 0x8000;

  // Media Key Codes
  static const int mediaPlay = 0x01;
  static const int mediaPause = 0x02;
  static const int mediaPlayPause = 0x03;
  static const int mediaStop = 0x04;
  static const int mediaRecord = 0x05;
  static const int mediaNext = 0x06;
  static const int mediaPrevious = 0x07;
  static const int mediaRewind = 0x08;
  static const int mediaFastForward = 0x09;
  static const int mediaVolumeUp = 0x0A;
  static const int mediaVolumeDown = 0x0B;
  static const int mediaMute = 0x0C;
}
