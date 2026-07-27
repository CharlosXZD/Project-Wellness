package com.example.project_wellness

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (not FlutterActivity) is required by the `health`
// plugin on Android 14+: it needs registerForActivityResult when requesting
// Health Connect permissions, which requires a ComponentActivity/FragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "project_wellness/app_icon"
    private val greenAlias = "com.example.project_wellness.MainActivityGreen"
    private val pinkAlias = "com.example.project_wellness.MainActivityPink"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "setIcon") {
                    val seed = call.argument<String>("seed")
                    val enableAlias = if (seed == "pink") pinkAlias else greenAlias
                    val disableAlias = if (seed == "pink") greenAlias else pinkAlias
                    try {
                        setAliasEnabled(disableAlias, false)
                        setAliasEnabled(enableAlias, true)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SET_ICON_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun setAliasEnabled(aliasClassName: String, enabled: Boolean) {
        val pm = packageManager
        val component = ComponentName(packageName, aliasClassName)
        val newState = if (enabled) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        pm.setComponentEnabledSetting(component, newState, PackageManager.DONT_KILL_APP)
    }
}
