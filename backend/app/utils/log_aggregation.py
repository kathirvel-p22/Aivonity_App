"""
AIVONITY Log Aggregation and Analysis System
Centralized log collection, analysis, and alerting
"""

import asyncio
import logging
import json
import re
from typing import Dict, Any, List, Optional, Callable, Pattern
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from collections import defaultdict, deque
from pathlib import Path
import gzip
import threading
from enum import Enum

from app.utils.exceptions import SystemError


class LogLevel(str, Enum):
    """Log levels for filtering"""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class LogPattern(str, Enum):
    """Common log patterns for analysis"""
    ERROR_PATTERN = "error_pattern"
    PERFORMANCE_PATTERN = "performance_pattern"
    SECURITY_PATTERN = "security_pattern"
    ANOMALY_PATTERN = "anomaly_pattern"


@dataclass
class LogEntry:
    """Structured log entry"""
    timestamp: datetime
    level: LogLevel
    logger_name: str
    message: str
    module: Optional[str] = None
    function: Optional[str] = None
    line_number: Optional[int] = None
    thread_id: Optional[int] = None
    process_id: Optional[int] = None
    user_id: Optional[str] = None
    correlation_id: Optional[str] = None
    extra_data: Dict[str, Any] = field(default_factory=dict)


@dataclass
class LogAnalysisResult:
    """Result of log analysis"""
    pattern_name: str
    matches: List[LogEntry]
    count: int
    time_range: tuple
    severity: str
    summary: str
    recommendations: List[str] = field(default_factory=list)


