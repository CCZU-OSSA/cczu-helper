use cczuni::{
    base::{app::AppVisitor, client::Account},
    extension::calendar::{
        parse_week_matrix, ApplicationCalendarExt, Schedule, TermCalendarParser,
    },
    impls::{apps::wechat::jwqywx::JwqywxApplication, client::DefaultClient},
};

use crate::messages::{
    ICalendarOutput, ICalendarWxInput, WeChatGradeData, WeChatGradesInput, WeChatGradesOutput,
    WeChatRankData, WeChatRankDataOutput, WeChatRankInput, WeChatTermsInput, WeChatTermsOutput,
};

pub async fn get_grades() {
    let rev = WeChatGradesInput::get_dart_signal_receiver();

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
                            grade: e.grade,
                            exam_type: e.exam_type,
                            teacher_name: e.teacher_name,
                            course_type_name: e.course_type_name,
                            grade_points: e.grade_points,
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
    let rev = ICalendarWxInput::get_dart_signal_receiver();

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

            if let Ok(raw) = result {
                let parsed = parse_week_matrix(raw);
                if let Ok(classlist) = parsed {
                    app.generate_icalendar_from_classlist(
                        classlist,
                        message.firstweekdate,
                        Schedule::default(),
                        message.reminder,
                    )
                } else {
                    ICalendarOutput {
                        ok: false,
                        data: parsed.unwrap_err().to_string(),
                    }
                    .send_signal_to_dart();
                    continue;
                }
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
    let rev = WeChatTermsInput::get_dart_signal_receiver();

    while let Some(_) = rev.recv().await {
        let client = DefaultClient::default();
        let app = client.visit::<JwqywxApplication<_>>().await;

        if let Ok(terms) = app.terms().await {
            WeChatTermsOutput {
                ok: true,
                terms: terms.message.into_iter().map(|t| t.term).collect(),
            }
            .send_signal_to_dart()
        } else {
            WeChatTermsOutput {
                ok: false,
                terms: vec![],
            }
            .send_signal_to_dart()
        }
    }
}

pub async fn get_rank() {
    let rev = WeChatRankInput::get_dart_signal_receiver();

    while let Some(data) = rev.recv().await {
        let message = data.message;
        let account = message.account.unwrap();

        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));

        let app = client.visit::<JwqywxApplication<_>>().await;

        let login = app.login().await;
        if let Err(message) = login {
            WeChatRankDataOutput {
                ok: false,
                data: None,
                error: Some(message.to_string()),
            }
            .send_signal_to_dart();
            continue;
        }

        if let Ok(_) = login {
            if let Ok(data) = app.get_credits_and_rank().await {
                let got = data.message.first();
                if let Some(data) = got {
                    WeChatRankDataOutput {
                        ok: true,
                        data: Some(WeChatRankData {
                            gpa: data.grade_points.clone(),
                            major_rank: data.major_rank.clone(),
                            rank: data.rank.clone(),
                            total_credits: data.total_credits.clone(),
                        }),
                        error: None,
                    }
                    .send_signal_to_dart();
                } else {
                    WeChatRankDataOutput {
                        ok: false,
                        data: None,
                        error: Some("Data is Empty".to_owned()),
                    }
                    .send_signal_to_dart();
                }
            } else {
                WeChatRankDataOutput {
                    ok: false,
                    data: None,
                    error: Some("Get Data Failed".to_owned()),
                }
                .send_signal_to_dart();
            }
        } else {
            WeChatRankDataOutput {
                ok: false,
                data: None,
                error: Some("Login Failed".to_owned()),
            }
            .send_signal_to_dart();
        }
    }
}
