use std::fs;

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;

#[cfg(windows)]
use std::os::windows::fs::MetadataExt;

use flutter_rust_bridge::frb;

#[frb(sync)]
pub fn get_file_permissions(path: &str) -> Result<(bool, bool), String> {
    let metadata = fs::metadata(path).map_err(|e| e.to_string())?;
    
    #[cfg(unix)]
    {
        let mode = metadata.permissions().mode();
        let has_read_permission = mode & 0o400 != 0; // Readable
        let has_write_permission = mode & 0o200 != 0; // Writable
        return Ok((has_read_permission, has_write_permission));
    }

    #[cfg(windows)]
    {
        let attributes = metadata.file_attributes();
        let is_read_only = attributes & 0x1 != 0;
        let has_read_permission = true; // Writable
        let has_write_permission = !is_read_only; // Read only
        return Ok((has_read_permission, has_write_permission));
    }
    
    #[cfg(not(any(unix, windows)))]
    {
        return Err("Unsupported platform".to_string());
    }
}
