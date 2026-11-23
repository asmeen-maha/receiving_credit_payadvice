/// Non-web fallback (tests, desktop): values live only for this run.
final Map<String, String> _memory = {};

String? readLocal(String key) => _memory[key];

void writeLocal(String key, String? value) => value == null ? _memory.remove(key) : _memory[key] = value;
