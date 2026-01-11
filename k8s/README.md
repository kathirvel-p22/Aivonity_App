# AIVONITY Kubernetes Deployment

This directory contains Kubernetes manifests and deployment scripts for the AIVONITY Intelligent Vehicle Assistant ecosystem.

## Prerequisites

- Kubernetes cluster (v1.20+)
- kubectl configured to connect to your cluster
- Docker registry access for custom images
- Ingress controller (nginx-ingress recommended)

## Architecture

The deployment includes:

- **Backend Services**: FastAPI application with AI agents
- **Databases**: PostgreSQL with TimescaleDB extension, Redis
- **Load Balancing**: Nginx reverse proxy with auto-scaling
- **Monitoring**: Prometheus and Grafana stack
- **Security**: TLS termination, secrets management
- **Auto-scaling**: Horizontal Pod Autoscaler (HPA)

## Quick Start

### 1. Update Secrets

Before deploying, update the secrets in `secrets.yaml` with your actual API keys:

```bash
# Encode your secrets in base64
echo -n "your-openai-api-key" | base64
echo -n "your-sendgrid-api-key" | base64
```

### 2. Build and Push Docker Images

```bash
# Build backend image
cd ../backend
docker build -t your-registry/aivonity-backend:latest .
docker push your-registry/aivonity-backend:latest

# Update image reference in backend-deployment.yaml
```

### 3. Deploy to Kubernetes

#### Using PowerShell (Windows):

```powershell
cd k8s
.\deploy.ps1
```

#### Using Bash (Linux/Mac):

```bash
cd k8s
./deploy.sh
```

#### Manual Deployment:

```bash
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
kubectl apply -f configmap.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f redis-deployment.yaml
kubectl apply -f backend-deployment.yaml
kubectl apply -f nginx-deployment.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml
kubectl apply -f monitoring.yaml
```

## Configuration

### Environment Variables

Key configuration is managed through ConfigMaps and Secrets:

- **ConfigMap** (`aivonity-config`): Non-sensitive configuration
- **Secret** (`aivonity-secrets`): API keys and passwords

### Resource Limits

Default resource allocations:

- **Backend**: 1-2GB RAM, 0.5-1 CPU per pod
- **PostgreSQL**: 512MB-1GB RAM, 0.25-0.5 CPU
- **Redis**: 256-512MB RAM, 0.1-0.2 CPU
- **Nginx**: 128-256MB RAM, 0.1-0.2 CPU

### Auto-scaling

HPA is configured for:

- **Backend**: 3-10 replicas based on CPU (70%) and memory (80%)
- **Nginx**: 2-5 replicas based on CPU (60%)

## Monitoring

### Prometheus Metrics

The backend exposes metrics at `/metrics` endpoint:

- Request latency and throughput
- AI agent performance
- Database connection pool status
- Custom business metrics

### Grafana Dashboards

Access Grafana at `http://grafana-service:3000`:

- Default credentials: admin/admin
- Pre-configured dashboards for system monitoring
- Custom dashboards for AIVONITY-specific metrics

## Security

### Network Policies

Consider implementing network policies to restrict pod-to-pod communication:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: aivonity-network-policy
  namespace: aivonity
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### RBAC

Implement Role-Based Access Control for service accounts:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aivonity-backend
  namespace: aivonity
```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending**: Check resource availability and node capacity
2. **ImagePullBackOff**: Verify image registry access and image names
3. **Database connection errors**: Check service names and port configurations
4. **Ingress not working**: Verify ingress controller installation

### Useful Commands

```bash
# Check pod status
kubectl get pods -n aivonity

# View logs
kubectl logs -f deployment/aivonity-backend-deployment -n aivonity

# Describe problematic pods
kubectl describe pod <pod-name> -n aivonity

# Port forward for local access
kubectl port-forward service/nginx-service 8080:80 -n aivonity

# Scale deployments
kubectl scale deployment aivonity-backend-deployment --replicas=5 -n aivonity

# Check HPA status
kubectl get hpa -n aivonity

# View events
kubectl get events -n aivonity --sort-by='.lastTimestamp'
```

### Health Checks

All services include health checks:

- **Backend**: `/health/quick` endpoint
- **PostgreSQL**: `pg_isready` command
- **Redis**: `redis-cli ping` command
- **Nginx**: `/health` endpoint

## Cleanup

To remove all AIVONITY resources:

#### Using PowerShell:

```powershell
.\cleanup.ps1
```

#### Using Bash:

```bash
./cleanup.sh
```

## Production Considerations

### High Availability

- Deploy across multiple availability zones
- Use managed database services (RDS, Cloud SQL)
- Implement backup and disaster recovery
- Set up monitoring and alerting

### Performance

- Tune database connection pools
- Implement caching strategies
- Use CDN for static assets
- Monitor and optimize ML model inference

### Security

- Enable Pod Security Standards
- Use network policies
- Implement secrets rotation
- Regular security scanning
- Enable audit logging

### Cost Optimization

- Use spot instances where appropriate
- Implement cluster autoscaling
- Monitor resource utilization
- Use resource quotas and limits

## Support

For deployment issues or questions:

1. Check the troubleshooting section
2. Review Kubernetes events and logs
3. Consult the main AIVONITY documentation
4. Contact the development team
