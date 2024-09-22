use crate::messages::{CmccAccountGenerateInput, CmccAccountGenerateOutput};

fn win_guid() -> String {
    use guid_create::GUID;
    use windows::Win32::System::Com::CoCreateGuid;

    let guid = unsafe { CoCreateGuid() }.unwrap();
    GUID::build_from_components(guid.data1, guid.data2, guid.data3, &guid.data4).to_string()
}

fn generate_account(phone: &str) -> String {
    let guid = win_guid().replace("-", "");
    let mut check = 0;
    for i in 0..3 {
        check += phone.chars().collect::<Vec<char>>()[i] as u32
            + guid.chars().collect::<Vec<char>>()[i] as u32;
    }
    format!("{}{:0<4}01{}", guid, check, phone).to_ascii_lowercase()
}

pub async fn cmcc_account() {
    let rev = CmccAccountGenerateInput::get_dart_signal_receiver();
    while let Some(signal) = rev.recv().await {
        CmccAccountGenerateOutput {
            account: generate_account(&signal.message.phone),
        }
        .send_signal_to_dart()
    }
}
