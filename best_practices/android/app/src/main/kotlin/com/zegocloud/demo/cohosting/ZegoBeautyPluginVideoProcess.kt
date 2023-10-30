package com.zegocloud.demo.cohosting

import android.graphics.SurfaceTexture
import im.zego.effects.entity.ZegoEffectsVideoFrameParam
import im.zego.effects.enums.ZegoEffectsVideoFrameFormat
import im.zego.zego_effects_plugin.ZGEffectsHelper
import im.zego.zego_express_engine.IZegoFlutterCustomVideoProcessHandler
import im.zego.zego_express_engine.ZGFlutterPublishChannel
import im.zego.zego_express_engine.ZGFlutterVideoFrameParam
import im.zego.zego_express_engine.ZegoCustomVideoProcessManager
import java.nio.ByteBuffer

class ZegoBeautyPluginVideoProcess : IZegoFlutterCustomVideoProcessHandler {
    fun enableCustomVideoProcessing() {
        ZegoCustomVideoProcessManager.getInstance().setCustomVideoProcessHandler(this)
    }

    override fun onStart(channel: ZGFlutterPublishChannel) {}
    override fun onStop(channel: ZGFlutterPublishChannel) {}
    override fun onCapturedUnprocessedTextureData(
        textureID: Int, width: Int, height: Int, referenceTimeMillisecond: Long,
        channel: ZGFlutterPublishChannel
    ) {
        val param = ZegoEffectsVideoFrameParam()
        param.format = ZegoEffectsVideoFrameFormat.RGBA32
        param.width = width
        param.height = height
        val processedTextureID = ZGEffectsHelper.getInstance().processTexture(textureID, param)
        ZegoCustomVideoProcessManager.getInstance().sendProcessedTextureData(
            processedTextureID, width, height,
            referenceTimeMillisecond, channel
        )
    }

    override fun onCapturedUnprocessedRawData(
        data: ByteBuffer?,
        dataLength: IntArray?,
        param: ZGFlutterVideoFrameParam?,
        referenceTimeMillisecond: Long,
        channel: ZGFlutterPublishChannel?
    ) {
       
    }

    override fun getCustomVideoProcessInputSurfaceTexture(
        width: Int,
        height: Int,
        channel: ZGFlutterPublishChannel?
    ): SurfaceTexture? {
        return null
    }

    companion object {
        val instance: ZegoBeautyPluginVideoProcess = ZegoBeautyPluginVideoProcess()
    }
}
