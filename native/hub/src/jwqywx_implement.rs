use cczuni::{
    base::{app::AppVisitor, client::Account},
    extension::calendar::{ApplicationCalendarExt, Schedule, TermCalendarParser},
    impls::{apps::wechat::jwqywx::JwqywxApplication, client::DefaultClient},
};

use crate::messages::{
    grades::{WeChatGradeData, WeChatGradesInput, WeChatGradesOutput},
    icalendar::{ICalendarOutput, ICalendarWxInput, WxTermsInput, WxTermsOutput},
};

pub async fn get_grades() {
    let mut rev = WeChatGradesInput::get_dart_signal_receiver().unwrap();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account.unwrap();

        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));

        let app = client.visit::<JwqywxApplication<_>>().await;
        let login = app.login().await;

        if let Ok(_) = login {
            let grade = app.get_grades().await;
            if let Ok(data) = grade {
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
                            exam_type: e.exam_type,
                        })
                        .collect(),
                    error: None,
                }
                .send_signal_to_dart()
            } else if let Err(message) = grade {
                WeChatGradesOutput {
                    ok: false,
                    data: vec![],
                    error: Some(message.to_string()),
                }
                .send_signal_to_dart()
            }
        } else if let Err(message) = login {
            WeChatGradesOutput {
                ok: false,
                data: vec![],
                error: Some(message.to_string()),
            }
            .send_signal_to_dart()
        }
    }
}

pub async fn generate_icalendar() {
    let mut rev = ICalendarWxInput::get_dart_signal_receiver().unwrap();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account.unwrap();

        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));

        let app = client.visit::<JwqywxApplication<_>>().await;
        let login = app.login().await;

        if let Err(message) = login {
            ICalendarOutput {
                ok: false,
                data: message.to_string(),
            }
            .send_signal_to_dart();
            continue;
        }

        let calendar = if let Some(term) = message.term {
            let result = app.get_term_classinfo_week_matrix(term).await;

            if let Ok(classlist) = result {
                app.generate_icalendar_from_classlist(
                    classlist,
                    message.firstweekdate,
                    Schedule::default(),
                    message.reminder,
                )
            } else {
                ICalendarOutput {
                    ok: false,
                    data: result.unwrap_err().to_string(),
                }
                .send_signal_to_dart();
                continue;
            }
        } else {
            app.generate_icalendar(message.firstweekdate, Schedule::default(), message.reminder)
                .await
        };

        if let Ok(data) = calendar {
            ICalendarOutput {
                ok: true,
                data: data.to_string(),
            }
            .send_signal_to_dart()
        } else if let Err(message) = calendar {
            ICalendarOutput {
                ok: false,
                data: message.to_string(),
            }
            .send_signal_to_dart()
        }
    }
}

pub async fn get_terms() {
    let mut rev = WxTermsInput::get_dart_signal_receiver().unwrap();

    while let Some(_) = rev.recv().await {
        let client = DefaultClient::default();
        let app = client.visit::<JwqywxApplication<_>>().await;

        if let Ok(terms) = app.terms().await {
            WxTermsOutput {
                ok: true,
                terms: terms.message.into_iter().map(|t| t.term).collect(),
            }
            .send_signal_to_dart()
        } else {
            WxTermsOutput {
                ok: false,
                terms: vec![],
            }
            .send_signal_to_dart()
        }
    }
}
