use cczu_client_api::sso::universal::UniversalClient;

use crate::messages::account::{AccountData, AccountLoginCallback};

pub async fn ssologin() {
    let mut rev = AccountData::get_dart_signal_receiver().unwrap();
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
            AccountLoginCallback {
                ok: true,
                account: Some(AccountData {
                    user: message.user,
                    password: message.password,
                }),
                error: None,
            }
            .send_signal_to_dart()
        }
    }
}
