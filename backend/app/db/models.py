"""
AIVONITY Database Models
Advanced SQLAlchemy models with innovative features
"""

from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Text, JSON, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import uuid
from datetime import datetime
from typing import Dict, Any, Optional

from app.db.database import Base

class TimestampMixin:
    """Mixin for automatic timestamp management"""
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

class User(Base, TimestampMixin):
    """Enhanced user model with advanced features"""
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), unique=True, nullable=True)
    name = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    
    # User preferences and settings
    preferences = Column(JSONB, default=dict, nullable=False)
    notification_settings = Column(JSONB, default=dict, nullable=False)
    language = Column(String(10), default="en", nullable=False)
    timezone = Column(String(50), default="UTC", nullable=False)
    
    # User role and permissions
    role = Column(String(50), default="owner", nullable=False)  # owner, admin, oem, service_center
    permissions = Column(JSONB, default=list, nullable=False)
    
    # Profile information
    avatar_url = Column(String(500), nullable=True)
    bio = Column(Text, nullable=True)
    location = Column(JSONB, nullable=True)  # {"city": "...", "country": "..."}
    
    # Relationships
    vehicles = relationship("Vehicle", back_populates="owner", cascade="all, delete-orphan")
    bookings = relationship("ServiceBooking", back_populates="user")
    chat_sessions = relationship("ChatSession", back_populates="user")
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, name={self.name})>"

class Vehicle(Base, TimestampMixin):
    """Advanced vehicle model with comprehensive tracking"""
    __tablename__ = "vehicles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Vehicle identification
    make = Column(String(100), nullable=False)
    model = Column(String(100), nullable=False)
    year = Column(Integer, nullable=False)
    vin = Column(String(17), unique=True, nullable=False, index=True)
    license_plate = Column(String(20), nullable=True)
    color = Column(String(50), nullable=True)
    
    # Vehicle specifications
    engine_type = Column(String(50), nullable=True)  # gasoline, diesel, electric, hybrid
    transmission = Column(String(50), nullable=True)  # manual, automatic, cvt
    fuel_capacity = Column(Float, nullable=True)
    engine_displacement = Column(Float, nullable=True)
    
    # Current status
    mileage = Column(Integer, default=0, nullable=False)
    health_score = Column(Float, default=1.0, nullable=False)
    last_service_date = Column(DateTime(timezone=True), nullable=True)
    next_service_due = Column(DateTime(timezone=True), nullable=True)
    registration_date = Column(DateTime(timezone=True), nullable=True)
    
    # Advanced tracking
    current_location = Column(JSONB, nullable=True)  # GPS coordinates
    maintenance_history = Column(JSONB, default=list, nullable=False)
    insurance_info = Column(JSONB, nullable=True)
    warranty_info = Column(JSONB, nullable=True)
    
    # AI-generated insights
    risk_factors = Column(JSONB, default=list, nullable=False)
    performance_metrics = Column(JSONB, default=dict, nullable=False)
    
    # Relationships
    owner = relationship("User", back_populates="vehicles")
    telemetry_data = relationship("TelemetryData", back_populates="vehicle")
    predictions = relationship("MaintenancePrediction", back_populates="vehicle")
    bookings = relationship("ServiceBooking", back_populates="vehicle")
    
    def __repr__(self):
        return f"<Vehicle(id={self.id}, make={self.make}, model={self.model}, vin={self.vin})>"

class TelemetryData(Base):
    """Time-series telemetry data with advanced processing"""
    __tablename__ = "telemetry_data"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    
    # Raw sensor data
    sensor_data = Column(JSONB, nullable=False)  # All sensor readings
    location = Column(JSONB, nullable=True)  # GPS coordinates
    
    # Processed data
    anomaly_score = Column(Float, nullable=True)
    quality_score = Column(Float, default=1.0, nullable=False)
    processed = Column(Boolean, default=False, nullable=False)
    processing_metadata = Column(JSONB, default=dict, nullable=False)
    
    # Data source and validation
    source = Column(String(50), default="obd", nullable=False)  # obd, can, manual
    validation_status = Column(String(20), default="pending", nullable=False)
    
    # Relationships
    vehicle = relationship("Vehicle", back_populates="telemetry_data")
    
    # Indexes for performance
    __table_args__ = (
        Index('idx_telemetry_vehicle_time', 'vehicle_id', 'timestamp'),
        Index('idx_telemetry_anomaly', 'anomaly_score'),
    )
    
    def __repr__(self):
        return f"<TelemetryData(id={self.id}, vehicle_id={self.vehicle_id}, timestamp={self.timestamp})>"

