use crate::messages::{AssetInfo, GetVersionInput, GetVersionOutput, VersionInfo};
use cczuni::internals::fields::DEFAULT_HEADERS;
use reqwest::Client;
pub async fn get_app_version() {
    let rev = GetVersionInput::get_dart_signal_receiver();
    while let Some(_) = rev.recv().await {
        if let Ok(response) = Client::new()
            .get("https://api.github.com/repos/CCZU-OSSA/cczu-helper/releases/latest")
            .headers(DEFAULT_HEADERS.clone())
            .send()
            .await
        {
            let data = response.text().await.unwrap();
            let latest: SerdeVersionInfo = serde_json::from_str(&data).unwrap();
            GetVersionOutput {
                ok: true,
                data: Some(VersionInfo {
                    tag_name: latest.tag_name,
                    name: latest.name,
                    body: latest.body,
                    assets: latest
                        .assets
                        .into_iter()
                        .map(|asset| AssetInfo {
                            name: asset.name,
                            browser_download_url: asset.browser_download_url,
                            size: asset.size,
                        })
                        .collect(),
                }),
                error: None,
            }
            .send_signal_to_dart()
        } else {
            GetVersionOutput {
                ok: false,
                data: None,
                error: Some("获取失败".into()),
            }
            .send_signal_to_dart()
        }
    }
}

#[derive(serde::Deserialize)]
struct SerdeVersionInfo {
    pub tag_name: String,
    pub name: String,
    pub body: String,
    pub assets: Vec<SerdeAssetInfo>,
}

#[derive(serde::Deserialize)]
struct SerdeAssetInfo {
    pub name: String,
    pub browser_download_url: String,
    pub size: i32,
}
