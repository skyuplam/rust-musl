//! `cargo run --example simple`

extern crate reqwest;
extern crate env_logger;
#[macro_use]
extern crate error_chain;
extern crate openssl_probe;

use std::collections::HashMap;

error_chain! {
    foreign_links {
        ReqError(reqwest::Error);
        IoError(std::io::Error);
    }
}

fn run() -> Result<()> {
    env_logger::init();
    openssl_probe::init_ssl_cert_env_vars();

    println!("GET https://www.rust-lang.org");

    let res: HashMap<String, String> = reqwest::get("https://www.rust-lang.org/en-US/")?
        .json()?;

    println!("{:#?}", res);

    println!("\n\nDone.");
    Ok(())
}

quick_main!(run);
