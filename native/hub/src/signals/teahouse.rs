use super::AccountData;
use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, DartSignal)]
pub struct TeahouseListInput {
    pub page: Option<i32>,
    pub page_size: Option<i32>,
    pub account: Option<AccountData>,
}

#[derive(Clone, Serialize, Deserialize, SignalPiece)]
pub struct TeahousePost {
    pub id: String,
    pub title: String,
    pub author: String,
    pub content: String,
    pub created_at: String,
}

#[derive(Serialize, RustSignal)]
pub struct TeahouseListOutput {
    pub ok: bool,
    pub data: Vec<TeahousePost>,
    pub error: Option<String>,
}

#[derive(Deserialize, DartSignal)]
pub struct CreatePostInput {
    pub title: String,
    pub content: String,
    pub account: Option<AccountData>,
}

#[derive(Serialize, RustSignal)]
pub struct CreatePostOutput {
    pub ok: bool,
    pub post: Option<TeahousePost>,
    pub error: Option<String>,
}

#[derive(Clone, Serialize, Deserialize, SignalPiece)]
pub struct Comment {
    pub id: String,
    pub post_id: String,
    pub author: String,
    pub content: String,
    pub created_at: String,
}

#[derive(Deserialize, DartSignal)]
pub struct FetchCommentsInput {
    pub post_id: String,
}

#[derive(Serialize, RustSignal)]
pub struct CommentsListOutput {
    pub ok: bool,
    pub data: Vec<Comment>,
    pub error: Option<String>,
}

#[derive(Deserialize, DartSignal)]
pub struct CreateCommentInput {
    pub post_id: String,
    pub content: String,
    pub account: Option<AccountData>,
}

#[derive(Serialize, RustSignal)]
pub struct CreateCommentOutput {
    pub ok: bool,
    pub comment: Option<Comment>,
    pub error: Option<String>,
}

#[derive(Deserialize, DartSignal)]
pub struct DeletePostInput {
    pub post_id: String,
}

#[derive(Serialize, RustSignal)]
pub struct DeletePostOutput {
    pub ok: bool,
    pub error: Option<String>,
}
