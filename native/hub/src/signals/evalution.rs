use super::AccountData;
use cczuni::impls::apps::wechat::jwqywx_type::EvaluatableClass;
use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, DartSignal)]
pub struct WeChatEvaluatableClassInput {
    pub account: AccountData,
    pub term: String,
}

#[derive(Serialize, RustSignal)]
pub struct WeChatEvaluatableClassOutput {
    pub ok: bool,
    pub classes: Vec<SimplifiedEvaluatableClass>,
    pub error: Option<String>,
}

#[derive(Deserialize, DartSignal)]
pub struct WeChatEvaluationInput {
    pub account: AccountData,
    pub term: String,
    pub evaluatable_class: SimplifiedEvaluatableClass,
    pub overall_score: i32,
    pub scores: Vec<i32>,
    pub comments: String,
}

#[derive(Serialize, RustSignal)]
pub struct WeChatEvaluationOutput {
    pub ok: bool,
    pub error: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, SignalPiece)]
pub struct SimplifiedEvaluatableClass {
    pub course_name: String,
    pub teacher_name: String,
    pub teacher_code: String,
    pub course_code: String,
    pub evaluation_status: Option<String>,
}

impl Into<EvaluatableClass> for SimplifiedEvaluatableClass {
    fn into(self) -> EvaluatableClass {
        EvaluatableClass {
            class_id: "".to_owned(),
            evaluation_id: 0,
            course_name: self.course_name,
            teacher_name: self.teacher_name,
            teacher_code: self.teacher_code,
            course_code: self.course_code,
            course_serial: "".to_owned(),
            category_code: "".to_owned(),
            evaluation_status: self.evaluation_status,
            teacher_id: "".to_owned(),
        }
    }
}
