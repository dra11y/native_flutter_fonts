//
//  FlutterFontRegistry.swift
//  native_flutter_fonts
//
//  Created by Grushka, Tom on 1/31/23.
//

import Flutter

struct FontManifestEntry: Decodable {
    let family: String
    let fonts: [Asset]

    struct Asset: Decodable {
        let asset: String
        let weight: Int?
        let style: String?
        let isItalic: Bool?
    }
}

public struct Font: Hashable {
    let family: String
    let asset: String
    let name: String
    let weight: Int
    let isItalic: Bool
}

public class FlutterFontRegistry {
    public static func resolveOrSystemDefault(
        family: String?,
        size: CGFloat? = nil,
        weight: Int? = nil,
        isItalic: Bool = false,
        debug: Bool = false) -> UIFont
    {
        resolve(family: family, size: size, weight: weight, isItalic: isItalic, debug: debug)
            ?? UIFont.systemFont(ofSize: size ?? UIFont.systemFontSize)
    }

    public static func resolve(
        family: String?,
        size: CGFloat? = nil,
        weight: Int? = nil,
        isItalic: Bool = false,
        debug: Bool = false) -> UIFont?
    {
        let weight = weight ?? 400
        let size = size ?? UIFont.systemFontSize
        let defaultFont = UIFont.systemFont(ofSize: size)
        let inputs = "family: \(String(describing: family)), size: \(size), weight: \(weight), isItalic: \(isItalic)"

        guard let family = family else {
            if debug {
                self.debug("No family provided. Resolved UIFont: \(defaultFont) of size: \(size) with inputs: \(inputs)")
            }
            return defaultFont
        }

        guard
            let font: Font = getRegisteredFonts()
                .filter({ $0.family == family && $0.isItalic == isItalic })
                .enumerated()
                .min(by: {
                    abs($0.element.weight - weight) < abs($1.element.weight - weight)
                })?.element
        else {
            if debug {
                self.debug("Resolving font nil because could not find font with given inputs: \(inputs).")
            }
            return nil
        }

        if
            let uiFont = UIFont(name: font.name, size: size)
        {
            if debug {
                self.debug("Resolved font: \(font), UIFont: \(uiFont) from inputs: \(inputs)")
            }
            return uiFont
        }

        assertionFailure("Could not resolve UIFont from inputs: \(inputs). This is programmer error.")
        return nil
    }

    public static func appleWeightFromFlutterWeight(_ weight: Int) -> CGFloat {
        let normalized = CGFloat(weight - 400)
        // Flutter normal weight = 400, min = 100, max = 900
        // iOS min weight = -1.0, normal = 0.0, max = 1.0
        return normalized / (normalized < 0 ? 300.0 : 500.0)
    }

    public static func flutterWeightFromAppleWeight(_ weight: CGFloat) -> Int {
        let normalized = Int(round(weight * (weight < 0 ? 3.0 : 5.0)) * 100.0) + 400
        return min(max(normalized, 100), 900)
    }

    /// Returns a registered list of `Font` objects.
    public static func getRegisteredFonts() -> Set<Font> {
        registeredFonts
    }

    private static var registrar: FlutterPluginRegistrar?

    private static var registeredFonts = Set<Font>()

    private static func debug(_ string: String) {
        #if DEBUG
        print("native_flutter_fonts iOS [DEBUG]: \(string)")
        #endif
    }

    private static var didRun: Bool = false

