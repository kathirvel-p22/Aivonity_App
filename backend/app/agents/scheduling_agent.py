"""
AIVONITY Scheduling Agent
Advanced service center integration and appointment optimization using OR-Tools
"""

import asyncio
import numpy as np
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timedelta
import json
import logging
from dataclasses import dataclass, asdict
import aiohttp
from geopy.distance import geodesic
from ortools.constraint_solver import routing_enums_pb2
from ortools.constraint_solver import pywrapcp
from ortools.linear_solver import pywraplp

from app.agents.base_agent import BaseAgent, AgentMessage
from app.db.models import ServiceCenter, ServiceBooking, Vehicle, User
from app.db.database import AsyncSessionLocal
from app.config import settings
from sqlalchemy import select, and_, or_, desc, func
from sqlalchemy.orm import selectinload

@dataclass
class ServiceRequest:
    """Service request structure"""
    vehicle_id: str
    user_id: str
    service_type: str
    urgency_level: str
    preferred_date: Optional[datetime] = None
    max_distance: Optional[float] = None
    budget_range: Optional[Tuple[float, float]] = None
    user_location: Optional[Tuple[float, float]] = None
    special_requirements: Optional[List[str]] = None

@dataclass
class ServiceCenterInfo:
    """Service center information"""
    id: str
    name: str
    location: Tuple[float, float]  # (latitude, longitude)
    services_offered: List[str]
    rating: float
    capacity: int
    operating_hours: Dict[str, Tuple[str, str]]  # day -> (start, end)
    pricing: Dict[str, float]  # service_type -> price
    specializations: List[str]
    contact_info: Dict[str, str]

@dataclass
class TimeSlot:
    """Available time slot"""
    start_time: datetime
    end_time: datetime
    service_center_id: str
    available_capacity: int
    estimated_duration: int  # minutes

@dataclass
class OptimizedAppointment:
    """Optimized appointment suggestion"""
    service_center: ServiceCenterInfo
    time_slot: TimeSlot
    total_score: float
    distance_km: float
    estimated_cost: float
    travel_time_minutes: int
    optimization_factors: Dict[str, float]

