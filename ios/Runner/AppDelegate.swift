import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appleReceiptChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "AppleReceiptBridge"
    ) else {
      return
    }

    appleReceiptChannel = FlutterMethodChannel(
      name: "dm_bhatt_tutions/apple_receipt",
      binaryMessenger: registrar.messenger()
    )
    appleReceiptChannel?.setMethodCallHandler { call, result in
      guard call.method == "getReceipt" else {
        result(FlutterMethodNotImplemented)
        return
      }

      guard
        let receiptURL = Bundle.main.appStoreReceiptURL,
        let receiptData = try? Data(contentsOf: receiptURL),
        !receiptData.isEmpty
      else {
        result(nil)
        return
      }

      result(receiptData.base64EncodedString())
    }
  }
}
