use serde::{Deserialize, Serialize};

#[derive(Deserialize, Serialize, Debug, Clone)]

pub struct ICalendarGenerateData {
    pub account: AccountData,
    pub firstweekdate: String,
    pub reminder: String,
}

#[derive(Deserialize, Serialize, Debug, Clone)]

pub struct AccountData {
    pub username: String,
    pub password: String,
}

#[derive(Serialize, Debug, Clone)]
pub struct TermData {
    pub name: String,
    pub value: String,
}

#[derive(Serialize, Debug, Clone)]
pub struct GradeData {
    pub name: String,
    pub point: String,
    pub grade: String,
}