    static func registerFonts(
        registrar: FlutterPluginRegistrar,
        file: String = #file,
        line: Int = #line,
        function: String = #function)
    {
        debug("Called FlutterFontRegistry.registerFonts from line: \(line) of file: \(file), function: \(function)")

        if didRun {
            debug("Already ran, bailing.")
            return
        }

        didRun = true

        self.registrar = registrar

        guard let manifest = loadFontManifest() else { return }

        manifest.forEach { manifestEntry in
            let family = NSString(string: manifestEntry.family).lastPathComponent

            manifestEntry.fonts.forEach { fontAsset in
                registerFontAsset(family: family, fontAsset: fontAsset)
            }
        }

        debug("Registered font families: \(registeredFonts)")
    }

    /// Loads the Flutter-generated FontManifest.json into an array of `FontManifestEntry`.
    private static func loadFontManifest() -> [FontManifestEntry]? {
        guard let registrar = registrar else {
            assertionFailure("Registrar not defined!")
            return nil
        }

        guard
            let manifestUrl = Bundle.main.url(forResource: registrar.lookupKey(forAsset: "FontManifest"), withExtension: "json"),
            let manifestData = try? Data(contentsOf: manifestUrl, options: .mappedIfSafe),
            let manifest = try? JSONDecoder().decode([FontManifestEntry].self, from: manifestData)
        else {
            assertionFailure("Could not load FontManifest.json!")
            return nil
        }

        return manifest
    }

    /// Attempts to load a font asset and quietly skips it if it can't.
    private static func registerFontAsset(family: String, fontAsset: FontManifestEntry.Asset) {
        guard let registrar = registrar else { return }

        // If we've already registered this asset, skip it.
        if registeredFonts.contains(where: { font in font.asset == fontAsset.asset }) {
            debug("Font asset already registered, skipping: \(fontAsset.asset)")
            return
        }

        let assetKey = registrar.lookupKey(forAsset: fontAsset.asset)

        let fontBaseFileName = NSString(string: NSString(string: fontAsset.asset).lastPathComponent).deletingPathExtension

        guard
            let fontUrl = Bundle.main.url(forResource: assetKey, withExtension: nil)
        else {
            debug("Could not get URL for font asset key \(assetKey)")
            return
        }

        guard
            let data = try? Data(contentsOf: fontUrl),
            let provider = CGDataProvider(data: data as CFData)
        else {
            debug("Could not get font data for: \(fontUrl)")
            return
        }

        guard
            let cgFont = CGFont(provider)
        else {
            debug("Could not get CGFont for family: \(family) with asset path: \(fontAsset.asset)")
            return
        }

        guard
            let fontName = cgFont.postScriptName as? String
        else {
            debug("Could not get PostScript name for font family: \(family) with asset path: \(fontAsset.asset)")
            return
        }

        let isItalic = cgFont.italicAngle != 0

        var unmanagedRegistrationError: Unmanaged<CFError>?
        let didRegister = CTFontManagerRegisterGraphicsFont(cgFont, &unmanagedRegistrationError)

        /// This error checking is really only for debugging anyway. The font registered or it didn't.
        /// The next check whether its `UIFont` can be created is the "real" test of success.
        #if DEBUG
            if
                !didRegister,

                /// Using `takeUnretainedValue()` because we do not own the reference
                /// (obviously `CTFontManager` owns it), thus releasing it ourselves causes a crash:
                /// https://stackoverflow.com/questions/29048826/when-to-use-takeunretainedvalue-or-takeretainedvalue-to-retrieve-unmanaged-o
                let unretainedValue = unmanagedRegistrationError?.takeUnretainedValue(),
                let error = CTFontManagerError(rawValue: CFErrorGetCode(unretainedValue))
            {
                if error == .alreadyRegistered {
                    debug("Font: \(fontName), family: \(family) is already registered in CTFontManager. Attempting to get UIFont and register...")
                } else {
                    debug("An error other than CTFontManagerError.alreadyRegistered occurred attempting to register font: \(fontName), family: \(family) with asset path: \(fontAsset.asset): \(error) \(unretainedValue). Attempting to get UIFont anyway...")
                }
            }
        #endif

        guard
            UIFont(name: fontName, size: UIFont.systemFontSize) != nil
        else {
            debug("Could not get UIFont for cgFont: \(cgFont) family: \(family) with asset path: \(fontAsset.asset), aborting!")
            return
        }

        let font = Font(
            family: family,
            asset: fontAsset.asset,
            name: fontName,
            weight: fontAsset.weight ?? 400,
            isItalic: isItalic)

        registeredFonts.insert(font)
        debug("Registered font: \(font)")
    }

}
