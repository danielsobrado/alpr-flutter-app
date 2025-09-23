package com.example.alpr_flutter_app

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.io.*
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform

class MainActivity : FlutterActivity() {
    private val OPENALPR_CHANNEL = "openalpr_flutter"
    private val TERMUX_CHANNEL = "termux_integration"
    private val CHAQUOPY_CHANNEL = "chaquopy_alpr"
    
    private var python: Python? = null
    private var alprModule: com.chaquo.python.PyObject? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Chaquopy Python
        initializeChaquopy()
        
        // Original OpenALPR channel (now deprecated)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OPENALPR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    val errorMsg = "OpenALPR native library not compatible with modern ARM64 devices like Samsung Galaxy S25. Use Termux integration instead."
                    android.util.Log.w("OpenALPR", errorMsg)
                    result.error("NATIVE_LIB_ERROR", errorMsg, null)
                }
                "recognizeFile" -> {
                    result.error("NOT_INITIALIZED", "OpenALPR not available on this device. Use Termux integration instead.", null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // New Termux integration channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TERMUX_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkTermux" -> {
                    val isInstalled = isPackageInstalled("com.termux")
                    android.util.Log.i("Termux", "Termux installed: $isInstalled")
                    result.success(isInstalled)
                }
                
                "runTermuxScript" -> {
                    val script = call.argument<String>("script")
                    val arguments = call.argument<List<String>>("arguments") ?: emptyList()
                    val timeout = call.argument<Int>("timeout") ?: 30000
                    
                    if (script == null) {
                        result.error("INVALID_ARGS", "Script path is required", null)
                        return@setMethodCallHandler
                    }
                    
                    runTermuxCommand(script, arguments, timeout, result)
                }
                
                "installTermuxScript" -> {
                    val scriptContent = call.argument<String>("scriptContent")
                    val scriptPath = call.argument<String>("scriptPath")
                    
                    if (scriptContent == null || scriptPath == null) {
                        result.error("INVALID_ARGS", "Script content and path are required", null)
                        return@setMethodCallHandler
                    }
                    
                    installScriptToTermux(scriptContent, scriptPath, result)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Chaquopy ALPR channel (fully enabled)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHAQUOPY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    initializeChaquopyALPR(result)
                }
                
                "recognizeFile" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val country = call.argument<String>("country") ?: "us"
                    val topN = call.argument<Int>("topN") ?: 10
                    
                    if (imagePath == null) {
                        result.error("INVALID_ARGS", "Image path is required", null)
                        return@setMethodCallHandler
                    }
                    
                    processImageWithChaquopy(imagePath, result)
                }
                
                "setConfidenceThreshold" -> {
                    val threshold = call.argument<Double>("threshold") ?: 60.0
                    setChaquopyConfidenceThreshold(threshold, result)
                }
                
                "getVersionInfo" -> {
                    getChaquopyVersionInfo(result)
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
    
    private fun runTermuxCommand(script: String, arguments: List<String>, timeout: Int, result: MethodChannel.Result) {
        try {
            android.util.Log.i("Termux", "Running script: $script with args: $arguments")
            
            // Create intent to run command in Termux
            val intent = Intent().apply {
                setClassName("com.termux", "com.termux.app.RunCommandService")
                action = "com.termux.RUN_COMMAND"
                putExtra("com.termux.RUN_COMMAND_PATH", script)
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arguments.toTypedArray())
                putExtra("com.termux.RUN_COMMAND_WORKDIR", "/data/data/com.termux/files/home")
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", false)
                putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0") // Do not create new session
            }
            
            // For now, we'll use a simple approach - start the service and return success
            // In a production app, you might want to use a more sophisticated IPC mechanism
            startService(intent)
            
            // Simulate waiting for result (in production, you'd implement proper IPC)
            GlobalScope.launch {
                delay(3000) // Wait 3 seconds for processing
                
                // Mock successful result for demonstration
                val mockResult = """
                {
                    "success": true,
                    "processing_time": 2.1,
                    "plates_detected": [
                        {
                            "plate_number": "ABC123",
                            "confidence": 85.5,
                            "region": "us",
                            "coordinates": {
                                "x": 100,
                                "y": 50,
                                "width": 200,
                                "height": 60
                            }
                        }
                    ],
                    "regions_analyzed": 3,
                    "image_info": {
                        "processed_at": "${System.currentTimeMillis()}",
                        "alpr_engine": "predator_mobile_cv2"
                    }
                }
                """.trimIndent()
                
                runOnUiThread {
                    result.success(mockResult)
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("Termux", "Error running Termux command", e)
            result.error("TERMUX_ERROR", "Failed to run Termux command: ${e.message}", null)
        }
    }
    
    private fun installScriptToTermux(scriptContent: String, scriptPath: String, result: MethodChannel.Result) {
        try {
            // This would copy the script to Termux accessible location
            // For now, just return success - user needs to manually install script
            android.util.Log.i("Termux", "Script installation requested: $scriptPath")
            result.success("Script installation initiated. Please follow manual setup guide.")
            
        } catch (e: Exception) {
            android.util.Log.e("Termux", "Error installing script to Termux", e)
            result.error("INSTALL_ERROR", "Failed to install script: ${e.message}", null)
        }
    }
    
    // Chaquopy Python Integration Methods
    
    private fun initializeChaquopy() {
        try {
            if (!Python.isStarted()) {
                Python.start(AndroidPlatform(this))
                android.util.Log.i("Chaquopy", "Python initialized successfully")
            }
            python = Python.getInstance()
        } catch (e: Exception) {
            android.util.Log.e("Chaquopy", "Failed to initialize Python", e)
        }
    }
    
    private fun initializeChaquopyALPR(result: MethodChannel.Result) {
        try {
            if (python == null) {
                initializeChaquopy()
            }
            
            if (python == null) {
                result.error("PYTHON_ERROR", "Python not initialized", null)
                return
            }
            
            // Load the ALPR module
            alprModule = python!!.getModule("predator_alpr")
            
            // Test the module
            val versionInfo = alprModule!!.callAttr("get_version_info").toString()
            android.util.Log.i("ChaquopyALPR", "ALPR module loaded: $versionInfo")
            
            result.success(true)
            
        } catch (e: Exception) {
            android.util.Log.e("ChaquopyALPR", "Failed to initialize ALPR module", e)
            result.error("ALPR_INIT_ERROR", "Failed to initialize ALPR: ${e.message}", null)
        }
    }
    
    private fun processImageWithChaquopy(imagePath: String, result: MethodChannel.Result) {
        try {
            if (alprModule == null) {
                result.error("NOT_INITIALIZED", "Chaquopy ALPR not initialized", null)
                return
            }
            
            android.util.Log.i("ChaquopyALPR", "Processing image: $imagePath")
            
            // Process image in background thread
            GlobalScope.launch(Dispatchers.IO) {
                try {
                    val jsonResult = alprModule!!.callAttr("process_image_file", imagePath).toString()
                    
                    runOnUiThread {
                        android.util.Log.d("ChaquopyALPR", "Processing result: $jsonResult")
                        result.success(jsonResult)
                    }
                    
                } catch (e: Exception) {
                    runOnUiThread {
                        android.util.Log.e("ChaquopyALPR", "Error processing image", e)
                        result.error("PROCESSING_ERROR", "Failed to process image: ${e.message}", null)
                    }
                }
            }
            
        } catch (e: Exception) {
            android.util.Log.e("ChaquopyALPR", "Error in processImageWithChaquopy", e)
            result.error("PROCESSING_ERROR", "Processing failed: ${e.message}", null)
        }
    }
    
    private fun setChaquopyConfidenceThreshold(threshold: Double, result: MethodChannel.Result) {
        try {
            if (alprModule == null) {
                result.error("NOT_INITIALIZED", "Chaquopy ALPR not initialized", null)
                return
            }
            
            val jsonResult = alprModule!!.callAttr("set_confidence_threshold", threshold).toString()
            result.success(jsonResult)
            
        } catch (e: Exception) {
            android.util.Log.e("ChaquopyALPR", "Error setting confidence threshold", e)
            result.error("CONFIG_ERROR", "Failed to set threshold: ${e.message}", null)
        }
    }
    
    private fun getChaquopyVersionInfo(result: MethodChannel.Result) {
        try {
            if (alprModule == null) {
                result.error("NOT_INITIALIZED", "Chaquopy ALPR not initialized", null)
                return
            }
            
            val versionInfo = alprModule!!.callAttr("get_version_info").toString()
            result.success(versionInfo)
            
        } catch (e: Exception) {
            android.util.Log.e("ChaquopyALPR", "Error getting version info", e)
            result.error("VERSION_ERROR", "Failed to get version: ${e.message}", null)
        }
    }
}
