use cczu_client_api::{
    app::{
        jwcas::JwcasApplication, jwcas_calendar::JwcasApplicationCalendarExt,
        jwcas_calendar_type::Schedule,
    },
    universal::UniversalClient,
};

use crate::messages::{
    grades::{GradeData, GradesInput, GradesOutput},
    icalendar::{ICalendarInput, ICalendarOutput},
};

pub async fn generate_icalendar() {
    let mut rev = ICalendarInput::get_dart_signal_receiver();
    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account.unwrap();
        let login_info = UniversalClient::auto_login(account.user, account.password).await;
        if let Err(messgae) = login_info {
            ICalendarOutput {
                ok: false,
                data: messgae,
            }
            .send_signal_to_dart()
        } else {
            let client = login_info.unwrap();
            let app: JwcasApplication = client.visit_application();
            app.login().await.unwrap();
            let data = app
                .generate_icalendar(message.firstweekdate, Schedule::default(), message.reminder)
                .await;
            if let Some(calendar) = data {
                ICalendarOutput {
                    ok: true,
                    data: calendar.to_string(),
                }
                .send_signal_to_dart()
            } else {
                ICalendarOutput {
                    ok: false,
                    data: "生成错误".into(),
                }
                .send_signal_to_dart()
            }
        }
    }
}

pub async fn get_grades() {
    let mut rev = GradesInput::get_dart_signal_receiver();
    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account.unwrap();
        let login_info = UniversalClient::auto_login(account.user, account.password).await;
        if let Err(error) = login_info {
            GradesOutput {
                ok: false,
                data: vec![],
                error: Some(error),
            }
            .send_signal_to_dart()
        } else {
            let client = login_info.unwrap();
            let app: JwcasApplication = client.visit_application();
            app.login().await.unwrap();
            let grades = app.get_gradeinfo_vec().await;
            if let Err(error) = grades {
                GradesOutput {
                    ok: false,
                    data: vec![],
                    error: Some(error),
                }
                .send_signal_to_dart()
            } else {
                GradesOutput {
                    ok: true,
                    data: grades
                        .unwrap()
                        .into_iter()
                        .map(|e| GradeData {
                            name: e.name,
                            point: e.point,
                            grade: e.grade,
                        })
                        .collect(),
                    error: None,
                }
                .send_signal_to_dart()
            }
        }
    }
}
