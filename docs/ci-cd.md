# AIVONITY CI/CD Pipeline Documentation

## Overview

The AIVONITY project uses GitHub Actions for continuous integration and deployment. The pipeline includes automated testing, security scanning, building, and deployment across multiple environments.

## Pipeline Structure

### 1. Backend CI/CD (`backend-ci.yml`)

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Changes to backend code or workflow files

**Jobs:**

- **Test**: Unit tests, integration tests, linting, type checking
- **Security Scan**: Bandit, Safety, vulnerability scanning
- **Build**: Docker image building and pushing to registry
- **Deploy Staging**: Automatic deployment to staging environment
- **Deploy Production**: Manual deployment to production environment
- **Rollback**: Automatic rollback on deployment failure

### 2. Mobile CI/CD (`mobile-ci.yml`)

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Changes to mobile code or workflow files

**Jobs:**

- **Test**: Flutter unit tests, widget tests, integration tests
- **Build Android**: APK and AAB building with signing
- **Build iOS**: IPA building with provisioning profiles
- **Security Scan**: Dependency auditing and vulnerability scanning
- **Deploy Android**: Play Store internal testing deployment
- **Deploy iOS**: TestFlight deployment

### 3. Infrastructure CI/CD (`infrastructure-ci.yml`)

**Triggers:**

- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches
- Changes to Kubernetes manifests or Docker Compose files

**Jobs:**

- **Validate Kubernetes**: Manifest validation and linting
- **Validate Docker Compose**: Configuration validation
- **Security Scan**: Infrastructure security scanning
- **Test Deployment**: Kind cluster testing
- **Deploy Infrastructure**: Environment-specific deployments

### 4. Security Scanning (`security-scan.yml`)

**Triggers:**

- Daily scheduled runs at 2 AM UTC
- Push to `main` branch
- Pull requests to `main` branch

**Jobs:**

- **CodeQL Analysis**: Static code analysis
- **Dependency Scan**: Vulnerability scanning for dependencies
- **Secret Scan**: Secret detection in codebase
- **Container Scan**: Docker image vulnerability scanning
- **Infrastructure Scan**: Kubernetes and Docker security scanning
- **Compliance Check**: Policy and compliance validation

## Environment Configuration

### Required Secrets

#### GitHub Repository Secrets

- `GITHUB_TOKEN`: Automatically provided by GitHub
- `OPENAI_API_KEY`: OpenAI API key for AI services
- `ANTHROPIC_API_KEY`: Anthropic API key for AI services
- `SENDGRID_API_KEY`: SendGrid API key for email notifications
- `TWILIO_ACCOUNT_SID`: Twilio account SID for SMS
- `TWILIO_AUTH_TOKEN`: Twilio auth token for SMS
- `SLACK_WEBHOOK_URL`: Slack webhook for notifications
- `SNYK_TOKEN`: Snyk token for security scanning

#### Kubernetes Secrets

- `KUBE_CONFIG_STAGING`: Base64 encoded kubeconfig for staging
- `KUBE_CONFIG_PRODUCTION`: Base64 encoded kubeconfig for production

#### Mobile App Secrets

- `ANDROID_KEYSTORE`: Base64 encoded Android keystore
- `ANDROID_KEY_ALIAS`: Android key alias
- `ANDROID_STORE_PASSWORD`: Android keystore password
- `ANDROID_KEY_PASSWORD`: Android key password
- `IOS_CERTIFICATE`: Base64 encoded iOS certificate
- `IOS_PROVISIONING_PROFILE`: Base64 encoded provisioning profile
- `IOS_CERTIFICATE_PASSWORD`: iOS certificate password
- `GOOGLE_PLAY_SERVICE_ACCOUNT`: Google Play service account JSON
- `APPLE_ID_EMAIL`: Apple ID email for TestFlight
- `APPLE_ID_PASSWORD`: Apple ID password for TestFlight

## Deployment Environments

### Staging Environment

- **Trigger**: Push to `develop` branch
- **Purpose**: Testing and validation before production
- **Features**: Full feature set with test data
- **Access**: Internal team and stakeholders

### Production Environment

- **Trigger**: Push to `main` branch
- **Purpose**: Live production environment
- **Features**: Full feature set with real data
- **Access**: End users and customers

## Quality Gates

### Code Quality

- Linting with flake8, black, and isort
- Type checking with mypy
- Code coverage minimum 80%
- Security scanning with Bandit

### Testing Requirements

- Unit tests must pass
- Integration tests must pass
- Security tests must pass
- Performance tests for critical paths

### Security Requirements

- No high or critical vulnerabilities
- Secret scanning must pass
- Container security scanning
- Infrastructure security validation

## Monitoring and Notifications

### Slack Notifications

- Deployment success/failure notifications
- Security scan results
- Infrastructure changes

### Metrics and Monitoring

- Build success/failure rates
- Deployment frequency
- Lead time for changes
- Mean time to recovery

## Troubleshooting

### Common Issues

1. **Test failures**: Check logs and fix failing tests
2. **Security scan failures**: Address vulnerabilities
3. **Build failures**: Check dependencies and configuration
4. **Deployment failures**: Verify Kubernetes configuration

### Rollback Procedures

- Automatic rollback on deployment failure
- Manual rollback using kubectl commands
- Database migration rollback procedures

## Best Practices

### Branch Strategy

- `main`: Production-ready code
- `develop`: Integration branch for features
- Feature branches: Individual feature development

### Commit Messages

- Use conventional commit format
- Include issue references
- Clear and descriptive messages

### Pull Request Process

- Required reviews from code owners
- All checks must pass
- Security review for sensitive changes

## Maintenance

### Regular Tasks

- Update dependencies weekly
- Review security scan results
- Monitor pipeline performance
- Update documentation

### Scheduled Maintenance

- Monthly security reviews
- Quarterly pipeline optimization
- Annual disaster recovery testing
