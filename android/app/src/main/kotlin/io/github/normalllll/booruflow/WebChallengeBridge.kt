package io.github.normalllll.booruflow

import android.net.Uri
import android.webkit.CookieManager
import android.webkit.WebStorage
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Raw native reads preserve HttpOnly and values containing multiple '=' signs. */
object WebChallengeBridge {
    private val hosts = setOf(
        "yande.re", "files.yande.re", "assets.yande.re",
        "konachan.net", "www.konachan.net", "konachan.com", "www.konachan.com",
        "danbooru.donmai.us", "cdn.donmai.us", "aibooru.online", "cdn.aibooru.download",
        "gelbooru.com", "www.gelbooru.com", "wallhaven.cc", "w.wallhaven.cc", "th.wallhaven.cc",
        "anime-pictures.net", "api.anime-pictures.net", "opreviews.anime-pictures.net", "oimages.anime-pictures.net",
    )

    fun attach(messenger: BinaryMessenger) {
        MethodChannel(messenger, "booruflow/web_challenge").setMethodCallHandler { call, result ->
            when (call.method) {
                "cookiesForUrl" -> {
                    val text = call.arguments as? String
                    val uri = text?.let { Uri.parse(it) }
                    if (uri == null || uri.scheme != "https" || uri.host !in hosts ||
                        uri.userInfo != null || uri.port !in listOf(-1, 443) ||
                        uri.path !in listOf("", "/") || uri.query != null || uri.fragment != null) {
                        result.error("invalidTarget", "Unsupported cookie target", null)
                    } else {
                        val header = CookieManager.getInstance().getCookie(text) ?: ""
                        if (header.length > 65536) {
                            result.error("cookieLimit", "Cookie limit exceeded", null)
                        } else {
                            result.success(header)
                        }
                    }
                }
                "clearBrowsingData" -> {
                    val manager = CookieManager.getInstance()
                    manager.removeAllCookies {
                        manager.flush()
                        WebStorage.getInstance().deleteAllData()
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
