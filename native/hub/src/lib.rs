//! This `hub` crate is the
//! entry point of the Rust logic.

use ical::generate_ical;
// This `tokio` will be used by Rinf.
// You can replace it with the original `tokio`
// if you're not targeting the web.
use tokio_with_wasm::tokio;

mod ical;
mod messages;

rinf::write_interface!();

// Always use non-blocking async functions
// such as `tokio::fs::File::open`.
// If you really need to use blocking code,
// use `tokio::task::spawn_blocking`.
async fn main() {
    // Repeat `tokio::spawn` anywhere in your code
    // if more concurrent tasks are needed.
    tokio::spawn(generate_ical());
}
