import FlutterMacOS
import Cocoa

public class NativeFlutterFontsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
      FlutterFontRegistry.registerFonts(registrar: registrar)
  }
}
