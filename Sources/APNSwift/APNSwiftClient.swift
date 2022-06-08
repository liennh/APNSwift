//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019-2020 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import Logging
import NIO

public protocol APNSwiftClient {
    var logger: Logger? { get }

    func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID?
    ) async throws
}

extension APNSwiftClient {
    private func logger(from loggerConfig: LoggerConfig) -> Logger? {
        switch loggerConfig {
        case .none:
            return nil
        case .clientLogger:
            return self.logger
        case .custom(let customLogger):
            return customLogger
        }
    }
    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter payload: the alert to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notification expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send(
        _ alert: APNSwiftAlert,
        pushType: APNSwiftConnection.PushType = .alert,
        to deviceToken: String,
        with encoder: JSONEncoder = JSONEncoder(),
        expiration: Date? = nil,
        priority: Int? = nil,
        collapseIdentifier: String? = nil,
        topic: String? = nil,
        loggerConfig: LoggerConfig = .clientLogger,
        apnsID: UUID? = nil
    ) async throws {
        try await self.send(
            APNSwiftPayload(alert: alert),
            pushType: pushType,
            to: deviceToken,
            with: encoder,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            loggerConfig: loggerConfig,
            apnsID: apnsID
        )
    }

    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter payload: the payload to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notification expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send(
        _ payload: APNSwiftPayload,
                     pushType: APNSwiftConnection.PushType = .alert,
        to deviceToken: String,
        with encoder: JSONEncoder = JSONEncoder(),
        expiration: Date? = nil,
        priority: Int? = nil,
        collapseIdentifier: String? = nil,
        topic: String? = nil,
        loggerConfig: LoggerConfig = .clientLogger,
        apnsID: UUID? = nil) async throws {
            try await self.send(
                BasicNotification(aps: payload),
                pushType: pushType,
                to: deviceToken,
                with: encoder,
                expiration: expiration,
                priority: priority,
                collapseIdentifier: collapseIdentifier,
                topic: topic,
                loggerConfig: loggerConfig,
                apnsID: apnsID
            )
    }

    /**
     APNSwiftConnection send method. Sends a notification to the desired deviceToken.
     - Parameter notification: the notification meta data and alert to send.
     - Parameter pushType: push type of the notification.
     - Parameter deviceToken: device token to send alert to.
     - Parameter encoder: customer JSON encoder if needed.
     - Parameter expiration: a date that the notification expires.
     - Parameter priority: priority to send the notification with.
     - Parameter collapseIdentifier: a collapse identifier to use for grouping notifications
     - Parameter topic: the bundle identifier that this notification belongs to.

     For more information see:
     [Retrieve Your App's Device Token](https://developer.apple.com/documentation/usernotifications/registering_your_app_with_apns#2942135)
     ### Usage Example: ###
     ```
     let apns = APNSwiftConnection.connect()
     let expiry = Date().addingTimeInterval(5)
     try apns.send(notification, pushType: .alert, to: "b27a07be2092c7fbb02ab5f62f3135c615e18acc0ddf39a30ffde34d41665276", with: JSONEncoder(), expiration: expiry, priority: 10, collapseIdentifier: "huro2").wait()
     ```
     */
    public func send<Notification>(
        _ notification: Notification,
        pushType: APNSwiftConnection.PushType = .alert,
        to deviceToken: String,
        with encoder: JSONEncoder = JSONEncoder(),
        expiration: Date? = nil,
        priority: Int? = nil,
        collapseIdentifier: String? = nil,
        topic: String? = nil,
        loggerConfig: LoggerConfig = .clientLogger,
        apnsID: UUID? = nil
    ) async throws where Notification: APNSwiftNotification {
        let data: Data = try encoder.encode(notification)
        try await self.send(
            raw: data,
            pushType: pushType,
            to: deviceToken,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            loggerConfig: loggerConfig,
            apnsID: apnsID
        )
    }

    /// This is to be used with caution. APNSwift cannot guarantee delivery if you do not have the correct payload.
    /// For more information see: [Creating APN Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)
    public func send<Bytes>(
        raw payload: Bytes,
        pushType: APNSwiftConnection.PushType = .alert,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        loggerConfig: LoggerConfig = .clientLogger,
        apnsID: UUID? = nil) async throws
    where Bytes : Collection, Bytes.Element == UInt8 {
            var buffer = ByteBufferAllocator().buffer(capacity: payload.count)
            buffer.writeBytes(payload)
        try await self.send(rawBytes: buffer,
                        pushType: pushType,
                        to: deviceToken,
                        expiration: expiration,
                        priority: priority,
                        collapseIdentifier: collapseIdentifier,
                        topic: topic,
                        logger: logger(from: loggerConfig),
                        apnsID: apnsID)
    }

    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType = .alert,
        to deviceToken: String,
        expiration: Date? = nil,
        priority: Int? = nil,
        collapseIdentifier: String? = nil,
        topic: String? = nil,
        loggerConfig: LoggerConfig = .clientLogger,
        apnsID: UUID? = nil
    ) async throws {
        try await self.send(
            rawBytes: payload,
            pushType: pushType,
            to: deviceToken,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            logger: logger(from: loggerConfig),
            apnsID: apnsID
        )
    }
}

private struct BasicNotification: APNSwiftNotification {
    let aps: APNSwiftPayload
}

public enum LoggerConfig {
    case none
    case clientLogger
    case custom(Logger)
}
