use crate::signals::{
    Comment, CreateCommentInput, CreateCommentOutput, CreatePostInput, CreatePostOutput,
    FetchCommentsInput, CommentsListOutput, TeahouseListInput, TeahouseListOutput,
    TeahousePost,
};
use reqwest::Client;
use serde_json::Value;
use std::env;
use dotenv::dotenv;
use once_cell::sync::Lazy;
use rinf::{DartSignal, RustSignal};
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::fs;
use serde_json;
use std::path::PathBuf;

fn data_dir() -> PathBuf {
    let mut p = std::env::current_exe().unwrap_or_else(|_| PathBuf::from("."));
    p.pop();
    p.push("teahouse_data");
    p
}

async fn load_data() {
    let dir = data_dir();
    let _ = fs::create_dir_all(&dir).await;

    let posts_path = dir.join("posts.json");
    if let Ok(data) = fs::read_to_string(&posts_path).await {
        if let Ok(vec) = serde_json::from_str::<Vec<TeahousePost>>(&data) {
            let mut posts = POSTS.lock().await;
            *posts = vec;
        }
    }

    let comments_path = dir.join("comments.json");
    if let Ok(data) = fs::read_to_string(&comments_path).await {
        if let Ok(vec) = serde_json::from_str::<Vec<Comment>>(&data) {
            let mut comments = COMMENTS.lock().await;
            *comments = vec;
        }
    }
}

async fn save_posts() {
    let dir = data_dir();
    let posts_path = dir.join("posts.json");
    let posts = POSTS.lock().await;
    let _ = fs::write(&posts_path, serde_json::to_string(&*posts).unwrap_or_default()).await;
}

async fn save_comments() {
    let dir = data_dir();
    let comments_path = dir.join("comments.json");
    let comments = COMMENTS.lock().await;
    let _ = fs::write(&comments_path, serde_json::to_string(&*comments).unwrap_or_default()).await;
}

static POSTS: Lazy<Arc<Mutex<Vec<TeahousePost>>>> = Lazy::new(|| Arc::new(Mutex::new(Vec::new())));
static COMMENTS: Lazy<Arc<Mutex<Vec<Comment>>>> = Lazy::new(|| Arc::new(Mutex::new(Vec::new())));

pub async fn get_teahouse_posts() {
    let rev = TeahouseListInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        // ensure data loaded once
        load_data().await;
        
        let message = signal.message;
        let page = message.page.unwrap_or(1).max(1);
        let page_size = message.page_size.unwrap_or(10).max(1);

        let posts = POSTS.lock().await;
        let total = posts.len() as i32;
        let start = ((page - 1) * page_size) as usize;
        let end = (start + page_size as usize).min(posts.len());

        let data = if start < posts.len() { posts[start..end].to_vec() } else { Vec::new() };

        TeahouseListOutput {
            ok: true,
            data,
            error: None,
        }
        .send_signal_to_dart()
    }
}

pub async fn sync_with_supabase() {
    // load local `.env` in development (ignored if not present)
    let _ = dotenv();
    let client = Client::new();
    // prefer environment variables; fall back to previous defaults for compatibility
    let supabase_url = env::var("SUPABASE_URL").unwrap_or_else(|_| {
        "https://udrykrwyvnvmavbrdnnm.supabase.co".to_string()
    });
    let supabase_key = env::var("SUPABASE_KEY").unwrap_or_else(|_| {
        "sb_publishable_5mGAY5LN0WGnIIGwG30dxQ_mY7TuV_4".to_string()
    });
    loop {
        // fetch posts
        let url = format!("{}/rest/v1/posts?select=*&order=created_at.desc", supabase_url);
        let resp = client
            .get(&url)
            .header("apikey", &supabase_key)
            .header("Authorization", format!("Bearer {}", &supabase_key))
            .send()
            .await;

        if let Ok(r) = resp {
            if let Ok(text) = r.text().await {
                if let Ok(json) = serde_json::from_str::<Value>(&text) {
                    if let Some(array) = json.as_array() {
                        let mut posts_guard = POSTS.lock().await;
                        posts_guard.clear();
                        for item in array.iter() {
                            let id = item.get("id").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let title = item.get("title").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let content = item.get("content").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let author = item.get("user_id").and_then(|v| v.as_str()).unwrap_or("匿名").to_string();
                            let created_at = item.get("created_at").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            posts_guard.push(TeahousePost { id, title, author, content, created_at });
                        }
                        let _ = save_posts().await;
                    }
                }
            }
        }

        // fetch comments
        let urlc = format!("{}/rest/v1/comments?select=*&order=created_at.asc", supabase_url);
        let resp = client
            .get(&urlc)
            .header("apikey", &supabase_key)
            .header("Authorization", format!("Bearer {}", &supabase_key))
            .send()
            .await;

        if let Ok(r) = resp {
            if let Ok(text) = r.text().await {
                if let Ok(json) = serde_json::from_str::<Value>(&text) {
                    if let Some(array) = json.as_array() {
                        let mut comments_guard = COMMENTS.lock().await;
                        comments_guard.clear();
                        for item in array.iter() {
                            let id = item.get("id").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let post_id = item.get("post_id").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let author = item.get("user_id").and_then(|v| v.as_str()).unwrap_or("匿名").to_string();
                            let content = item.get("content").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            let created_at = item.get("created_at").and_then(|v| v.as_str()).unwrap_or("").to_string();
                            comments_guard.push(Comment { id, post_id, author, content, created_at });
                        }
                        let _ = save_comments().await;
                    }
                }
            }
        }

        tokio::time::sleep(std::time::Duration::from_secs(15)).await;
    }
}

