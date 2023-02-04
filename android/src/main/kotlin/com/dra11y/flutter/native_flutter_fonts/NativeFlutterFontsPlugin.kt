package com.dra11y.flutter.native_flutter_fonts

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding

class NativeFlutterFontsPlugin: FlutterPlugin {
  override fun onAttachedToEngine(flutterPluginBinding: FlutterPluginBinding) {
    FlutterFontRegistry.registerTypefaces(flutterPluginBinding)
  }

  override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
  }
}
