use crate::api::booru_auth::AuthState;
use crate::api::booru_models::{BooruTagSuggestion, HttpHeader, MediaVariantKind};
use crate::booru::error::{BooruError, BooruErrorCode, BooruResult};
use crate::booru::model::{MediaVariant, Post, PostId, PostPage, SearchQuery};
use crate::booru::network::NetworkRuntime;
use crate::booru::source::SourceDefinition;
use async_trait::async_trait;
use std::sync::Arc;

#[derive(Clone)]
pub struct RequestContext {
    pub runtime: Arc<NetworkRuntime>,
}

#[derive(Clone)]
pub struct PreparedMedia {
    pub media: MediaVariant,
    pub headers: Vec<HttpHeader>,
    pub allow_disk_cache: bool,
}

#[async_trait]
pub trait BooruAdapter: Send + Sync {
    fn definition(&self) -> &SourceDefinition;

    async fn search(&self, ctx: &RequestContext, query: SearchQuery) -> BooruResult<PostPage>;

    async fn feed(
        &self,
        ctx: &RequestContext,
        request: crate::api::booru_models::FeedRequest,
    ) -> BooruResult<PostPage> {
        if request.kind != crate::api::booru_models::FeedKind::Latest {
            return Err(self.unsupported());
        }
        self.search(ctx, crate::booru::discovery::latest_query(request))
            .await
    }

    async fn get_post(&self, ctx: &RequestContext, id: &PostId) -> BooruResult<Post>;

    async fn autocomplete(
        &self,
        _ctx: &RequestContext,
        _text: &str,
    ) -> BooruResult<Vec<BooruTagSuggestion>> {
        Err(self.unsupported())
    }

    async fn related_posts(&self, _ctx: &RequestContext, _id: &PostId) -> BooruResult<Vec<Post>> {
        Err(self.unsupported())
    }

    async fn prepare_media(
        &self,
        ctx: &RequestContext,
        id: &PostId,
        variant: MediaVariantKind,
    ) -> BooruResult<PreparedMedia> {
        let post = self.get_post(ctx, id).await?;
        let media = select_media(&post.media, variant).ok_or_else(|| self.unsupported())?;
        let url = reqwest::Url::parse(&media.url)
            .map_err(|_| BooruError::invalid_response(self.definition().id))?;
        let headers = ctx.runtime.prepared_headers(self.definition(), &url)?;
        Ok(PreparedMedia {
            media,
            headers,
            allow_disk_cache: true,
        })
    }

    async fn verify_auth(&self, _ctx: &RequestContext) -> BooruResult<AuthState> {
        Err(self.unsupported())
    }

    fn unsupported(&self) -> BooruError {
        BooruError::new(
            BooruErrorCode::UnsupportedCapability,
            Some(self.definition().id),
            "booru.error.unsupportedCapability",
        )
    }
}

pub fn select_media(media: &[MediaVariant], preferred: MediaVariantKind) -> Option<MediaVariant> {
    let exact = media.iter().find(|media| media.kind == preferred);
    if preferred == MediaVariantKind::Original {
        exact.cloned()
    } else {
        exact
            .or_else(|| {
                [
                    MediaVariantKind::Original,
                    MediaVariantKind::Sample,
                    MediaVariantKind::Preview,
                    MediaVariantKind::Thumbnail,
                ]
                .into_iter()
                .find_map(|kind| media.iter().find(|media| media.kind == kind))
            })
            .cloned()
    }
}
