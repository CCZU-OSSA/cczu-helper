//! This `hub` crate is the
//! entry point of the Rust logic.

// This `tokio` will be used by Rinf.
// You can replace it with the original `tokio`
// if you're not targeting the web.
use tokio;

mod account_implments;
mod app_implements;
mod fields;
mod jwcas_implments;
mod jwqywx_implement;
mod messages;
#[cfg(windows)]

mod windows;


rinf::write_interface!();

// Always use non-blocking async functions
// such as `tokio::fs::File::open`.
// If you really need to use blocking code,
// use `tokio::task::spawn_blocking`.
async fn main() {
    // Repeat `tokio::spawn` anywhere in your code
    // if more concurrent tasks are needed.
    tokio::spawn(account_implments::sso_login());
    tokio::spawn(account_implments::edu_login());
    tokio::spawn(jwcas_implments::generate_icalendar());
    tokio::spawn(jwcas_implments::get_grades());
    tokio::spawn(jwqywx_implement::get_grades());

    if cfg!(windows) {
        tokio::spawn(windows::cmcc_account());
    }

    tokio::spawn(app_implements::get_app_version());
}
