//
//  NetworkEventProducer.swift
//  AudioPlayer
//
//  Created by Kevin DELANNOY on 08/03/16.
//  Copyright © 2016 Kevin Delannoy. All rights reserved.
//

import Foundation

private extension Selector {
    /// The selector to call when reachability status changes.
    static let reachabilityStatusChanged =
        #selector(NetworkEventProducer.reachabilityStatusChanged(_:))
}

/**
 *  A `NetworkEventProducer` generates `NetworkEvent`s when there is changes on the network.
 */
class NetworkEventProducer: NSObject, EventProducer {
    /**
       A `NetworkEvent` is an event a network monitor

       - NetworkChanged:           The network changed.
       - ConnectionRetrieved:      The connection is now up.
       - ConnectionLost:           The connection has been lost.
     */
    enum NetworkEvent: Event {
        case NetworkChanged
        case ConnectionRetrieved
        case ConnectionLost
    }

    /// The reachability to work with.
    let reachability: Reachability

    /// The date at which connection was lost.
    private(set) var connectionLossDate: NSDate?

    /// The listener that will be alerted a new event occured.
    weak var eventListener: EventListener?

    /// A boolean value indicating whether we're currently listening to events on the player.
    private var listening = false

    /// The last status received.
    private var lastStatus: Reachability.NetworkStatus

    /**
     Initializes a `NetworkEventProducer` with a reachability.

     - parameter reachability: The reachability to work with.
     */
    init(reachability: Reachability) {
        lastStatus = reachability.currentReachabilityStatus
        self.reachability = reachability

        if lastStatus == .NotReachable {
            connectionLossDate = NSDate()
        }
    }

    /**
     Stops producing events on deinitialization.
     */
    deinit {
        stopProducingEvents()
    }

    /**
     Starts listening to the player events.
     */
    func startProducingEvents() {
        guard !listening else {
            return
        }

        //Saving current status
        lastStatus = reachability.currentReachabilityStatus

        //Starting to listen to events
        NSNotificationCenter.defaultCenter().addObserver(self, selector: .reachabilityStatusChanged,
            name: kReachabilityChangedNotification, object: reachability)
        reachability.startNotifier()

        //Saving that we're currently listening
        listening = true
    }

    /**
     Stops listening to the player events.
     */
    func stopProducingEvents() {
        guard listening else {
            return
        }

        //Stops listening to events
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: kReachabilityChangedNotification,
            object: reachability)
        reachability.stopNotifier()

        //Saving that we're not listening anymore
        listening = false
    }

    /**
     The method that will be called when Reachability generates an event.

     - parameter note: The sender information.
     */
    @objc private func reachabilityStatusChanged(note: NSNotification) {
        let newStatus = reachability.currentReachabilityStatus
        if newStatus != lastStatus {
            if newStatus == .NotReachable {
                connectionLossDate = NSDate()
                eventListener?.onEvent(NetworkEvent.ConnectionLost, generetedBy: self)
            } else if lastStatus == .NotReachable {
                eventListener?.onEvent(NetworkEvent.ConnectionRetrieved, generetedBy: self)
                connectionLossDate = nil
            } else {
                eventListener?.onEvent(NetworkEvent.NetworkChanged, generetedBy: self)
            }
            lastStatus = newStatus
        }
    }
}