pub async fn create_post() {
    let rev = CreatePostInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let mut posts = POSTS.lock().await;
        let id = chrono::Utc::now().timestamp_millis().to_string();
        let author = message
            .account
            .as_ref()
            .map(|a| a.user.clone())
            .unwrap_or_default();
        let post = TeahousePost {
            id: id.clone(),
            title: message.title.clone(),
            author: if author.is_empty() { "匿名".to_string() } else { author },
            content: message.content.clone(),
            created_at: chrono::Utc::now().to_rfc3339(),
        };
        posts.push(post.clone());
        // persist
        save_posts().await;

        CreatePostOutput {
            ok: true,
            post: Some(post.clone()),
            error: None,
        }
        .send_signal_to_dart();

        // Also send updated list (page 1)
        let list = POSTS.lock().await;
        TeahouseListOutput {
            ok: true,
            data: list.clone(),
            error: None,
        }
        .send_signal_to_dart();
    }
}

pub async fn get_comments() {
    let rev = FetchCommentsInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        load_data().await;
        let message = signal.message;
        let comments = COMMENTS.lock().await;
        let data: Vec<Comment> = comments
            .iter()
            .filter(|c| c.post_id == message.post_id)
            .cloned()
            .collect();

        CommentsListOutput {
            ok: true,
            data,
            error: None,
        }
        .send_signal_to_dart();
    }
}

pub async fn create_comment() {
    let rev = CreateCommentInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let mut comments = COMMENTS.lock().await;
        let id = chrono::Utc::now().timestamp_millis().to_string();
        let author = message
            .account
            .as_ref()
            .map(|a| a.user.clone())
            .unwrap_or_default();
        let comment = Comment {
            id: id.clone(),
            post_id: message.post_id.clone(),
            author: if author.is_empty() { "匿名".to_string() } else { author },
            content: message.content.clone(),
            created_at: chrono::Utc::now().to_rfc3339(),
        };
        comments.push(comment.clone());
        save_comments().await;

        CreateCommentOutput {
            ok: true,
            comment: Some(comment.clone()),
            error: None,
        }
        .send_signal_to_dart();

        // send updated comments for this post
        let comments_guard = COMMENTS.lock().await;
        let data: Vec<Comment> = comments_guard
            .iter()
            .filter(|c| c.post_id == message.post_id)
            .cloned()
            .collect();

        CommentsListOutput {
            ok: true,
            data,
            error: None,
        }
        .send_signal_to_dart();
    }
}

pub async fn delete_post() {
    let rev = crate::signals::DeletePostInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let mut posts = POSTS.lock().await;
        let orig_len = posts.len();
        posts.retain(|p| p.id != message.post_id);
        let removed = orig_len != posts.len();
        if removed {
            // remove comments
            let mut comments = COMMENTS.lock().await;
            comments.retain(|c| c.post_id != message.post_id);
            let _ = save_posts().await;
            let _ = save_comments().await;
            crate::signals::DeletePostOutput { ok: true, error: None }.send_signal_to_dart();
            // broadcast updated list
            let list = POSTS.lock().await;
            crate::signals::TeahouseListOutput { ok: true, data: list.clone(), error: None }
                .send_signal_to_dart();
        } else {
            crate::signals::DeletePostOutput { ok: false, error: Some("Post not found".into()) }
                .send_signal_to_dart();
        }
    }
}
