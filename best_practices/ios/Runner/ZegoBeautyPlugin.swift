//
//  ZegoBeautyPlugin.swift
//  Runner
//
//  Created by Kael Ding on 2023/6/29.
//

import Foundation
import Flutter

public class ZegoBeautyPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "zego_beauty_effects", binaryMessenger: registrar.messenger())
        let instance = ZegoBeautyPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "enableCustomVideoProcessing" {
            ZegoBeautyPluginVideoProcess.shared.enableCustomVideoProcessing()
            result(nil)
        } else if call.method == "getResourcesFolder" {
            let path = Bundle.main.path(forResource: "BeautyResources", ofType: nil)
            result(path)
        }
    }
}
