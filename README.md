# LiveEvent

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Demo Instructions 🚀

1. Visit [`localhost:4000/analyses`](http://localhost:4000/analyses) in your browser
2. Click "Start New Analysis" to begin a document processing job
3. Watch as the job progresses through various states:
   * 📊 Calculating Pages
   * 🔄 In Progress (with batch processing indicators)
   * 🔍 Analyzing Results
   * ✅ Completed

Each job simulates processing a document with multiple pages, showing real-time updates through LiveView!

## Goals
✅ Experiment with LiveView 1.0
✅ Experiment with Commanded event sourcing
✅ Combine event sourcing with pushing updates to liveviews from background jobs
⏳ Experiment with LangChain / Elixir for AI

## Next Steps
* Learn about testing ES systems
* Learn about retrying actions that are the result of a command
* Make something that actually works
* Do something with Fly.io?
* Learn about LangChain / Elixir for AI
