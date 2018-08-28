//
// Created by Zap on 07.08.2018.
//

import Foundation


public typealias Token = String

public struct Factory {

    public static func makeBot(
        configuration:        URLSessionConfiguration,
        token:                Token,
        targetQueue:          DispatchQueue? = nil,
        delegateQueue:        DispatchQueue,
        initialUpdatesOffset: Update.ID? = nil
    ) -> Bot {

        let api = APIClient(configuration: configuration)

        /// API limits from [FAQ page](https://core.telegram.org/bots/faq#my-bot-is-hitting-limits-how-do-i-avoid-this)
        let limits = [
            Limiter.Limit(duration: 1,  quantity: 1),
            Limiter.Limit(duration: 60, quantity: 20)
        ]

        let limiter = Limiter(limits: Set(limits), targetQueue: delegateQueue)

        return Bot(
            api:            DOSProtectedAPI(api: api, limiter: limiter),
            pollingTimeout: configuration.timeoutIntervalForRequest,
            token:          token,
            targetQueue:    targetQueue,
            delegateQueue:  delegateQueue,
            initialOffset:  initialUpdatesOffset
        )
    }
}

public protocol SubscriptionHolder: AnyObject {}

public final class Bot {


    // MARK: - Private properties

    private class Holder: SubscriptionHolder {
        deinit {
            print("Holder got deallocated")
        }
    }

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

    private let queue: DispatchQueue
    private let delegateQueue: DispatchQueue


    // MARK: - Initialization / Deinitialization

    /// parameter pollingTimeout - should be the same as timeout in URLSessionConfiguration in API
    internal init(
        api:            API,
        pollingTimeout: TimeInterval,
        token:          Token,
        targetQueue:    DispatchQueue?,
        delegateQueue:  DispatchQueue,
        initialOffset:  Update.ID? = nil
    ) {
        self.api            = api
        self.pollingTimeout = pollingTimeout
        self.token          = token
        self.queue          = DispatchQueue(label: "com.zababako.swiftygram.bot", target: targetQueue)
        self.delegateQueue  = delegateQueue
        self.offset         = initialOffset
    }


    // MARK: - Bot

    public func updateErrorRecoveryTime(_ time: TimeInterval) {
        queue.async { self.errorRecoveryTime = time }
    }

    public func subscribeToUpdates(handler: @escaping (Result<[Update]>) -> Void) -> SubscriptionHolder {

        let holder = Holder()

        queue.async {
            self.subscriptionsRegistry[WeakBox(holder)] = handler
        }

        return holder
    }

    public func getMe(onComplete: @escaping (Result<User>) -> Void) {

        let handler = { result in self.delegateQueue.async { onComplete(result) } }

        Result.action(handler: handler) {
            api.send(
                request: try APIMethod.GetMe().request(for: token),
                onComplete: $0
            )
        }
    }

    public func send(
        message:               String,
        to:                    Receiver,
        parseMode:             ParseMode?   = nil,
        disableWebPagePreview: Bool?        = nil,
        disableNotification:   Bool?        = nil,
        replyToMessageId:      Message.ID?  = nil,
        replyMarkup:           ReplyMarkup? = nil,
        onComplete:            @escaping (Result<Message>) -> Void
    ) {

        let handler = { result in self.delegateQueue.async { onComplete(result) } }

        Result.action(handler: handler) {
            api.send(
                request: try APIMethod.SendMessage(
                    chatId: 			   to,
                    text: 				   message,
                    parseMode: 			   parseMode,
                    disableWebPagePreview: disableWebPagePreview,
                    disableNotification:   disableNotification,
                    replyToMessageId:      replyToMessageId,
                    replyMarkup:           replyMarkup
                ).request(for: token),
                onComplete: $0
            )
        }
    }

    public func send(
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
                    result
                        .onSuccess {
                        updates in

                        if let last = updates.last {
                            self.offset = last.updateId.next
                        }

                        self.propagateUpdateResult(result)
                    }
                    .onFailure {
                        error in

                        if error.isNotTimeout {
                            self.propagateUpdateResult(result)
                        }
                    }

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

private extension Error {

    var isTimeout: Bool {
    #if os(Linux)
        guard let nsError = self as? NSError else { return false }
        return nsError.domain == NSURLErrorDomain && nsError.code == -1001
    #else
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == -1001
    #endif
    }

    var isNotTimeout: Bool {
        return !isTimeout
    }
}
