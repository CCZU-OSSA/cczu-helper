use cczuni::{
    base::{app::AppVisitor, client::Account},
    impls::{
        apps::wechat::jwqywx::JwqywxApplication, client::DefaultClient,
        login::sso::SSOUniversalLogin,
    },
};

use crate::messages::account::{AccountLoginCallback, EduAccountLoginInput, SsoAccountLoginInput};

pub async fn sso_login() {
    let mut rev = SsoAccountLoginInput::get_dart_signal_receiver().unwrap();
    while let Some(signal) = rev.recv().await {
        let account = signal.message.account.unwrap();
        let login_client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()))
                .sso_universal_login()
                .await;
        if let Err(message) = login_client {
            AccountLoginCallback {
                ok: false,
                error: Some(message.to_string()),
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
        let app = DefaultClient::new(Account::new(account.user.clone(), account.password.clone()))
            .visit::<JwqywxApplication<_>>()
            .await;

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
