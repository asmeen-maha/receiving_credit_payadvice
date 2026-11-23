// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Reads from the browser's localStorage. Storage can be blocked (private
/// mode, site data disabled), so failures read as "not set".
String? readLocal(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

void writeLocal(String key, String? value) {
  try {
    if (value == null) {
      html.window.localStorage.remove(key);
    } else {
      html.window.localStorage[key] = value;
    }
  } catch (_) {
    // Not persisted; the value still applies for this session.
  }
}
