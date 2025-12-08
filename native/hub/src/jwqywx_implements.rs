use cczuni::{
    base::{app::AppVisitor, client::Account},
    extension::calendar::{
        parse_week_matrix, ApplicationCalendarExt, Schedule, TermCalendarParser,
    },
    impls::{apps::wechat::jwqywx::JwqywxApplication, client::DefaultClient},
};
use rinf::{DartSignal, RustSignal};

use crate::signals::{
    ICalendarOutput, ICalendarWxInput, SimplifiedEvaluatableClass, WeChatEvaluatableClassInput,
    WeChatEvaluatableClassOutput, WeChatEvaluationInput, WeChatEvaluationOutput, WeChatExamData,
    WeChatExamsInput, WeChatExamsOutput, WeChatGradeData, WeChatGradesInput, WeChatGradesOutput,
    WeChatRankData, WeChatRankDataOutput, WeChatRankInput, WeChatTermsInput, WeChatTermsOutput,
};

pub async fn get_grades() {
    let rev = WeChatGradesInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account;

        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));

        let app = client.visit::<JwqywxApplication<_>>().await;
        let login = app.login().await;

        if let Ok(login) = login {
            if login
                .message
                .first()
                .map(|e| e.userid.is_empty())
                .unwrap_or(true)
            {
                WeChatGradesOutput {
                    ok: false,
                    data: vec![],
                    error: Some("Error Password".to_owned()),
                }
                .send_signal_to_dart();
                continue;
            }
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
        let account = message.account;

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
        match app.terms().await {
            Ok(terms) => WeChatTermsOutput {
                ok: true,
                terms: terms.message.into_iter().map(|t| t.term).collect(),
                error: None,
            }
            .send_signal_to_dart(),
            Err(err) => WeChatTermsOutput {
                ok: false,
                terms: vec![],
                error: Some(err.to_string()),
            }
            .send_signal_to_dart(),
        }
    }
}

pub async fn get_rank() {
    let rev = WeChatRankInput::get_dart_signal_receiver();

    while let Some(data) = rev.recv().await {
        let message = data.message;
        let account = message.account;

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

        if let Ok(login) = login {
            if login
                .message
                .first()
                .map(|e| e.userid.is_empty())
                .unwrap_or(true)
            {
                WeChatRankDataOutput {
                    ok: false,
                    data: None,
                    error: Some("Error Password".to_owned()),
                }
                .send_signal_to_dart();
                continue;
            }
            if let Ok(data) = app.get_credits_and_rank().await {
                let got = data.message.first();
                if let Some(data) = got {
                    WeChatRankDataOutput {
                        ok: true,
                        data: Some(WeChatRankData {
                            gpa: data.grade_points.to_string(),
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

pub async fn get_evalutable_class() {
    let rev = WeChatEvaluatableClassInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account;

        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));

        let app = client.visit::<JwqywxApplication<_>>().await;
        let login = app.login().await;

        if let Err(message) = login {
            WeChatEvaluatableClassOutput {
                ok: false,
                classes: vec![],
                error: Some(message.to_string()),
            }
            .send_signal_to_dart();
            continue;
        }

        if let Ok(classes) = app.get_evaluatable_class(message.term).await {
            WeChatEvaluatableClassOutput {
                ok: true,
                classes: classes
                    .message
                    .into_iter()
                    .map(|c| SimplifiedEvaluatableClass {
                        course_name: c.course_name,
                        teacher_name: c.teacher_name,
                        teacher_code: c.teacher_code,
                        course_code: c.course_code,
                        evaluation_status: c.evaluation_status,
                    })
                    .collect(),
                error: None,
            }
            .send_signal_to_dart();
        } else {
            WeChatEvaluatableClassOutput {
                ok: false,
                classes: vec![],
                error: Some("Failed to fetch evaluatable classes".to_owned()),
            }
            .send_signal_to_dart();
        }
    }
}

pub async fn submit_evaluation() {
    let rev = WeChatEvaluationInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account;

        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));

        let app = client.visit::<JwqywxApplication<_>>().await;
        let login = app.login().await;

        if let Err(message) = login {
            WeChatEvaluationOutput {
                ok: false,
                error: Some(message.to_string()),
            }
            .send_signal_to_dart();
            continue;
        }

        if let Ok(_) = app
            .evaluate_class(
                message.term,
                &message.evaluatable_class.into(),
                message.overall_score,
                message.scores,
                message.comments,
            )
            .await
        {
            WeChatEvaluationOutput {
                ok: true,
                error: None,
            }
            .send_signal_to_dart();
        } else {
            WeChatEvaluationOutput {
                ok: false,
                error: Some("Evaluation submission failed".to_owned()),
            }
            .send_signal_to_dart();
        }
    }
}

pub async fn get_exams() {
    let rev = WeChatExamsInput::get_dart_signal_receiver();

    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account;
        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));
        let app = client.visit::<JwqywxApplication<_>>().await;
        let login = app.login().await;
        if let Err(message) = login {
            WeChatExamsOutput {
                ok: false,
                data: vec![],
                error: Some(message.to_string()),
            }
            .send_signal_to_dart();
            continue;
        }
        if let Ok(login) = login {
            if login
                .message
                .first()
                .map(|e| e.userid.is_empty())
                .unwrap_or(true)
            {
                WeChatExamsOutput {
                    ok: false,
                    data: vec![],
                    error: Some("Error Password".to_owned()),
                }
                .send_signal_to_dart();
                continue;
            }
            let exams = app.get_exams(message.term).await;
            if let Ok(data) = exams {
                WeChatExamsOutput {
                    ok: true,
                    data: data
                        .message
                        .into_iter()
                        .filter(|e| e.classroom.is_some() && e.time_range.is_some())
                        .map(|e| WeChatExamData {
                            name: e.course_name,
                            location: e.classroom.unwrap_or_default(),
                            date: e.time_range.unwrap_or_default(),
                        })
                        .collect(),
                    error: None,
                }
                .send_signal_to_dart()
            } else if let Err(message) = exams {
                WeChatExamsOutput {
                    ok: false,
                    data: vec![],
                    error: Some(message.to_string()),
                }
                .send_signal_to_dart()
            }
        } else if let Err(message) = login {
            WeChatExamsOutput {
                ok: false,
                data: vec![],
                error: Some(message.to_string()),
            }
            .send_signal_to_dart()
        }
    }
}
