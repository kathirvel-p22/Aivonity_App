"""
AIVONITY Authentication API
Advanced authentication with JWT and security features
"""

from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
import bcrypt
import jwt
from pydantic import BaseModel, EmailStr, validator

from app.db.database import get_db
from app.db.models import User
from app.config import settings
from app.utils.logging_config import get_logger, security_logger

logger = get_logger(__name__)
router = APIRouter()
security = HTTPBearer()

# Pydantic models for request/response
class UserRegistration(BaseModel):
    email: EmailStr
    password: str
    name: str
    phone: Optional[str] = None
    language: str = "en"
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < settings.minPasswordLength:
            raise ValueError(f'Password must be at least {settings.minPasswordLength} characters')
        if len(v) > settings.maxPasswordLength:
            raise ValueError(f'Password must be less than {settings.maxPasswordLength} characters')
        return v
    
    @validator('name')
    def validate_name(cls, v):
        if len(v.strip()) < 2:
            raise ValueError('Name must be at least 2 characters')
        if len(v) > settings.maxNameLength:
            raise ValueError(f'Name must be less than {settings.maxNameLength} characters')
        return v.strip()

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: Dict[str, Any]

class UserProfile(BaseModel):
    id: str
    email: str
    name: str
    phone: Optional[str]
    language: str
    is_verified: bool
    created_at: datetime
    preferences: Dict[str, Any]

class PasswordChange(BaseModel):
    current_password: str
    new_password: str
    
    @validator('new_password')
    def validate_new_password(cls, v):
        if len(v) < settings.minPasswordLength:
            raise ValueError(f'Password must be at least {settings.minPasswordLength} characters')
        return v

# Utility functions
def hash_password(password: str) -> str:
    """Hash password using bcrypt"""
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

def verify_password(password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "iat": datetime.utcnow()})
    
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> Dict[str, Any]:
    """Decode and validate JWT token"""
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    """Get current authenticated user"""
    try:
        payload = decode_access_token(credentials.credentials)
        user_id = payload.get("sub")
        
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Get user from database
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User account is disabled",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        return user
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting current user: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

