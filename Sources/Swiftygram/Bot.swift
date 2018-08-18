//
// Created by Zap on 07.08.2018.
//

import Foundation


public typealias Token = String

public protocol SubscriptionHolder: AnyObject {}

public protocol Bot: AnyObject {

    func updateErrorRecoveryTime(_ time: TimeInterval)

    func getMe(onComplete: @escaping (Result<User>) -> Void)
    func send(
        message:             String,
        to:                  Receiver,
        parseMode:           ParseMode?,
        disableNotification: Bool?,
        replyToMessageId:    Message.ID?,
        replyMarkup:         ReplyMarkup?,
        onComplete:          @escaping (Result<Message>) -> Void
    )
    func send(
        document:            DocumentToSend,
        to:                  Receiver,
        thumb:               DocumentToSend?,
        caption:             String?,
        parseMode:           ParseMode?,
        disableNotification: Bool?,
        replyToMessageId:    Message.ID?,
        replyMarkup:         ReplyMarkup?,
        onComplete:          @escaping (Result<Message>) -> Void
    )

    func subscribeToUpdates(handler: @escaping (Result<[Update]>) -> Void) -> SubscriptionHolder
}




private class Holder: SubscriptionHolder {}

final class SwiftyBot: Bot {


    // MARK: - Private properties

    private let api:   API
    private let token: Token

    private let pollingTimeout: TimeInterval

    private var errorRecoveryTime: TimeInterval = 10
    private var offset: Update.ID?
    private var subscriptionsRegistry: [WeakBox<Holder> : (Result<[Update]>) -> Void] = [:] {
        didSet {
            subscriptionsRegistry = subscriptionsRegistry.filter { (box, _) in box.value != nil }
            isUpdating = !subscriptionsRegistry.isEmpty
        }
    }
    private var isUpdating: Bool = false {
        didSet {
            guard isUpdating != oldValue else { return }

            if isUpdating { checkUpdates() }
        }
    }

    private let queue: DispatchQueue = DispatchQueue(label: "swiftygram.bot")
    private let delegateQueue: DispatchQueue


    // MARK: - Initialization / Deinitialization

    /// parameter pollingTimeout - should be the same as timeout in URLSessionConfiguration in API
    init(
        api:            API,
        pollingTimeout: TimeInterval,
        token:          Token,
        delegateQueue:  DispatchQueue,
        initialOffset:  Update.ID? = nil
    ) {
        self.api            = api
        self.pollingTimeout = pollingTimeout
        self.token          = token
        self.delegateQueue  = delegateQueue
        self.offset         = initialOffset
    }


    // MARK: - Bot

    func updateErrorRecoveryTime(_ time: TimeInterval) {
        queue.async { self.errorRecoveryTime = time }
    }

    func subscribeToUpdates(handler: @escaping (Result<[Update]>) -> Void) -> SubscriptionHolder {

        let holder = Holder()

        queue.async {
            self.subscriptionsRegistry[WeakBox(holder)] = handler
        }

        return holder
    }

    func getMe(onComplete: @escaping (Result<User>) -> Void) {

        let handler = { result in self.delegateQueue.async { onComplete(result) } }

        Result.action(handler: handler) {
            api.send(
                request: try APIMethod.GetMe().request(for: token),
                onComplete: $0
            )
        }
    }

    func send(
        message:             String,
        to:                  Receiver,
        parseMode:           ParseMode?   = nil,
        disableNotification: Bool?        = nil,
        replyToMessageId:    Message.ID?  = nil,
        replyMarkup:         ReplyMarkup? = nil,
        onComplete:          @escaping (Result<Message>) -> Void
    ) {

        let handler = { result in self.delegateQueue.async { onComplete(result) } }

        Result.action(handler: handler) {
            api.send(
                request: try APIMethod.SendMessage(
                    chatId: 			   to,
                    text: 				   message,
                    parseMode: 			   parseMode,
                    disableWebPagePreview: nil, // TODO: add to protocol
                    disableNotification:   disableNotification,
                    replyToMessageId:      replyToMessageId,
                    replyMarkup:           replyMarkup
                ).request(for: token),
                onComplete: $0
            )
        }
    }

    func send(
        document:            DocumentToSend,
        to:                  Receiver,
        thumb:               DocumentToSend? = nil,
        caption:             String?         = nil,
        parseMode:           ParseMode?      = nil,
        disableNotification: Bool?           = nil,
        replyToMessageId:    Message.ID?     = nil,
        replyMarkup:         ReplyMarkup?    = nil,
        onComplete:          @escaping (Result<Message>) -> Void
    ) {
        let handler = { result in self.delegateQueue.async { onComplete(result) } }

        Result.action(handler: handler) {
            api.send(
                request: try APIMethod.SendDocument(
                    chatId:              to,
                    document:            document,
                    thumb:               thumb,
                    caption:             caption,
                    parseMode:           parseMode,
                    disableNotification: disableNotification,
                    replyToMessageId:    replyToMessageId,
                    replyMarkup:         replyMarkup
                ).request(for: token),
                onComplete: $0
            )
        }
    }


    // MARK: - Private Methods

    private func propagateUpdateResult(_ result: Result<[Update]>) {

        subscriptionsRegistry = subscriptionsRegistry.filter { (box, _) in box.value != nil }

        subscriptionsRegistry.forEach { (_, handler) in
            delegateQueue.async { handler(result) }
        }
    }

    private func checkUpdates() {

        // Asserting this code is performed on self.queue

        let timeout = Int(pollingTimeout)

        do {
            api.send(
                request: try APIMethod.GetUpdates(
                    offset:         offset,
                    limit:          nil,
                    timeout:        timeout,
                    allowedUpdates: nil
                ).request(for: token)
            ) {
                [queue]
                (result: Result<[Update]>) in

                queue.async {
                    result.onSuccess {
                        updates in

                        if let last = updates.last {
                            self.offset = last.updateId.next
                        }
                    }

                    self.propagateUpdateResult(result)

                    guard self.isUpdating else { return }

                    let delay: TimeInterval = result.choose(
                        ifSuccess: 0,
                        ifFailure: self.errorRecoveryTime
                    )

                    queue.asyncAfter(seconds: delay) {
                        self.checkUpdates()
                    }
                }
            }
        } catch {

            propagateUpdateResult(.failure(error))

            guard isUpdating else { return }

            queue.asyncAfter(seconds: errorRecoveryTime) {
                self.checkUpdates()
            }
        }
    }
}

