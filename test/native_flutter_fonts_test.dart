import 'package:flutter_test/flutter_test.dart';
import 'package:native_flutter_fonts/native_flutter_fonts.dart';
import 'package:native_flutter_fonts/native_flutter_fonts_platform_interface.dart';
import 'package:native_flutter_fonts/native_flutter_fonts_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeFlutterFontsPlatform
    with MockPlatformInterfaceMixin
    implements NativeFlutterFontsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeFlutterFontsPlatform initialPlatform = NativeFlutterFontsPlatform.instance;

  test('$MethodChannelNativeFlutterFonts is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeFlutterFonts>());
  });

  test('getPlatformVersion', () async {
    NativeFlutterFonts nativeFlutterFontsPlugin = NativeFlutterFonts();
    MockNativeFlutterFontsPlatform fakePlatform = MockNativeFlutterFontsPlatform();
    NativeFlutterFontsPlatform.instance = fakePlatform;

    expect(await nativeFlutterFontsPlugin.getPlatformVersion(), '42');
  });
}
