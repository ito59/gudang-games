import 'package:flutter/widgets.dart';

/// Material Symbols Outlined glyphs used by the design.
///
/// Codepoints come from the upstream `MaterialSymbolsOutlined.codepoints`
/// file. The font is variable, so `Icon(..., fill: 1)` fills a glyph the same
/// way `font-variation-settings: 'FILL' 1` does in `code.html`.
///
/// Keep these `const`: the icon tree-shaker only strips unused glyphs when the
/// codepoints are known at compile time.
class AppIcons {
  const AppIcons._();

  static const _family = 'MaterialSymbolsOutlined';

  static const swords = IconData(0xf889, fontFamily: _family);
  static const magicButton = IconData(0xf136, fontFamily: _family);
  static const chess = IconData(0xf5e7, fontFamily: _family);
  static const sportsSoccer = IconData(0xea2f, fontFamily: _family);
  static const speed = IconData(0xe9e4, fontFamily: _family);
  static const notifications = IconData(0xe7f5, fontFamily: _family);
  static const playArrow = IconData(0xe037, fontFamily: _family);
  static const star = IconData(0xf09a, fontFamily: _family);
  static const home = IconData(0xe9b2, fontFamily: _family);
  static const sportsEsports = IconData(0xea28, fontFamily: _family);
  static const group = IconData(0xea21, fontFamily: _family);
  static const person = IconData(0xf0d3, fontFamily: _family);

  // Profile
  static const edit = IconData(0xf097, fontFamily: _family);
  static const chevronRight = IconData(0xe5cc, fontFamily: _family);
  static const settings = IconData(0xe8b8, fontFamily: _family);
  static const privacyTip = IconData(0xf0dc, fontFamily: _family);
  static const help = IconData(0xe8fd, fontFamily: _family);
  static const description = IconData(0xe873, fontFamily: _family);
  static const gavel = IconData(0xe90e, fontFamily: _family);
  static const personRemove = IconData(0xef66, fontFamily: _family);
  static const logout = IconData(0xe9ba, fontFamily: _family);
  static const locationOn = IconData(0xf1db, fontFamily: _family);
  static const photoCamera = IconData(0xe412, fontFamily: _family);
  static const arrowBack = IconData(0xe5c4, fontFamily: _family);
  static const check = IconData(0xe668, fontFamily: _family);
  static const trophy = IconData(0xea23, fontFamily: _family);
  static const schedule = IconData(0xefd6, fontFamily: _family);
  static const videogameAsset = IconData(0xe338, fontFamily: _family);

  // Community
  static const favorite = IconData(0xe87e, fontFamily: _family);
  static const modeComment = IconData(0xe253, fontFamily: _family);
  static const share = IconData(0xe80d, fontFamily: _family);
  static const groupAdd = IconData(0xe7f0, fontFamily: _family);
  static const playCircle = IconData(0xe1c4, fontFamily: _family);
  static const bolt = IconData(0xea0b, fontFamily: _family);
  static const forum = IconData(0xe8af, fontFamily: _family);
  static const moreHoriz = IconData(0xe5d3, fontFamily: _family);

  // Chat
  static const send = IconData(0xe163, fontFamily: _family);
  static const doneAll = IconData(0xe877, fontFamily: _family);
  static const chatBubble = IconData(0xe0cb, fontFamily: _family);
  static const personAdd = IconData(0xea4d, fontFamily: _family);
  static const accountCircle = IconData(0xf20b, fontFamily: _family);

  // Moderation
  static const flag = IconData(0xe153, fontFamily: _family);
  static const block = IconData(0xe14b, fontFamily: _family);

  // Feed
  static const close = IconData(0xe5cd, fontFamily: _family);
  static const editSquare = IconData(0xf88d, fontFamily: _family);
  static const refresh = IconData(0xe5d5, fontFamily: _family);
  static const cloudOff = IconData(0xe2c1, fontFamily: _family);
}
