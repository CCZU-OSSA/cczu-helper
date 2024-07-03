use std::io::Cursor;

use cczu_client_api::{base::client::AuthClient, sso::universal::UniversalClient};

use crate::messages::account::{AccountLogin, AccountLoginCallback, AccountWithCookies};

pub async fn login() {
    let mut rev = AccountLogin::get_dart_signal_receiver().unwrap();
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
            .send_signal_to_dart()
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
            .send_signal_to_dart()
        }
    }
}
