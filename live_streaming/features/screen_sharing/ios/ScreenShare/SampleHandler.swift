//
//  SampleHandler.swift
//  ScreenShare
//
//  Created by Kael Ding on 2023/5/18.
//

import ReplayKit
import ZegoExpressEngine

class SampleHandler: RPBroadcastSampleHandler {

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        
        ZegoReplayKitExt.sharedInstance().setup(withDelegate: self)
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        ZegoReplayKitExt.sharedInstance().finished()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        ZegoReplayKitExt.sharedInstance().send(sampleBuffer, with: sampleBufferType)
    }
}

extension SampleHandler: ZegoReplayKitExtHandler {
    func broadcastFinished(_ broadcast: ZegoReplayKitExt, reason: ZegoReplayKitExtReason) {
        switch reason {
        case .hostStop:
            let userInfo = [NSLocalizedDescriptionKey: "Host app stop srceen capture"]
            let error = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: userInfo)
            finishBroadcastWithError(error)
        case .connectFail:
            let userInfo = [NSLocalizedDescriptionKey: "Connect host app fail need startScreenCapture in host app"]
            let error = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: userInfo)
            finishBroadcastWithError(error)
        case .disconnect:
            let userInfo = [NSLocalizedDescriptionKey: "disconnect with host app"]
            let error = NSError(domain: NSCocoaErrorDomain, code: 0, userInfo: userInfo)
            finishBroadcastWithError(error)
        @unknown default:
            break
        }
    }
}