class MaintenancePrediction(Base, TimestampMixin):
    """ML-based maintenance predictions with confidence scoring"""
    __tablename__ = "maintenance_predictions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    
    # Prediction details
    component = Column(String(100), nullable=False)
    failure_probability = Column(Float, nullable=False)
    confidence_score = Column(Float, nullable=False)
    timeframe_days = Column(Integer, nullable=False)
    
    # Recommendation
    recommended_action = Column(Text, nullable=False)
    urgency_level = Column(String(20), default="medium", nullable=False)  # low, medium, high, critical
    estimated_cost = Column(Float, nullable=True)
    
    # ML model information
    model_version = Column(String(50), nullable=False)
    model_accuracy = Column(Float, nullable=True)
    feature_importance = Column(JSONB, default=dict, nullable=False)
    
    # Status tracking
    status = Column(String(20), default="pending", nullable=False)  # pending, acknowledged, scheduled, completed
    acknowledged_at = Column(DateTime(timezone=True), nullable=True)
    scheduled_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    vehicle = relationship("Vehicle", back_populates="predictions")
    
    def __repr__(self):
        return f"<MaintenancePrediction(id={self.id}, component={self.component}, probability={self.failure_probability})>"

class ServiceCenter(Base, TimestampMixin):
    """Service center information with advanced capabilities"""
    __tablename__ = "service_centers"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    
    # Location and contact
    address = Column(Text, nullable=False)
    city = Column(String(100), nullable=False)
    state = Column(String(100), nullable=False)
    country = Column(String(100), nullable=False)
    postal_code = Column(String(20), nullable=False)
    coordinates = Column(JSONB, nullable=False)  # {"lat": ..., "lng": ...}
    
    phone = Column(String(20), nullable=True)
    email = Column(String(255), nullable=True)
    website = Column(String(500), nullable=True)
    
    # Service capabilities
    services_offered = Column(JSONB, default=list, nullable=False)
    specializations = Column(JSONB, default=list, nullable=False)
    certifications = Column(JSONB, default=list, nullable=False)
    
    # Ratings and reviews
    rating = Column(Float, default=0.0, nullable=False)
    review_count = Column(Integer, default=0, nullable=False)
    
    # Operational details
    operating_hours = Column(JSONB, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    capacity = Column(Integer, default=10, nullable=False)
    
    # Relationships
    bookings = relationship("ServiceBooking", back_populates="service_center")
    
    def __repr__(self):
        return f"<ServiceCenter(id={self.id}, name={self.name}, city={self.city})>"

class ServiceBooking(Base, TimestampMixin):
    """Advanced service booking with optimization features"""
    __tablename__ = "service_bookings"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    service_center_id = Column(UUID(as_uuid=True), ForeignKey("service_centers.id"), nullable=False)
    
    # Booking details
    appointment_datetime = Column(DateTime(timezone=True), nullable=False)
    estimated_duration = Column(Integer, nullable=False)  # minutes
    service_type = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    
    # Status and tracking
    status = Column(String(20), default="scheduled", nullable=False)  # scheduled, confirmed, in_progress, completed, cancelled
    confirmation_code = Column(String(20), unique=True, nullable=False)
    
    # Optimization metadata
    optimization_score = Column(Float, nullable=True)
    optimization_factors = Column(JSONB, default=dict, nullable=False)
    
    # Cost and payment
    estimated_cost = Column(Float, nullable=True)
    actual_cost = Column(Float, nullable=True)
    payment_status = Column(String(20), default="pending", nullable=False)
    
    # Notes and feedback
    notes = Column(Text, nullable=True)
    customer_feedback = Column(JSONB, nullable=True)
    service_report = Column(JSONB, nullable=True)
    
    # Relationships
    user = relationship("User", back_populates="bookings")
    vehicle = relationship("Vehicle", back_populates="bookings")
    service_center = relationship("ServiceCenter", back_populates="bookings")
    
    def __repr__(self):
        return f"<ServiceBooking(id={self.id}, status={self.status}, datetime={self.appointment_datetime})>"

class ChatSession(Base, TimestampMixin):
    """AI chat session tracking with conversation history"""
    __tablename__ = "chat_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # Session details
    session_type = Column(String(20), default="text", nullable=False)  # text, voice, mixed
    language = Column(String(10), default="en", nullable=False)
    
    # Conversation data
    messages = Column(JSONB, default=list, nullable=False)
    context = Column(JSONB, default=dict, nullable=False)
    
    # AI model information
    ai_model = Column(String(50), nullable=False)
    total_tokens = Column(Integer, default=0, nullable=False)
    
    # Session status
    is_active = Column(Boolean, default=True, nullable=False)
    ended_at = Column(DateTime(timezone=True), nullable=True)
    
    # Quality metrics
    satisfaction_score = Column(Float, nullable=True)
    resolution_status = Column(String(20), nullable=True)  # resolved, escalated, pending
    
    # Relationships
    user = relationship("User", back_populates="chat_sessions")
    
    def __repr__(self):
        return f"<ChatSession(id={self.id}, user_id={self.user_id}, type={self.session_type})>"

class AgentLog(Base):
    """Comprehensive agent activity logging for UEBA"""
    __tablename__ = "agent_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Agent information
    agent_name = Column(String(50), nullable=False)
    agent_version = Column(String(20), nullable=False)
    
    # Log details
    log_level = Column(String(10), nullable=False)  # DEBUG, INFO, WARNING, ERROR, CRITICAL
    message = Column(Text, nullable=False)
    
    # Context and metadata
    context = Column(JSONB, default=dict, nullable=False)
    user_id = Column(UUID(as_uuid=True), nullable=True)
    vehicle_id = Column(UUID(as_uuid=True), nullable=True)
    
    # Performance metrics
    execution_time = Column(Float, nullable=True)
    memory_usage = Column(Float, nullable=True)
    
    # Security and behavior analysis
    behavior_score = Column(Float, nullable=True)
    anomaly_indicators = Column(JSONB, default=list, nullable=False)
    
    def __repr__(self):
        return f"<AgentLog(id={self.id}, agent={self.agent_name}, level={self.log_level})>"

class SystemMetrics(Base):
    """System performance and health metrics"""
    __tablename__ = "system_metrics"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Metric details
    metric_name = Column(String(100), nullable=False)
    metric_value = Column(Float, nullable=False)
    metric_unit = Column(String(20), nullable=True)
    
    # Source and context
    source = Column(String(50), nullable=False)  # agent, system, database, etc.
    tags = Column(JSONB, default=dict, nullable=False)
    
    def __repr__(self):
        return f"<SystemMetrics(name={self.metric_name}, value={self.metric_value}, timestamp={self.timestamp})>"

class MaintenanceEvent(Base, TimestampMixin):
    """Maintenance event tracking for root cause analysis"""
    __tablename__ = "maintenance_events"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    vehicle_id = Column(UUID(as_uuid=True), ForeignKey("vehicles.id"), nullable=False)
    
    # Event details
    event_type = Column(String(50), nullable=False)  # failure, repair, service, inspection
    component = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    
    # Cost and duration
    cost = Column(Float, nullable=True)
    duration_hours = Column(Float, nullable=True)
    
    # Service information
    service_center_id = Column(UUID(as_uuid=True), ForeignKey("service_centers.id"), nullable=True)
    technician_notes = Column(Text, nullable=True)
    parts_replaced = Column(JSONB, default=list, nullable=False)
    
    # Analysis fields
    root_cause = Column(String(200), nullable=True)
    severity = Column(String(20), default="medium", nullable=False)  # low, medium, high, critical
    
    # Metadata
    source = Column(String(50), default="manual", nullable=False)  # manual, automated, obd
    validation_status = Column(String(20), default="pending", nullable=False)
    
    # Relationships
    vehicle = relationship("Vehicle")
    service_center = relationship("ServiceCenter")
    
    def __repr__(self):
        return f"<MaintenanceEvent(id={self.id}, component={self.component}, type={self.event_type})>"

class FailurePattern(Base, TimestampMixin):
    """Identified failure patterns from analysis"""
    __tablename__ = "failure_patterns"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    pattern_id = Column(String(100), unique=True, nullable=False)
    
    # Pattern details
    component = Column(String(100), nullable=False)
    failure_mode = Column(String(100), nullable=False)
    frequency = Column(Integer, nullable=False)
    
    # Affected vehicles
    vehicles_affected = Column(JSONB, default=list, nullable=False)
    
    # Statistical analysis
    average_mileage_at_failure = Column(Float, nullable=False)
    average_age_at_failure = Column(Float, nullable=False)
    common_conditions = Column(JSONB, default=dict, nullable=False)
    confidence_score = Column(Float, nullable=False)
    
    # Analysis metadata
    analysis_date = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    analysis_window_days = Column(Integer, default=365, nullable=False)
    
    def __repr__(self):
        return f"<FailurePattern(id={self.id}, component={self.component}, frequency={self.frequency})>"

class RCAReport(Base, TimestampMixin):
    """Root Cause Analysis reports"""
    __tablename__ = "rca_reports"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    report_id = Column(String(100), unique=True, nullable=False)
    
    # Report details
    title = Column(String(255), nullable=False)
    component = Column(String(100), nullable=False)
    failure_mode = Column(String(100), nullable=False)
    
    # Affected vehicles
    affected_vehicles = Column(JSONB, default=list, nullable=False)
    
    # Analysis results
    root_causes = Column(JSONB, default=list, nullable=False)
    contributing_factors = Column(JSONB, default=list, nullable=False)
    recommendations = Column(JSONB, default=list, nullable=False)
    capa_actions = Column(JSONB, default=list, nullable=False)
    
    # Impact assessment
    severity_level = Column(String(20), nullable=False)  # low, medium, high, critical
    business_impact = Column(JSONB, default=dict, nullable=False)
    
    # Status tracking
    status = Column(String(20), default="draft", nullable=False)  # draft, reviewed, approved, implemented
    reviewed_by = Column(String(100), nullable=True)
    approved_by = Column(String(100), nullable=True)
    
    # Implementation tracking
    implementation_status = Column(String(20), default="pending", nullable=False)
    implementation_date = Column(DateTime(timezone=True), nullable=True)
    effectiveness_score = Column(Float, nullable=True)
    
    def __repr__(self):
        return f"<RCAReport(id={self.id}, title={self.title}, severity={self.severity_level})>"

class CAPAAction(Base, TimestampMixin):
    """CAPA (Corrective and Preventive Action) tracking"""
    __tablename__ = "capa_actions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    rca_report_id = Column(UUID(as_uuid=True), ForeignKey("rca_reports.id"), nullable=False)
    
    # Action details
    action_type = Column(String(20), nullable=False)  # corrective, preventive, verification, communication
    action_title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    
    # Responsibility and timeline
    responsible_team = Column(String(100), nullable=False)
    assigned_to = Column(String(100), nullable=True)
    due_date = Column(DateTime(timezone=True), nullable=False)
    
    # Status tracking
    status = Column(String(20), default="planned", nullable=False)  # planned, in_progress, completed, cancelled
    completion_date = Column(DateTime(timezone=True), nullable=True)
    
    # Success criteria and verification
    success_criteria = Column(Text, nullable=False)
    verification_method = Column(String(100), nullable=True)
    verification_date = Column(DateTime(timezone=True), nullable=True)
    effectiveness_score = Column(Float, nullable=True)
    
    # Cost and resources
    estimated_cost = Column(Float, nullable=True)
    actual_cost = Column(Float, nullable=True)
    resources_required = Column(JSONB, default=list, nullable=False)
    
    # Notes and updates
    notes = Column(Text, nullable=True)
    updates = Column(JSONB, default=list, nullable=False)
    
    # Relationships
    rca_report = relationship("RCAReport")
    
    def __repr__(self):
        return f"<CAPAAction(id={self.id}, title={self.action_title}, status={self.status})>"

class FleetInsight(Base, TimestampMixin):
    """Fleet-wide insights and analytics"""
    __tablename__ = "fleet_insights"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Insight details
    insight_type = Column(String(50), nullable=False)  # pattern, trend, anomaly, recommendation
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    
    # Scope and filters
    oem_id = Column(String(100), nullable=True)
    vehicle_makes = Column(JSONB, default=list, nullable=False)
    vehicle_models = Column(JSONB, default=list, nullable=False)
    time_period = Column(String(50), nullable=False)
    
    # Analysis results
    data_points = Column(Integer, nullable=False)
    confidence_score = Column(Float, nullable=False)
    statistical_significance = Column(Float, nullable=True)
    
    # Insight content
    key_findings = Column(JSONB, default=list, nullable=False)
    recommendations = Column(JSONB, default=list, nullable=False)
    business_impact = Column(JSONB, default=dict, nullable=False)
    
    # Visualization data
    charts_data = Column(JSONB, default=dict, nullable=False)
    
    # Status and lifecycle
    status = Column(String(20), default="active", nullable=False)  # active, archived, superseded
    priority = Column(String(20), default="medium", nullable=False)  # low, medium, high, critical
    
    def __repr__(self):
        return f"<FleetInsight(id={self.id}, type={self.insight_type}, title={self.title})>"