use super::{error, rules::RULES_VERSION};
use crate::api::web_challenge::WebChallengeCandidate;
use crate::booru::error::{BooruErrorCode, BooruResult};
use serde::{Deserialize, Serialize};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};

const MAX_RECORD: u64 = 1024 * 1024;

#[derive(Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Record {
    pub version: u32,
    pub rules_version: u32,
    pub source_id: String,
    pub commit_id: String,
    pub verified_at: Option<String>,
    pub material: Option<WebChallengeCandidate>,
}

pub struct Storage {
    directory: PathBuf,
}
pub struct PreparedRecord {
    temporary: tempfile::NamedTempFile,
    path: PathBuf,
    source: String,
}

impl Storage {
    pub fn new(support: &Path) -> Self {
        Self {
            directory: support.join("web-verification").join("sessions-v1"),
        }
    }

    fn path(&self, source: &str) -> BooruResult<PathBuf> {
        super::rules::rules(source)?;
        Ok(self.directory.join(format!("{source}.session")))
    }

    pub fn read(&self, source: &str) -> BooruResult<Option<Record>> {
        let file = match std::fs::File::open(self.path(source)?) {
            Ok(file) => file,
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(None),
            Err(_) => return Err(storage_error(source)),
        };
        let mut bytes = Vec::new();
        file.take(MAX_RECORD + 1)
            .read_to_end(&mut bytes)
            .map_err(|_| storage_error(source))?;
        if bytes.len() as u64 > MAX_RECORD {
            return Err(storage_error(source));
        }
        let plain = unprotect(&bytes).map_err(|_| storage_error(source))?;
        let record: Record = serde_json::from_slice(&plain).map_err(|_| storage_error(source))?;
        if record.version != 1
            || record.rules_version != RULES_VERSION
            || record.source_id != source
        {
            return Err(storage_error(source));
        }
        Ok(Some(record))
    }

    pub fn prepare(&self, record: &Record) -> BooruResult<PreparedRecord> {
        let source = &record.source_id;
        let path = self.path(source)?;
        let plain = serde_json::to_vec(record).map_err(|_| storage_error(source))?;
        if plain.len() as u64 > MAX_RECORD / 2 {
            return Err(storage_error(source));
        }
        let bytes = protect(&plain).map_err(|_| storage_error(source))?;
        std::fs::create_dir_all(&self.directory).map_err(|_| storage_error(source))?;
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            std::fs::set_permissions(&self.directory, std::fs::Permissions::from_mode(0o700))
                .map_err(|_| storage_error(source))?;
        }
        // NamedTempFile is mode 0600 on Unix. On Windows the contents are DPAPI
        // encrypted for the current user, including the stored browser identity.
        let mut temporary =
            tempfile::NamedTempFile::new_in(&self.directory).map_err(|_| storage_error(source))?;
        temporary
            .write_all(&bytes)
            .map_err(|_| storage_error(source))?;
        temporary
            .as_file()
            .sync_all()
            .map_err(|_| storage_error(source))?;
        Ok(PreparedRecord {
            temporary,
            path,
            source: source.clone(),
        })
    }
}

impl PreparedRecord {
    pub fn commit(self) -> BooruResult<()> {
        self.temporary
            .persist(&self.path)
            .map_err(|_| storage_error(&self.source))?;
        // A rename has committed. Failure of a subsequent directory sync cannot
        // truthfully be reported as a failed replacement or roll back live state.
        #[cfg(unix)]
        if let Some(parent) = self.path.parent() {
            if let Ok(directory) = std::fs::File::open(parent) {
                let _ = directory.sync_all();
            }
        }
        Ok(())
    }
}

fn storage_error(source: &str) -> crate::booru::error::BooruError {
    error(source, BooruErrorCode::Internal, "storageFailed")
}

#[cfg(not(windows))]
fn protect(bytes: &[u8]) -> Result<Vec<u8>, ()> {
    Ok(bytes.to_vec())
}
#[cfg(not(windows))]
fn unprotect(bytes: &[u8]) -> Result<Vec<u8>, ()> {
    Ok(bytes.to_vec())
}

#[cfg(windows)]
fn protect(bytes: &[u8]) -> Result<Vec<u8>, ()> {
    dpapi(bytes, true)
}
#[cfg(windows)]
fn unprotect(bytes: &[u8]) -> Result<Vec<u8>, ()> {
    dpapi(bytes, false)
}

#[cfg(windows)]
fn dpapi(bytes: &[u8], encrypt: bool) -> Result<Vec<u8>, ()> {
    use std::ffi::c_void;
    #[repr(C)]
    struct Blob {
        length: u32,
        data: *mut u8,
    }
    #[link(name = "crypt32")]
    extern "system" {
        fn CryptProtectData(
            input: *const Blob,
            description: *const u16,
            entropy: *const Blob,
            reserved: *mut c_void,
            prompt: *const c_void,
            flags: u32,
            output: *mut Blob,
        ) -> i32;
        fn CryptUnprotectData(
            input: *const Blob,
            description: *mut *mut u16,
            entropy: *const Blob,
            reserved: *mut c_void,
            prompt: *const c_void,
            flags: u32,
            output: *mut Blob,
        ) -> i32;
    }
    #[link(name = "kernel32")]
    extern "system" {
        fn LocalFree(memory: *mut c_void) -> *mut c_void;
    }
    let input = Blob {
        length: u32::try_from(bytes.len()).map_err(|_| ())?,
        data: bytes.as_ptr() as *mut u8,
    };
    let entropy_bytes = b"BooruFlow Web Verification v1";
    let entropy = Blob {
        length: entropy_bytes.len() as u32,
        data: entropy_bytes.as_ptr() as *mut u8,
    };
    let mut output = Blob {
        length: 0,
        data: std::ptr::null_mut(),
    };
    // SAFETY: all inputs remain live for the synchronous call. DPAPI allocates
    // output with LocalAlloc; copy it into Rust ownership and release it once.
    unsafe {
        let ok = if encrypt {
            CryptProtectData(
                &input,
                std::ptr::null(),
                &entropy,
                std::ptr::null_mut(),
                std::ptr::null(),
                1,
                &mut output,
            )
        } else {
            CryptUnprotectData(
                &input,
                std::ptr::null_mut(),
                &entropy,
                std::ptr::null_mut(),
                std::ptr::null(),
                1,
                &mut output,
            )
        };
        if ok == 0 {
            return Err(());
        }
        let result = if !output.data.is_null() && u64::from(output.length) <= MAX_RECORD {
            Ok(std::slice::from_raw_parts(output.data, output.length as usize).to_vec())
        } else {
            Err(())
        };
        if !output.data.is_null() {
            LocalFree(output.data.cast());
        }
        result
    }
}
