package com.example.nglclone

import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.yourapp/instagram_share"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareToInstagramStory") {
                val imagePath = call.argument<String>("imagePath")
                if (imagePath != null) {
                    val success = shareToInstagramStory(imagePath)
                    result.success(success)
                } else {
                    result.error("INVALID_ARGUMENT", "Image path is required", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun shareToInstagramStory(imagePath: String): Boolean {
        // Check if Instagram is installed
        if (!isAppInstalled("com.instagram.android")) {
            return false
        }

        try {
            // Convert the file path to a content URI using FileProvider
            val imageFile = File(imagePath)
            val contentUri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                imageFile
            )

            // Create the intent for Instagram Stories
            val intent = Intent("com.instagram.share.ADD_TO_STORY")
            intent.setDataAndType(contentUri, "image/png")
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            // Verify Instagram can handle this intent
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return true
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return false
    }

    private fun isAppInstalled(packageName: String): Boolean {
        try {
            context.packageManager.getPackageInfo(packageName, 0)
            return true
        } catch (e: Exception) {
            return false
        }
    }
}