use cczuni::{
    base::{app::AppVisitor, client::Account},
    impls::{apps::wechat::jwqywx::JwqywxApplication, client::DefaultClient},
};

use crate::messages::grades::{WeChatGradeData, WeChatGradesInput, WeChatGradesOutput};

pub async fn get_grades() {
    let mut rev = WeChatGradesInput::get_dart_signal_receiver().unwrap();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account.unwrap();

        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));

        let app = client.visit::<JwqywxApplication<_>>().await;
        if let Some(_) = app.login().await {
            if let Some(data) = app.get_grades().await {
                WeChatGradesOutput {
                    ok: true,
                    data: data
                        .message
                        .into_iter()
                        .map(|e| WeChatGradeData {
                            class_name: e.class_name,
                            course_name: e.course_name,
                            term: e.term,
                            credits: e.course_credits,
                            usual_grade: e.usual_grade,
                            mid_grade: e.mid_exam_grade,
                            end_grade: e.end_exam_grade,
                            exam_grade: e.exam_grade,
                        })
                        .collect(),
                    error: None,
                }
                .send_signal_to_dart()
            } else {
                WeChatGradesOutput {
                    ok: false,
                    data: vec![],
                    error: Some("获取成绩失败".to_owned()),
                }
                .send_signal_to_dart()
            }
        } else {
            WeChatGradesOutput {
                ok: false,
                data: vec![],
                error: Some("登陆失败".to_owned()),
            }
            .send_signal_to_dart()
        }
    }
}
