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
mod teahouse_implments;

#[cfg(windows)]
mod windows;

rinf::write_interface!();

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

    tokio::spawn(teahouse_implments::get_teahouse_posts());
    tokio::spawn(teahouse_implments::create_post());
    tokio::spawn(teahouse_implments::get_comments());
    tokio::spawn(teahouse_implments::create_comment());
    tokio::spawn(teahouse_implments::delete_post());
    tokio::spawn(teahouse_implments::sync_with_supabase());

    #[cfg(windows)]
    {
        tokio::spawn(windows::cmcc_account());
    }

    tokio::spawn(app_implements::get_app_version());

    rinf::dart_shutdown().await;
}
