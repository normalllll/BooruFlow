//! Preserve WebView2's raw domain. wry's cookie::Cookie::domain() strips its dot.

use crate::api::booru_auth::WebCookie;
const MAX_COOKIES: usize = 128;
const MAX_COOKIE_BYTES: usize = 64 * 1024;
use std::sync::mpsc;
use webview2_com::Microsoft::Web::WebView2::Win32::{
    ICoreWebView2Cookie, ICoreWebView2CookieManager, ICoreWebView2Profile2, ICoreWebView2_13,
    ICoreWebView2_2,
};
use webview2_com::{take_pwstr, ClearBrowsingDataCompletedHandler, GetCookiesCompletedHandler};
#[cfg(test)]
use windows::core::HSTRING;
use windows::core::{Interface, BOOL, PCWSTR, PWSTR};
use windows::Win32::Foundation::E_UNEXPECTED;
use wry::{WebView, WebViewExtWindows};

/// Native failures carry only an operation and OS error, never cookie/UA data.
#[derive(Debug, thiserror::Error)]
pub(crate) enum NativeWebViewError {
    #[error("{stage}: {cause}")]
    System {
        stage: &'static str,
        cause: windows::core::Error,
    },
    #[error("{0}")]
    Callback(&'static str),
}

impl From<&'static str> for NativeWebViewError {
    fn from(value: &'static str) -> Self {
        Self::Callback(value)
    }
}

pub(crate) struct CapturedCookie {
    pub material: WebCookie,
    #[cfg(test)]
    pub http_only: bool,
}

fn manager(view: &WebView) -> windows::core::Result<ICoreWebView2CookieManager> {
    // SAFETY: the caller runs on the WebView's owning UI thread. COM wrappers
    // retain their references; no raw pointer escapes this module.
    unsafe {
        let webview: ICoreWebView2_2 = view.controller().CoreWebView2()?.cast()?;
        webview.CookieManager()
    }
}

pub(crate) fn read(
    view: &WebView,
    allowed_domains: &[String],
) -> Result<Vec<CapturedCookie>, NativeWebViewError> {
    let allowed_domains = allowed_domains.to_vec();
    let manager = manager(view).map_err(|cause| NativeWebViewError::System {
        stage: "cookieStoreUnavailable",
        cause,
    })?;
    let (sender, receiver) = mpsc::channel();
    // SAFETY: GetCookies owns its callback until completion. The callback reads
    // COM-owned values into owned Rust strings and sends them over the channel.
    unsafe {
        manager
            .GetCookies(
                PCWSTR::null(),
                &GetCookiesCompletedHandler::create(Box::new(move |error_code, list| {
                    let result = (|| {
                        error_code.map_err(|cause| NativeWebViewError::System {
                            stage: "cookieStoreUnavailable",
                            cause,
                        })?;
                        let list = list.ok_or("cookieStoreUnavailable")?;
                        let mut count = 0;
                        list.Count(&mut count)
                            .map_err(|cause| NativeWebViewError::System {
                                stage: "cookieStoreUnavailable",
                                cause,
                            })?;
                        if count > 1024 {
                            return Err("cookieLimitExceeded".into());
                        }
                        let mut output = Vec::new();
                        let mut bytes = 0;
                        for index in 0..count {
                            let raw = list.GetValueAtIndex(index).map_err(|cause| {
                                NativeWebViewError::System {
                                    stage: "cookieStoreUnavailable",
                                    cause,
                                }
                            })?;
                            let item =
                                convert(raw).map_err(|cause| NativeWebViewError::System {
                                    stage: "cookieMetadataMissing",
                                    cause,
                                })?;
                            let domain = item
                                .material
                                .domain
                                .strip_prefix('.')
                                .unwrap_or(&item.material.domain);
                            if !allowed_domains
                                .iter()
                                .any(|allowed| domain.eq_ignore_ascii_case(allowed))
                            {
                                continue;
                            }
                            let cookie = &item.material;
                            bytes += cookie.name.len()
                                + cookie.value.len()
                                + cookie.domain.len()
                                + cookie.path.len();
                            if output.len() >= MAX_COOKIES || bytes > MAX_COOKIE_BYTES {
                                return Err("cookieLimitExceeded".into());
                            }
                            output.push(item);
                        }
                        Ok(output)
                    })();
                    sender
                        .send(result)
                        .map_err(|_| windows::core::Error::from(E_UNEXPECTED))
                })),
            )
            .map_err(|cause| NativeWebViewError::System {
                stage: "cookieStoreUnavailable",
                cause,
            })?;
    }
    // Like Wry's implementation, pump the STA while awaiting this native callback.
    wait_native(receiver)?
}

unsafe fn convert(cookie: ICoreWebView2Cookie) -> windows::core::Result<CapturedCookie> {
    let mut name = PWSTR::null();
    cookie.Name(&mut name)?;
    let name = take_pwstr(name);
    let mut value = PWSTR::null();
    cookie.Value(&mut value)?;
    let value = take_pwstr(value);
    let mut domain = PWSTR::null();
    cookie.Domain(&mut domain)?;
    let domain = take_pwstr(domain);
    let mut path = PWSTR::null();
    cookie.Path(&mut path)?;
    let path = take_pwstr(path);
    let mut secure = BOOL::default();
    cookie.IsSecure(&mut secure)?;
    let mut http_only = BOOL::default();
    cookie.IsHttpOnly(&mut http_only)?;
    let mut session = BOOL::default();
    cookie.IsSession(&mut session)?;
    let mut expires = 0.0;
    cookie.Expires(&mut expires)?;
    let expires_at_iso8601 = if session.as_bool() {
        None
    } else {
        if !expires.is_finite() {
            return Err(E_UNEXPECTED.into());
        }
        Some(
            time::OffsetDateTime::from_unix_timestamp(expires as i64)
                .map_err(|_| windows::core::Error::from(E_UNEXPECTED))?
                .format(&time::format_description::well_known::Rfc3339)
                .map_err(|_| windows::core::Error::from(E_UNEXPECTED))?,
        )
    };
    Ok(CapturedCookie {
        material: WebCookie {
            name,
            value,
            domain,
            path,
            secure: secure.as_bool(),
            expires_at_iso8601,
        },
        #[cfg(test)]
        http_only: http_only.as_bool(),
    })
}

