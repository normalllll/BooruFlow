use super::{error, rules, OperationLease};
use crate::api::web_challenge::{WebChallengeCandidate, WebChallengeSpec};
use crate::booru::error::{BooruErrorCode, BooruResult};
use crate::windows_webview;
use muda::{Menu, MenuEvent, MenuItem, Submenu};
use std::path::{Path, PathBuf};
use std::sync::{mpsc, OnceLock};
use std::time::{Duration, Instant};
use tao::event::{Event, WindowEvent};
use tao::event_loop::{ControlFlow, EventLoop, EventLoopBuilder};
use tao::platform::run_return::EventLoopExtRunReturn;
use tao::platform::windows::{EventLoopBuilderExtWindows, WindowExtWindows};
use tao::window::WindowBuilder;
use wry::{
    NewWindowResponse, ProxyConfig, ProxyEndpoint, WebContext, WebViewBuilder,
    WebViewBuilderExtWindows,
};

struct Job {
    #[cfg(test)]
    fixture: bool,
    support: PathBuf,
    spec: WebChallengeSpec,
    lease: OperationLease,
    proxy: Option<String>,
    browser_args: Option<String>,
    title: String,
    finish_label: String,
    cancel_label: String,
    response: tokio::sync::oneshot::Sender<BooruResult<WebChallengeCandidate>>,
}

static WINDOW_THREAD: OnceLock<Option<mpsc::Sender<Job>>> = OnceLock::new();

pub async fn collect(
    support: PathBuf,
    spec: WebChallengeSpec,
    lease: OperationLease,
    proxy: Option<String>,
    browser_args: Option<String>,
    title: String,
    finish_label: String,
    cancel_label: String,
) -> BooruResult<WebChallengeCandidate> {
    let source = spec.source_id.clone();
    let sender = WINDOW_THREAD
        .get_or_init(|| {
            let (sender, receiver) = mpsc::channel::<Job>();
            std::thread::Builder::new()
                .name("booruflow-web-verification".into())
                .spawn(move || {
                    // Windows supports a dedicated owning UI thread. Keep one event loop
                    // for the process and reuse run_return for subsequent windows.
                    let mut events = EventLoopBuilder::new()
                        .with_any_thread(true)
                        .with_dpi_aware(false)
                        .build();
                    for job in receiver {
                        let result = run(&mut events, &job);
                        let _ = job.response.send(result);
                    }
                })
                .ok()
                .map(|_| sender)
        })
        .as_ref()
        .ok_or_else(|| {
            error(
                &source,
                BooruErrorCode::UnsupportedCapability,
                "webViewUnavailable",
            )
        })?;
    let (response, result) = tokio::sync::oneshot::channel();
    sender
        .send(Job {
            #[cfg(test)]
            fixture: false,
            support,
            spec,
            lease,
            proxy,
            browser_args,
            title,
            finish_label,
            cancel_label,
            response,
        })
        .map_err(|_| {
            error(
                &source,
                BooruErrorCode::UnsupportedCapability,
                "webViewUnavailable",
            )
        })?;
    result
        .await
        .map_err(|_| error(&source, BooruErrorCode::Internal, "webViewUnavailable"))?
}

pub fn validate_proxy(source: &str, value: Option<&str>) -> BooruResult<Option<ProxyConfig>> {
    let Some(value) = value else {
        return Ok(None);
    };
    let url = reqwest::Url::parse(value).map_err(|_| {
        error(
            source,
            BooruErrorCode::UnsupportedCapability,
            "proxyUnsupported",
        )
    })?;
    if !url.username().is_empty() || url.password().is_some() {
        return Err(error(
            source,
            BooruErrorCode::UnsupportedCapability,
            "proxyUnsupported",
        ));
    }
    let endpoint = ProxyEndpoint {
        host: url
            .host_str()
            .ok_or_else(|| {
                error(
                    source,
                    BooruErrorCode::UnsupportedCapability,
                    "proxyUnsupported",
                )
            })?
            .into(),
        port: url
            .port_or_known_default()
            .or_else(|| matches!(url.scheme(), "socks5" | "socks5h").then_some(1080))
            .ok_or_else(|| {
                error(
                    source,
                    BooruErrorCode::UnsupportedCapability,
                    "proxyUnsupported",
                )
            })?
            .to_string(),
    };
    match url.scheme() {
        "http" => Ok(Some(ProxyConfig::Http(endpoint))),
        "socks5" | "socks5h" => Ok(Some(ProxyConfig::Socks5(endpoint))),
        _ => Err(error(
            source,
            BooruErrorCode::UnsupportedCapability,
            "proxyUnsupported",
        )),
    }
}

