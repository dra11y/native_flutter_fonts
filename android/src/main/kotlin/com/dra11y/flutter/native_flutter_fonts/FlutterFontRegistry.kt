package com.dra11y.flutter.native_flutter_fonts

import android.content.res.AssetManager
import android.graphics.Typeface
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import java.nio.charset.Charset

fun Typeface.withWeight(weight: Int): Typeface =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        Typeface.create(this, weight, this.isItalic)
    } else {
        Typeface.create(this, if (weight >= 700) Typeface.BOLD else Typeface.NORMAL)
    }

fun Typeface.withItalic(isItalic: Boolean): Typeface =
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        Typeface.create(this, if (weight == 0) 400 else weight, isItalic)
    } else {
        Typeface.create(this, if (isItalic) {
            if (isBold) Typeface.BOLD_ITALIC else Typeface.ITALIC
        } else {
            if (isBold) Typeface.BOLD else Typeface.NORMAL
        })
    }

@Serializable
data class FontManifestEntry(
    val family: String,
    val fonts: List<Asset>,
) {
    @Serializable
    data class Asset(
        val asset: String,
        val weight: Int? = null,
        val style: String? = null,
    )
}

data class TypefaceKey(val name: String, val weight: Int, val isBold: Boolean, val isItalic: Boolean)

class FlutterFontRegistry {
    companion object {
        private const val TAG = "FlutterFontRegistry"

        private var isInitialized: Boolean = false
        private lateinit var manifest: List<FontManifestEntry>
        private val registeredTypefaces = mutableMapOf<TypefaceKey, Typeface>()

        @JvmStatic
        fun resolve(family: String?, weight: Int = 400, isItalic: Boolean = false, debug: Boolean = false) : Typeface =
            resolveOrNull(family, weight, isItalic, debug)
                ?: if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                    Typeface.create(
                        Typeface.DEFAULT,
                        weight,
                        isItalic,
                    )
                else {
                    (if (weight >= 700) Typeface.DEFAULT_BOLD else Typeface.DEFAULT)
                        .withWeight(weight)
                        .withItalic(isItalic)
                }

        @JvmStatic
        fun resolveOrNull(
            family: String?,
            weight: Int = 400,
            isItalic: Boolean = false,
            debug: Boolean = false): Typeface? {
            if (!isInitialized) {
                error("FlutterFontRegistry has not been initialized!")
            }

            val isBold = weight >= 700
            val typeface = family?.let { name ->
                val byName = registeredTypefaces.filterKeys { key -> key.name == name }
                    .ifEmpty { return@let null }

                byName.filterKeys { it.weight == weight && it.isItalic == isItalic }
                    .ifEmpty {
                        byName.filterKeys { it.isBold == isBold && it.isItalic == isItalic }
                    }
                    .ifEmpty {
                        byName.filterKeys { it.isItalic == isItalic }
                    }
                    .values.firstOrNull()
            }
                ?.withWeight(weight)
                ?.withItalic(isItalic)

            if (debug) {
                if (typeface != null) {
                    Log.d(TAG, "resolved font $family, weight = $weight, isItalic = $isItalic!")
                } else {
                    Log.d(
                        TAG,
                        "failed to resolve font $family, weight = $weight, isItalic = $isItalic; registered typefaces = $registeredTypefaces"
                    )
                }
            }

            return typeface ?: Typeface.defaultFromStyle(when (listOf(isBold, isItalic)) {
                listOf(false, false) -> Typeface.NORMAL
                listOf(true, false) -> Typeface.BOLD
                listOf(false, true) -> Typeface.ITALIC
                else -> Typeface.BOLD_ITALIC
            })
        }

        internal fun registerTypefaces(binding: FlutterPlugin.FlutterPluginBinding) {
            if (isInitialized) {
                Log.d(TAG, "Already initialized!")
                return
            }
            val assetManager: AssetManager = binding.applicationContext.assets
            val manifestPath = binding.flutterAssets.getAssetFilePathByName("FontManifest.json")
            val manifestText = assetManager.open(manifestPath).reader(Charset.forName("utf-8")).readText()

            // We need to try...catch serialization errors here, otherwise it silently fails.
            try {
                manifest = Json.decodeFromString(manifestText)
            } catch (exception: SerializationException) {
                Log.e(TAG, exception.toString())
            }

            manifest.forEach { entry ->
                Log.d(TAG, entry.toString())
                val family = entry.family.split("/").last()
                entry.fonts.forEach { font ->
                    Log.d(TAG, font.toString())
                    val assetPath = binding.flutterAssets.getAssetFilePathByName(font.asset)
                    Log.e(TAG, assetPath)
                    Typeface.createFromAsset(assetManager, assetPath)?.let { typeface ->
                        val weight = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            typeface.weight
                        } else {
                            font.weight ?: 400
                        }
                        val typefaceKey = TypefaceKey(family, weight = weight, isBold = typeface.isBold, isItalic = typeface.isItalic)
                        registeredTypefaces[typefaceKey] = typeface
                    }
                }
            }

            isInitialized = true
        }
    }
}
