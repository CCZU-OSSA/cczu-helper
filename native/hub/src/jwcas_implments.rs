use cczuni::{
    base::{app::AppVisitor, client::Account},
    extension::calendar::{ApplicationCalendarExt, Schedule},
    impls::{
        apps::sso::jwcas::JwcasApplication, client::DefaultClient, login::sso::SSOUniversalLogin,
        services::webvpn::WebVPNService,
    },
};

use crate::messages::{
    grades::{GradeData, GradesInput, GradesOutput},
    icalendar::{ICalendarInput, ICalendarOutput},
    vpn::{VpnServiceUserInput, VpnServiceUserOutput},
};

pub async fn generate_icalendar() {
    let mut rev = ICalendarInput::get_dart_signal_receiver().unwrap();
    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account.unwrap();
        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));
        let login = client.sso_universal_login().await;

        if let Err(messgae) = login {
            ICalendarOutput {
                ok: false,
                data: messgae.to_string(),
            }
            .send_signal_to_dart()
        } else {
            let app = client.visit::<JwcasApplication<_>>().await;
            if let Err(err) = app.login().await {
                ICalendarOutput {
                    ok: false,
                    data: err.to_string(),
                }
                .send_signal_to_dart()
            } else {
                let data = app
                    .generate_icalendar(
                        message.firstweekdate,
                        Schedule::default(),
                        message.reminder,
                    )
                    .await;
                if let Ok(calendar) = data {
                    ICalendarOutput {
                        ok: true,
                        data: calendar.to_string(),
                    }
                    .send_signal_to_dart()
                } else if let Err(message) = data {
                    ICalendarOutput {
                        ok: false,
                        data: message.to_string(),
                    }
                    .send_signal_to_dart()
                }
            }
        }
    }
}
pub async fn get_grades() {
    let mut rev = GradesInput::get_dart_signal_receiver().unwrap();
    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let account = message.account.unwrap();
        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));
        let login = client.sso_universal_login().await;
        if let Err(error) = login {
            GradesOutput {
                ok: false,
                data: vec![],
                error: Some(error.to_string()),
            }
            .send_signal_to_dart()
        } else {
            let app = client.visit::<JwcasApplication<_>>().await;
            app.login().await.unwrap();
            let grades = app.get_gradeinfo_vec().await;
            if let Err(error) = grades {
                GradesOutput {
                    ok: false,
                    data: vec![],
                    error: Some(error.to_string()),
                }
                .send_signal_to_dart();
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
                .send_signal_to_dart();
            }
        }
    }
}
