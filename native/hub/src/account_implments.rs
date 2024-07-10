use cczu_client_api::{
    base::client::{SimpleClient, Visitor},
    sso::universal::UniversalClient,
    wechat::app::jwqywx::JwqywxApplication,
};

use crate::messages::account::{AccountLoginCallback, EduAccountLoginInput, SsoAccountLoginInput};

pub async fn sso_login() {
    let mut rev = SsoAccountLoginInput::get_dart_signal_receiver().unwrap();
    while let Some(signal) = rev.recv().await {
        let account = signal.message.account.unwrap();
        let login_client =
            UniversalClient::auto_login(account.user.clone(), account.password.clone()).await;
        if let Err(message) = login_client {
            AccountLoginCallback {
                ok: false,
                error: Some(message),
            }
            .send_signal_to_dart()
        } else {
            AccountLoginCallback {
                ok: true,
                error: None,
            }
            .send_signal_to_dart()
        }
    }
}

pub async fn edu_login() {
    let mut rev = EduAccountLoginInput::get_dart_signal_receiver().unwrap();
    while let Some(signal) = rev.recv().await {
        let account = signal.message.account.unwrap();
        let app = SimpleClient::new(account.user.clone(), account.password.clone())
            .visit_application::<JwqywxApplication>();

        let login_info = app.login().await;
        if let Some(message) = login_info {
            if let Some(user) = message.message.first() {
                if user.userid.is_empty() {
                    AccountLoginCallback {
                        ok: false,
                        error: Some("登陆失败".into()),
                    }
                    .send_signal_to_dart();

                    continue;
                }
            }
            AccountLoginCallback {
                ok: true,
                error: None,
            }
            .send_signal_to_dart()
        } else {
            AccountLoginCallback {
                ok: false,
                error: Some("登陆失败".into()),
            }
            .send_signal_to_dart()
        }
    }
}
