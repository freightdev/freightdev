// README.md for Phase 1

# Microservices Test Suite - Phase 1

Enterprise-grade microservices testing platform built with SvelteKit.

## Features Implemented (Phase 1)

✅ **Service Management**

- Add, edit, delete microservices
- Health check monitoring
- Environment-specific configurations
- Authentication management

✅ **HTTP Request Testing**

- Visual request builder
- Support for all HTTP methods
- Headers and query parameters
- Request body with JSON/form data
- Authentication (Bearer, API Key, Basic)

✅ **Response Analysis**

- Formatted response display
- Response time tracking
- Status code analysis
- Headers inspection
- Copy/download responses

✅ **Testing Playground**

- Interactive request builder
- Real-time response viewer
- Request history tracking

✅ **Dashboard & Monitoring**

- Service health overview
- Request statistics
- Recent activity feed
- Quick action shortcuts

## Quick Start

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd microservices-test-suite

# Install dependencies
npm install

# Start development server
npm run dev
```

### Adding Your First Service

1. Navigate to **Services** page
2. Click **Add Service**
3. Configure your service:
    - **Name**: e.g., "User Service"
    - **Base URL**: e.g., "https://api.yourservice.com"
    - **Authentication**: Choose your auth method
4. Save and test connectivity

### Testing Your APIs

1. Go to **Testing Playground**
2. Select your service
3. Configure your request:
    - Choose HTTP method
    - Set endpoint path
    - Add parameters/headers
    - Include request body if needed
4. Click **Send Request**
5. Analyze the response

## Project Structure

```
src/
├── lib/
│   ├── components/          # Reusable UI components
│   ├── services/           # Business logic services
│   ├── stores/            # Svelte stores for state management
│   └── utils/             # Utility functions
├── routes/                # SvelteKit pages
└── app.html              # HTML template
```

## Configuration

### Service Configuration

Services can be configured with:

- Base URLs per environment
- Authentication methods
- Custom headers
- Request timeouts

### Supported Authentication

- Bearer Token (JWT)
- API Key (custom header)
- Basic Authentication
- No Authentication

## Development

```bash
# Development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run tests
npm test

# Format code
npm run format

# Lint code
npm run lint
```

## Next Phase Features

🔄 **Coming in Phase 2**:

- Test suite management
- Automated test execution
- Performance testing
- Security testing
- Advanced assertions
- Test reporting
- Load testing

## Tech Stack

- **Frontend**: SvelteKit, TailwindCSS
- **State Management**: Svelte Stores
- **HTTP Client**: Custom fetch-based client
- **Styling**: TailwindCSS with dark mode
- **Icons**: Lucide Svelte

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
