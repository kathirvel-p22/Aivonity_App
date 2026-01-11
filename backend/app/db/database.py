"""
AIVONITY Database Configuration
Advanced database setup with TimescaleDB integration
"""

from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy import text
import logging
from typing import AsyncGenerator

from app.config import settings

logger = logging.getLogger(__name__)

# Create async engine with optimized configuration
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DATABASE_POOL_SIZE,
    max_overflow=settings.DATABASE_MAX_OVERFLOW,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=settings.DEBUG
)

# Create async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

class Base(DeclarativeBase):
    """Base class for all database models"""
    pass

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Dependency to get database session"""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()

async def init_db():
    """Initialize database with TimescaleDB extensions and hypertables"""
    try:
        async with engine.begin() as conn:
            # Create TimescaleDB extension
            await conn.execute(text("CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"))
            logger.info("✅ TimescaleDB extension created")
            
            # Import all models to ensure they're registered
            from app.db import models
            
            # Create all tables
            await conn.run_sync(Base.metadata.create_all)
            logger.info("✅ Database tables created")
            
            # Create hypertables for time-series data
            await create_hypertables(conn)
            
            # Create indexes for performance
            await create_indexes(conn)
            
            logger.info("✅ Database initialization complete")
            
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {e}")
        raise

async def create_hypertables(conn):
    """Create TimescaleDB hypertables for time-series data"""
    hypertables = [
        {
            "table": "telemetry_data",
            "time_column": "timestamp",
            "chunk_interval": "1 day"
        },
        {
            "table": "agent_logs", 
            "time_column": "timestamp",
            "chunk_interval": "1 day"
        },
        {
            "table": "system_metrics",
            "time_column": "timestamp", 
            "chunk_interval": "1 hour"
        }
    ]
    
    for hypertable in hypertables:
        try:
            # Check if hypertable already exists
            result = await conn.execute(text(f"""
                SELECT * FROM timescaledb_information.hypertables 
                WHERE hypertable_name = '{hypertable['table']}'
            """))
            
            if not result.fetchone():
                # Create hypertable
                await conn.execute(text(f"""
                    SELECT create_hypertable('{hypertable['table']}', '{hypertable['time_column']}',
                    chunk_time_interval => INTERVAL '{hypertable['chunk_interval']}');
                """))
                logger.info(f"✅ Hypertable created: {hypertable['table']}")
            else:
                logger.info(f"ℹ️ Hypertable already exists: {hypertable['table']}")
                
        except Exception as e:
            logger.warning(f"⚠️ Could not create hypertable {hypertable['table']}: {e}")

async def create_indexes(conn):
    """Create performance indexes"""
    indexes = [
        # Telemetry data indexes
        "CREATE INDEX IF NOT EXISTS idx_telemetry_vehicle_time ON telemetry_data (vehicle_id, timestamp DESC);",
        "CREATE INDEX IF NOT EXISTS idx_telemetry_anomaly ON telemetry_data (anomaly_score) WHERE anomaly_score > 0.7;",
        "CREATE INDEX IF NOT EXISTS idx_telemetry_processed ON telemetry_data (processed, timestamp);",
        
        # Vehicle indexes
        "CREATE INDEX IF NOT EXISTS idx_vehicle_user ON vehicles (user_id);",
        "CREATE INDEX IF NOT EXISTS idx_vehicle_vin ON vehicles (vin);",
        "CREATE INDEX IF NOT EXISTS idx_vehicle_health ON vehicles (health_score);",
        
        # Prediction indexes
        "CREATE INDEX IF NOT EXISTS idx_prediction_vehicle ON maintenance_predictions (vehicle_id, created_at DESC);",
        "CREATE INDEX IF NOT EXISTS idx_prediction_probability ON maintenance_predictions (failure_probability DESC);",
        "CREATE INDEX IF NOT EXISTS idx_prediction_status ON maintenance_predictions (status, timeframe_days);",
        
        # Booking indexes
        "CREATE INDEX IF NOT EXISTS idx_booking_user ON service_bookings (user_id, appointment_datetime);",
        "CREATE INDEX IF NOT EXISTS idx_booking_status ON service_bookings (status, appointment_datetime);",
        "CREATE INDEX IF NOT EXISTS idx_booking_service_center ON service_bookings (service_center_id);",
        
        # Agent logs indexes
        "CREATE INDEX IF NOT EXISTS idx_agent_logs_time ON agent_logs (timestamp DESC);",
        "CREATE INDEX IF NOT EXISTS idx_agent_logs_agent ON agent_logs (agent_name, timestamp DESC);",
        "CREATE INDEX IF NOT EXISTS idx_agent_logs_level ON agent_logs (log_level, timestamp DESC);",
    ]
    
    for index_sql in indexes:
        try:
            await conn.execute(text(index_sql))
        except Exception as e:
            logger.warning(f"⚠️ Could not create index: {e}")
    
    logger.info("✅ Database indexes created")

async def setup_data_retention():
    """Setup automatic data retention policies"""
    retention_policies = [
        {
            "table": "telemetry_data",
            "retention_period": f"{settings.TELEMETRY_RETENTION_DAYS} days"
        },
        {
            "table": "agent_logs",
            "retention_period": "90 days"
        },
        {
            "table": "system_metrics", 
            "retention_period": "30 days"
        }
    ]
    
    async with engine.begin() as conn:
        for policy in retention_policies:
            try:
                await conn.execute(text(f"""
                    SELECT add_retention_policy('{policy['table']}', INTERVAL '{policy['retention_period']}');
                """))
                logger.info(f"✅ Retention policy set for {policy['table']}: {policy['retention_period']}")
            except Exception as e:
                logger.warning(f"⚠️ Could not set retention policy for {policy['table']}: {e}")

# Health check function
async def check_db_health() -> bool:
    """Check database connectivity and health"""
    try:
        async with engine.begin() as conn:
            await conn.execute(text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"❌ Database health check failed: {e}")
        return False