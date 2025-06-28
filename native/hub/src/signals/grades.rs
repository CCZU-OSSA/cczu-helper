use super::AccountData;
use rinf::{DartSignal, RustSignal, SignalPiece};
use serde::{Deserialize, Serialize};

#[derive(Deserialize, DartSignal)]
pub struct GradesInput {
    pub account: AccountData,
}

#[derive(Serialize, SignalPiece)]
pub struct GradeData {
    pub name: String,
    pub point: String,
    pub grade: String,
}

#[derive(Serialize, RustSignal)]
pub struct GradesOutput {
    pub ok: bool,
    pub data: Vec<GradeData>,
    pub error: Option<String>,
}

#[derive(Deserialize, DartSignal)]
pub struct WeChatGradesInput {
    pub account: AccountData,
}

#[derive(Serialize, SignalPiece)]
pub struct WeChatGradeData {
    pub class_name: String,
    pub course_name: String,
    pub term: i32,
    pub credits: f32,
    pub grade: f32,
    pub exam_type: String,
    pub teacher_name: String,
    pub course_type_name: String,
    pub grade_points: f32,
}

#[derive(Serialize, RustSignal)]
pub struct WeChatGradesOutput {
    pub ok: bool,
    pub data: Vec<WeChatGradeData>,
    pub error: Option<String>,
}

#[derive(Deserialize, DartSignal)]
pub struct WeChatRankInput {
    pub account: AccountData,
}

#[derive(Serialize, SignalPiece)]
pub struct WeChatRankData {
    pub rank: String,
    pub major_rank: String,
    pub gpa: String,
    pub total_credits: String,
}

#[derive(Serialize, RustSignal)]
pub struct WeChatRankDataOutput {
    pub ok: bool,
    pub data: Option<WeChatRankData>,
    pub error: Option<String>,
}