# API Endpoints
@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register_user(
    user_data: UserRegistration,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """Register new user account"""
    try:
        # Check if user already exists
        result = await db.execute(select(User).where(User.email == user_data.email))
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            security_logger.log_authentication_attempt(
                email=user_data.email,
                success=False,
                ip_address=request.client.host,
                user_agent=request.headers.get("user-agent", "")
            )
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        
        # Hash password
        hashed_password = hash_password(user_data.password)
        
        # Create user
        new_user = User(
            email=user_data.email,
            name=user_data.name,
            phone=user_data.phone,
            hashed_password=hashed_password,
            language=user_data.language,
            preferences={
                "notifications": {
                    "email": True,
                    "push": True,
                    "sms": False
                },
                "dashboard": {
                    "theme": "auto",
                    "units": "metric"
                }
            },
            notification_settings={
                "maintenance_alerts": True,
                "anomaly_alerts": True,
                "booking_reminders": True,
                "weekly_reports": True
            }
        )
        
        db.add(new_user)
        await db.commit()
        await db.refresh(new_user)
        
        # Create access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(new_user.id), "email": new_user.email, "role": new_user.role},
            expires_delta=access_token_expires
        )
        
        # Log successful registration
        security_logger.log_authentication_attempt(
            email=user_data.email,
            success=True,
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent", "")
        )
        
        logger.info(f"✅ New user registered: {user_data.email}")
        
        return TokenResponse(
            access_token=access_token,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user={
                "id": str(new_user.id),
                "email": new_user.email,
                "name": new_user.name,
                "role": new_user.role,
                "language": new_user.language,
                "is_verified": new_user.is_verified
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error registering user: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed"
        )

@router.post("/login", response_model=TokenResponse)
async def login_user(
    user_credentials: UserLogin,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """Authenticate user and return access token"""
    try:
        # Get user by email
        result = await db.execute(select(User).where(User.email == user_credentials.email))
        user = result.scalar_one_or_none()
        
        # Verify user exists and password is correct
        if not user or not verify_password(user_credentials.password, user.hashed_password):
            security_logger.log_authentication_attempt(
                email=user_credentials.email,
                success=False,
                ip_address=request.client.host,
                user_agent=request.headers.get("user-agent", "")
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Check if user is active
        if not user.is_active:
            security_logger.log_authentication_attempt(
                email=user_credentials.email,
                success=False,
                ip_address=request.client.host,
                user_agent=request.headers.get("user-agent", "")
            )
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Account is disabled"
            )
        
        # Create access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email, "role": user.role},
            expires_delta=access_token_expires
        )
        
        # Log successful login
        security_logger.log_authentication_attempt(
            email=user_credentials.email,
            success=True,
            ip_address=request.client.host,
            user_agent=request.headers.get("user-agent", "")
        )
        
        logger.info(f"✅ User logged in: {user_credentials.email}")
        
        return TokenResponse(
            access_token=access_token,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user={
                "id": str(user.id),
                "email": user.email,
                "name": user.name,
                "role": user.role,
                "language": user.language,
                "is_verified": user.is_verified,
                "preferences": user.preferences
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error during login: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed"
        )

@router.get("/profile", response_model=UserProfile)
async def get_user_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    try:
        return UserProfile(
            id=str(current_user.id),
            email=current_user.email,
            name=current_user.name,
            phone=current_user.phone,
            language=current_user.language,
            is_verified=current_user.is_verified,
            created_at=current_user.created_at,
            preferences=current_user.preferences
        )
        
    except Exception as e:
        logger.error(f"Error getting user profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get profile"
        )

@router.put("/profile")
async def update_user_profile(
    profile_data: Dict[str, Any],
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update user profile"""
    try:
        # Update allowed fields
        allowed_fields = ["name", "phone", "language", "preferences", "notification_settings"]
        
        for field, value in profile_data.items():
            if field in allowed_fields and hasattr(current_user, field):
                setattr(current_user, field, value)
        
        current_user.updated_at = datetime.utcnow()
        
        await db.commit()
        await db.refresh(current_user)
        
        logger.info(f"✅ Profile updated for user: {current_user.email}")
        
        return {"message": "Profile updated successfully"}
        
    except Exception as e:
        logger.error(f"Error updating profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to update profile"
        )

@router.post("/change-password")
async def change_password(
    password_data: PasswordChange,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Change user password"""
    try:
        # Verify current password
        if not verify_password(password_data.current_password, current_user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password is incorrect"
            )
        
        # Hash new password
        new_hashed_password = hash_password(password_data.new_password)
        
        # Update password
        current_user.hashed_password = new_hashed_password
        current_user.updated_at = datetime.utcnow()
        
        await db.commit()
        
        logger.info(f"✅ Password changed for user: {current_user.email}")
        
        return {"message": "Password changed successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error changing password: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to change password"
        )

@router.post("/refresh")
async def refresh_token(
    current_user: User = Depends(get_current_user)
):
    """Refresh access token"""
    try:
        # Create new access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": str(current_user.id), "email": current_user.email, "role": current_user.role},
            expires_delta=access_token_expires
        )
        
        return TokenResponse(
            access_token=access_token,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            user={
                "id": str(current_user.id),
                "email": current_user.email,
                "name": current_user.name,
                "role": current_user.role,
                "language": current_user.language,
                "is_verified": current_user.is_verified
            }
        )
        
    except Exception as e:
        logger.error(f"Error refreshing token: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to refresh token"
        )

@router.post("/logout")
async def logout_user(current_user: User = Depends(get_current_user)):
    """Logout user (client should discard token)"""
    try:
        logger.info(f"✅ User logged out: {current_user.email}")
        return {"message": "Logged out successfully"}
        
    except Exception as e:
        logger.error(f"Error during logout: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Logout failed"
        )