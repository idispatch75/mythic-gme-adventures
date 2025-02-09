import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

InlineSpan getInlineLink({
  required String text,
  required String url,
  TextStyle? textStyle,
}) {
  var style = const TextStyle(
    color: Colors.blue,
  );
  if (textStyle != null) {
    style = textStyle.merge(style);
  }

  return TextSpan(
    text: text,
    style: style,
    recognizer: TapGestureRecognizer()..onTap = () => launchUrlString(url),
  );
}

InlineSpan getUserManualLink({TextStyle? textStyle, String? anchor}) {
  var url = 'https://idispatch75.github.io/mythic-gme-adventures/user_manual/';
  if (anchor != null) {
    url += '#$anchor';
  }

  return getInlineLink(
    text: 'User Manual',
    url: url,
    textStyle: textStyle,
  );
}
