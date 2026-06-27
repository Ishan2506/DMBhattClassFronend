import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, SKRequestDelegate {
  private var appleReceiptChannel: FlutterMethodChannel?
  private var pendingReceiptResult: FlutterResult?
  private var receiptRefreshRequest: SKReceiptRefreshRequest?

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
      if call.method == "refreshReceipt" {
        self.refreshReceipt(result)
        return
      }

      guard call.method == "getReceipt" else {
        result(FlutterMethodNotImplemented)
        return
      }

      if let receipt = self.readReceipt() {
        result(receipt)
        return
      }

      self.refreshReceipt(result)
    }
  }

  private func readReceipt() -> String? {
    guard
      let receiptURL = Bundle.main.appStoreReceiptURL,
      let receiptData = try? Data(contentsOf: receiptURL),
      !receiptData.isEmpty
    else {
      return nil
    }

    return receiptData.base64EncodedString()
  }

  private func refreshReceipt(_ result: @escaping FlutterResult) {
    guard pendingReceiptResult == nil else {
      result(
        FlutterError(
          code: "RECEIPT_REFRESH_IN_PROGRESS",
          message: "Apple receipt refresh is already in progress.",
          details: nil
        )
      )
      return
    }

    pendingReceiptResult = result
    receiptRefreshRequest = SKReceiptRefreshRequest()
    receiptRefreshRequest?.delegate = self
    receiptRefreshRequest?.start()
  }

  func requestDidFinish(_ request: SKRequest) {
    let receipt = readReceipt()
    pendingReceiptResult?(receipt)
    pendingReceiptResult = nil
    receiptRefreshRequest = nil
  }

  func request(_ request: SKRequest, didFailWithError error: Error) {
    pendingReceiptResult?(
      FlutterError(
        code: "RECEIPT_REFRESH_FAILED",
        message: error.localizedDescription,
        details: nil
      )
    )
    pendingReceiptResult = nil
    receiptRefreshRequest = nil
  }
}
