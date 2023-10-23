//
//  ZegoBeautyPluginVideoProcess.swift
//  Runner
//
//  Created by Kael Ding on 2023/6/29.
//

import Foundation
import zego_express_engine
import zego_effects_plugin

public class ZegoBeautyPluginVideoProcess: NSObject, ZegoFlutterCustomVideoProcessHandler {
    public static let shared = ZegoBeautyPluginVideoProcess()
    
    public func enableCustomVideoProcessing() {
        ZegoCustomVideoProcessManager.sharedInstance().setCustomVideoProcessHandler(self)
    }
    
    public func onStart(_ channel: ZGFlutterPublishChannel) {
        
    }
    
    public func onStop(_ channel: ZGFlutterPublishChannel) {
        
    }
    
    public func onCapturedUnprocessedCVPixelBuffer(_ buffer: CVPixelBuffer, timestamp: CMTime, channel: ZGFlutterPublishChannel) {
        ZegoEffectsMethodHandler.sharedInstance().processImageBuffer(buffer)
        ZegoCustomVideoProcessManager.sharedInstance().sendProcessedCVPixelBuffer(buffer,
                                                                                  timestamp: timestamp,
                                                                                  channel: channel)
    }
}
