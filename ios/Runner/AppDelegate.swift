import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // (اختياري) اجعل إشعارات iOS تمر عبر Flutter plugins
    // لا تضف UNUserNotificationCenterDelegate هنا لتجنب التكرار

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // دعم إشعارات Push (iOS 10+) عبر Firebase Messaging / flutter_local_notifications
  // وجود هذه الدوال يكفي بدون إعلان UNUserNotificationCenterDelegate في class signature

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound, .badge])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}
