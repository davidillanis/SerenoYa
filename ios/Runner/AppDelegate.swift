import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flutter encodes each --dart-define entry separately in base64.
    let defines = Bundle.main.object(forInfoDictionaryKey: "FlutterDartDefines") as? String ?? ""
    let prefix = "GOOGLE_MAPS_API_KEY="
    let mapsKey = defines.split(separator: ",").compactMap { entry -> String? in
      guard let data = Data(base64Encoded: String(entry)),
            let value = String(data: data, encoding: .utf8),
            value.hasPrefix(prefix) else { return nil }
      return String(value.dropFirst(prefix.count))
    }.last
    if let mapsKey, !mapsKey.isEmpty {
      GMSServices.provideAPIKey(mapsKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
