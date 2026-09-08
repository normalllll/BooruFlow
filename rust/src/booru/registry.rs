use crate::booru::adapter::BooruAdapter;
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use std::collections::BTreeMap;
use std::sync::Arc;

pub struct SourceRegistry {
    adapters: BTreeMap<String, Arc<dyn BooruAdapter>>,
    order: Vec<String>,
}

impl SourceRegistry {
    pub fn new(adapters: Vec<Arc<dyn BooruAdapter>>) -> BooruResult<Self> {
        let mut map = BTreeMap::new();
        let mut order = Vec::new();
        for adapter in adapters {
            let id = adapter.definition().id.to_owned();
            if map.insert(id.clone(), adapter).is_some() {
                return Err(BooruError::new(
                    BooruErrorCode::Internal,
                    Some(&id),
                    "booru.error.duplicateSource",
                ));
            }
            order.push(id);
        }
        Ok(Self {
            adapters: map,
            order,
        })
    }

    pub fn get(&self, source_id: &str) -> BooruResult<Arc<dyn BooruAdapter>> {
        self.adapters.get(source_id).cloned().ok_or_else(|| {
            BooruError::new(
                BooruErrorCode::InvalidRequest,
                Some(source_id),
                "booru.error.unknownSource",
            )
        })
    }

    pub fn all(&self) -> impl Iterator<Item = &Arc<dyn BooruAdapter>> {
        self.order.iter().filter_map(|id| self.adapters.get(id))
    }
}
