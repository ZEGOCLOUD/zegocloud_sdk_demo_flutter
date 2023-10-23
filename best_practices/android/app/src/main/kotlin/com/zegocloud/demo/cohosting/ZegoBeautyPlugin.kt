package com.zegocloud.demo.cohosting

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class ZegoBeautyPlugin(flutterEngine: BinaryMessenger, context: Context): MethodChannel.MethodCallHandler {

    private val channelName = "zego_beauty_effects"
    private val channel: MethodChannel
    private val mContext: Context

    init {
        channel = MethodChannel(flutterEngine, channelName)
        channel.setMethodCallHandler(this)
        mContext = context
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "enableCustomVideoProcessing") {
            ZegoBeautyPluginVideoProcess.instance.enableCustomVideoProcessing()
            result.success(null)
        } else if (call.method == "getResourcesFolder") {
            val path = mContext.externalCacheDir?.path + File.separator + "BeautyResources"
            
            // copy all files from assets.
            ZegoFileUtil.copyFileFromAssets(mContext, "BeautyResources", path)
            Log.i("TAG", "onMethodCall: $path")

            result.success(path)
        } else {
            result.notImplemented()
        }
    }
}