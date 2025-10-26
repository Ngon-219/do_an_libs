use chrono::{Duration, Utc};
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation, Algorithm};
use crate::structs::token_claims::{TokenClaims, UserRole};
use axum::{
    http::{ StatusCode},
    response::{IntoResponse, Response},
};

#[derive(Clone)]
pub struct JwtManager {
    secret_key: String,
}

#[derive(Debug)]
pub enum AuthError {
    Jwt(jsonwebtoken::errors::Error),
    Forbidden,
    MissingToken,
    InvalidAuthHeader,
}

impl IntoResponse for AuthError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AuthError::Jwt(_) => (StatusCode::UNAUTHORIZED, "Invalid or expired token"),
            AuthError::Forbidden => (StatusCode::FORBIDDEN, "Insufficient permissions"),
            AuthError::MissingToken => (StatusCode::UNAUTHORIZED, "Missing authorization token"),
            AuthError::InvalidAuthHeader => (StatusCode::UNAUTHORIZED, "Invalid authorization header"),
        };
        (status, message).into_response()
    }
}

impl JwtManager {
    pub fn new(secret_key: impl Into<String>) -> Self {
        Self {
            secret_key: secret_key.into(),
        }
    }

    pub fn decode_jwt(&self, token: &str) -> Result<TokenClaims, jsonwebtoken::errors::Error> {
        let decoding_key = DecodingKey::from_secret(self.secret_key.as_ref());
        let validation = Validation::new(Algorithm::HS256);

        decode::<TokenClaims>(token, &decoding_key, &validation).map(|data| data.claims)
    }

    pub fn generate_jwt(
        &self,
        user_id: &str,
        user_name: &str,
        role: UserRole,
        iap: Option<usize>,
        expiration_seconds: i64,
    ) -> Result<String, jsonwebtoken::errors::Error> {
        let now = Utc::now();
        let iat = now.timestamp() as usize;
        let exp = (now + Duration::seconds(expiration_seconds)).timestamp() as usize;

        let claims = TokenClaims {
            user_id: user_id.to_string(),
            user_name: user_name.to_string(),
            iap,
            iat,
            exp,
            role,
        };

        encode(
            &Header::default(),
            &claims,
            &EncodingKey::from_secret(self.secret_key.as_ref()),
        )
    }

    pub fn has_role(&self, token: &str, allowed: &[UserRole]) -> Result<bool, jsonwebtoken::errors::Error> {
        let claims = self.decode_jwt(token)?;
        Ok(allowed.iter().any(|r| r == &claims.role))
    }

    pub fn authorize_roles(&self, token: &str, allowed: &[UserRole]) -> Result<TokenClaims, AuthError> {
        let claims = self.decode_jwt(token).map_err(AuthError::Jwt)?;
        if allowed.iter().any(|r| r == &claims.role) {
            Ok(claims)
        } else {
            Err(AuthError::Forbidden)
        }
    }
}
