// Conditional import — на web использует dart:html, на Android — заглушку.
export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
