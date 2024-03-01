use serde::Serialize;

#[derive(Serialize, Debug, Clone)]
pub struct TermData {
    pub name: String,
    pub value: String,
}