class LogPatternMatcher:
    """Pattern matcher for log analysis"""
    
    def __init__(self):
        self.patterns: Dict[str, Pattern] = {}
        self.pattern_handlers: Dict[str, Callable] = {}
        self._setup_default_patterns()
    
    def _setup_default_patterns(self):
        """Setup default log patterns"""
        
        # Error patterns
        self.add_pattern(
            "database_connection_error",
            r"database.*connection.*(?:failed|error|timeout)",
            self._handle_database_error
        )
        
        self.add_pattern(
            "authentication_failure",
            r"authentication.*(?:failed|invalid|denied)",
            self._handle_auth_error
        )
        
        self.add_pattern(
            "api_timeout",
            r"(?:timeout|timed out).*(?:api|request|response)",
            self._handle_timeout_error
        )
        
        # Performance patterns
        self.add_pattern(
            "slow_query",
            r"slow.*query.*(\d+)ms",
            self._handle_slow_query
        )
        
        self.add_pattern(
            "high_memory_usage",
            r"memory.*usage.*(\d+)%",
            self._handle_high_memory
        )
        
        # Security patterns
        self.add_pattern(
            "suspicious_login",
            r"suspicious.*login.*attempt",
            self._handle_suspicious_login
        )
        
        self.add_pattern(
            "rate_limit_exceeded",
            r"rate.*limit.*exceeded",
            self._handle_rate_limit
        )
        
        # Anomaly patterns
        self.add_pattern(
            "unusual_error_rate",
            r"error.*rate.*(?:high|unusual|spike)",
            self._handle_error_spike
        )
    
    def add_pattern(self, name: str, pattern: str, handler: Callable):
        """Add a new pattern matcher"""
        self.patterns[name] = re.compile(pattern, re.IGNORECASE)
        self.pattern_handlers[name] = handler
    
    def match_patterns(self, log_entry: LogEntry) -> List[str]:
        """Match log entry against all patterns"""
        matches = []
        
        for pattern_name, pattern in self.patterns.items():
            if pattern.search(log_entry.message):
                matches.append(pattern_name)
                
                # Call pattern handler
                try:
                    handler = self.pattern_handlers.get(pattern_name)
                    if handler:
                        handler(log_entry, pattern_name)
                except Exception as e:
                    logging.getLogger("log_pattern_matcher").error(
                        f"Pattern handler failed for {pattern_name}: {str(e)}"
                    )
        
        return matches
    
    def _handle_database_error(self, log_entry: LogEntry, pattern_name: str):
        """Handle database error pattern"""
        logging.getLogger("log_analysis").warning(
            f"Database error detected: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )
    
    def _handle_auth_error(self, log_entry: LogEntry, pattern_name: str):
        """Handle authentication error pattern"""
        logging.getLogger("log_analysis").warning(
            f"Authentication failure detected: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )
    
    def _handle_timeout_error(self, log_entry: LogEntry, pattern_name: str):
        """Handle timeout error pattern"""
        logging.getLogger("log_analysis").warning(
            f"Timeout error detected: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )
    
    def _handle_slow_query(self, log_entry: LogEntry, pattern_name: str):
        """Handle slow query pattern"""
        logging.getLogger("log_analysis").info(
            f"Slow query detected: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )
    
    def _handle_high_memory(self, log_entry: LogEntry, pattern_name: str):
        """Handle high memory usage pattern"""
        logging.getLogger("log_analysis").warning(
            f"High memory usage detected: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )
    
    def _handle_suspicious_login(self, log_entry: LogEntry, pattern_name: str):
        """Handle suspicious login pattern"""
        logging.getLogger("log_analysis").error(
            f"Suspicious login detected: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )
    
    def _handle_rate_limit(self, log_entry: LogEntry, pattern_name: str):
        """Handle rate limit pattern"""
        logging.getLogger("log_analysis").warning(
            f"Rate limit exceeded: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )
    
    def _handle_error_spike(self, log_entry: LogEntry, pattern_name: str):
        """Handle error spike pattern"""
        logging.getLogger("log_analysis").error(
            f"Error spike detected: {log_entry.message}",
            extra={"pattern": pattern_name, "log_entry": log_entry.__dict__}
        )


class LogAggregator:
    """Aggregate and analyze logs from multiple sources"""
    
    def __init__(self, max_entries: int = 10000):
        self.max_entries = max_entries
        self.log_entries: deque = deque(maxlen=max_entries)
        self.pattern_matcher = LogPatternMatcher()
        self.analysis_results: Dict[str, LogAnalysisResult] = {}
        self.logger = logging.getLogger("log_aggregator")
        self._lock = threading.RLock()
        
        # Statistics
        self.stats = {
            "total_entries": 0,
            "entries_by_level": defaultdict(int),
            "entries_by_logger": defaultdict(int),
            "pattern_matches": defaultdict(int)
        }
    
    def add_log_entry(self, log_entry: LogEntry):
        """Add a log entry to the aggregator"""
        with self._lock:
            self.log_entries.append(log_entry)
            
            # Update statistics
            self.stats["total_entries"] += 1
            self.stats["entries_by_level"][log_entry.level.value] += 1
            self.stats["entries_by_logger"][log_entry.logger_name] += 1
            
            # Check patterns
            matches = self.pattern_matcher.match_patterns(log_entry)
            for match in matches:
                self.stats["pattern_matches"][match] += 1
    
    def parse_log_line(self, log_line: str, log_format: str = "json") -> Optional[LogEntry]:
        """Parse a log line into a LogEntry"""
        try:
            if log_format == "json":
                return self._parse_json_log(log_line)
            else:
                return self._parse_text_log(log_line)
        except Exception as e:
            self.logger.error(f"Failed to parse log line: {str(e)}")
            return None
    
    def _parse_json_log(self, log_line: str) -> LogEntry:
        """Parse JSON formatted log line"""
        data = json.loads(log_line.strip())
        
        return LogEntry(
            timestamp=datetime.fromisoformat(data.get("timestamp", datetime.utcnow().isoformat())),
            level=LogLevel(data.get("level", "INFO")),
            logger_name=data.get("logger", "unknown"),
            message=data.get("message", ""),
            module=data.get("module"),
            function=data.get("function"),
            line_number=data.get("line_number"),
            thread_id=data.get("thread_id"),
            process_id=data.get("process_id"),
            user_id=data.get("user_id"),
            correlation_id=data.get("correlation_id"),
            extra_data={k: v for k, v in data.items() if k not in [
                "timestamp", "level", "logger", "message", "module", 
                "function", "line_number", "thread_id", "process_id",
                "user_id", "correlation_id"
            ]}
        )
    
    def _parse_text_log(self, log_line: str) -> LogEntry:
        """Parse text formatted log line"""
        # Simple regex pattern for standard log format
        pattern = r"(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d+ \[(\w+)\] (\w+): (.+)"
        match = re.match(pattern, log_line.strip())
        
        if match:
            timestamp_str, level, logger_name, message = match.groups()
            timestamp = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
            
            return LogEntry(
                timestamp=timestamp,
                level=LogLevel(level),
                logger_name=logger_name,
                message=message
            )
        else:
            # Fallback for unparseable lines
            return LogEntry(
                timestamp=datetime.utcnow(),
                level=LogLevel.INFO,
                logger_name="unknown",
                message=log_line.strip()
            )
    
    def get_entries(
        self,
        level: Optional[LogLevel] = None,
        logger_name: Optional[str] = None,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        limit: int = 1000
    ) -> List[LogEntry]:
        """Get filtered log entries"""
        with self._lock:
            entries = list(self.log_entries)
        
        # Apply filters
        if level:
            entries = [e for e in entries if e.level == level]
        
        if logger_name:
            entries = [e for e in entries if e.logger_name == logger_name]
        
        if start_time:
            entries = [e for e in entries if e.timestamp >= start_time]
        
        if end_time:
            entries = [e for e in entries if e.timestamp <= end_time]
        
        # Sort by timestamp (newest first) and limit
        entries.sort(key=lambda x: x.timestamp, reverse=True)
        return entries[:limit]
    
    def analyze_patterns(self, time_window_hours: int = 24) -> Dict[str, LogAnalysisResult]:
        """Analyze log patterns within time window"""
        cutoff_time = datetime.utcnow() - timedelta(hours=time_window_hours)
        recent_entries = self.get_entries(start_time=cutoff_time)
        
        pattern_results = {}
        
        for pattern_name in self.pattern_matcher.patterns.keys():
            matches = []
            
            for entry in recent_entries:
                if self.pattern_matcher.patterns[pattern_name].search(entry.message):
                    matches.append(entry)
            
            if matches:
                # Determine severity based on pattern and frequency
                severity = self._determine_severity(pattern_name, len(matches), time_window_hours)
                
                result = LogAnalysisResult(
                    pattern_name=pattern_name,
                    matches=matches,
                    count=len(matches),
                    time_range=(matches[-1].timestamp, matches[0].timestamp),
                    severity=severity,
                    summary=f"Found {len(matches)} occurrences of {pattern_name} in the last {time_window_hours} hours",
                    recommendations=self._get_recommendations(pattern_name, len(matches))
                )
                
                pattern_results[pattern_name] = result
        
        return pattern_results
    
    def _determine_severity(self, pattern_name: str, count: int, hours: int) -> str:
        """Determine severity based on pattern and frequency"""
        rate_per_hour = count / hours
        
        # Define severity thresholds by pattern type
        thresholds = {
            "database_connection_error": {"critical": 5, "high": 2, "medium": 1},
            "authentication_failure": {"critical": 20, "high": 10, "medium": 5},
            "api_timeout": {"critical": 10, "high": 5, "medium": 2},
            "suspicious_login": {"critical": 1, "high": 1, "medium": 1},
            "rate_limit_exceeded": {"critical": 50, "high": 20, "medium": 10}
        }
        
        pattern_thresholds = thresholds.get(pattern_name, {"critical": 10, "high": 5, "medium": 2})
        
        if rate_per_hour >= pattern_thresholds["critical"]:
            return "critical"
        elif rate_per_hour >= pattern_thresholds["high"]:
            return "high"
        elif rate_per_hour >= pattern_thresholds["medium"]:
            return "medium"
        else:
            return "low"
    
    def _get_recommendations(self, pattern_name: str, count: int) -> List[str]:
        """Get recommendations based on pattern analysis"""
        recommendations = {
            "database_connection_error": [
                "Check database server health and connectivity",
                "Review connection pool configuration",
                "Monitor database performance metrics"
            ],
            "authentication_failure": [
                "Review authentication logs for suspicious patterns",
                "Consider implementing account lockout policies",
                "Monitor for brute force attacks"
            ],
            "api_timeout": [
                "Review API endpoint performance",
                "Check network connectivity and latency",
                "Consider increasing timeout values or optimizing queries"
            ],
            "suspicious_login": [
                "Investigate login attempts immediately",
                "Consider blocking suspicious IP addresses",
                "Enable additional authentication factors"
            ],
            "rate_limit_exceeded": [
                "Review rate limiting configuration",
                "Identify clients causing excessive requests",
                "Consider implementing adaptive rate limiting"
            ]
        }
        
        return recommendations.get(pattern_name, ["Review logs and investigate further"])
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get aggregation statistics"""
        with self._lock:
            return {
                "total_entries": self.stats["total_entries"],
                "current_buffer_size": len(self.log_entries),
                "max_buffer_size": self.max_entries,
                "entries_by_level": dict(self.stats["entries_by_level"]),
                "entries_by_logger": dict(self.stats["entries_by_logger"]),
                "pattern_matches": dict(self.stats["pattern_matches"]),
                "buffer_utilization": len(self.log_entries) / self.max_entries * 100
            }


class LogFileWatcher:
    """Watch log files for new entries"""
    
    def __init__(self, log_aggregator: LogAggregator):
        self.log_aggregator = log_aggregator
        self.watched_files: Dict[str, Dict[str, Any]] = {}
        self.logger = logging.getLogger("log_file_watcher")
        self._running = False
        self._watch_task: Optional[asyncio.Task] = None
    
    def add_log_file(self, file_path: str, log_format: str = "json"):
        """Add a log file to watch"""
        path = Path(file_path)
        if path.exists():
            self.watched_files[file_path] = {
                "path": path,
                "format": log_format,
                "last_position": path.stat().st_size,
                "last_modified": path.stat().st_mtime
            }
            self.logger.info(f"Added log file to watch: {file_path}")
        else:
            self.logger.warning(f"Log file not found: {file_path}")
    
    async def start_watching(self):
        """Start watching log files"""
        if self._running:
            return
        
        self._running = True
        self._watch_task = asyncio.create_task(self._watch_files())
        self.logger.info("Started log file watching")
    
    async def stop_watching(self):
        """Stop watching log files"""
        self._running = False
        if self._watch_task:
            self._watch_task.cancel()
            try:
                await self._watch_task
            except asyncio.CancelledError:
                pass
        self.logger.info("Stopped log file watching")
    
    async def _watch_files(self):
        """Watch files for changes"""
        while self._running:
            try:
                for file_path, file_info in self.watched_files.items():
                    await self._check_file_changes(file_path, file_info)
                
                await asyncio.sleep(1)  # Check every second
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                self.logger.error(f"Error watching files: {str(e)}")
                await asyncio.sleep(5)
    
    async def _check_file_changes(self, file_path: str, file_info: Dict[str, Any]):
        """Check if file has changed and process new entries"""
        try:
            path = file_info["path"]
            
            if not path.exists():
                return
            
            current_size = path.stat().st_size
            current_modified = path.stat().st_mtime
            
            # Check if file has grown or been modified
            if (current_size > file_info["last_position"] or 
                current_modified > file_info["last_modified"]):
                
                # Read new content
                with open(path, 'r', encoding='utf-8') as f:
                    f.seek(file_info["last_position"])
                    new_lines = f.readlines()
                
                # Process new lines
                for line in new_lines:
                    if line.strip():
                        log_entry = self.log_aggregator.parse_log_line(
                            line, file_info["format"]
                        )
                        if log_entry:
                            self.log_aggregator.add_log_entry(log_entry)
                
                # Update file info
                file_info["last_position"] = current_size
                file_info["last_modified"] = current_modified
                
        except Exception as e:
            self.logger.error(f"Error checking file {file_path}: {str(e)}")


# Global log aggregator instance
log_aggregator = LogAggregator()
log_file_watcher = LogFileWatcher(log_aggregator)


async def setup_log_aggregation():
    """Setup log aggregation system"""
    
    # Add log files to watch
    log_files = [
        ("logs/aivonity.json", "json"),
        ("logs/agents.log", "json"),
        ("logs/audit.log", "json"),
        ("logs/security.log", "json"),
        ("logs/performance.log", "json")
    ]
    
    for file_path, format_type in log_files:
        log_file_watcher.add_log_file(file_path, format_type)
    
    # Start watching
    await log_file_watcher.start_watching()
    
    logging.getLogger("log_aggregation").info("Log aggregation system initialized")


async def shutdown_log_aggregation():
    """Shutdown log aggregation system"""
    await log_file_watcher.stop_watching()