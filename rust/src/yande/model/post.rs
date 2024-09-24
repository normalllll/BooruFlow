use flutter_rust_bridge::frb;
use serde::Deserialize;
use serde::Serialize;


#[frb()]
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Post {
    pub id: i64,
    pub tags: String,
    pub created_at: i64,
    pub updated_at: i64,
    pub creator_id: Option<i64>,
    pub author: String,
    pub change: i64,
    pub source: String,
    pub score: i64,
    pub md5: String,
    pub file_size: i64,
    pub file_ext: String,
    pub file_url: Option<String>,
    pub is_shown_in_index: bool,
    pub preview_url: String,
    pub preview_width: i64,
    pub preview_height: i64,
    pub actual_preview_width: i64,
    pub actual_preview_height: i64,
    pub sample_url: String,
    pub sample_width: i64,
    pub sample_height: i64,
    pub sample_file_size: i64,
    pub jpeg_url: String,
    pub jpeg_width: i64,
    pub jpeg_height: i64,
    pub jpeg_file_size: i64,
    pub rating: String,
    pub is_rating_locked: bool,
    pub has_children: bool,
    pub parent_id: Option<i64>,
    pub status: String,
    pub is_pending: bool,
    pub width: i64,
    pub height: i64,
    pub is_held: bool,
    pub is_note_locked: bool,
}
