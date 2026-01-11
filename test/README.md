# AIVONITY Automated Testing Suite

This directory contains the comprehensive automated testing suite for the AIVONITY application, covering unit tests, integration tests, end-to-end tests, and performance tests.

## Test Structure

```
test/
├── unit/                    # Unit tests for individual components
│   ├── models/             # Model unit tests
│   ├── services/           # Service unit tests
│   ├── widgets/            # Widget unit tests
│   └── utils/              # Utility unit tests
├── integration/            # Integration tests for API endpoints
│   ├── auth/               # Authentication integration tests
│   ├── telemetry/          # Telemetry integration tests
│   ├── chat/               # AI chat integration tests
│   └── notifications/      # Notification integration tests
├── e2e/                    # End-to-end tests for user journeys
│   ├── user_flows/         # Complete user journey tests
│   └── critical_paths/     # Critical functionality tests
├── performance/            # Performance and load tests
│   ├── load_tests/         # Load testing scenarios
│   └── stress_tests/       # Stress testing scenarios
├── helpers/                # Test helpers and utilities
├── fixtures/               # Test data and fixtures
└── mocks/                  # Mock implementations

```

## Running Tests

### Unit Tests

```bash
flutter test test/unit/
```

### Integration Tests

```bash
flutter test test/integration/
```

### End-to-End Tests

```bash
flutter test test/e2e/
```

### Performance Tests

```bash
flutter test test/performance/
```

### All Tests

```bash
flutter test
```

## Test Coverage

The testing suite aims for:

- 90% code coverage for core functionality
- 100% coverage for critical paths (authentication, safety features)
- 85% overall code coverage

## Test Categories

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test API endpoints and service integration
- **E2E Tests**: Test complete user journeys
- **Performance Tests**: Test load handling and response times
