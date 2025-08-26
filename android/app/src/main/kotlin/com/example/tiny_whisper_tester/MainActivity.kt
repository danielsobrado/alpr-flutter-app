package com.example.alpr_flutter_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.openalpr.OpenALPR
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "openalpr_flutter"
    private var openALPR: OpenALPR? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val configPath = call.argument<String>("configPath")
                    val runtimeDataPath = call.argument<String>("runtimeDataPath")
                    
                    try {
                        openALPR = OpenALPR.Factory.create(this, File(runtimeDataPath).absolutePath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", "Failed to initialize OpenALPR: ${e.message}", null)
                    }
                }
                "recognizeFile" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val country = call.argument<String>("country") ?: "us"
                    val region = call.argument<String>("region") ?: ""
                    val configPath = call.argument<String>("configPath")
                    val topN = call.argument<Int>("topN") ?: 10
                    
                    if (openALPR == null) {
                        result.error("NOT_INITIALIZED", "OpenALPR not initialized", null)
                        return@setMethodCallHandler
                    }
                    
                    if (imagePath == null || configPath == null) {
                        result.error("INVALID_ARGS", "Missing required arguments", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        val recognitionResult = openALPR!!.recognizeWithCountryRegionNConfig(
                            country, region, configPath, imagePath, topN
                        )
                        result.success(recognitionResult)
                    } catch (e: Exception) {
                        result.error("RECOGNITION_ERROR", "Failed to recognize plates: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
