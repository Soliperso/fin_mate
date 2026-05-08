import Flutter
import ObjectiveC
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppDelegate.patchClipboardHasStrings()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Flutter calls `clipboardHasStrings` synchronously on the main thread, which blocks
  // when iOS accesses UIPasteboard (slow on iOS 16+). Replace with an instant return
  // so the paste button always appears without hanging the UI thread.
  private static func patchClipboardHasStrings() {
    guard let pluginClass = NSClassFromString("FlutterPlatformPlugin"),
          let method = class_getInstanceMethod(pluginClass, NSSelectorFromString("clipboardHasStrings:"))
    else { return }

    let block: @convention(block) (AnyObject, FlutterResult) -> Void = { _, result in
      result(["value": true])
    }
    method_setImplementation(method, imp_implementationWithBlock(block))
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
