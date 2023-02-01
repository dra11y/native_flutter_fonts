# native_flutter_fonts

Currently iOS only. Android coming soon.

Provides a font registry and resolver on the native side so that native code can resolve and use Flutter fonts.

Automatically attempts to load all fonts from the Flutter font asset manifest, and stores them in a singleton instance so that they can be accessed.

This is currently used by the following plugins:
  * native_tab_bar
  * accessible_text_view

## Installation / Setup

  1. Add as a dependency to your plugin's or project's pubspec.yaml.
  2. __Important!__ Add to your `plugin_name.podspec` (plugin), or `Podfile` (app project).

  ### Plugin `plugin_name.podspec`

```rb
Pod::Spec.new do |s|
    ...
    s.dependency 'Flutter'
    s.dependency 'native_flutter_fonts' # <-- add here
    ...
end
```

  ### App `Podfile` -- Do not add if your app already uses a plugin that depends on the `native_flutter_fonts` pod!

```rb
...
target 'Runner' do
    use_frameworks!
    use_modular_headers!
    ...
    pod 'native_flutter_fonts' # <-- add here
    ...
end
...
```

## Usage

In your Swift file:
```swift
import native_flutter_fonts
...

let textFont: UIFont? = FlutterFontRegistry.resolve(family: 'Roboto', size: 14, weight: 400)

let fallbackFont: UIFont = FlutterFontRegistry.resolveOrSystemDefault(family: 'My Font', size: 14, weight: 400)
```

The `resolve` and `resolveOrSystemDefault` functions expect font weights in Flutter `FontWeight` units. These range from 100 (thin) to 400 (normal) to 900 (extra bold), in increments of 100.

However, iOS font weights (`CGFloat`) range from -1.0 (thin) to 0.0 (normal) to +1.0 (extra bold).

To convert between the two, we provide two convenience functions:

```swift
FlutterFontRegistry.flutterWeightFromAppleWeight(_ weight: CGFloat) -> Int

FlutterFontRegistry.appleWeightFromFlutterWeight(_ weight: Int) -> CGFloat
```