#[cfg(test)]
pub(crate) fn set_test_cookie(view: &WebView, domain: &str) -> Result<(), NativeWebViewError> {
    let manager = manager(view).map_err(|cause| NativeWebViewError::System {
        stage: "selfTestCookieManagerUnavailable",
        cause,
    })?;
    // SAFETY: this local fixture uses a fresh, isolated WebView2 profile. Native
    // CreateCookie is necessary because Wry normalizes away the leading dot.
    unsafe {
        let cookie = manager
            .CreateCookie(
                &HSTRING::from("spike_http_only"),
                &HSTRING::from("abc=def=="),
                &HSTRING::from(domain),
                &HSTRING::from("/api/v3"),
            )
            .map_err(|cause| NativeWebViewError::System {
                stage: "selfTestSetCookieFailed",
                cause,
            })?;
        cookie
            .SetIsHttpOnly(true)
            .map_err(|cause| NativeWebViewError::System {
                stage: "selfTestSetCookieFailed",
                cause,
            })?;
        cookie
            .SetIsSecure(true)
            .map_err(|cause| NativeWebViewError::System {
                stage: "selfTestSetCookieFailed",
                cause,
            })?;
        cookie
            .SetExpires((time::OffsetDateTime::now_utc().unix_timestamp() + 3600) as f64)
            .map_err(|cause| NativeWebViewError::System {
                stage: "selfTestSetCookieFailed",
                cause,
            })?;
        manager
            .AddOrUpdateCookie(&cookie)
            .map_err(|cause| NativeWebViewError::System {
                stage: "selfTestSetCookieFailed",
                cause,
            })?;
    }
    Ok(())
}

pub(crate) fn clear(view: &WebView) -> Result<(), NativeWebViewError> {
    let (sender, receiver) = mpsc::channel();
    // SAFETY: the view belongs to this UI thread and uses a private test profile.
    // Unlike Wry's fire-and-forget cleanup, await the completion before closing it.
    unsafe {
        let webview: ICoreWebView2_13 = view
            .controller()
            .CoreWebView2()
            .and_then(|view| view.cast())
            .map_err(|cause| NativeWebViewError::System {
                stage: "profileUnavailable",
                cause,
            })?;
        let profile: ICoreWebView2Profile2 = webview
            .Profile()
            .and_then(|profile| profile.cast())
            .map_err(|cause| NativeWebViewError::System {
            stage: "profileUnavailable",
            cause,
        })?;
        profile
            .ClearBrowsingDataAll(&ClearBrowsingDataCompletedHandler::create(Box::new(
                move |result| {
                    sender
                        .send(result.map_err(|cause| NativeWebViewError::System {
                            stage: "profileClearFailed",
                            cause,
                        }))
                        .map_err(|_| windows::core::Error::from(E_UNEXPECTED))
                },
            )))
            .map_err(|cause| NativeWebViewError::System {
                stage: "profileClearFailed",
                cause,
            })?;
    }
    wait_native(receiver)?
}

pub(crate) fn user_agent(view: &WebView) -> Result<String, NativeWebViewError> {
    use webview2_com::Microsoft::Web::WebView2::Win32::ICoreWebView2Settings2;
    // SAFETY: called only on the owning STA; take_pwstr releases the returned buffer.
    unsafe {
        let settings: ICoreWebView2Settings2 = view
            .controller()
            .CoreWebView2()
            .and_then(|view| view.Settings())
            .and_then(|settings| settings.cast())
            .map_err(|cause| NativeWebViewError::System {
                stage: "userAgentUnavailable",
                cause,
            })?;
        let mut value = PWSTR::null();
        settings
            .UserAgent(&mut value)
            .map_err(|cause| NativeWebViewError::System {
                stage: "userAgentUnavailable",
                cause,
            })?;
        Ok(take_pwstr(value))
    }
}

fn wait_native<T>(receiver: mpsc::Receiver<T>) -> Result<T, NativeWebViewError> {
    use windows::Win32::UI::WindowsAndMessaging::{
        DispatchMessageW, PeekMessageW, TranslateMessage, MSG, PM_REMOVE,
    };
    let deadline = std::time::Instant::now() + std::time::Duration::from_secs(10);
    loop {
        match receiver.try_recv() {
            Ok(value) => return Ok(value),
            Err(mpsc::TryRecvError::Disconnected) => return Err("nativeCallbackFailed".into()),
            Err(mpsc::TryRecvError::Empty) => {}
        }
        if std::time::Instant::now() >= deadline {
            return Err("nativeCallbackTimedOut".into());
        }
        // SAFETY: pump only the owning UI thread while its COM callback is pending.
        unsafe {
            let mut message = MSG::default();
            while PeekMessageW(&mut message, None, 0, 0, PM_REMOVE).as_bool() {
                let _ = TranslateMessage(&message);
                DispatchMessageW(&message);
            }
        }
        std::thread::sleep(std::time::Duration::from_millis(5));
    }
}
