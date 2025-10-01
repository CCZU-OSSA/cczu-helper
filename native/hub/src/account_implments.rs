use crate::signals::{AccountLoginCallback, EDUAccountLoginInput, SSOAccountLoginInput};
use cczuni::{
    base::{app::AppVisitor, client::Account},
    impls::{
        apps::{sso::jwcas::JwcasApplication, wechat::jwqywx::JwqywxApplication},
        client::DefaultClient,
        login::sso::SSOUniversalLogin,
    },
};
use rinf::{DartSignal, RustSignal};

pub async fn sso_login() {
    let rev = SSOAccountLoginInput::get_dart_signal_receiver();
    while let Some(signal) = rev.recv().await {
        let account = signal.message.account;
        let client =
            DefaultClient::new(Account::new(account.user.clone(), account.password.clone()));
        let login: Option<String> = match client.sso_universal_login().await {
            Ok(_) => match client.visit::<JwcasApplication<_>>().await.login().await {
                Ok(_) => None,
                Err(e) => Some(e.to_string()),
            },
            Err(e) => Some(e.to_string()),
        };
        if let Some(message) = login {
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
    let rev = EDUAccountLoginInput::get_dart_signal_receiver();
    while let Some(signal) = rev.recv().await {
        let account = signal.message.account;
        let app = DefaultClient::new(Account::new(account.user.clone(), account.password.clone()))
            .visit::<JwqywxApplication<_>>()
            .await;

        let login = app.login().await;
        if let Ok(message) = login {
            if let Some(user) = message.message.first() {
                if user.userid.is_empty() || user.id.is_empty() {
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
        } else if let Err(err) = login {
            AccountLoginCallback {
                ok: false,
                error: Some(err.to_string()),
            }
            .send_signal_to_dart()
        }
    }
}
