use rustc_version::version_meta;

fn main() {
    let target = std::env::var("TARGET").expect("TARGET is not set");
    let rustc_meta = version_meta().expect("Failed to get rustc version meta");

    println!("cargo:rustc-env=RUSTC_VERSION={}", rustc_meta.semver);
    println!("cargo:rustc-env=RUSTC_HOST={}", rustc_meta.host);
    println!("cargo:rustc-env=RUSTC_TARGET={}", target);
    println!("cargo:rustc-env=RUSTC_CHANNEL={:?}", rustc_meta.channel);
    println!(
        "cargo:rustc-env=RUSTC_COMMIT_HASH={}",
        rustc_meta
            .commit_hash
            .unwrap_or(String::from("unknown hash"))
    );
    println!(
        "cargo:rustc-env=RUSTC_COMMIT_DATE={}",
        rustc_meta
            .commit_date
            .unwrap_or(String::from("unknown date"))
    );
    println!(
        "cargo:rustc-env=RUSTC_LLVM_VERSION={:?}",
        rustc_meta.llvm_version
    );
}
