use cczu_ical_rs::{
    ical::{get_reminder, ICal},
    user::UserClient,
};
use regex::Regex;
use scraper::{Html, Selector};

use crate::typedata::{AccountData, ICalendarGenerateData, TermData};

pub async fn impl_generate_ical(data: ICalendarGenerateData) -> Result<String, String> {
    let user = data.account;
    let client = UserClient::new(&user.username, &user.password);
    if let Err(message) = client.login().await {
        return Err(message);
    };

    match client.get_classlist().await {
        Ok(v) => Ok(ICal::new(data.firstweekdate, v)
            .to_ical(get_reminder(&data.reminder))
            .to_string()),
        Err(e) => Err(e),
    }
}

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

pub async fn impl_login_wifi(account: AccountData) -> Result<String, String> {
    if let Ok(response) = reqwest::get("http://6.6.6.6/").await {
        if let Ok(text) = response.text().await {
            let re = Regex::new(r#"wlanacip=(.*?)&ssid"#).unwrap();
            if let Some(raw_acip) = re.find(&text) {
                let acip = raw_acip
                    .as_str()
                    .trim_start_matches("wlanacip=")
                    .trim_end_matches("&ssid");
                if let Ok(response) = reqwest::get(format!(
                "http://172.16.1.52:801/eportal/portal/login?wlan_ac_ip={}&user_account={}&user_password={}",
                acip,account.username,account.password,
            ))
            .await{
                if let Ok(callback) =response.text().await   {
                    return  Ok(callback);
                }
            }else{
                return Err("连接认证失败错误".into());
            }
            } else {
                return Err("获取ACIP错误".into());
            }
        }
        return Err("获取页面错误".into());
    }
    Err("获取页面错误".into())
}
