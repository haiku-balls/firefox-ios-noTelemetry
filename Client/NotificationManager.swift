// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UserNotifications
import Shared

protocol NotificationManagerProtocol {
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func getNotificationSettings(sendTelemetry: Bool, completion: @escaping (UNNotificationSettings) -> Void)
    func hasPermission(completion: @escaping (Bool) -> Void)
    func schedule(title: String, body: String, id: String, date: Date, repeats: Bool)
    func schedule(title: String, body: String, id: String, interval: TimeInterval, repeats: Bool)
    func findDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void)
    func findDeliveredNotificationForId(id: String, completion: @escaping (UNNotification?) -> Void)
    func removeAllPendingNotifications()
    func removePendingNotificationsWithId(ids: [String])
}

class NotificationManager: NotificationManagerProtocol {
    private var center: UserNotificationCenterProtocol

    init(center: UserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = center
    }

    // Requests the user’s authorization to allow local and remote notifications and sends Telemetry
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            completion(granted, error)

            guard !AppConstants.isRunningUnitTest else { return }

        }
    }

    @available(*, renamed: "requestAuthorization()")
    func requestAuthorization(completion: @escaping (Result<Bool, Error>) -> Void) {
        self.requestAuthorization { granted, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(granted))
            }
        }
    }

    func requestAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            requestAuthorization { result in
                continuation.resume(with: result)
            }
        }
    }

    // Retrieves the authorization and feature-related notification settings and sends Telemetry
    func getNotificationSettings(sendTelemetry: Bool = false,
                                 completion: @escaping (UNNotificationSettings) -> Void) {
        center.getNotificationSettings { settings in
            completion(settings)

            guard sendTelemetry else { return }
           
        }
    }

    // Determines if the user has allowed notifications
    func hasPermission(completion: @escaping (Bool) -> Void) {
        getNotificationSettings { settings in
            var hasPermission = false
            switch settings.authorizationStatus {
            case .authorized, .ephemeral, .provisional:
                hasPermission = true
            case .notDetermined, .denied:
                fallthrough
            @unknown default:
                hasPermission = false
            }
            completion(hasPermission)
        }
    }

    func getNotificationSettings(sendTelemetry: Bool = false) async -> UNNotificationSettings {
        return await withCheckedContinuation { continuation in
            getNotificationSettings(sendTelemetry: sendTelemetry) { result in
                continuation.resume(returning: result)
            }
        }
    }

    // Scheduling push notification based on the Date trigger (Ex 25 December at 10:00PM)
    func schedule(title: String,
                  body: String,
                  id: String,
                  date: Date,
                  repeats: Bool = false) {
        let units: Set<Calendar.Component> = [.minute, .hour, .day, .month, .year]
        let dateComponents = Calendar.current.dateComponents(units, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents,
                                                    repeats: repeats)
        schedule(title: title, body: body, id: id, trigger: trigger)
    }

    // Scheduling push notification based on the time interval trigger (Ex 2 sec, 10min)
    func schedule(title: String,
                  body: String,
                  id: String,
                  interval: TimeInterval,
                  repeats: Bool = false) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval,
                                                        repeats: repeats)
        schedule(title: title, body: body, id: id, trigger: trigger)
    }

    // Fetches all delivered notifications that are still present in Notification Center.
    func findDeliveredNotifications(completion: @escaping ([UNNotification]) -> Void) {
        center.getDeliveredNotifications { notificationList in
            completion(notificationList)
        }
    }

    // Fetches all delivered notifications that are still present in Notification Center by id
    func findDeliveredNotificationForId(id: String,
                                        completion: @escaping (UNNotification?) -> Void) {
        findDeliveredNotifications { notificationList in
            let notification = notificationList.first(where: { notification -> Bool in
                notification.request.identifier == id
            })
            completion(notification)
        }
    }

    // Remove all pending notifications
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // Remove pending notifications with id
    func removePendingNotificationsWithId(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    // Helper method that takes trigger based on date or time interval
    private func schedule(title: String,
                          body: String,
                          id: String,
                          trigger: UNNotificationTrigger) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = body
        notificationContent.sound = UNNotificationSound.default
        let trigger = trigger
        let request = UNNotificationRequest(identifier: id,
                                            content: notificationContent,
                                            trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }


}
