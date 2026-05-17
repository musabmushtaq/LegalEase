# LegalEase Security Policy

## Overview

This document outlines the security measures and best practices implemented in LegalEase.

## Key Security Features

### 1. Authentication & Authorization

- **JWT Tokens**: Secure token-based authentication with HS256 algorithm
- **Password Hashing**: bcrypt with configurable salt rounds (12 rounds by default)
- **Token Expiration**: Implement token refresh mechanism (recommended: 24 hours)
- **Secure Storage**: Tokens stored in localStorage on web (future: httpOnly cookies recommended)

### 2. Input Validation

- **Username**: 3-50 characters, alphanumeric and underscore only
- **Email**: Valid email format validation
- **Password**: Minimum 8 characters, maximum 128 characters
- **File Uploads**: Type validation (PDF, DOC, DOCX, TXT, PNG, JPG, JPEG)
- **File Size**: Maximum 10MB per file
- **Message Content**: Non-empty, sanitized

### 3. CORS & Origin Validation

- **Restricted Origins**: Only whitelisted domains allowed
- **Credentials**: Enabled for authenticated requests
- **Methods**: Limited to GET, POST, PATCH, DELETE, OPTIONS
- **Headers**: Content-Type and Authorization only

### 4. Rate Limiting

Endpoint rate limits (per minute):

- `/auth/register`: 5 requests/minute
- `/auth/login`: 10 requests/minute
- `/chats/{id}/messages`: 60 requests/minute
- `/users/{id}/chats`: 60 requests/minute
- `/chats/{id}/share`: 20 requests/minute
- `/users/{id}/search`: 30 requests/minute

### 5. SQL/NoSQL Injection Prevention

- **Parameterized Queries**: All database queries use parameterization
- **Input Sanitization**: All user inputs validated before use
- **ORM Usage**: Motor (async MongoDB driver) prevents injection attacks

### 6. Data Protection

- **Sensitive Data**: Passwords hashed with bcrypt
- **JWT Secret**: Should be 32+ characters, random
- **Environment Variables**: All secrets stored in .env, not in code
- **Database Indexing**: Unique indexes on email and username

### 7. HTTPS/TLS

- **SSL/TLS**: Required for production (enabled via reverse proxy)
- **Certificate**: Valid SSL certificate (Let's Encrypt recommended)
- **Protocol**: TLSv1.2 minimum
- **Cipher Suites**: Strong ciphers only

### 8. Security Headers

Implemented headers:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Referrer-Policy: no-referrer-when-downgrade
Content-Security-Policy: default-src 'self'
```

## Recommended Security Practices

### For Developers

1. **Never commit secrets**: Use .env files, never hardcode secrets
2. **Validate all inputs**: Always validate user input on both client and server
3. **Sanitize output**: Escape HTML entities in user-generated content
4. **Use HTTPS**: Always use HTTPS in production
5. **Keep dependencies updated**: Regularly update all npm and pip packages
6. **Use secure random**: Use `secrets` module for token generation
7. **Log security events**: Log failed logins, suspicious activity
8. **Code review**: Security-focused code reviews before deployment

### For Deployments

1. **Environment Isolation**: Separate dev, staging, and production environments
2. **Firewall Rules**: Restrict database access to API servers only
3. **VPN Access**: Require VPN for administrative access
4. **Monitoring**: Enable CloudTrail, application monitoring
5. **Backup Strategy**: Daily backups with encryption
6. **Incident Response**: Have incident response plan ready
7. **Access Control**: Implement principle of least privilege
8. **Audit Logs**: Enable and monitor audit logs

## Known Limitations & Future Improvements

### Current Limitations

1. **Tokens in localStorage**: Vulnerable to XSS attacks
   - **Fix**: Migrate to httpOnly cookies
   - **Timeline**: Q2 2024

2. **No Token Refresh**: Tokens valid for lifetime
   - **Fix**: Implement refresh token mechanism
   - **Timeline**: Q2 2024

3. **No Rate Limiting per User**: Based on IP address
   - **Fix**: Implement user-based rate limiting
   - **Timeline**: Q1 2024

4. **Demo AI Responses**: Using hardcoded responses
   - **Fix**: Integrate with actual AI service (Gemini API)
   - **Timeline**: Q3 2024

### Planned Security Enhancements

- [ ] Two-Factor Authentication (2FA)
- [ ] OAuth 2.0 / OpenID Connect
- [ ] API Key management for third-party integrations
- [ ] End-to-end encryption for messages
- [ ] Audit logging with tamper-proof timestamps
- [ ] Data encryption at rest
- [ ] Security scanning in CI/CD pipeline
- [ ] Dependency vulnerability scanning (Snyk)
- [ ] GDPR compliance features
- [ ] CCPA compliance features

## Vulnerability Reporting

### Responsible Disclosure

If you discover a security vulnerability, please email **security@legalease.dev** with:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

**Please do not** disclose the vulnerability publicly until we have a fix available.

### Response Timeline

- **24 hours**: Initial acknowledgment
- **72 hours**: Initial assessment
- **7 days**: Patch release for critical vulnerabilities
- **30 days**: Patch release for non-critical vulnerabilities

## Compliance

### GDPR Compliance

- User consent for data collection
- Right to access personal data
- Right to be forgotten (data deletion)
- Data portability
- Privacy policy and terms of service

### CCPA Compliance

- Disclosure of personal information collection
- Consumer rights notices
- Opt-out mechanism
- Non-discrimination for exercising rights

## Third-Party Security

- **Dependencies**: Regular security audits of all packages
- **APIs**: Secure communication with external APIs
- **Data Sharing**: No sharing of user data with third parties without consent

## Testing Security

### Manual Testing

```bash
# Test SQL injection
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin\" OR \"1\"=\"1","password":"test"}'

# Test rate limiting
for i in {1..15}; do curl http://localhost:8000/auth/login; done

# Test CORS
curl -H "Origin: https://evil.com" http://localhost:8000/health
```

### Automated Testing

```bash
# Run security tests
pytest tests/test_security.py -v

# Check dependencies for vulnerabilities
pip install safety
safety check

# SAST scanning
bandit -r api/
```

## Security Benchmarks

Target security scores:

- **OWASP Top 10**: Compliant
- **CWE Top 25**: No critical vulnerabilities
- **Security Headers**: A+ (securityheaders.com)
- **SSL Labs**: A+ (ssllabs.com)

## Contact

- **Security Issues**: security@legalease.dev
- **General Questions**: support@legalease.dev
- **Bug Reports**: GitHub Issues (non-security)
