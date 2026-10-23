use super::{error, rules, OperationLease};
use crate::api::web_challenge::{WebChallengeCandidate, WebChallengeSpec};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
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

#[cfg(test)]
#[derive(Clone, Copy, PartialEq, Eq)]
enum WindowFixture {
    Capture,
    Cancel,
    Close,
}

struct Job {
    #[cfg(test)]
    fixture: Option<WindowFixture>,
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

static WINDOW_THREAD: OnceLock<Result<mpsc::Sender<Job>, std::io::Error>> = OnceLock::new();

fn window_sender() -> Result<&'static mpsc::Sender<Job>, &'static std::io::Error> {
    WINDOW_THREAD
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
                .map(|_| sender)
        })
        .as_ref()
}

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
    let sender = window_sender().map_err(|cause| window_failure(&source, "thread-start", cause))?;
    let (response, result) = tokio::sync::oneshot::channel();
    sender
        .send(Job {
            #[cfg(test)]
            fixture: None,
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
        .map_err(|cause| window_failure(&source, "worker-send", &cause))?;
    result
        .await
        .map_err(|cause| window_failure(&source, "worker-receive", &cause))?
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

fn window_failure(source: &str, stage: &str, cause: &dyn std::fmt::Display) -> BooruError {
    // Only native window/thread errors enter here. Never pass browser material,
    // request headers, browser arguments or a credential-bearing request URL.
    error(source, BooruErrorCode::Internal, "windowFailed")
        .with_details(format!("stage={stage}\n{cause}"))
}

fn runtime_failure(source: &str, cause: &wry::Error) -> BooruError {
    // A failed environment/controller creation is not proof that Runtime is
    // absent. Only the version-detection API's file-not-found result is.
    let missing = matches!(cause,
        wry::Error::WebView2Error(webview2_com::Error::WindowsError(error))
            if error.code().0 as u32 == 0x80070002);
    if missing {
        error(
            source,
            BooruErrorCode::UnsupportedCapability,
            "runtimeMissing",
        )
        .with_details(format!("stage=runtime-detection\n{cause}"))
    } else {
        window_failure(source, "runtime-detection", cause)
    }
}

#[derive(Clone, Copy)]
enum WindowCompletion {
    Capture,
    Cancel,
    TimedOut,
}

fn run(events: &mut EventLoop<()>, job: &Job) -> BooruResult<WebChallengeCandidate> {
    let source = &job.spec.source_id;
    if job.lease.cancellation.is_cancelled() {
        return Err(error(source, BooruErrorCode::Cancelled, "cancelled"));
    }
    wry::webview_version().map_err(|cause| runtime_failure(source, &cause))?;
    cleanup_profiles(&job.support, source)?;
    let root = profile_root(&job.support);
    std::fs::create_dir_all(&root)
        .map_err(|cause| window_failure(source, "profile-root", &cause))?;
    let profile = tempfile::Builder::new()
        .prefix(&format!("challenge-{source}-"))
        .tempdir_in(&root)
        .map_err(|cause| window_failure(source, "profile-create", &cause))?;
    let mut context = WebContext::new(Some(profile.path().join("webview")));
    let window_builder = WindowBuilder::new()
        .with_title(&job.title)
        .with_inner_size(tao::dpi::LogicalSize::new(1100.0, 800.0));
    #[cfg(test)]
    let window_builder = window_builder
        .with_visible(job.fixture.is_none())
        .with_focused(job.fixture.is_none());
    let window = window_builder
        .build(events)
        .map_err(|cause| window_failure(source, "window-create", &cause))?;
    #[cfg(test)]
    if job.fixture.is_some() {
        assert_ne!(
            unsafe { windows::Win32::UI::WindowsAndMessaging::GetForegroundWindow() }.0 as isize,
            window.hwnd()
        );
    }
    let finish = MenuItem::new(&job.finish_label, true, None);
    let cancel = MenuItem::new(&job.cancel_label, true, None);
    let submenu = Submenu::with_items(&job.spec.display_name, true, &[&finish, &cancel])
        .map_err(|cause| window_failure(source, "menu-create", &cause))?;
    let menu = Menu::with_items(&[&submenu])
        .map_err(|cause| window_failure(source, "menu-create", &cause))?;
    // SAFETY: the menu and HWND belong to this live owning UI thread.
    unsafe { menu.init_for_hwnd(window.hwnd()) }
        .map_err(|cause| window_failure(source, "menu-attach", &cause))?;
    let navigation = job.spec.clone();
    let mut builder = WebViewBuilder::new_with_web_context(&mut context)
        .with_url(&job.spec.entry_url)
        .with_devtools(false)
        .with_navigation_handler(move |url| rules::navigation_allowed(&navigation, &url))
        .with_new_window_req_handler(|_, _| NewWindowResponse::Deny)
        .with_download_started_handler(|_, _| false);
    #[cfg(test)]
    if job.fixture.is_some() {
        builder = WebViewBuilder::new_with_web_context(&mut context)
            .with_focused(false)
            .with_html("<html><body>Local verification fixture</body></html>");
    }
    if let Some(proxy) = validate_proxy(source, job.proxy.as_deref())? {
        builder = builder.with_proxy_config(proxy);
    }
    if let Some(arguments) = &job.browser_args {
        builder = builder.with_additional_browser_args(arguments);
    }
    let view = builder
        .build(&window)
        .map_err(|cause| window_failure(source, "webview-create", &cause))?;
    let allowed = rules::rules(source)?
        .cookie_domains
        .iter()
        .map(|domain| (*domain).into())
        .collect::<Vec<_>>();
    let mut completion = None;
    #[cfg(test)]
    if matches!(
        job.fixture,
        Some(WindowFixture::Capture | WindowFixture::Close)
    ) {
        windows_webview::set_test_cookie(&view, &format!(".{}", allowed[0])).unwrap();
        let captured = windows_webview::read(&view, &allowed).unwrap();
        assert_eq!(captured.len(), 1);
        assert!(captured[0].http_only);
    }
    #[cfg(test)]
    if job.fixture == Some(WindowFixture::Close) {
        use windows::Win32::Foundation::{HWND, LPARAM, WPARAM};
        use windows::Win32::UI::WindowsAndMessaging::{PostMessageW, WM_CLOSE};
        unsafe {
            PostMessageW(
                Some(HWND(window.hwnd() as _)),
                WM_CLOSE,
                WPARAM(0),
                LPARAM(0),
            )
            .unwrap();
        }
    }
    events.run_return(|event, _, control| {
        if completion.is_some() {
            *control = ControlFlow::Exit;
            return;
        }
        *control = ControlFlow::WaitUntil(Instant::now() + Duration::from_millis(100));
        let mut closing = matches!(
            event,
            Event::WindowEvent {
                window_id,
                event: WindowEvent::CloseRequested,
                ..
            } if window_id == window.id()
        );
        let mut cancelling = job.lease.cancellation.is_cancelled();
        #[cfg(test)]
        if let Some(fixture) = job.fixture {
            closing |= fixture == WindowFixture::Capture;
            cancelling |= fixture == WindowFixture::Cancel;
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
        completion = if Instant::now() >= job.lease.deadline {
            Some(WindowCompletion::TimedOut)
        } else if cancelling {
            Some(WindowCompletion::Cancel)
        } else if closing {
            Some(WindowCompletion::Capture)
        } else {
            None
        };
        if completion.is_some() {
            *control = ControlFlow::Exit;
        }
    });
    // WebView2's synchronous wrappers pump the STA. Never run them inside
    // Tao's window-event callback: a nested pump can consume its pending idle
    // transition and strand run_return after WM_CLOSE. Keep the live view until
    // the event loop returns, then capture/clear on the same owning thread.
    window.set_visible(false);
    let result = match completion.unwrap_or(WindowCompletion::Cancel) {
        WindowCompletion::Cancel => Err(error(source, BooruErrorCode::Cancelled, "cancelled")),
        WindowCompletion::TimedOut => Err(error(source, BooruErrorCode::Timeout, "timedOut")),
        WindowCompletion::Capture => (|| {
            let user_agent = windows_webview::user_agent(&view).map_err(|cause| {
                error(source, BooruErrorCode::Internal, "captureFailed")
                    .with_details(format!("stage=capture-user-agent\n{cause}"))
            })?;
            let cookies = windows_webview::read(&view, &allowed)
                .map_err(|cause| {
                    error(source, BooruErrorCode::Internal, "captureFailed")
                        .with_details(format!("stage=capture-cookies\n{cause}"))
                })?
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
        })(),
    };
    let cleared = windows_webview::clear(&view).map_err(|cause| {
        error(source, BooruErrorCode::Internal, "cleanupFailed")
            .with_details(format!("stage=clear-browsing-data\n{cause}"))
    });
    #[cfg(test)]
    if job.fixture.is_some() {
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
        match std::fs::remove_dir_all(&path) {
            Ok(()) => break,
            Err(_) if !path.exists() => break,
            Err(cause) if Instant::now() >= deadline => {
                return Err(error(source, BooruErrorCode::Internal, "cleanupFailed")
                    .with_details(format!("stage=profile-remove\n{cause}")));
            }
            Err(_) => {}
        }
        std::thread::sleep(Duration::from_millis(50));
    }
    cleared?;
    result
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
    let root = std::fs::canonicalize(root).map_err(|cause| {
        error(source, BooruErrorCode::Internal, "cleanupFailed")
            .with_details(format!("stage=profile-cleanup\n{cause}"))
    })?;
    for entry in std::fs::read_dir(&root).map_err(|cause| {
        error(source, BooruErrorCode::Internal, "cleanupFailed")
            .with_details(format!("stage=profile-cleanup\n{cause}"))
    })? {
        let entry = entry.map_err(|cause| {
            error(source, BooruErrorCode::Internal, "cleanupFailed")
                .with_details(format!("stage=profile-cleanup\n{cause}"))
        })?;
        if !entry
            .file_name()
            .to_string_lossy()
            .starts_with(&format!("challenge-{source}-"))
        {
            continue;
        }
        let kind = entry.file_type().map_err(|cause| {
            error(source, BooruErrorCode::Internal, "cleanupFailed")
                .with_details(format!("stage=profile-cleanup\n{cause}"))
        })?;
        if !kind.is_dir() || kind.is_symlink() {
            continue;
        }
        let path = std::fs::canonicalize(entry.path()).map_err(|cause| {
            error(source, BooruErrorCode::Internal, "cleanupFailed")
                .with_details(format!("stage=profile-cleanup\n{cause}"))
        })?;
        if path.parent() != Some(root.as_path()) {
            continue;
        }
        std::fs::remove_dir_all(path).map_err(|cause| {
            error(source, BooruErrorCode::Internal, "cleanupFailed")
                .with_details(format!("stage=profile-cleanup\n{cause}"))
        })?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn failure_details_keep_system_code_without_misdiagnosing_runtime() {
        fn windows_error(code: u32) -> wry::Error {
            wry::Error::WebView2Error(webview2_com::Error::WindowsError(
                windows::core::Error::from_hresult(windows::core::HRESULT(code as i32)),
            ))
        }
        let missing = runtime_failure("aibooru", &windows_error(0x80070002));
        assert_eq!(missing.user_message_key, "webChallenge.runtimeMissing");
        assert!(missing
            .details
            .unwrap()
            .to_ascii_lowercase()
            .contains("80070002"));
        let conflict = runtime_failure("aibooru", &windows_error(0x8007139f));
        assert_eq!(conflict.user_message_key, "webChallenge.windowFailed");
        assert!(conflict
            .details
            .unwrap()
            .to_ascii_lowercase()
            .contains("8007139f"));
        // An installed runtime can still fail to create a window/controller.
        let create = window_failure("aibooru", "webview-create", &windows_error(0x80070002));
        assert_eq!(create.user_message_key, "webChallenge.windowFailed");
        assert!(create
            .details
            .unwrap()
            .starts_with("stage=webview-create\n"));
    }

    #[test]
    #[ignore = "requires Windows desktop and WebView2; hidden local HTML only"]
    fn sequential_sources_close_and_cancel_without_foreground_or_remote_navigation() {
        std::thread::spawn(|| {
            let support = tempfile::tempdir().unwrap();
            let owner =
                super::super::ChallengeCoordinator::shared(support.path().to_str().unwrap())
                    .unwrap();
            let generation = owner.attach_engine().unwrap();
            for (index, (source, proxy, browser_args)) in [
                ("konachan_com", None, None),
                (
                    "aibooru",
                    None,
                    Some("--host-resolver-rules=\"MAP aibooru.online 127.0.0.1\""),
                ),
                ("aibooru", None, None),
                (
                    "konachan_com",
                    None,
                    Some("--host-resolver-rules=\"MAP konachan.com [::1]\""),
                ),
                ("aibooru", Some("http://127.0.0.1:9"), None),
                ("konachan_com", Some("socks5://127.0.0.1:9"), None),
            ]
            .into_iter()
            .enumerate()
            {
                let lease = owner
                    .begin(source, generation, Duration::from_secs(30))
                    .unwrap();
                let (response, received) = tokio::sync::oneshot::channel();
                let job = Job {
                    fixture: Some(if index.is_multiple_of(2) {
                        WindowFixture::Close
                    } else {
                        WindowFixture::Cancel
                    }),
                    support: support.path().into(),
                    spec: WebChallengeSpec {
                        source_id: source.into(),
                        display_name: "Local sequence fixture".into(),
                        entry_url: "about:blank".into(),
                        navigation_hosts: vec![],
                        capture_targets: vec![],
                        timeout_seconds: 30,
                    },
                    lease: lease.clone(),
                    proxy: proxy.map(str::to_owned),
                    browser_args: browser_args.map(str::to_owned),
                    title: "Local sequence fixture".into(),
                    finish_label: "Finish".into(),
                    cancel_label: "Cancel".into(),
                    response,
                };
                eprintln!("opening local sequence index={index} source={source}");
                window_sender()
                    .expect("worker starts")
                    .send(job)
                    .unwrap_or_else(|_| panic!("worker disconnected at index={index}"));
                let result = received.blocking_recv().expect("worker returns result");
                if index.is_multiple_of(2) {
                    let captured = result
                        .unwrap_or_else(|error| panic!("index={index} source={source}: {error:?}"));
                    assert_eq!(captured.cookies.len(), 1);
                    assert_eq!(
                        captured.cookies[0].domain,
                        format!(".{}", rules::rules(source).unwrap().cookie_domains[0])
                    );
                    assert!(!captured.user_agent.is_empty());
                } else {
                    assert_eq!(result.err().unwrap().code, BooruErrorCode::Cancelled);
                }
                owner.cancel(&lease.id).unwrap();
                assert_eq!(
                    std::fs::read_dir(profile_root(support.path()))
                        .unwrap()
                        .count(),
                    0
                );
            }
        })
        .join()
        .unwrap();
    }

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
                    fixture: Some(WindowFixture::Capture),
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
