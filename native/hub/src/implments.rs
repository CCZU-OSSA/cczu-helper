use crate::typedata::{AccountData, GradeData, ICalendarGenerateData, TermData};
use cczu_ical_rs::{
    ical::{get_reminder, ICal},
    user::UserClient,
};
use regex::Regex;
use scraper::{ElementRef, Html, Selector};

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
    }
    Err("获取页面错误".into())
}

pub async fn impl_check_update() -> Result<String, String> {
    if let Ok(response) = reqwest::Client::new()
        .get("https://api.github.com/repos/CCZU-OSSA/cczu-helper/releases/latest")
        .header("User-Agent", "CCZU Helper")
        .send()
        .await
    {
        if let Ok(text) = response.text().await {
            return Ok(text);
        }
    }
    Err("获取页面错误".into())
}

fn extract_string(element: &ElementRef) -> String {
    element.text().next().unwrap().to_string()
}

pub async fn impl_get_grades(account: AccountData) -> Result<Vec<GradeData>, String> {
    let client = UserClient::new(&account.username, &account.password);
    if let Err(message) = client.login().await {
        return Err(message);
    }
    if let Ok(response) = client
        .client
        .get("http://219.230.159.132/web_cjgl/cx_cj_jxjhcj_xh.aspx")
        .send()
        .await
    {
        if let Ok(text) = response.text().await {
            let selector = Selector::parse(r#"tr[class="dg1-item"]"#).unwrap();
            let dom = Html::parse_document(&text);
            return Ok(dom
                .select(&selector)
                .map(|e| {
                    let childs: Vec<ElementRef> = e.child_elements().collect();
                    GradeData {
                        name: extract_string(childs.get(5).unwrap()),
                        point: extract_string(childs.get(8).unwrap()),
                        grade: extract_string(childs.get(9).unwrap()),
                    }
                })
                .collect());
        }
    }

    Err("获取页面失败".into())
}
