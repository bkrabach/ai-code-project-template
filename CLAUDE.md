# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important: Consult DISCOVERIES.md

Before implementing solutions to complex problems:

1. **Check DISCOVERIES.md** for similar issues that have already been solved
2. **Update DISCOVERIES.md** when you:
   - Encounter non-obvious problems that require research or debugging
   - Find conflicts between tools or libraries
   - Discover framework-specific patterns or limitations
   - Solve issues that future developers might face again
3. **Format entries** with: Date, Issue, Root Cause, Solution, and Prevention sections

## Build/Test/Lint Commands

- Install dependencies: `make install` (uses uv)
- Add new dependencies: `uv add package-name` (in the specific project directory)
- Add development dependencies: `uv add --dev package-name`
- Run all checks: `make check` (runs lint, format, type check)
- Run all tests: `make test` or `make pytest`
- Run a single test: `uv run pytest tests/path/to/test_file.py::TestClass::test_function -v`
- Upgrade dependency lock: `make lock-upgrade`

## Dependency Management

- **ALWAYS use `uv`** for Python dependency management in this project
- To add dependencies: `cd` to the specific project directory and run `uv add <package>`
- This ensures proper dependency resolution and updates both `pyproject.toml` and `uv.lock`
- Never manually edit `pyproject.toml` dependencies - always use `uv add`

## Code Style Guidelines

- Use Python type hints consistently including for self in class methods
- Import statements at top of files, organized by standard lib, third-party, local
- Use descriptive variable/function names (e.g., `get_workspace` not `gw`)
- Use `Optional` from typing for optional parameters
- Initialize variables outside code blocks before use
- All code must work with Python 3.11+
- Use Pydantic for data validation and settings

## Formatting Guidelines

- Line length: 120 characters (configured in ruff.toml)
- Use `# type: ignore` for Reflex dynamic methods
- For complex type ignores, use `# pyright: ignore[specificError]`
- When working with Reflex state setters in lambdas, keep them on one line to avoid pyright errors
- The project uses ruff for formatting and linting - settings in `ruff.toml`
- VSCode is configured to format on save with ruff
- **IMPORTANT**: All files must end with a newline character (add blank line at EOF)

## Dev Environment Tips

- Run `make` to create a virtual environment and install dependencies.
- Activate the virtual environment with `source .venv/bin/activate` (Linux/Mac) or `.venv\Scripts\activate` (Windows).

## Testing Instructions

- Run `make check` to run all checks including linting, formatting, and type checking.
- Run `make test` to run the tests.

## IMPORTANT: Service Testing After Code Changes

After making code changes, you MUST:

1. **Run `make check`** - This catches syntax, linting, and type errors
2. **Start the affected service** - This catches runtime errors and invalid API usage
3. **Test basic functionality** - Send a test request or verify the service starts cleanly
4. **Stop the service** - Use Ctrl+C or kill the process
   - IMPORTANT: Always stop services you start to free up ports

### Common Runtime Errors Not Caught by `make check`

- Invalid API calls to external libraries
- Import errors from circular dependencies
- Configuration or environment errors
- Port conflicts if services weren't stopped properly

## Documentation for External Libraries

Use the Context7 MCP server tools as a first tool for searching for up-to-date documentation on external libraries. It provides a simple interface to search through documentation and find relevant information quickly. If that fails to provide the information needed, fall back to a web search.

## Implementation Philosophy

This section outlines the core implementation philosophy and guidelines for software development projects. It serves as a central reference for decision-making and development approach throughout the project.

### Core Philosophy

Embodies a Zen-like minimalism that values simplicity and clarity above all. This approach reflects:

- **Wabi-sabi philosophy**: Embracing simplicity and the essential. Each line serves a clear purpose without unnecessary embellishment.
- **Occam's Razor thinking**: The solution should be as simple as possible, but no simpler.
- **Trust in emergence**: Complex systems work best when built from simple, well-defined components that do one thing well.
- **Present-moment focus**: The code handles what's needed now rather than anticipating every possible future scenario.
- **Pragmatic trust**: The developer trusts external systems enough to interact with them directly, handling failures as they occur rather than assuming they'll happen.