fn run(events: &mut EventLoop<()>, job: &Job) -> BooruResult<WebChallengeCandidate> {
    let source = &job.spec.source_id;
    if job.lease.cancellation.is_cancelled() {
        return Err(error(source, BooruErrorCode::Cancelled, "cancelled"));
    }
    cleanup_profiles(&job.support, source)?;
    let root = profile_root(&job.support);
    std::fs::create_dir_all(&root)
        .map_err(|_| error(source, BooruErrorCode::Internal, "storageFailed"))?;
    let profile = tempfile::Builder::new()
        .prefix(&format!("challenge-{source}-"))
        .tempdir_in(&root)
        .map_err(|_| error(source, BooruErrorCode::Internal, "storageFailed"))?;
    let mut context = WebContext::new(Some(profile.path().join("webview")));
    let window = WindowBuilder::new()
        .with_title(&job.title)
        .with_inner_size(tao::dpi::LogicalSize::new(1100.0, 800.0))
        .build(events)
        .map_err(|_| {
            error(
                source,
                BooruErrorCode::UnsupportedCapability,
                "webViewUnavailable",
            )
        })?;
    #[cfg(test)]
    if job.fixture {
        window.set_visible(false);
    }
    let finish = MenuItem::new(&job.finish_label, true, None);
    let cancel = MenuItem::new(&job.cancel_label, true, None);
    let submenu = Submenu::with_items(&job.spec.display_name, true, &[&finish, &cancel])
        .map_err(|_| error(source, BooruErrorCode::Internal, "unavailable"))?;
    let menu = Menu::with_items(&[&submenu])
        .map_err(|_| error(source, BooruErrorCode::Internal, "unavailable"))?;
    // SAFETY: the menu and HWND belong to this live owning UI thread.
    unsafe { menu.init_for_hwnd(window.hwnd()) }
        .map_err(|_| error(source, BooruErrorCode::Internal, "unavailable"))?;
    let navigation = job.spec.clone();
    let mut builder = WebViewBuilder::new_with_web_context(&mut context)
        .with_url(&job.spec.entry_url)
        .with_devtools(false)
        .with_navigation_handler(move |url| rules::navigation_allowed(&navigation, &url))
        .with_new_window_req_handler(|_, _| NewWindowResponse::Deny)
        .with_download_started_handler(|_, _| false);
    #[cfg(test)]
    if job.fixture {
        builder = WebViewBuilder::new_with_web_context(&mut context)
            .with_html("<html><body>Local verification fixture</body></html>");
    }
    if let Some(proxy) = validate_proxy(source, job.proxy.as_deref())? {
        builder = builder.with_proxy_config(proxy);
    }
    if let Some(arguments) = &job.browser_args {
        builder = builder.with_additional_browser_args(arguments);
    }
    let view = builder.build(&window).map_err(|_| {
        error(
            source,
            BooruErrorCode::UnsupportedCapability,
            "webViewUnavailable",
        )
    })?;
    let allowed = rules::rules(source)?
        .cookie_domains
        .iter()
        .map(|domain| (*domain).into())
        .collect::<Vec<_>>();
    let mut result = None;
    let mut finished = false;
    #[cfg(test)]
    if job.fixture {
        windows_webview::set_test_cookie(&view).unwrap();
        let captured = windows_webview::read(&view, &allowed).unwrap();
        assert_eq!(captured.len(), 1);
        assert!(captured[0].http_only);
    }
    events.run_return(|event, _, control| {
        if finished {
            *control = ControlFlow::Exit;
            return;
        }
        *control = ControlFlow::WaitUntil(Instant::now() + Duration::from_millis(100));
        let mut closing = matches!(
            event,
            Event::WindowEvent {
                event: WindowEvent::CloseRequested,
                ..
            }
        );
        let mut cancelling = job.lease.cancellation.is_cancelled();
        #[cfg(test)]
        if job.fixture {
            closing = true;
        }
        // Muda's global handler is write-once. Poll its channel so sequential
        // verification windows do not retain the first window's event proxy.
        while let Ok(event) = MenuEvent::receiver().try_recv() {
            if event.id == *finish.id() {
                closing = true;
            }
            if event.id == *cancel.id() {
                cancelling = true;
            }
        }
        if Instant::now() >= job.lease.deadline {
            result = Some(Err(error(source, BooruErrorCode::Timeout, "timedOut")));
            finished = true;
        } else if cancelling {
            result = Some(Err(error(source, BooruErrorCode::Cancelled, "cancelled")));
            finished = true;
        } else if closing {
            // Capture before destroying WebView2, including native HttpOnly
            // cookies and the actual browser UA. No page JavaScript is trusted.
            result = Some((|| {
                let user_agent = windows_webview::user_agent(&view)
                    .map_err(|_| error(source, BooruErrorCode::Internal, "captureFailed"))?;
                let cookies = windows_webview::read(&view, &allowed)
                    .map_err(|_| error(source, BooruErrorCode::Internal, "captureFailed"))?
                    .into_iter()
                    .map(|cookie| cookie.material)
                    .collect::<Vec<_>>();
                if cookies.is_empty() {
                    return Err(error(source, BooruErrorCode::InvalidRequest, "noCookies"));
                }
                Ok(WebChallengeCandidate {
                    cookies,
                    snapshots: vec![],
                    user_agent,
                })
            })());
            finished = true;
        }
        if finished {
            window.set_visible(false);
            *control = ControlFlow::Exit;
        }
    });
    let cleared = windows_webview::clear(&view)
        .map_err(|_| error(source, BooruErrorCode::Internal, "cleanupFailed"));
    #[cfg(test)]
    if job.fixture {
        assert!(windows_webview::read(&view, &allowed).unwrap().is_empty());
    }
    drop(view);
    drop(context);
    drop(window);
    drop(menu);
    // WebView2 may release file handles shortly after its controllers close.
    let path = profile.keep();
    let deadline = Instant::now() + Duration::from_secs(5);
    loop {
        if std::fs::remove_dir_all(&path).is_ok() || !path.exists() {
            break;
        }
        if Instant::now() >= deadline {
            return Err(error(source, BooruErrorCode::Internal, "cleanupFailed"));
        }
        std::thread::sleep(Duration::from_millis(50));
    }
    cleared?;
    result.unwrap_or_else(|| Err(error(source, BooruErrorCode::Cancelled, "cancelled")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    #[ignore = "requires Windows desktop and WebView2; local HTML only"]
    fn repeated_native_capture_and_cleanup() {
        std::thread::spawn(|| {
            let support = tempfile::tempdir().unwrap();
            let owner =
                super::super::ChallengeCoordinator::shared(support.path().to_str().unwrap())
                    .unwrap();
            let generation = owner.attach_engine().unwrap();
            let mut events = EventLoopBuilder::new()
                .with_any_thread(true)
                .with_dpi_aware(false)
                .build();
            for _ in 0..2 {
                let lease = owner
                    .begin("anime_pictures", generation, Duration::from_secs(30))
                    .unwrap();
                let (response, _) = tokio::sync::oneshot::channel();
                let job = Job {
                    fixture: true,
                    support: support.path().into(),
                    spec: WebChallengeSpec {
                        source_id: "anime_pictures".into(),
                        display_name: "Local fixture".into(),
                        entry_url: "https://anime-pictures.net/".into(),
                        navigation_hosts: vec![],
                        capture_targets: vec![],
                        timeout_seconds: 30,
                    },
                    lease: lease.clone(),
                    proxy: None,
                    browser_args: None,
                    title: "Local fixture".into(),
                    finish_label: "Finish".into(),
                    cancel_label: "Cancel".into(),
                    response,
                };
                let value = run(&mut events, &job).unwrap();
                assert_eq!(value.cookies[0].domain, ".anime-pictures.net");
                assert_eq!(value.cookies[0].path, "/api/v3");
                assert_eq!(value.cookies[0].value, "abc=def==");
                assert!(!value.user_agent.is_empty());
                assert_eq!(
                    std::fs::read_dir(profile_root(support.path()))
                        .unwrap()
                        .count(),
                    0
                );
                owner.cancel(&lease.id).unwrap();
            }
        })
        .join()
        .unwrap();
    }
}

fn profile_root(support: &Path) -> PathBuf {
    support.join("web-verification").join("browser")
}

/// Only this application's registered temporary profiles are removed. Symlinks
/// and paths resolving outside the dedicated root are never followed.
pub fn cleanup_profiles(support: &Path, source: &str) -> BooruResult<()> {
    rules::rules(source)?;
    let root = profile_root(support);
    if !root.exists() {
        return Ok(());
    }
    let root = std::fs::canonicalize(root)
        .map_err(|_| error("network", BooruErrorCode::Internal, "cleanupFailed"))?;
    for entry in std::fs::read_dir(&root)
        .map_err(|_| error("network", BooruErrorCode::Internal, "cleanupFailed"))?
    {
        let entry =
            entry.map_err(|_| error("network", BooruErrorCode::Internal, "cleanupFailed"))?;
        if !entry
            .file_name()
            .to_string_lossy()
            .starts_with(&format!("challenge-{source}-"))
        {
            continue;
        }
        let kind = entry
            .file_type()
            .map_err(|_| error("network", BooruErrorCode::Internal, "cleanupFailed"))?;
        if !kind.is_dir() || kind.is_symlink() {
            continue;
        }
        let path = std::fs::canonicalize(entry.path())
            .map_err(|_| error("network", BooruErrorCode::Internal, "cleanupFailed"))?;
        if path.parent() != Some(root.as_path()) {
            continue;
        }
        std::fs::remove_dir_all(path)
            .map_err(|_| error("network", BooruErrorCode::Internal, "cleanupFailed"))?;
    }
    Ok(())
}
