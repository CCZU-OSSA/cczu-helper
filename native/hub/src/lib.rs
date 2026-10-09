//! This `hub` crate is the
//! entry point of the Rust logic.

// This `tokio` will be used by Rinf.
// You can replace it with the original `tokio`
// if you're not targeting the web.
use tokio;

mod account_implments;

mod app_implements;
mod iccard_implments;
mod jwcas_implments;
mod jwqywx_implements;
mod signals;
mod utils_implments;

#[cfg(windows)]
mod windows;

rinf::write_interface!();

#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
pub extern "system" fn Java_io_github_cczuossa_cczu_1helper_CczuHelperApplication_initializeRustls<'caller>(
    mut env: jni::EnvUnowned<'caller>,
    _class: jni::objects::JClass<'caller>,
    context: jni::objects::JObject<'caller>,
) {
    use jni::errors::ThrowRuntimeExAndDefault;

    env.with_env(|env| rustls_platform_verifier::android::init_with_env(env, context))
        .resolve::<ThrowRuntimeExAndDefault>();
}

// Always use non-blocking async functions
// such as `tokio::fs::File::open`.
// If you really need to use blocking code,
// use `tokio::task::spawn_blocking`.
#[tokio::main]
async fn main() {
    // Repeat `tokio::spawn` anywhere in your code
    // if more concurrent tasks are needed.
    tokio::spawn(account_implments::sso_login());
    tokio::spawn(account_implments::edu_login());

    tokio::spawn(jwcas_implments::generate_icalendar());
    tokio::spawn(jwcas_implments::get_grades());
    tokio::spawn(jwcas_implments::lab_durations());

    tokio::spawn(jwqywx_implements::get_grades());
    tokio::spawn(jwqywx_implements::get_terms());
    tokio::spawn(jwqywx_implements::get_rank());
    tokio::spawn(jwqywx_implements::generate_icalendar());
    tokio::spawn(jwqywx_implements::submit_evaluation());
    tokio::spawn(jwqywx_implements::get_evalutable_class());
    tokio::spawn(jwqywx_implements::get_exams());

    tokio::spawn(iccard_implments::query_buildings());
    tokio::spawn(iccard_implments::query_room());

    tokio::spawn(utils_implments::service_status());

    #[cfg(windows)]
    {
        tokio::spawn(windows::cmcc_account());
    }

    tokio::spawn(app_implements::get_app_version());

    rinf::dart_shutdown().await;
}
