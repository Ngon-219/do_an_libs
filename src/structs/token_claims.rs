use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct TokenClaims {
    pub user_id: String,
    pub user_name: String,
    pub iap: Option<usize>,
    pub iat: usize,
    pub exp: usize,
    pub role: UserRole,
}

#[derive(Debug, Serialize, Deserialize, Clone, PartialEq)]
#[serde(rename_all = "UPPERCASE")]
pub enum UserRole {
    ADMIN,
    MANAGER,
    STUDENT,
    TEACHER,
}