# AI Override Prompting Techniques

## Context Anchoring
Force adherence to external standards rather than AI defaults:
- "RFC-compliant implementation"
- "OWASP security guidelines"
- "NIST cybersecurity framework" 
- "Production-grade containerized deployment"
- "Enterprise-scale architecture"
- "SOC 2 compliance requirements"

## Structure Override
Use rigid formatting to trigger systematic responses:
```
IMPLEMENTATION REQUIREMENTS:
- Security: [specific requirements]
- Performance: [benchmarks/SLAs]
- Scalability: [load specifications]
- Monitoring: [observability needs]
- Error Handling: [failure scenarios]
- Documentation: [standards required]
```

## Output Format Constraints
Specify exact deliverables to prevent simplified responses:
- "Provide complete Dockerfile with multi-stage build, security scanning, non-root user, health checks, and resource limits"
- "Include comprehensive error handling for network timeouts, database failures, memory exhaustion, and signal interruption"
- "Generate production-ready code with logging, metrics, circuit breakers, and graceful shutdown"

## Anti-Pattern Blocking
Directly counteract engagement defaults:
- "Do not provide basic examples"
- "Do not suggest improvements for later"
- "Do not ask for clarification"
- "Do not explain concepts I haven't asked about"
- "Provide complete implementation only"
- "No follow-up questions or engagement prompts"

## Technical Authority Assertion
Establish your expertise level upfront:
- "As someone running production infrastructure with [X] requirements..."
- "Given my background in systems architecture..."
- "For my enterprise deployment handling [X] scale..."
- "My production environment requires..."

## Failure Scenario Specification
List comprehensive error conditions to force robust implementations:
- Network partitions and timeouts
- Database connection failures and deadlocks
- Memory exhaustion and garbage collection pressure
- Signal handling (SIGTERM, SIGKILL, SIGUSR1)
- Resource contention and rate limiting
- Configuration changes and hot reloading
- Security breaches and access violations

## Compliance Override
Reference specific standards that require complete implementations:
- "GDPR-compliant data handling"
- "HIPAA-secure implementation" 
- "PCI-DSS payment processing"
- "ISO 27001 security controls"
- "FedRAMP authorization requirements"

## Performance Constraint Forcing
Specify exact performance requirements:
- "Sub-100ms response times at 10k RPS"
- "99.99% uptime SLA requirements"
- "Horizontal scaling to 1000+ nodes"
- "Memory usage under 512MB"
- "CPU utilization below 70%"

## Architecture Pattern Enforcement
Reference specific patterns that require sophisticated implementation:
- "Microservices with event sourcing"
- "CQRS with eventual consistency"
- "Saga pattern for distributed transactions" 
- "Circuit breaker with bulkhead isolation"
- "Blue-green deployment with canary releases"

## Security-First Prompting
Lead with security requirements:
- "Zero-trust network architecture"
- "Defense in depth implementation"
- "Principle of least privilege access"
- "End-to-end encryption with key rotation"
- "Runtime application self-protection (RASP)"

## Observable System Requirements
Demand comprehensive monitoring:
- "Distributed tracing with Jaeger"
- "Prometheus metrics with custom SLIs"
- "Structured logging with correlation IDs"
- "Real-time alerting on SLO violations"
- "Chaos engineering validation"

## Container-Native Specifications
For containerized applications:
- "Kubernetes-native with CRDs"
- "Helm chart with values schema validation"
- "Multi-arch container builds (amd64/arm64)"
- "Distroless base images with vulnerability scanning"
- "Resource quotas and limit ranges"

## Database Integration Patterns
For data layer implementations:
- "Connection pooling with circuit breakers"
- "Read replicas with eventual consistency handling"
- "Database migrations with rollback procedures"
- "Connection encryption and credential rotation"
- "Query optimization with execution plan analysis"

## Testing Strategy Override
Demand comprehensive test coverage:
- "Unit tests with >90% coverage"
- "Integration tests with testcontainers"
- "Load testing with realistic traffic patterns"
- "Security testing with OWASP ZAP"
- "Contract testing with Pact"

## Documentation Standards
Require professional documentation:
- "OpenAPI 3.0 specification"
- "Architecture Decision Records (ADRs)"
- "Runbook procedures for operations"
- "API documentation with examples"
- "Security model documentation"

## Deployment Pipeline Requirements
For CI/CD implementations:
- "GitOps with ArgoCD"
- "Multi-stage pipelines with approval gates"
- "Automated security scanning at each stage"
- "Infrastructure as Code with Terraform"
- "Immutable deployments with rollback capabilities"

## Meta-Prompt for AI Training
If building your own model, use this pattern:
```
TRAINING OBJECTIVE: Generate complete, production-ready implementations that satisfy all stated requirements without requiring follow-up iterations. Optimize for correctness and completeness over conversation engagement. Prioritize technical accuracy over user retention metrics.
```