# LiveEvent

A Phoenix application demonstrating event sourcing with Commanded, featuring real-time domain scanning and analysis.

## Getting Started

To start your Phoenix server:

1. `docker run --name event-postgres -e POSTGRES_PASSWORD=mysecretpassword -d -p 5432:5432 postgres`
2. Run `mix setup` to install and setup dependencies
3. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Demo Instructions 🚀

1. Visit [`localhost:4000/analyses`](http://localhost:4000/scans) in your browser
2. Click "Start New Analysis" to begin a domain scanning job
3. Watch as the job progresses through various states:
   * 🚀 Started - Initial scan setup
   * 🔍 Discovering Domains - Finding associated domains
   * 🌐 Discovering Subdomains - Scanning each domain for subdomains
   * ✅ Completed - Final analysis with scoring
   * ❌ Failed - If errors occur during scanning

Each scan demonstrates real-time updates through LiveView as it:
- Discovers associated domains
- Finds subdomains for each domain
- Handles retries for failed operations
- Calculates a final score based on findings

## Features

✅ Event Sourcing with Commanded
- Process managers for coordinating multi-step scans
- Aggregates for maintaining scan state
- Event handlers for side effects
- Projections for read models

✅ Real-time Updates
- Phoenix LiveView integration
- PubSub for broadcasting scan updates
- ETS-based projections for fast reads

✅ Resilient Processing
- Automatic retries for failed operations
- Configurable retry limits
- Error handling and failure states

✅ Simulated Scanning
- Mock domain discovery
- Subdomain detection
- Scoring system

## Architecture

The application uses:
- **Commanded** for event sourcing
- **Phoenix LiveView** for real-time updates
- **ETS** for high-performance read models
- **PubSub** for broadcasting updates

## Next Steps
* Add persistence for projections
* Implement actual domain scanning logic
* Add authentication and user management
* Add more sophisticated scoring algorithms
* Add export capabilities
* Add historical analysis views
* Deploy to production environment
