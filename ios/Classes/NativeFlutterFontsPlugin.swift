import Flutter
import UIKit

public class NativeFlutterFontsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
      FlutterFontRegistry.registerFonts(registrar: registrar)
  }
}
