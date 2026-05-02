package com.example.amn_app

import android.Manifest
import android.app.Activity
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.telecom.TelecomManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

object AndroidCallController {
    private const val REQUEST_PERMISSIONS = 1201
    private const val REQUEST_ROLE = 1202
    private lateinit var applicationContext: Context

    fun initialize(context: Context) {
        applicationContext = context.applicationContext
    }

    fun requestSetup(activity: Activity) {
        requestMissingPermissions(activity)
        requestDialerRole(activity)
    }

    fun hasRequiredPermissions(): Boolean {
        val answerGranted = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ANSWER_PHONE_CALLS,
        ) == PackageManager.PERMISSION_GRANTED
        val readGranted = ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.READ_PHONE_STATE,
        ) == PackageManager.PERMISSION_GRANTED
        return answerGranted && readGranted
    }

    fun requestMissingPermissions(activity: Activity) {
        val missing = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.ANSWER_PHONE_CALLS) != PackageManager.PERMISSION_GRANTED) {
            missing.add(Manifest.permission.ANSWER_PHONE_CALLS)
        }
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            missing.add(Manifest.permission.READ_PHONE_STATE)
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(activity, missing.toTypedArray(), REQUEST_PERMISSIONS)
        }
    }

    fun isDefaultDialer(): Boolean {
        if (!::applicationContext.isInitialized) {
            return false
        }
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = applicationContext.getSystemService(RoleManager::class.java)
            roleManager?.isRoleHeld(RoleManager.ROLE_DIALER) == true
        } else {
            val telecomManager = applicationContext.getSystemService(TelecomManager::class.java)
            telecomManager?.defaultDialerPackage == applicationContext.packageName
        }
    }

    fun requestDialerRole(activity: Activity) {
        if (isDefaultDialer()) {
            return
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = activity.getSystemService(RoleManager::class.java)
            val intent = roleManager?.createRequestRoleIntent(RoleManager.ROLE_DIALER)
            if (intent != null) {
                activity.startActivityForResult(intent, REQUEST_ROLE)
            }
        } else {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
            intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, activity.packageName)
            activity.startActivityForResult(intent, REQUEST_ROLE)
        }
    }
}
