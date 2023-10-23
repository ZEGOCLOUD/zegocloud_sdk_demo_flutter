package com.zegocloud.demo.cohosting

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream

object ZegoFileUtil {
    fun copyFileFromAssets(context: Context, assetsFilePath: String, targetFileFullPath: String) {
        try {
            val fileNames = context.assets.list(assetsFilePath) //获取assets目录下的所有文件及目录名
            val file = File(targetFileFullPath)
            if (fileNames!!.isNotEmpty()) {
                file.mkdirs()
                for (fileName in fileNames) {
                    copyFileFromAssets(
                        context,
                        assetsFilePath + File.separator + fileName,
                        targetFileFullPath + File.separator + fileName
                    )
                }
            } else { //如果是文件
                val fileTemp = File("$targetFileFullPath.temp")
                if (file.exists()) {
                    Log.d("Tag", "文件存在")
                    return
                }
                fileTemp.parentFile.mkdir()
                val `is` = context.assets.open(assetsFilePath)
                val fos = FileOutputStream(fileTemp)
                val buffer = ByteArray(1024)
                var byteCount = 0
                while (`is`.read(buffer).also { byteCount = it } != -1) { //循环从输入流读取 buffer字节
                    fos.write(buffer, 0, byteCount) //将读取的输入流写入到输出流
                }
                fos.flush() //刷新缓冲区
                `is`.close()
                fos.close()
                fileTemp.renameTo(file)
            }
        } catch (e: Exception) {
            Log.d("Tag", "copyFileFromAssets " + "IOException-" + e.message)
        }
    }
}
