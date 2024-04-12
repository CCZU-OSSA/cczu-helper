use std::io::Cursor;

use cczu_client_api::{
    app::{
        jwcas::JwcasApplication, jwcas_calendar::JwcasApplicationCalendarExt,
        jwcas_calendar_type::Schedule,
    },
    client::UserClient,
    universal::UniversalClient,
};
use tokio_with_wasm::tokio;

use crate::messages::{
    account::{AccountLogin, AccountLoginCallback, AccountWithCookies},
    icalendar::{ICalendarInput, ICalendarOutput},
};

pub async fn login() {
    let mut rev = AccountLogin::get_dart_signal_receiver();
    while let Some(signal) = rev.recv().await {
        let message = signal.message;
        let login_client =
            UniversalClient::auto_login(message.user.clone(), message.password.clone()).await;
        if let Err(message) = login_client {
            AccountLoginCallback {
                ok: false,
                account: None,
                error: Some(message),
            }
            .send_signal_to_dart(None)
        } else {
            let client = login_client.unwrap();
            let mut cookies: Cursor<Vec<u8>> = Cursor::default();

            client
                .get_cookies()
                .lock()
                .unwrap()
                .save_json(&mut cookies)
                .unwrap();

            AccountLoginCallback {
                ok: true,
                account: Some(AccountWithCookies {
                    user: message.user,
                    password: message.password,
                    cookies: String::from_utf8(cookies.into_inner()).unwrap(),
                }),
                error: None,
            }
            .send_signal_to_dart(None)
        }
    }
}

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
            .send_signal_to_dart(None)
        } else {
            let client = login_info.unwrap();
            let app: JwcasApplication = client.visit_application();
            app.login().await.unwrap();
            app.generate_icalendar(message.firstweekdate, Schedule::default(), message.reminder)
                .await;
        }
    }
}

#[tokio::test]
async fn test_login() {
    let login_client = UniversalClient::auto_login("123".into(), "123".into()).await;
    println!("{}", login_client.is_err());
}
