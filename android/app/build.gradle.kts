import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val mapsApiKey = providers.gradleProperty("dart-defines").orNull
    ?.split(",")
    ?.map { String(Base64.getDecoder().decode(it), Charsets.UTF_8) }
    ?.lastOrNull { it.startsWith("GOOGLE_MAPS_API_KEY=") }
    ?.substringAfter("=") ?: ""

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties =
    Properties().apply {
        if (keystorePropertiesFile.exists()) {
            FileInputStream(keystorePropertiesFile).use(::load)
        }
    }
val requiredSigningProperties = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
val missingSigningProperties =
    requiredSigningProperties.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
val isReleaseSigningConfigured = missingSigningProperties.isEmpty()

android {
    namespace = "com.oppsissora.serenoya"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.oppsissora.serenoya"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsApiKey
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (isReleaseSigningConfigured) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (isReleaseSigningConfigured) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

val validateReleaseSigning =
    tasks.register("validateReleaseSigning") {
        doLast {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "Falta android/key.properties. Crea el archivo antes de compilar una versión release.",
                )
            }
            if (missingSigningProperties.isNotEmpty()) {
                throw GradleException(
                    "Faltan propiedades de firma en android/key.properties: " +
                        missingSigningProperties.joinToString(", "),
                )
            }

            val configuredKeystore = file(keystoreProperties.getProperty("storeFile"))
            if (!configuredKeystore.isFile) {
                throw GradleException(
                    "No se encontró el almacén de claves configurado en android/key.properties.",
                )
            }
        }
    }

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(validateReleaseSigning)
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