This development philosophy values clear documentation, readable code, and belief that good architecture emerges from simplicity rather than being imposed through complexity.

### Core Design Principles

#### 1. Ruthless Simplicity

- **KISS principle taken to heart**: Keep everything as simple as possible, but no simpler
- **Minimize abstractions**: Every layer of abstraction must justify its existence
- **Start minimal, grow as needed**: Begin with the simplest implementation that meets current needs
- **Avoid future-proofing**: Don't build for hypothetical future requirements
- **Question everything**: Regularly challenge complexity in the codebase

#### 2. Architectural Integrity with Minimal Implementation

- **Preserve key architectural patterns**: Example: MCP for service communication, SSE for events, separate I/O channels, etc.
- **Simplify implementations**: Maintain pattern benefits with dramatically simpler code
- **Scrappy but structured**: Lightweight implementations of solid architectural foundations
- **End-to-end thinking**: Focus on complete flows rather than perfect components

#### 3. Library Usage Philosophy

- **Use libraries as intended**: Minimal wrappers around external libraries
- **Direct integration**: Avoid unnecessary adapter layers
- **Selective dependency**: Add dependencies only when they provide substantial value
- **Understand what you import**: No black-box dependencies

### Technical Implementation Guidelines

#### API Layer

- Implement only essential endpoints
- Minimal middleware with focused validation
- Clear error responses with useful messages
- Consistent patterns across endpoints

#### Database & Storage

- Simple schema focused on current needs
- Use TEXT/JSON fields to avoid excessive normalization early
- Add indexes only when needed for performance
- Delay complex database features until required

#### MCP Implementation

- Streamlined MCP client with minimal error handling
- Utilize FastMCP when possible, falling back to lower-level only when necessary
- Focus on core functionality without elaborate state management
- Simplified connection lifecycle with basic error recovery
- Implement only essential health checks

#### SSE & Real-time Updates

- Basic SSE connection management
- Simple resource-based subscriptions
- Direct event delivery without complex routing
- Minimal state tracking for connections

### #Event System

- Simple topic-based publisher/subscriber
- Direct event delivery without complex pattern matching
- Clear, minimal event payloads
- Basic error handling for subscribers

#### LLM Integration

- Direct integration with PydanticAI
- Minimal transformation of responses
- Handle common error cases only
- Skip elaborate caching initially

#### Message Routing

- Simplified queue-based processing
- Direct, focused routing logic
- Basic routing decisions without excessive action types
- Simple integration with other components

### Development Approach

#### Vertical Slices

- Implement complete end-to-end functionality slices
- Start with core user journeys
- Get data flowing through all layers early
- Add features horizontally only after core flows work

#### Iterative Implementation

- 80/20 principle: Focus on high-value, low-effort features first
- One working feature > multiple partial features
- Validate with real usage before enhancing
- Be willing to refactor early work as patterns emerge

#### Testing Strategy

- Emphasis on integration and end-to-end tests
- Manual testability as a design goal
- Focus on critical path testing initially
- Add unit tests for complex logic and edge cases
- Testing pyramid: 60% unit, 30% integration, 10% end-to-end

#### Error Handling

- Handle common errors robustly
- Log detailed information for debugging
- Provide clear error messages to users
- Fail fast and visibly during development

### Decision-Making Framework

When faced with implementation decisions, ask these questions:

1. **Necessity**: "Do we actually need this right now?"
2. **Simplicity**: "What's the simplest way to solve this problem?"
3. **Directness**: "Can we solve this more directly?"
4. **Value**: "Does the complexity add proportional value?"
5. **Maintenance**: "How easy will this be to understand and change later?"

### Areas to Embrace Complexity

Some areas justify additional complexity:

1. **Security**: Never compromise on security fundamentals
2. **Data integrity**: Ensure data consistency and reliability
3. **Core user experience**: Make the primary user flows smooth and reliable
4. **Error visibility**: Make problems obvious and diagnosable

### Areas to Aggressively Simplify

Push for extreme simplicity in these areas:

1. **Internal abstractions**: Minimize layers between components
2. **Generic "future-proof" code**: Resist solving non-existent problems
3. **Edge case handling**: Handle the common cases well first
4. **Framework usage**: Use only what you need from frameworks
5. **State management**: Keep state simple and explicit

### Practical Examples

#### Good Example: Direct SSE Implementation

```python
# Simple, focused SSE manager that does exactly what's needed
class SseManager:
    def __init__(self):
        self.connections = {}  # Simple dictionary tracking

    async def add_connection(self, resource_id, user_id):
        """Add a new SSE connection"""
        connection_id = str(uuid.uuid4())
        queue = asyncio.Queue()
        self.connections[connection_id] = {
            "resource_id": resource_id,
            "user_id": user_id,
            "queue": queue
        }
        return queue, connection_id

    async def send_event(self, resource_id, event_type, data):
        """Send an event to all connections for a resource"""
        # Direct delivery to relevant connections only
        for conn_id, conn in self.connections.items():
            if conn["resource_id"] == resource_id:
                await conn["queue"].put({
                    "event": event_type,
                    "data": data
                })
```

#### Bad Example: Over-engineered SSE Implementation

```python
# Overly complex with unnecessary abstractions and state tracking
class ConnectionRegistry:
    def __init__(self, metrics_collector, cleanup_interval=60):
        self.connections_by_id = {}
        self.connections_by_resource = defaultdict(list)
        self.connections_by_user = defaultdict(list)
        self.metrics_collector = metrics_collector
        self.cleanup_task = asyncio.create_task(self._cleanup_loop(cleanup_interval))

    # [50+ more lines of complex indexing and state management]
```

### Remember

- It's easier to add complexity later than to remove it
- Code you don't write has no bugs
- Favor clarity over cleverness
- The best code is often the simplest

This philosophy section serves as the foundational guide for all implementation decisions in the project.

## Modular Design Philosophy

This section outlines the modular design philosophy that guides the development of our software. It emphasizes the importance of creating a modular architecture that promotes reusability, maintainability, and scalability all optimized for use with LLM-based AI tools for working with "right-sized" tasks that the models can _easily_ accomplish (vs pushing their limits), allow working within single requests that fit entirely with context windows, and allow for the use of LLMs to help with the design and implementation of the modules themselves.

To achieve this, we follow a set of principles and practices that ensure our codebase remains clean, organized, and easy to work with. This modular design philosophy is particularly important as we move towards a future where AI tools will play a significant role in software development. The goal is to create a system that is not only easy for humans to understand and maintain but also one that can be easily interpreted and manipulated by AI agents. Use the following guidelines to support this goal:

_(how the agent structures work so modules can later be auto-regenerated)_

1. **Think “bricks & studs.”**

   - A _brick_ = a self-contained directory (or file set) that delivers one clear responsibility.
   - A _stud_ = the public contract (function signatures, CLI, API schema, or data model) other bricks latch onto.

2. **Always start with the contract.**

   - Create or update a short `README` or top-level docstring inside the brick that states: _purpose, inputs, outputs, side-effects, dependencies_.
   - Keep it small enough to hold in one prompt; future code-gen tools will rely on this spec.

3. **Build the brick in isolation.**

   - Put code, tests, and fixtures inside the brick’s folder.
   - Expose only the contract via `__all__` or an interface file; no other brick may import internals.

4. **Verify with lightweight tests.**

   - Focus on behaviour at the contract level; integration tests live beside the brick.

5. **Regenerate, don’t patch.**

   - When a change is needed _inside_ a brick, rewrite the whole brick from its spec instead of line-editing scattered files.
   - If the contract itself must change, locate every brick that consumes that contract and regenerate them too.

6. **Parallel variants are allowed but optional.**

   - To experiment, create sibling folders like `auth_v2/`; run tests to choose a winner, then retire the loser.

7. **Human ↔️ AI handshake.**

   - **Human (architect/QA):** writes or tweaks the spec, reviews behaviour.
   - **Agent (builder):** generates the brick, runs tests, reports results. Humans rarely need to read the code unless tests fail.

_By following this loop—spec → isolated build → behaviour test → regenerate—you produce code that stays modular today and is ready for automated regeneration tomorrow._