class SchedulingAgent(BaseAgent):
    """
    Advanced Scheduling Agent for service optimization
    Handles service center integration and appointment optimization using OR-Tools
    """
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__("scheduling_agent", config)
        
        # Service center management
        self.service_centers = {}  # Cache of service centers
        self.availability_cache = {}  # Cache of availability data
        self.cache_ttl = config.get("cache_ttl", 1800)  # 30 minutes
        
        # Optimization parameters
        self.max_distance_km = config.get("max_distance_km", 50)
        self.max_suggestions = config.get("max_suggestions", 5)
        self.optimization_weights = {
            "distance": 0.3,
            "rating": 0.25,
            "cost": 0.2,
            "availability": 0.15,
            "specialization": 0.1
        }
        
        # OR-Tools solver configuration
        self.solver_time_limit = config.get("solver_time_limit", 30)  # seconds
        
        # Service center API configuration
        self.service_center_api_base = config.get("service_center_api_base", "https://api.servicecenters.com")
        self.api_timeout = config.get("api_timeout", 30)
        
        # Performance tracking
        self.bookings_made = 0
        self.optimization_requests = 0
        self.average_optimization_time = 0.0

    def _define_capabilities(self) -> List[str]:
        """Define Scheduling Agent capabilities"""
        return [
            "service_center_integration",
            "availability_management",
            "appointment_optimization",
            "constraint_satisfaction",
            "multi_objective_optimization",
            "conflict_resolution",
            "alternative_suggestions",
            "real_time_updates",
            "rating_management",
            "cost_optimization"
        ]

    async def _initialize_resources(self):
        """Initialize scheduling resources and service center connections"""
        try:
            # Load service centers from database
            await self._load_service_centers()
            
            # Initialize availability tracking
            await self._initialize_availability_tracking()
            
            # Start background tasks
            asyncio.create_task(self._availability_update_loop())
            asyncio.create_task(self._cache_cleanup_loop())
            asyncio.create_task(self._service_center_sync_loop())
            
            self.logger.info("✅ Scheduling Agent resources initialized")
            
        except Exception as e:
            self.logger.error(f"❌ Failed to initialize Scheduling Agent resources: {e}")
            raise

    async def process_message(self, message: AgentMessage) -> Optional[AgentMessage]:
        """Process incoming messages for scheduling and optimization"""
        try:
            message_type = message.message_type
            payload = message.payload
            
            if message_type == "urgent_maintenance_needed":
                return await self._process_urgent_scheduling(payload, message.correlation_id)
            
            elif message_type == "maintenance_recommendations":
                return await self._process_maintenance_scheduling(payload, message.correlation_id)
            
            elif message_type == "schedule_appointment":
                return await self._process_appointment_request(payload, message.correlation_id)
            
            elif message_type == "reschedule_appointment":
                return await self._process_reschedule_request(payload, message.correlation_id)
            
            elif message_type == "cancel_appointment":
                return await self._process_cancellation(payload, message.correlation_id)
            
            elif message_type == "find_alternatives":
                return await self._process_alternative_request(payload, message.correlation_id)
            
            else:
                self.logger.warning(f"⚠️ Unknown message type: {message_type}")
                return None
                
        except Exception as e:
            self.logger.error(f"❌ Error processing message: {e}")
            return AgentMessage(
                sender=self.agent_name,
                recipient=message.sender,
                message_type="error",
                payload={"error": str(e), "original_message_id": message.id},
                correlation_id=message.correlation_id
            )

    async def _process_urgent_scheduling(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process urgent maintenance scheduling with priority optimization"""
        try:
            vehicle_id = payload.get("vehicle_id")
            predictions = payload.get("predictions", [])
            
            self.logger.info(f"🚨 Processing urgent scheduling for vehicle {vehicle_id}")
            
            # Create high-priority service request
            service_request = await self._create_urgent_service_request(vehicle_id, predictions)
            
            # Find immediate availability
            urgent_appointments = await self._find_urgent_appointments(service_request)
            
            if urgent_appointments:
                # Auto-book the best urgent appointment
                best_appointment = urgent_appointments[0]
                booking_result = await self._create_booking(service_request, best_appointment)
                
                response_payload = {
                    "vehicle_id": vehicle_id,
                    "booking_confirmed": True,
                    "appointment": asdict(best_appointment),
                    "booking_id": booking_result["booking_id"],
                    "alternatives": [asdict(apt) for apt in urgent_appointments[1:3]],
                    "urgency_level": "critical"
                }
                
                # Notify customer agent
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="customer_agent",
                    message_type="urgent_appointment_booked",
                    payload=response_payload,
                    priority=5,
                    correlation_id=correlation_id
                )
            else:
                # No immediate availability - escalate
                response_payload = {
                    "vehicle_id": vehicle_id,
                    "booking_confirmed": False,
                    "message": "No immediate availability for urgent service",
                    "escalation_required": True,
                    "recommendations": await self._get_emergency_recommendations(service_request)
                }
                
                return AgentMessage(
                    sender=self.agent_name,
                    recipient="customer_agent",
                    message_type="urgent_scheduling_failed",
                    payload=response_payload,
                    priority=5,
                    correlation_id=correlation_id
                )
                
        except Exception as e:
            self.logger.error(f"❌ Error processing urgent scheduling: {e}")
            raise

    async def _process_maintenance_scheduling(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process regular maintenance scheduling with optimization"""
        try:
            vehicle_id = payload.get("vehicle_id")
            predictions = payload.get("predictions", [])
            
            self.logger.info(f"🔧 Processing maintenance scheduling for vehicle {vehicle_id}")
            
            # Create service request
            service_request = await self._create_service_request(vehicle_id, predictions)
            
            # Optimize appointments using OR-Tools
            optimized_appointments = await self._optimize_appointments(service_request)
            
            response_payload = {
                "vehicle_id": vehicle_id,
                "optimized_appointments": [asdict(apt) for apt in optimized_appointments],
                "optimization_summary": {
                    "total_options": len(optimized_appointments),
                    "best_score": optimized_appointments[0].total_score if optimized_appointments else 0,
                    "optimization_time": self.average_optimization_time
                }
            }
            
            return AgentMessage(
                sender=self.agent_name,
                recipient="customer_agent",
                message_type="appointment_options",
                payload=response_payload,
                priority=2,
                correlation_id=correlation_id
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error processing maintenance scheduling: {e}")
            raise

    async def _optimize_appointments(self, service_request: ServiceRequest) -> List[OptimizedAppointment]:
        """
        Optimize appointments using OR-Tools for multi-objective optimization
        Considers distance, rating, cost, availability, and specialization
        """
        try:
            start_time = datetime.now()
            self.optimization_requests += 1
            
            # Get available service centers and time slots
            available_centers = await self._get_available_service_centers(service_request)
            time_slots = await self._get_available_time_slots(available_centers, service_request)
            
            if not available_centers or not time_slots:
                return []
            
            # Create optimization problem
            solver = pywraplp.Solver.CreateSolver('SCIP')
            if not solver:
                self.logger.error("❌ OR-Tools solver not available")
                return await self._fallback_optimization(service_request, available_centers, time_slots)
            
            # Decision variables: x[i][j] = 1 if appointment i is assigned to time slot j
            x = {}
            for i, center in enumerate(available_centers):
                for j, slot in enumerate(time_slots):
                    if slot.service_center_id == center.id:
                        x[i, j] = solver.IntVar(0, 1, f'x_{i}_{j}')
            
            # Objective function: maximize total score
            objective_terms = []
            
            for i, center in enumerate(available_centers):
                for j, slot in enumerate(time_slots):
                    if (i, j) in x:
                        score = self._calculate_appointment_score(center, slot, service_request)
                        objective_terms.append(score * x[i, j])
            
            solver.Maximize(solver.Sum(objective_terms))
            
            # Constraints
            # 1. Each service center can only have one appointment per time slot
            for j, slot in enumerate(time_slots):
                constraint_terms = []
                for i, center in enumerate(available_centers):
                    if (i, j) in x:
                        constraint_terms.append(x[i, j])
                if constraint_terms:
                    solver.Add(solver.Sum(constraint_terms) <= slot.available_capacity)
            
            # 2. Select at most max_suggestions appointments
            all_vars = [x[i, j] for i, j in x.keys()]
            solver.Add(solver.Sum(all_vars) <= self.max_suggestions)
            
            # 3. Distance constraint
            if service_request.max_distance:
                for i, center in enumerate(available_centers):
                    if service_request.user_location:
                        distance = geodesic(service_request.user_location, center.location).kilometers
                        if distance > service_request.max_distance:
                            for j, slot in enumerate(time_slots):
                                if (i, j) in x:
                                    solver.Add(x[i, j] == 0)
            
            # Solve the optimization problem
            solver.SetTimeLimit(self.solver_time_limit * 1000)  # milliseconds
            status = solver.Solve()
            
            optimized_appointments = []
            
            if status == pywraplp.Solver.OPTIMAL or status == pywraplp.Solver.FEASIBLE:
                for i, center in enumerate(available_centers):
                    for j, slot in enumerate(time_slots):
                        if (i, j) in x and x[i, j].solution_value() > 0.5:
                            appointment = await self._create_optimized_appointment(
                                center, slot, service_request
                            )
                            optimized_appointments.append(appointment)
            
            # Sort by total score
            optimized_appointments.sort(key=lambda x: x.total_score, reverse=True)
            
            # Update performance metrics
            optimization_time = (datetime.now() - start_time).total_seconds()
            self.average_optimization_time = (
                (self.average_optimization_time * (self.optimization_requests - 1) + optimization_time) 
                / self.optimization_requests
            )
            
            self.logger.info(f"✅ Optimized {len(optimized_appointments)} appointments in {optimization_time:.2f}s")
            
            return optimized_appointments[:self.max_suggestions]
            
        except Exception as e:
            self.logger.error(f"❌ Error in appointment optimization: {e}")
            # Fallback to simple scoring
            return await self._fallback_optimization(service_request, available_centers, time_slots)

    async def _fallback_optimization(self, service_request: ServiceRequest, 
                                   available_centers: List[ServiceCenterInfo], 
                                   time_slots: List[TimeSlot]) -> List[OptimizedAppointment]:
        """Fallback optimization using simple scoring when OR-Tools fails"""
        try:
            appointments = []
            
            for center in available_centers:
                for slot in time_slots:
                    if slot.service_center_id == center.id:
                        appointment = await self._create_optimized_appointment(
                            center, slot, service_request
                        )
                        appointments.append(appointment)
            
            # Sort by total score and return top suggestions
            appointments.sort(key=lambda x: x.total_score, reverse=True)
            return appointments[:self.max_suggestions]
            
        except Exception as e:
            self.logger.error(f"❌ Error in fallback optimization: {e}")
            return []

    def _calculate_appointment_score(self, center: ServiceCenterInfo, slot: TimeSlot, 
                                   request: ServiceRequest) -> float:
        """Calculate multi-objective score for an appointment option"""
        try:
            scores = {}
            
            # Distance score (closer is better)
            if request.user_location:
                distance = geodesic(request.user_location, center.location).kilometers
                scores["distance"] = max(0, 1 - (distance / self.max_distance_km))
            else:
                scores["distance"] = 0.5
            
            # Rating score (higher rating is better)
            scores["rating"] = center.rating / 5.0
            
            # Cost score (lower cost is better, if budget specified)
            if request.budget_range and request.service_type in center.pricing:
                service_cost = center.pricing[request.service_type]
                budget_max = request.budget_range[1]
                if service_cost <= budget_max:
                    scores["cost"] = 1 - (service_cost / budget_max)
                else:
                    scores["cost"] = 0
            else:
                scores["cost"] = 0.5
            
            # Availability score (more capacity is better)
            max_capacity = 10  # Assume max capacity for normalization
            scores["availability"] = min(1.0, slot.available_capacity / max_capacity)
            
            # Specialization score (matching specializations is better)
            if request.special_requirements:
                matching_specs = len(set(request.special_requirements) & set(center.specializations))
                total_specs = len(request.special_requirements)
                scores["specialization"] = matching_specs / total_specs if total_specs > 0 else 0
            else:
                scores["specialization"] = 0.5
            
            # Calculate weighted total score
            total_score = sum(
                scores[factor] * weight 
                for factor, weight in self.optimization_weights.items()
            )
            
            return total_score
            
        except Exception as e:
            self.logger.error(f"❌ Error calculating appointment score: {e}")
            return 0.0

    async def _create_optimized_appointment(self, center: ServiceCenterInfo, slot: TimeSlot, 
                                          request: ServiceRequest) -> OptimizedAppointment:
        """Create an optimized appointment object with all details"""
        try:
            # Calculate distance and travel time
            distance_km = 0
            travel_time_minutes = 0
            
            if request.user_location:
                distance_km = geodesic(request.user_location, center.location).kilometers
                travel_time_minutes = int(distance_km * 2)  # Rough estimate: 2 minutes per km
            
            # Calculate estimated cost
            estimated_cost = center.pricing.get(request.service_type, 0)
            
            # Calculate total score
            total_score = self._calculate_appointment_score(center, slot, request)
            
            # Create optimization factors breakdown
            optimization_factors = {
                "distance_score": max(0, 1 - (distance_km / self.max_distance_km)),
                "rating_score": center.rating / 5.0,
                "cost_score": 0.5,  # Default if no budget specified
                "availability_score": min(1.0, slot.available_capacity / 10),
                "specialization_score": 0.5  # Default if no special requirements
            }
            
            return OptimizedAppointment(
                service_center=center,
                time_slot=slot,
                total_score=total_score,
                distance_km=distance_km,
                estimated_cost=estimated_cost,
                travel_time_minutes=travel_time_minutes,
                optimization_factors=optimization_factors
            )
            
        except Exception as e:
            self.logger.error(f"❌ Error creating optimized appointment: {e}")
            raise

    async def _get_available_service_centers(self, request: ServiceRequest) -> List[ServiceCenterInfo]:
        """Get service centers that can handle the requested service"""
        try:
            available_centers = []
            
            for center_id, center in self.service_centers.items():
                # Check if center offers the required service
                if request.service_type in center.services_offered:
                    # Check distance constraint
                    if request.user_location and request.max_distance:
                        distance = geodesic(request.user_location, center.location).kilometers
                        if distance > request.max_distance:
                            continue
                    
                    # Check specialization requirements
                    if request.special_requirements:
                        if not any(spec in center.specializations for spec in request.special_requirements):
                            continue
                    
                    available_centers.append(center)
            
            return available_centers
            
        except Exception as e:
            self.logger.error(f"❌ Error getting available service centers: {e}")
            return []

    async def _get_available_time_slots(self, centers: List[ServiceCenterInfo], 
                                      request: ServiceRequest) -> List[TimeSlot]:
        """Get available time slots for the given service centers"""
        try:
            time_slots = []
            
            # Define search window
            start_date = request.preferred_date or datetime.now()
            end_date = start_date + timedelta(days=14)  # 2 weeks window
            
            for center in centers:
                # Get availability from cache or API
                center_availability = await self._get_center_availability(center.id, start_date, end_date)
                
                for slot_data in center_availability:
                    slot = TimeSlot(
                        start_time=slot_data["start_time"],
                        end_time=slot_data["end_time"],
                        service_center_id=center.id,
                        available_capacity=slot_data["available_capacity"],
                        estimated_duration=slot_data.get("estimated_duration", 120)  # 2 hours default
                    )
                    time_slots.append(slot)
            
            return time_slots
            
        except Exception as e:
            self.logger.error(f"❌ Error getting available time slots: {e}")
            return []

    async def _load_service_centers(self):
        """Load service centers from database and external APIs"""
        try:
            # Create mock service centers for demo
            mock_centers = [
                ServiceCenterInfo(
                    id="sc_001",
                    name="Downtown Auto Service",
                    location=(40.7589, -73.9851),  # Times Square area
                    services_offered=["general_maintenance", "engine_service", "brake_service"],
                    rating=4.5,
                    capacity=8,
                    operating_hours={"monday": ("8:00", "18:00"), "tuesday": ("8:00", "18:00")},
                    pricing={"general_maintenance": 150, "engine_service": 300, "brake_service": 200},
                    specializations=["engine_specialist", "brake_specialist"],
                    contact_info={"phone": "555-0101", "email": "service@downtown.com"}
                ),
                ServiceCenterInfo(
                    id="sc_002",
                    name="Express Car Care",
                    location=(40.7505, -73.9934),  # Near Penn Station
                    services_offered=["general_maintenance", "electrical_service", "transmission_service"],
                    rating=4.2,
                    capacity=6,
                    operating_hours={"monday": ("7:00", "19:00"), "tuesday": ("7:00", "19:00")},
                    pricing={"general_maintenance": 120, "electrical_service": 180, "transmission_service": 400},
                    specializations=["electrical_specialist", "transmission_specialist"],
                    contact_info={"phone": "555-0102", "email": "info@expresscare.com"}
                ),
                ServiceCenterInfo(
                    id="sc_003",
                    name="Premium Auto Solutions",
                    location=(40.7614, -73.9776),  # Central Park area
                    services_offered=["general_maintenance", "cooling_service", "fuel_service"],
                    rating=4.8,
                    capacity=10,
                    operating_hours={"monday": ("8:00", "17:00"), "tuesday": ("8:00", "17:00")},
                    pricing={"general_maintenance": 200, "cooling_service": 250, "fuel_service": 180},
                    specializations=["cooling_specialist", "fuel_specialist"],
                    contact_info={"phone": "555-0103", "email": "service@premiumauto.com"}
                )
            ]
            
            for center in mock_centers:
                self.service_centers[center.id] = center
            
            self.logger.info(f"✅ Loaded {len(self.service_centers)} service centers")
            
        except Exception as e:
            self.logger.error(f"❌ Error loading service centers: {e}")

    async def _get_center_availability(self, center_id: str, start_date: datetime, 
                                     end_date: datetime) -> List[Dict[str, Any]]:
        """Get availability for a specific service center"""
        try:
            # Check cache first
            cache_key = f"{center_id}_{start_date.date()}_{end_date.date()}"
            if cache_key in self.availability_cache:
                cache_entry = self.availability_cache[cache_key]
                if datetime.now() - cache_entry["timestamp"] < timedelta(seconds=self.cache_ttl):
                    return cache_entry["data"]
            
            # Fetch from external API or generate mock data
            availability_data = await self._fetch_center_availability(center_id, start_date, end_date)
            
            # Cache the result
            self.availability_cache[cache_key] = {
                "data": availability_data,
                "timestamp": datetime.now()
            }
            
            return availability_data
            
        except Exception as e:
            self.logger.error(f"❌ Error getting center availability: {e}")
            return []

    async def _fetch_center_availability(self, center_id: str, start_date: datetime, 
                                       end_date: datetime) -> List[Dict[str, Any]]:
        """Fetch availability from external API or generate mock data"""
        try:
            # For demo purposes, generate mock availability data
            # In production, this would call the actual service center API
            
            availability = []
            current_date = start_date.date()
            end_date_only = end_date.date()
            
            while current_date <= end_date_only:
                # Skip weekends for simplicity
                if current_date.weekday() < 5:  # Monday = 0, Friday = 4
                    # Generate morning and afternoon slots
                    for hour in [9, 14]:  # 9 AM and 2 PM
                        slot_start = datetime.combine(current_date, datetime.min.time().replace(hour=hour))
                        slot_end = slot_start + timedelta(hours=2)
                        
                        availability.append({
                            "start_time": slot_start,
                            "end_time": slot_end,
                            "available_capacity": np.random.randint(1, 4),  # 1-3 available slots
                            "estimated_duration": 120  # 2 hours
                        })
                
                current_date += timedelta(days=1)
            
            return availability
            
        except Exception as e:
            self.logger.error(f"❌ Error fetching center availability: {e}")
            return []

    async def _create_service_request(self, vehicle_id: str, predictions: List[Dict[str, Any]]) -> ServiceRequest:
        """Create a service request from vehicle predictions"""
        try:
            async with AsyncSessionLocal() as session:
                # Get vehicle and user information
                stmt = select(Vehicle).options(selectinload(Vehicle.user)).where(Vehicle.id == vehicle_id)
                result = await session.execute(stmt)
                vehicle = result.scalar_one_or_none()
                
                if not vehicle:
                    raise ValueError(f"Vehicle {vehicle_id} not found")
                
                # Determine service type based on predictions
                service_type = "general_maintenance"
                urgency_level = "low"
                special_requirements = []
                
                if predictions:
                    # Find highest risk component
                    highest_risk = max(predictions, key=lambda x: x["failure_probability"])
                    
                    if highest_risk["failure_probability"] > 0.8:
                        urgency_level = "critical"
                    elif highest_risk["failure_probability"] > 0.6:
                        urgency_level = "high"
                    elif highest_risk["failure_probability"] > 0.4:
                        urgency_level = "medium"
                    
                    # Map component to service type
                    component_service_map = {
                        "engine": "engine_service",
                        "transmission": "transmission_service",
                        "brakes": "brake_service",
                        "battery": "electrical_service",
                        "cooling_system": "cooling_service",
                        "fuel_system": "fuel_service"
                    }
                    
                    service_type = component_service_map.get(highest_risk["component"], "general_maintenance")
                    
                    # Add special requirements based on components
                    for prediction in predictions:
                        if prediction["failure_probability"] > 0.5:
                            special_requirements.append(f"{prediction['component']}_specialist")
                
                # Get user location (mock data for demo)
                user_location = (40.7128, -74.0060)  # New York City coordinates
                
                return ServiceRequest(
                    vehicle_id=vehicle_id,
                    user_id=str(vehicle.user_id),
                    service_type=service_type,
                    urgency_level=urgency_level,
                    preferred_date=datetime.now() + timedelta(days=1),
                    max_distance=self.max_distance_km,
                    budget_range=(100, 500),  # Mock budget range
                    user_location=user_location,
                    special_requirements=special_requirements
                )
                
        except Exception as e:
            self.logger.error(f"❌ Error creating service request: {e}")
            raise

    async def _create_urgent_service_request(self, vehicle_id: str, predictions: List[Dict[str, Any]]) -> ServiceRequest:
        """Create an urgent service request"""
        request = await self._create_service_request(vehicle_id, predictions)
        request.urgency_level = "critical"
        request.preferred_date = datetime.now()  # ASAP
        request.max_distance = self.max_distance_km * 2  # Expand search radius for urgent cases
        return request

    async def _find_urgent_appointments(self, request: ServiceRequest) -> List[OptimizedAppointment]:
        """Find immediate appointments for urgent cases"""
        try:
            # Get all available centers
            available_centers = await self._get_available_service_centers(request)
            
            # Look for immediate availability (today and tomorrow)
            end_date = datetime.now() + timedelta(days=2)
            time_slots = await self._get_available_time_slots(available_centers, request)
            
            # Filter for immediate slots (next 24 hours)
            immediate_slots = [
                slot for slot in time_slots 
                if slot.start_time <= datetime.now() + timedelta(hours=24)
            ]
            
            urgent_appointments = []
            for center in available_centers:
                for slot in immediate_slots:
                    if slot.service_center_id == center.id:
                        appointment = await self._create_optimized_appointment(center, slot, request)
                        urgent_appointments.append(appointment)
            
            # Sort by urgency score (prioritize distance and availability)
            urgent_appointments.sort(key=lambda x: (x.optimization_factors["distance_score"] + 
                                                   x.optimization_factors["availability_score"]), reverse=True)
            
            return urgent_appointments
            
        except Exception as e:
            self.logger.error(f"❌ Error finding urgent appointments: {e}")
            return []

    async def _create_booking(self, request: ServiceRequest, appointment: OptimizedAppointment) -> Dict[str, Any]:
        """Create a booking in the database"""
        try:
            async with AsyncSessionLocal() as session:
                booking = ServiceBooking(
                    user_id=request.user_id,
                    vehicle_id=request.vehicle_id,
                    service_center_id=appointment.service_center.id,
                    appointment_datetime=appointment.time_slot.start_time,
                    service_type=request.service_type,
                    estimated_duration=appointment.time_slot.estimated_duration,
                    status="scheduled",
                    notes=f"Auto-scheduled based on {request.urgency_level} priority",
                    created_at=datetime.utcnow()
                )
                
                session.add(booking)
                await session.commit()
                await session.refresh(booking)
                
                self.bookings_made += 1
                
                return {
                    "booking_id": str(booking.id),
                    "status": "confirmed",
                    "appointment_datetime": booking.appointment_datetime.isoformat()
                }
                
        except Exception as e:
            self.logger.error(f"❌ Error creating booking: {e}")
            raise

    async def _get_emergency_recommendations(self, request: ServiceRequest) -> List[str]:
        """Get emergency recommendations when no immediate availability"""
        recommendations = [
            "Contact emergency roadside assistance if vehicle is unsafe to drive",
            "Check with nearby independent mechanics for immediate service",
            "Consider towing to nearest available service center",
            "Monitor vehicle closely and avoid extended driving until serviced"
        ]
        
        # Add component-specific recommendations
        if "engine" in request.service_type:
            recommendations.append("Check engine oil level and coolant temperature")
        elif "brake" in request.service_type:
            recommendations.append("Avoid heavy braking and drive at reduced speeds")
        elif "battery" in request.service_type:
            recommendations.append("Keep jumper cables available and avoid short trips")
        
        return recommendations

    async def _initialize_availability_tracking(self):
        """Initialize availability tracking system"""
        try:
            # Initialize availability cache
            self.availability_cache = {}
            
            # Set up real-time availability updates if external API supports it
            # This would typically involve WebSocket connections or webhooks
            
            self.logger.info("✅ Availability tracking initialized")
            
        except Exception as e:
            self.logger.error(f"❌ Error initializing availability tracking: {e}")

    # Background task methods
    async def _availability_update_loop(self):
        """Background task to update availability data"""
        while True:
            try:
                await asyncio.sleep(300)  # Update every 5 minutes
                # Update availability for all service centers
                await self._refresh_availability_cache()
            except Exception as e:
                self.logger.error(f"❌ Error in availability update loop: {e}")

    async def _cache_cleanup_loop(self):
        """Background task for cache cleanup"""
        while True:
            try:
                await asyncio.sleep(1800)  # Run every 30 minutes
                current_time = datetime.now()
                
                # Clean expired cache entries
                expired_keys = [
                    key for key, value in self.availability_cache.items()
                    if current_time - value["timestamp"] > timedelta(seconds=self.cache_ttl)
                ]
                
                for key in expired_keys:
                    del self.availability_cache[key]
                
                self.logger.info(f"🧹 Cleaned {len(expired_keys)} expired cache entries")
                
            except Exception as e:
                self.logger.error(f"❌ Error in cache cleanup loop: {e}")

    async def _service_center_sync_loop(self):
        """Background task to sync service center data"""
        while True:
            try:
                await asyncio.sleep(3600)  # Sync every hour
                await self._load_service_centers()  # Refresh service center data
            except Exception as e:
                self.logger.error(f"❌ Error in service center sync loop: {e}")

    async def _refresh_availability_cache(self):
        """Refresh availability cache for all service centers"""
        try:
            start_date = datetime.now()
            end_date = start_date + timedelta(days=14)
            
            for center_id in self.service_centers.keys():
                await self._get_center_availability(center_id, start_date, end_date)
            
        except Exception as e:
            self.logger.error(f"❌ Error refreshing availability cache: {e}")

    # Placeholder methods for other message types
    async def _process_appointment_request(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process regular appointment request"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="customer_agent",
            message_type="appointment_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )

    async def _process_reschedule_request(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process appointment reschedule request"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="customer_agent",
            message_type="reschedule_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )

    async def _process_cancellation(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process appointment cancellation"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="customer_agent",
            message_type="cancellation_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )

    async def _process_alternative_request(self, payload: Dict[str, Any], correlation_id: str) -> AgentMessage:
        """Process request for alternative appointments"""
        # Implementation would go here
        return AgentMessage(
            sender=self.agent_name,
            recipient="customer_agent",
            message_type="alternatives_response",
            payload={"status": "processed"},
            correlation_id=correlation_id
        )