use flutter_rust_bridge::frb;

#[frb(sync)]
pub fn rustc_version() -> String {
    format!(
        "{} ({}) ({}) {}\nCompiled from \"{}\" to \"{}\"",
        env!("RUSTC_VERSION"),
        env!("RUSTC_CHANNEL"),
        env!("RUSTC_COMMIT_DATE"),
        env!("RUSTC_COMMIT_HASH"),
        env!("RUSTC_HOST"),
        env!("RUSTC_TARGET"),
    )
}
