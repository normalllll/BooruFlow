use crate::yande::model::Post;
use flutter_rust_bridge::frb;
use serde::{Deserialize, Serialize};

#[frb()]
#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Similar {
    pub posts: Vec<Post>,
    pub source: Post,
}
