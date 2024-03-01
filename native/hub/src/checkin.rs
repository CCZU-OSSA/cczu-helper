use scraper::{Html, Selector};
use tokio_with_wasm::tokio;

use crate::models::TermData;

pub async fn impl_generate_termviews() -> Result<Vec<TermData>, String> {
    if let Ok(response) = reqwest::get("http://202.195.100.156:808/").await {
        if let Ok(text) = response.text().await {
            let dom = Html::parse_document(text.clone().as_str());
            let selector = Selector::parse("option").unwrap();

            return Ok(dom
                .select(&selector)
                .map(|element| TermData {
                    name: element.text().collect(),
                    value: element.attr("value").unwrap().to_string(),
                })
                .collect::<Vec<TermData>>());
        }
        return Err("获取页面错误".into());
    }
    Err("获取页面错误".into())
}

#[tokio::test]
async fn test_terms() {
    println!("{:?}", impl_generate_termviews().await);
}
