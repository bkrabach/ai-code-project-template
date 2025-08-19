# anthropics/claude-code-sdk-python/blob/main

[git-collector-data]

**URL:** https://github.com/anthropics/claude-code-sdk-python/blob/main/  
**Date:** 8/17/2025, 10:43:48 AM  
**Files:** 27  

=== File: README.md ===
# Claude Code SDK for Python

Python SDK for Claude Code. See the [Claude Code SDK documentation](https://docs.anthropic.com/en/docs/claude-code/sdk) for more information.

## Installation

```bash
pip install claude-code-sdk
```

**Prerequisites:**
- Python 3.10+
- Node.js 
- Claude Code: `npm install -g @anthropic-ai/claude-code`

## Quick Start

```python
import anyio
from claude_code_sdk import query

async def main():
    async for message in query(prompt="What is 2 + 2?"):
        print(message)

anyio.run(main)
```

## Usage

### Basic Query

```python
from claude_code_sdk import query, ClaudeCodeOptions, AssistantMessage, TextBlock

# Simple query
async for message in query(prompt="Hello Claude"):
    if isinstance(message, AssistantMessage):
        for block in message.content:
            if isinstance(block, TextBlock):
                print(block.text)

# With options
options = ClaudeCodeOptions(
    system_prompt="You are a helpful assistant",
    max_turns=1
)

async for message in query(prompt="Tell me a joke", options=options):
    print(message)
```

### Using Tools

```python
options = ClaudeCodeOptions(
    allowed_tools=["Read", "Write", "Bash"],
    permission_mode='acceptEdits'  # auto-accept file edits
)

async for message in query(
    prompt="Create a hello.py file", 
    options=options
):
    # Process tool use and results
    pass
```

### Working Directory

```python
from pathlib import Path

options = ClaudeCodeOptions(
    cwd="/path/to/project"  # or Path("/path/to/project")
)
```

## API Reference

### `query(prompt, options=None)`

Main async function for querying Claude.

**Parameters:**
- `prompt` (str): The prompt to send to Claude
- `options` (ClaudeCodeOptions): Optional configuration

**Returns:** AsyncIterator[Message] - Stream of response messages

### Types

See [src/claude_code_sdk/types.py](src/claude_code_sdk/types.py) for complete type definitions:
- `ClaudeCodeOptions` - Configuration options
- `AssistantMessage`, `UserMessage`, `SystemMessage`, `ResultMessage` - Message types
- `TextBlock`, `ToolUseBlock`, `ToolResultBlock` - Content blocks

## Error Handling

```python
from claude_code_sdk import (
    ClaudeSDKError,      # Base error
    CLINotFoundError,    # Claude Code not installed
    CLIConnectionError,  # Connection issues
    ProcessError,        # Process failed
    CLIJSONDecodeError,  # JSON parsing issues
)

try:
    async for message in query(prompt="Hello"):
        pass
except CLINotFoundError:
    print("Please install Claude Code")
except ProcessError as e:
    print(f"Process failed with exit code: {e.exit_code}")
except CLIJSONDecodeError as e:
    print(f"Failed to parse response: {e}")
```

See [src/claude_code_sdk/_errors.py](src/claude_code_sdk/_errors.py) for all error types.

## Available Tools

See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code/settings#tools-available-to-claude) for a complete list of available tools.

## Examples

See [examples/quick_start.py](examples/quick_start.py) for a complete working example.

## License

MIT


=== File: examples/quick_start.py ===
#!/usr/bin/env python3
"""Quick start example for Claude Code SDK."""

import anyio

from claude_code_sdk import (
    AssistantMessage,
    ClaudeCodeOptions,
    ResultMessage,
    TextBlock,
    query,
)


async def basic_example():
    """Basic example - simple question."""
    print("=== Basic Example ===")

    async for message in query(prompt="What is 2 + 2?"):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")
    print()


async def with_options_example():
    """Example with custom options."""
    print("=== With Options Example ===")

    options = ClaudeCodeOptions(
        system_prompt="You are a helpful assistant that explains things simply.",
        max_turns=1,
    )

    async for message in query(
        prompt="Explain what Python is in one sentence.", options=options
    ):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")
    print()


async def with_tools_example():
    """Example using tools."""
    print("=== With Tools Example ===")

    options = ClaudeCodeOptions(
        allowed_tools=["Read", "Write"],
        system_prompt="You are a helpful file assistant.",
    )

    async for message in query(
        prompt="Create a file called hello.txt with 'Hello, World!' in it",
        options=options,
    ):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")
        elif isinstance(message, ResultMessage) and message.total_cost_usd > 0:
            print(f"\nCost: ${message.total_cost_usd:.4f}")
    print()


async def main():
    """Run all examples."""
    await basic_example()
    await with_options_example()
    await with_tools_example()


if __name__ == "__main__":
    anyio.run(main)


=== File: examples/streaming_mode.py ===
#!/usr/bin/env python3
"""
Comprehensive examples of using ClaudeSDKClient for streaming mode.

This file demonstrates various patterns for building applications with
the ClaudeSDKClient streaming interface.

The queries are intentionally simplistic. In reality, a query can be a more
complex task that Claude SDK uses its agentic capabilities and tools (e.g. run
bash commands, edit files, search the web, fetch web content) to accomplish.

Usage:
./examples/streaming_mode.py - List the examples
./examples/streaming_mode.py all - Run all examples
./examples/streaming_mode.py basic_streaming - Run a specific example
"""

import asyncio
import contextlib
import sys

from claude_code_sdk import (
    AssistantMessage,
    ClaudeCodeOptions,
    ClaudeSDKClient,
    CLIConnectionError,
    ResultMessage,
    SystemMessage,
    TextBlock,
    ToolResultBlock,
    ToolUseBlock,
    UserMessage,
)


def display_message(msg):
    """Standardized message display function.

    - UserMessage: "User: <content>"
    - AssistantMessage: "Claude: <content>"
    - SystemMessage: ignored
    - ResultMessage: "Result ended" + cost if available
    """
    if isinstance(msg, UserMessage):
        for block in msg.content:
            if isinstance(block, TextBlock):
                print(f"User: {block.text}")
    elif isinstance(msg, AssistantMessage):
        for block in msg.content:
            if isinstance(block, TextBlock):
                print(f"Claude: {block.text}")
    elif isinstance(msg, SystemMessage):
        # Ignore system messages
        pass
    elif isinstance(msg, ResultMessage):
        print("Result ended")


async def example_basic_streaming():
    """Basic streaming with context manager."""
    print("=== Basic Streaming Example ===")

    async with ClaudeSDKClient() as client:
        print("User: What is 2+2?")
        await client.query("What is 2+2?")

        # Receive complete response using the helper method
        async for msg in client.receive_response():
            display_message(msg)

    print("\n")


async def example_multi_turn_conversation():
    """Multi-turn conversation using receive_response helper."""
    print("=== Multi-Turn Conversation Example ===")

    async with ClaudeSDKClient() as client:
        # First turn
        print("User: What's the capital of France?")
        await client.query("What's the capital of France?")

        # Extract and print response
        async for msg in client.receive_response():
            display_message(msg)

        # Second turn - follow-up
        print("\nUser: What's the population of that city?")
        await client.query("What's the population of that city?")

        async for msg in client.receive_response():
            display_message(msg)

    print("\n")


async def example_concurrent_responses():
    """Handle responses while sending new messages."""
    print("=== Concurrent Send/Receive Example ===")

    async with ClaudeSDKClient() as client:
        # Background task to continuously receive messages
        async def receive_messages():
            async for message in client.receive_messages():
                display_message(message)

        # Start receiving in background
        receive_task = asyncio.create_task(receive_messages())

        # Send multiple messages with delays
        questions = [
            "What is 2 + 2?",
            "What is the square root of 144?",
            "What is 10% of 80?",
        ]

        for question in questions:
            print(f"\nUser: {question}")
            await client.query(question)
            await asyncio.sleep(3)  # Wait between messages

        # Give time for final responses
        await asyncio.sleep(2)

        # Clean up
        receive_task.cancel()
        with contextlib.suppress(asyncio.CancelledError):
            await receive_task

    print("\n")


async def example_with_interrupt():
    """Demonstrate interrupt capability."""
    print("=== Interrupt Example ===")
    print("IMPORTANT: Interrupts require active message consumption.")

    async with ClaudeSDKClient() as client:
        # Start a long-running task
        print("\nUser: Count from 1 to 100 slowly")
        await client.query(
            "Count from 1 to 100 slowly, with a brief pause between each number"
        )

        # Create a background task to consume messages
        messages_received = []
        interrupt_sent = False

        async def consume_messages():
            """Consume messages in the background to enable interrupt processing."""
            async for message in client.receive_messages():
                messages_received.append(message)
                if isinstance(message, AssistantMessage):
                    for block in message.content:
                        if isinstance(block, TextBlock):
                            # Print first few numbers
                            print(f"Claude: {block.text[:50]}...")
                elif isinstance(message, ResultMessage):
                    display_message(message)
                    if interrupt_sent:
                        break

        # Start consuming messages in the background
        consume_task = asyncio.create_task(consume_messages())

        # Wait 2 seconds then send interrupt
        await asyncio.sleep(2)
        print("\n[After 2 seconds, sending interrupt...]")
        interrupt_sent = True
        await client.interrupt()

        # Wait for the consume task to finish processing the interrupt
        await consume_task

        # Send new instruction after interrupt
        print("\nUser: Never mind, just tell me a quick joke")
        await client.query("Never mind, just tell me a quick joke")

        # Get the joke
        async for msg in client.receive_response():
            display_message(msg)

    print("\n")


async def example_manual_message_handling():
    """Manually handle message stream for custom logic."""
    print("=== Manual Message Handling Example ===")

    async with ClaudeSDKClient() as client:
        await client.query(
            "List 5 programming languages and their main use cases"
        )

        # Manually process messages with custom logic
        languages_found = []

        async for message in client.receive_messages():
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        text = block.text
                        print(f"Claude: {text}")
                        # Custom logic: extract language names
                        for lang in [
                            "Python",
                            "JavaScript",
                            "Java",
                            "C++",
                            "Go",
                            "Rust",
                            "Ruby",
                        ]:
                            if lang in text and lang not in languages_found:
                                languages_found.append(lang)
                                print(f"Found language: {lang}")
            elif isinstance(message, ResultMessage):
                display_message(message)
                print(f"Total languages mentioned: {len(languages_found)}")
                break

    print("\n")


async def example_with_options():
    """Use ClaudeCodeOptions to configure the client."""
    print("=== Custom Options Example ===")

    # Configure options
    options = ClaudeCodeOptions(
        allowed_tools=["Read", "Write"],  # Allow file operations
        max_thinking_tokens=10000,
        system_prompt="You are a helpful coding assistant.",
    )

    async with ClaudeSDKClient(options=options) as client:
        print("User: Create a simple hello.txt file with a greeting message")
        await client.query(
            "Create a simple hello.txt file with a greeting message"
        )

        tool_uses = []
        async for msg in client.receive_response():
            if isinstance(msg, AssistantMessage):
                display_message(msg)
                for block in msg.content:
                    if hasattr(block, "name") and not isinstance(
                        block, TextBlock
                    ):  # ToolUseBlock
                        tool_uses.append(getattr(block, "name", ""))
            else:
                display_message(msg)

        if tool_uses:
            print(f"Tools used: {', '.join(tool_uses)}")

    print("\n")


async def example_async_iterable_prompt():
    """Demonstrate send_message with async iterable."""
    print("=== Async Iterable Prompt Example ===")

    async def create_message_stream():
        """Generate a stream of messages."""
        print("User: Hello! I have multiple questions.")
        yield {
            "type": "user",
            "message": {"role": "user", "content": "Hello! I have multiple questions."},
            "parent_tool_use_id": None,
            "session_id": "qa-session",
        }

        print("User: First, what's the capital of Japan?")
        yield {
            "type": "user",
            "message": {
                "role": "user",
                "content": "First, what's the capital of Japan?",
            },
            "parent_tool_use_id": None,
            "session_id": "qa-session",
        }

        print("User: Second, what's 15% of 200?")
        yield {
            "type": "user",
            "message": {"role": "user", "content": "Second, what's 15% of 200?"},
            "parent_tool_use_id": None,
            "session_id": "qa-session",
        }

    async with ClaudeSDKClient() as client:
        # Send async iterable of messages
        await client.query(create_message_stream())

        # Receive the three responses
        async for msg in client.receive_response():
            display_message(msg)
        async for msg in client.receive_response():
            display_message(msg)
        async for msg in client.receive_response():
            display_message(msg)

    print("\n")


async def example_bash_command():
    """Example showing tool use blocks when running bash commands."""
    print("=== Bash Command Example ===")
    
    async with ClaudeSDKClient() as client:
        print("User: Run a bash echo command")
        await client.query("Run a bash echo command that says 'Hello from bash!'")
        
        # Track all message types received
        message_types = []
        
        async for msg in client.receive_messages():
            message_types.append(type(msg).__name__)
            
            if isinstance(msg, UserMessage):
                # User messages can contain tool results
                for block in msg.content:
                    if isinstance(block, TextBlock):
                        print(f"User: {block.text}")
                    elif isinstance(block, ToolResultBlock):
                        print(f"Tool Result (id: {block.tool_use_id}): {block.content[:100] if block.content else 'None'}...")
                        
            elif isinstance(msg, AssistantMessage):
                # Assistant messages can contain tool use blocks
                for block in msg.content:
                    if isinstance(block, TextBlock):
                        print(f"Claude: {block.text}")
                    elif isinstance(block, ToolUseBlock):
                        print(f"Tool Use: {block.name} (id: {block.id})")
                        if block.name == "Bash":
                            command = block.input.get("command", "")
                            print(f"  Command: {command}")
                            
            elif isinstance(msg, ResultMessage):
                print("Result ended")
                if msg.total_cost_usd:
                    print(f"Cost: ${msg.total_cost_usd:.4f}")
                break
        
        print(f"\nMessage types received: {', '.join(set(message_types))}")
    
    print("\n")


async def example_error_handling():
    """Demonstrate proper error handling."""
    print("=== Error Handling Example ===")

    client = ClaudeSDKClient()

    try:
        await client.connect()

        # Send a message that will take time to process
        print("User: Run a bash sleep command for 60 seconds")
        await client.query("Run a bash sleep command for 60 seconds")

        # Try to receive response with a short timeout
        try:
            messages = []
            async with asyncio.timeout(10.0):
                async for msg in client.receive_response():
                    messages.append(msg)
                    if isinstance(msg, AssistantMessage):
                        for block in msg.content:
                            if isinstance(block, TextBlock):
                                print(f"Claude: {block.text[:50]}...")
                    elif isinstance(msg, ResultMessage):
                        display_message(msg)
                        break

        except asyncio.TimeoutError:
            print(
                "\nResponse timeout after 10 seconds - demonstrating graceful handling"
            )
            print(f"Received {len(messages)} messages before timeout")

    except CLIConnectionError as e:
        print(f"Connection error: {e}")

    except Exception as e:
        print(f"Unexpected error: {e}")

    finally:
        # Always disconnect
        await client.disconnect()

    print("\n")


async def main():
    """Run all examples or a specific example based on command line argument."""
    examples = {
        "basic_streaming": example_basic_streaming,
        "multi_turn_conversation": example_multi_turn_conversation,
        "concurrent_responses": example_concurrent_responses,
        "with_interrupt": example_with_interrupt,
        "manual_message_handling": example_manual_message_handling,
        "with_options": example_with_options,
        "async_iterable_prompt": example_async_iterable_prompt,
        "bash_command": example_bash_command,
        "error_handling": example_error_handling,
    }

    if len(sys.argv) < 2:
        # List available examples
        print("Usage: python streaming_mode.py <example_name>")
        print("\nAvailable examples:")
        print("  all - Run all examples")
        for name in examples:
            print(f"  {name}")
        sys.exit(0)

    example_name = sys.argv[1]

    if example_name == "all":
        # Run all examples
        for example in examples.values():
            await example()
            print("-" * 50 + "\n")
    elif example_name in examples:
        # Run specific example
        await examples[example_name]()
    else:
        print(f"Error: Unknown example '{example_name}'")
        print("\nAvailable examples:")
        print("  all - Run all examples")
        for name in examples:
            print(f"  {name}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())


=== File: examples/streaming_mode_ipython.py ===
#!/usr/bin/env python3
"""
IPython-friendly code snippets for ClaudeSDKClient streaming mode.

These examples are designed to be copy-pasted directly into IPython.
Each example is self-contained and can be run independently.

The queries are intentionally simplistic. In reality, a query can be a more
complex task that Claude SDK uses its agentic capabilities and tools (e.g. run
bash commands, edit files, search the web, fetch web content) to accomplish.
"""

# ============================================================================
# BASIC STREAMING
# ============================================================================

from claude_code_sdk import ClaudeSDKClient, AssistantMessage, TextBlock, ResultMessage

async with ClaudeSDKClient() as client:
    print("User: What is 2+2?")
    await client.query("What is 2+2?")

    async for msg in client.receive_response():
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")


# ============================================================================
# STREAMING WITH REAL-TIME DISPLAY
# ============================================================================

import asyncio
from claude_code_sdk import ClaudeSDKClient, AssistantMessage, TextBlock

async with ClaudeSDKClient() as client:
    async def send_and_receive(prompt):
        print(f"User: {prompt}")
        await client.query(prompt)
        async for msg in client.receive_response():
            if isinstance(msg, AssistantMessage):
                for block in msg.content:
                    if isinstance(block, TextBlock):
                        print(f"Claude: {block.text}")

    await send_and_receive("Tell me a short joke")
    print("\n---\n")
    await send_and_receive("Now tell me a fun fact")


# ============================================================================
# PERSISTENT CLIENT FOR MULTIPLE QUESTIONS
# ============================================================================

from claude_code_sdk import ClaudeSDKClient, AssistantMessage, TextBlock

# Create client
client = ClaudeSDKClient()
await client.connect()


# Helper to get response
async def get_response():
    async for msg in client.receive_response():
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")


# Use it multiple times
print("User: What's 2+2?")
await client.query("What's 2+2?")
await get_response()

print("User: What's 10*10?")
await client.query("What's 10*10?")
await get_response()

# Don't forget to disconnect when done
await client.disconnect()


# ============================================================================
# WITH INTERRUPT CAPABILITY
# ============================================================================
# IMPORTANT: Interrupts require active message consumption. You must be
# consuming messages from the client for the interrupt to be processed.

import asyncio
from claude_code_sdk import ClaudeSDKClient, AssistantMessage, TextBlock, ResultMessage

async with ClaudeSDKClient() as client:
    print("\n--- Sending initial message ---\n")

    # Send a long-running task
    print("User: Count from 1 to 100, run bash sleep for 1 second in between")
    await client.query("Count from 1 to 100, run bash sleep for 1 second in between")

    # Create a background task to consume messages
    messages_received = []
    interrupt_sent = False

    async def consume_messages():
        async for msg in client.receive_messages():
            messages_received.append(msg)
            if isinstance(msg, AssistantMessage):
                for block in msg.content:
                    if isinstance(block, TextBlock):
                        print(f"Claude: {block.text}")

            # Check if we got a result after interrupt
            if isinstance(msg, ResultMessage) and interrupt_sent:
                break

    # Start consuming messages in the background
    consume_task = asyncio.create_task(consume_messages())

    # Wait a bit then send interrupt
    await asyncio.sleep(10)
    print("\n--- Sending interrupt ---\n")
    interrupt_sent = True
    await client.interrupt()

    # Wait for the consume task to finish
    await consume_task

    # Send a new message after interrupt
    print("\n--- After interrupt, sending new message ---\n")
    await client.query("Just say 'Hello! I was interrupted.'")

    async for msg in client.receive_response():
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")


# ============================================================================
# ERROR HANDLING PATTERN
# ============================================================================

from claude_code_sdk import ClaudeSDKClient, AssistantMessage, TextBlock

try:
    async with ClaudeSDKClient() as client:
        print("User: Run a bash sleep command for 60 seconds")
        await client.query("Run a bash sleep command for 60 seconds")

        # Timeout after 20 seconds
        messages = []
        async with asyncio.timeout(20.0):
            async for msg in client.receive_response():
                messages.append(msg)
                if isinstance(msg, AssistantMessage):
                    for block in msg.content:
                        if isinstance(block, TextBlock):
                            print(f"Claude: {block.text}")

except asyncio.TimeoutError:
    print("Request timed out after 20 seconds")
except Exception as e:
    print(f"Error: {e}")


# ============================================================================
# SENDING ASYNC ITERABLE OF MESSAGES
# ============================================================================

from claude_code_sdk import ClaudeSDKClient, AssistantMessage, TextBlock

async def message_generator():
    """Generate multiple messages as an async iterable."""
    print("User: I have two math questions.")
    yield {
        "type": "user",
        "message": {"role": "user", "content": "I have two math questions."},
        "parent_tool_use_id": None,
        "session_id": "math-session"
    }
    print("User: What is 25 * 4?")
    yield {
        "type": "user",
        "message": {"role": "user", "content": "What is 25 * 4?"},
        "parent_tool_use_id": None,
        "session_id": "math-session"
    }
    print("User: What is 100 / 5?")
    yield {
        "type": "user",
        "message": {"role": "user", "content": "What is 100 / 5?"},
        "parent_tool_use_id": None,
        "session_id": "math-session"
    }

async with ClaudeSDKClient() as client:
    # Send async iterable instead of string
    await client.query(message_generator())

    async for msg in client.receive_response():
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")


# ============================================================================
# COLLECTING ALL MESSAGES INTO A LIST
# ============================================================================

from claude_code_sdk import ClaudeSDKClient, AssistantMessage, TextBlock, ResultMessage

async with ClaudeSDKClient() as client:
    print("User: What are the primary colors?")
    await client.query("What are the primary colors?")

    # Collect all messages into a list
    messages = [msg async for msg in client.receive_response()]

    # Process them afterwards
    for msg in messages:
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    print(f"Claude: {block.text}")
        elif isinstance(msg, ResultMessage):
            print(f"Total messages: {len(messages)}")


=== File: examples/streaming_mode_trio.py ===
#!/usr/bin/env python3
"""
Example of multi-turn conversation using trio with the Claude SDK.

This demonstrates how to use the ClaudeSDKClient with trio for interactive,
stateful conversations where you can send follow-up messages based on
Claude's responses.
"""

import trio

from claude_code_sdk import (
    AssistantMessage,
    ClaudeCodeOptions,
    ClaudeSDKClient,
    ResultMessage,
    SystemMessage,
    TextBlock,
    UserMessage,
)


def display_message(msg):
    """Standardized message display function.

    - UserMessage: "User: <content>"
    - AssistantMessage: "Claude: <content>"
    - SystemMessage: ignored
    - ResultMessage: "Result ended" + cost if available
    """
    if isinstance(msg, UserMessage):
        for block in msg.content:
            if isinstance(block, TextBlock):
                print(f"User: {block.text}")
    elif isinstance(msg, AssistantMessage):
        for block in msg.content:
            if isinstance(block, TextBlock):
                print(f"Claude: {block.text}")
    elif isinstance(msg, SystemMessage):
        # Ignore system messages
        pass
    elif isinstance(msg, ResultMessage):
        print("Result ended")


async def multi_turn_conversation():
    """Example of a multi-turn conversation using trio."""
    async with ClaudeSDKClient(
        options=ClaudeCodeOptions(model="claude-3-5-sonnet-20241022")
    ) as client:
        print("=== Multi-turn Conversation with Trio ===\n")

        # First turn: Simple math question
        print("User: What's 15 + 27?")
        await client.query("What's 15 + 27?")

        async for message in client.receive_response():
            display_message(message)
        print()

        # Second turn: Follow-up calculation
        print("User: Now multiply that result by 2")
        await client.query("Now multiply that result by 2")

        async for message in client.receive_response():
            display_message(message)
        print()

        # Third turn: One more operation
        print("User: Divide that by 7 and round to 2 decimal places")
        await client.query("Divide that by 7 and round to 2 decimal places")

        async for message in client.receive_response():
            display_message(message)

        print("\nConversation complete!")


if __name__ == "__main__":
    trio.run(multi_turn_conversation)


=== File: pyproject.toml ===
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "claude-code-sdk"
version = "0.0.20"
description = "Python SDK for Claude Code"
readme = "README.md"
requires-python = ">=3.10"
license = {text = "MIT"}
authors = [
    {name = "Anthropic", email = "support@anthropic.com"},
]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
    "Programming Language :: Python :: 3.13",
    "Typing :: Typed",
]
keywords = ["claude", "ai", "sdk", "anthropic"]
dependencies = [
    "anyio>=4.0.0",
    "typing_extensions>=4.0.0; python_version<'3.11'",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-asyncio>=0.20.0",
    "anyio[trio]>=4.0.0",
    "pytest-cov>=4.0.0",
    "mypy>=1.0.0",
    "ruff>=0.1.0",
]

[project.urls]
Homepage = "https://github.com/anthropics/claude-code-sdk-python"
Documentation = "https://docs.anthropic.com/en/docs/claude-code/sdk"
Issues = "https://github.com/anthropics/claude-code-sdk-python/issues"

[tool.hatch.build.targets.wheel]
packages = ["src/claude_code_sdk"]

[tool.hatch.build.targets.sdist]
include = [
    "/src",
    "/tests",
    "/README.md",
    "/LICENSE",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
addopts = [
    "--import-mode=importlib",
]

[tool.pytest-asyncio]
asyncio_mode = "auto"

[tool.mypy]
python_version = "3.10"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
strict_equality = true

[tool.ruff]
target-version = "py310"
line-length = 88

[tool.ruff.lint]
select = [
    "E",  # pycodestyle errors
    "W",  # pycodestyle warnings
    "F",  # pyflakes
    "I",  # isort
    "N",  # pep8-naming
    "UP", # pyupgrade
    "B",  # flake8-bugbear
    "C4", # flake8-comprehensions
    "PTH", # flake8-use-pathlib
    "SIM", # flake8-simplify
]
ignore = [
    "E501", # line too long (handled by formatter)
]

[tool.ruff.lint.isort]
known-first-party = ["claude_code_sdk"]

=== File: src/claude_code_sdk/__init__.py ===
"""Claude SDK for Python."""

from ._errors import (
    ClaudeSDKError,
    CLIConnectionError,
    CLIJSONDecodeError,
    CLINotFoundError,
    ProcessError,
)
from .client import ClaudeSDKClient
from .query import query
from .types import (
    AssistantMessage,
    ClaudeCodeOptions,
    ContentBlock,
    McpServerConfig,
    Message,
    PermissionMode,
    ResultMessage,
    SystemMessage,
    TextBlock,
    ThinkingBlock,
    ToolResultBlock,
    ToolUseBlock,
    UserMessage,
)

__version__ = "0.0.20"

__all__ = [
    # Main exports
    "query",
    "ClaudeSDKClient",
    # Types
    "PermissionMode",
    "McpServerConfig",
    "UserMessage",
    "AssistantMessage",
    "SystemMessage",
    "ResultMessage",
    "Message",
    "ClaudeCodeOptions",
    "TextBlock",
    "ThinkingBlock",
    "ToolUseBlock",
    "ToolResultBlock",
    "ContentBlock",
    # Errors
    "ClaudeSDKError",
    "CLIConnectionError",
    "CLINotFoundError",
    "ProcessError",
    "CLIJSONDecodeError",
]


=== File: src/claude_code_sdk/_errors.py ===
"""Error types for Claude SDK."""

from typing import Any


class ClaudeSDKError(Exception):
    """Base exception for all Claude SDK errors."""


class CLIConnectionError(ClaudeSDKError):
    """Raised when unable to connect to Claude Code."""


class CLINotFoundError(CLIConnectionError):
    """Raised when Claude Code is not found or not installed."""

    def __init__(
        self, message: str = "Claude Code not found", cli_path: str | None = None
    ):
        if cli_path:
            message = f"{message}: {cli_path}"
        super().__init__(message)


class ProcessError(ClaudeSDKError):
    """Raised when the CLI process fails."""

    def __init__(
        self, message: str, exit_code: int | None = None, stderr: str | None = None
    ):
        self.exit_code = exit_code
        self.stderr = stderr

        if exit_code is not None:
            message = f"{message} (exit code: {exit_code})"
        if stderr:
            message = f"{message}\nError output: {stderr}"

        super().__init__(message)


class CLIJSONDecodeError(ClaudeSDKError):
    """Raised when unable to decode JSON from CLI output."""

    def __init__(self, line: str, original_error: Exception):
        self.line = line
        self.original_error = original_error
        super().__init__(f"Failed to decode JSON: {line[:100]}...")


class MessageParseError(ClaudeSDKError):
    """Raised when unable to parse a message from CLI output."""

    def __init__(self, message: str, data: dict[str, Any] | None = None):
        self.data = data
        super().__init__(message)


=== File: src/claude_code_sdk/_internal/__init__.py ===
"""Internal implementation details."""


=== File: src/claude_code_sdk/_internal/client.py ===
"""Internal client implementation."""

from collections.abc import AsyncIterable, AsyncIterator
from typing import Any

from ..types import ClaudeCodeOptions, Message
from .message_parser import parse_message
from .transport.subprocess_cli import SubprocessCLITransport


class InternalClient:
    """Internal client implementation."""

    def __init__(self) -> None:
        """Initialize the internal client."""

    async def process_query(
        self, prompt: str | AsyncIterable[dict[str, Any]], options: ClaudeCodeOptions
    ) -> AsyncIterator[Message]:
        """Process a query through transport."""

        transport = SubprocessCLITransport(
            prompt=prompt, options=options, close_stdin_after_prompt=True
        )

        try:
            await transport.connect()

            async for data in transport.receive_messages():
                yield parse_message(data)

        finally:
            await transport.disconnect()


=== File: src/claude_code_sdk/_internal/message_parser.py ===
"""Message parser for Claude Code SDK responses."""

import logging
from typing import Any

from .._errors import MessageParseError
from ..types import (
    AssistantMessage,
    ContentBlock,
    Message,
    ResultMessage,
    SystemMessage,
    TextBlock,
    ThinkingBlock,
    ToolResultBlock,
    ToolUseBlock,
    UserMessage,
)

logger = logging.getLogger(__name__)


def parse_message(data: dict[str, Any]) -> Message:
    """
    Parse message from CLI output into typed Message objects.

    Args:
        data: Raw message dictionary from CLI output

    Returns:
        Parsed Message object

    Raises:
        MessageParseError: If parsing fails or message type is unrecognized
    """
    if not isinstance(data, dict):
        raise MessageParseError(
            f"Invalid message data type (expected dict, got {type(data).__name__})",
            data,
        )

    message_type = data.get("type")
    if not message_type:
        raise MessageParseError("Message missing 'type' field", data)

    match message_type:
        case "user":
            try:
                if isinstance(data["message"]["content"], list):
                    user_content_blocks: list[ContentBlock] = []
                    for block in data["message"]["content"]:
                        match block["type"]:
                            case "text":
                                user_content_blocks.append(
                                    TextBlock(text=block["text"])
                                )
                            case "thinking":
                                user_content_blocks.append(
                                    ThinkingBlock(
                                        thinking=block["thinking"],
                                        signature=block["signature"],
                                    )
                                )
                            case "tool_use":
                                user_content_blocks.append(
                                    ToolUseBlock(
                                        id=block["id"],
                                        name=block["name"],
                                        input=block["input"],
                                    )
                                )
                            case "tool_result":
                                user_content_blocks.append(
                                    ToolResultBlock(
                                        tool_use_id=block["tool_use_id"],
                                        content=block.get("content"),
                                        is_error=block.get("is_error"),
                                    )
                                )
                    return UserMessage(content=user_content_blocks)
                return UserMessage(content=data["message"]["content"])
            except KeyError as e:
                raise MessageParseError(
                    f"Missing required field in user message: {e}", data
                ) from e

        case "assistant":
            try:
                content_blocks: list[ContentBlock] = []
                for block in data["message"]["content"]:
                    match block["type"]:
                        case "text":
                            content_blocks.append(TextBlock(text=block["text"]))
                        case "tool_use":
                            content_blocks.append(
                                ToolUseBlock(
                                    id=block["id"],
                                    name=block["name"],
                                    input=block["input"],
                                )
                            )
                        case "tool_result":
                            content_blocks.append(
                                ToolResultBlock(
                                    tool_use_id=block["tool_use_id"],
                                    content=block.get("content"),
                                    is_error=block.get("is_error"),
                                )
                            )

                return AssistantMessage(
                    content=content_blocks, model=data["message"]["model"]
                )
            except KeyError as e:
                raise MessageParseError(
                    f"Missing required field in assistant message: {e}", data
                ) from e

        case "system":
            try:
                return SystemMessage(
                    subtype=data["subtype"],
                    data=data,
                )
            except KeyError as e:
                raise MessageParseError(
                    f"Missing required field in system message: {e}", data
                ) from e

        case "result":
            try:
                return ResultMessage(
                    subtype=data["subtype"],
                    duration_ms=data["duration_ms"],
                    duration_api_ms=data["duration_api_ms"],
                    is_error=data["is_error"],
                    num_turns=data["num_turns"],
                    session_id=data["session_id"],
                    total_cost_usd=data.get("total_cost_usd"),
                    usage=data.get("usage"),
                    result=data.get("result"),
                )
            except KeyError as e:
                raise MessageParseError(
                    f"Missing required field in result message: {e}", data
                ) from e

        case _:
            raise MessageParseError(f"Unknown message type: {message_type}", data)


=== File: src/claude_code_sdk/_internal/transport/__init__.py ===
"""Transport implementations for Claude SDK."""

from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from typing import Any


class Transport(ABC):
    """Abstract transport for Claude communication."""

    @abstractmethod
    async def connect(self) -> None:
        """Initialize connection."""
        pass

    @abstractmethod
    async def disconnect(self) -> None:
        """Close connection."""
        pass

    @abstractmethod
    async def send_request(
        self, messages: list[dict[str, Any]], options: dict[str, Any]
    ) -> None:
        """Send request to Claude."""
        pass

    @abstractmethod
    def receive_messages(self) -> AsyncIterator[dict[str, Any]]:
        """Receive messages from Claude."""
        pass

    @abstractmethod
    def is_connected(self) -> bool:
        """Check if transport is connected."""
        pass


__all__ = ["Transport"]


=== File: src/claude_code_sdk/_internal/transport/subprocess_cli.py ===
"""Subprocess transport implementation using Claude Code CLI."""

import json
import logging
import os
import shutil
import tempfile
from collections import deque
from collections.abc import AsyncIterable, AsyncIterator
from pathlib import Path
from subprocess import PIPE
from typing import Any

import anyio
from anyio.abc import Process
from anyio.streams.text import TextReceiveStream, TextSendStream

from ..._errors import CLIConnectionError, CLINotFoundError, ProcessError
from ..._errors import CLIJSONDecodeError as SDKJSONDecodeError
from ...types import ClaudeCodeOptions
from . import Transport

logger = logging.getLogger(__name__)

_MAX_BUFFER_SIZE = 1024 * 1024  # 1MB buffer limit


class SubprocessCLITransport(Transport):
    """Subprocess transport using Claude Code CLI."""

    def __init__(
        self,
        prompt: str | AsyncIterable[dict[str, Any]],
        options: ClaudeCodeOptions,
        cli_path: str | Path | None = None,
        close_stdin_after_prompt: bool = False,
    ):
        self._prompt = prompt
        self._is_streaming = not isinstance(prompt, str)
        self._options = options
        self._cli_path = str(cli_path) if cli_path else self._find_cli()
        self._cwd = str(options.cwd) if options.cwd else None
        self._process: Process | None = None
        self._stdout_stream: TextReceiveStream | None = None
        self._stderr_stream: TextReceiveStream | None = None
        self._stdin_stream: TextSendStream | None = None
        self._pending_control_responses: dict[str, dict[str, Any]] = {}
        self._request_counter = 0
        self._close_stdin_after_prompt = close_stdin_after_prompt
        self._task_group: anyio.abc.TaskGroup | None = None
        self._stderr_file: Any = None  # tempfile.NamedTemporaryFile

    def _find_cli(self) -> str:
        """Find Claude Code CLI binary."""
        if cli := shutil.which("claude"):
            return cli

        locations = [
            Path.home() / ".npm-global/bin/claude",
            Path("/usr/local/bin/claude"),
            Path.home() / ".local/bin/claude",
            Path.home() / "node_modules/.bin/claude",
            Path.home() / ".yarn/bin/claude",
        ]

        for path in locations:
            if path.exists() and path.is_file():
                return str(path)

        node_installed = shutil.which("node") is not None

        if not node_installed:
            error_msg = "Claude Code requires Node.js, which is not installed.\n\n"
            error_msg += "Install Node.js from: https://nodejs.org/\n"
            error_msg += "\nAfter installing Node.js, install Claude Code:\n"
            error_msg += "  npm install -g @anthropic-ai/claude-code"
            raise CLINotFoundError(error_msg)

        raise CLINotFoundError(
            "Claude Code not found. Install with:\n"
            "  npm install -g @anthropic-ai/claude-code\n"
            "\nIf already installed locally, try:\n"
            '  export PATH="$HOME/node_modules/.bin:$PATH"\n'
            "\nOr specify the path when creating transport:\n"
            "  SubprocessCLITransport(..., cli_path='/path/to/claude')"
        )

    def _build_command(self) -> list[str]:
        """Build CLI command with arguments."""
        cmd = [self._cli_path, "--output-format", "stream-json", "--verbose"]

        if self._options.system_prompt:
            cmd.extend(["--system-prompt", self._options.system_prompt])

        if self._options.append_system_prompt:
            cmd.extend(["--append-system-prompt", self._options.append_system_prompt])

        if self._options.allowed_tools:
            cmd.extend(["--allowedTools", ",".join(self._options.allowed_tools)])

        if self._options.max_turns:
            cmd.extend(["--max-turns", str(self._options.max_turns)])

        if self._options.disallowed_tools:
            cmd.extend(["--disallowedTools", ",".join(self._options.disallowed_tools)])

        if self._options.model:
            cmd.extend(["--model", self._options.model])

        if self._options.permission_prompt_tool_name:
            cmd.extend(
                ["--permission-prompt-tool", self._options.permission_prompt_tool_name]
            )

        if self._options.permission_mode:
            cmd.extend(["--permission-mode", self._options.permission_mode])

        if self._options.continue_conversation:
            cmd.append("--continue")

        if self._options.resume:
            cmd.extend(["--resume", self._options.resume])

        if self._options.settings:
            cmd.extend(["--settings", self._options.settings])

        if self._options.add_dirs:
            # Convert all paths to strings and add each directory
            for directory in self._options.add_dirs:
                cmd.extend(["--add-dir", str(directory)])

        if self._options.mcp_servers:
            if isinstance(self._options.mcp_servers, dict):
                # Dict format: serialize to JSON
                cmd.extend(
                    [
                        "--mcp-config",
                        json.dumps({"mcpServers": self._options.mcp_servers}),
                    ]
                )
            else:
                # String or Path format: pass directly as file path or JSON string
                cmd.extend(["--mcp-config", str(self._options.mcp_servers)])

        # Add extra args for future CLI flags
        for flag, value in self._options.extra_args.items():
            if value is None:
                # Boolean flag without value
                cmd.append(f"--{flag}")
            else:
                # Flag with value
                cmd.extend([f"--{flag}", str(value)])

        # Add prompt handling based on mode
        if self._is_streaming:
            # Streaming mode: use --input-format stream-json
            cmd.extend(["--input-format", "stream-json"])
        else:
            # String mode: use --print with the prompt
            cmd.extend(["--print", str(self._prompt)])

        return cmd

    async def connect(self) -> None:
        """Start subprocess."""
        if self._process:
            return

        cmd = self._build_command()
        try:
            # Create a temp file for stderr to avoid pipe buffer deadlock
            # We can't use context manager as we need it for the subprocess lifetime
            self._stderr_file = tempfile.NamedTemporaryFile(  # noqa: SIM115
                mode="w+", prefix="claude_stderr_", suffix=".log", delete=False
            )

            # Enable stdin pipe for both modes (but we'll close it for string mode)
            self._process = await anyio.open_process(
                cmd,
                stdin=PIPE,
                stdout=PIPE,
                stderr=self._stderr_file,
                cwd=self._cwd,
                env={**os.environ, "CLAUDE_CODE_ENTRYPOINT": "sdk-py"},
            )

            if self._process.stdout:
                self._stdout_stream = TextReceiveStream(self._process.stdout)

            # Handle stdin based on mode
            if self._is_streaming:
                # Streaming mode: keep stdin open and start streaming task
                if self._process.stdin:
                    self._stdin_stream = TextSendStream(self._process.stdin)
                    # Start streaming messages to stdin in background
                    self._task_group = anyio.create_task_group()
                    await self._task_group.__aenter__()
                    self._task_group.start_soon(self._stream_to_stdin)
            else:
                # String mode: close stdin immediately (backward compatible)
                if self._process.stdin:
                    await self._process.stdin.aclose()

        except FileNotFoundError as e:
            # Check if the error comes from the working directory or the CLI
            if self._cwd and not Path(self._cwd).exists():
                raise CLIConnectionError(
                    f"Working directory does not exist: {self._cwd}"
                ) from e
            raise CLINotFoundError(f"Claude Code not found at: {self._cli_path}") from e
        except Exception as e:
            raise CLIConnectionError(f"Failed to start Claude Code: {e}") from e

    async def disconnect(self) -> None:
        """Terminate subprocess."""
        if not self._process:
            return

        # Cancel task group if it exists
        if self._task_group:
            self._task_group.cancel_scope.cancel()
            await self._task_group.__aexit__(None, None, None)
            self._task_group = None

        if self._process.returncode is None:
            try:
                self._process.terminate()
                with anyio.fail_after(5.0):
                    await self._process.wait()
            except TimeoutError:
                self._process.kill()
                await self._process.wait()
            except ProcessLookupError:
                pass

        # Clean up temp file
        if self._stderr_file:
            try:
                self._stderr_file.close()
                Path(self._stderr_file.name).unlink()
            except Exception:
                pass
            self._stderr_file = None

        self._process = None
        self._stdout_stream = None
        self._stderr_stream = None
        self._stdin_stream = None

    async def send_request(self, messages: list[Any], options: dict[str, Any]) -> None:
        """Send additional messages in streaming mode."""
        if not self._is_streaming:
            raise CLIConnectionError("send_request only works in streaming mode")

        if not self._stdin_stream:
            raise CLIConnectionError("stdin not available - stream may have ended")

        # Send each message as a user message
        for message in messages:
            # Ensure message has required structure
            if not isinstance(message, dict):
                message = {
                    "type": "user",
                    "message": {"role": "user", "content": str(message)},
                    "parent_tool_use_id": None,
                    "session_id": options.get("session_id", "default"),
                }

            await self._stdin_stream.send(json.dumps(message) + "\n")

    async def _stream_to_stdin(self) -> None:
        """Stream messages to stdin for streaming mode."""
        if not self._stdin_stream or not isinstance(self._prompt, AsyncIterable):
            return

        try:
            async for message in self._prompt:
                if not self._stdin_stream:
                    break
                await self._stdin_stream.send(json.dumps(message) + "\n")

            # Close stdin after prompt if requested (e.g., for query() one-shot mode)
            if self._close_stdin_after_prompt and self._stdin_stream:
                await self._stdin_stream.aclose()
                self._stdin_stream = None
            # Otherwise keep stdin open for send_request (ClaudeSDKClient interactive mode)
        except Exception as e:
            logger.debug(f"Error streaming to stdin: {e}")
            if self._stdin_stream:
                await self._stdin_stream.aclose()
                self._stdin_stream = None

    async def receive_messages(self) -> AsyncIterator[dict[str, Any]]:
        """Receive messages from CLI."""
        if not self._process or not self._stdout_stream:
            raise CLIConnectionError("Not connected")

        json_buffer = ""

        # Process stdout messages first
        try:
            async for line in self._stdout_stream:
                line_str = line.strip()
                if not line_str:
                    continue

                json_lines = line_str.split("\n")

                for json_line in json_lines:
                    json_line = json_line.strip()
                    if not json_line:
                        continue

                    # Keep accumulating partial JSON until we can parse it
                    json_buffer += json_line

                    if len(json_buffer) > _MAX_BUFFER_SIZE:
                        json_buffer = ""
                        raise SDKJSONDecodeError(
                            f"JSON message exceeded maximum buffer size of {_MAX_BUFFER_SIZE} bytes",
                            ValueError(
                                f"Buffer size {len(json_buffer)} exceeds limit {_MAX_BUFFER_SIZE}"
                            ),
                        )

                    try:
                        data = json.loads(json_buffer)
                        json_buffer = ""

                        # Handle control responses separately
                        if data.get("type") == "control_response":
                            response = data.get("response", {})
                            request_id = response.get("request_id")
                            if request_id:
                                # Store the response for the pending request
                                self._pending_control_responses[request_id] = response
                            continue

                        try:
                            yield data
                        except GeneratorExit:
                            return
                    except json.JSONDecodeError:
                        # We are speculatively decoding the buffer until we get
                        # a full JSON object. If there is an actual issue, we
                        # raise an error after _MAX_BUFFER_SIZE.
                        continue

        except anyio.ClosedResourceError:
            pass
        except GeneratorExit:
            # Client disconnected - still need to clean up
            pass

        # Read stderr from temp file (keep only last N lines for memory efficiency)
        stderr_lines: deque[str] = deque(maxlen=100)  # Keep last 100 lines
        if self._stderr_file:
            try:
                # Flush any pending writes
                self._stderr_file.flush()
                # Read from the beginning
                self._stderr_file.seek(0)
                for line in self._stderr_file:
                    line_text = line.strip()
                    if line_text:
                        stderr_lines.append(line_text)
            except Exception:
                pass

        # Check process completion and handle errors
        try:
            returncode = await self._process.wait()
        except Exception:
            returncode = -1

        # Convert deque to string for error reporting
        stderr_output = "\n".join(list(stderr_lines)) if stderr_lines else ""
        if len(stderr_lines) == stderr_lines.maxlen:
            stderr_output = (
                f"[stderr truncated, showing last {stderr_lines.maxlen} lines]\n"
                + stderr_output
            )

        # Use exit code for error detection, not string matching
        if returncode is not None and returncode != 0:
            raise ProcessError(
                f"Command failed with exit code {returncode}",
                exit_code=returncode,
                stderr=stderr_output,
            )
        elif stderr_output:
            # Log stderr for debugging but don't fail on non-zero exit
            logger.debug(f"Process stderr: {stderr_output}")

    def is_connected(self) -> bool:
        """Check if subprocess is running."""
        return self._process is not None and self._process.returncode is None

    async def interrupt(self) -> None:
        """Send interrupt control request (only works in streaming mode)."""
        if not self._is_streaming:
            raise CLIConnectionError(
                "Interrupt requires streaming mode (AsyncIterable prompt)"
            )

        if not self._stdin_stream:
            raise CLIConnectionError("Not connected or stdin not available")

        await self._send_control_request({"subtype": "interrupt"})

    async def _send_control_request(self, request: dict[str, Any]) -> dict[str, Any]:
        """Send a control request and wait for response."""
        if not self._stdin_stream:
            raise CLIConnectionError("Stdin not available")

        # Generate unique request ID
        self._request_counter += 1
        request_id = f"req_{self._request_counter}_{os.urandom(4).hex()}"

        # Build control request
        control_request = {
            "type": "control_request",
            "request_id": request_id,
            "request": request,
        }

        # Send request
        await self._stdin_stream.send(json.dumps(control_request) + "\n")

        # Wait for response
        while request_id not in self._pending_control_responses:
            await anyio.sleep(0.1)

        response = self._pending_control_responses.pop(request_id)

        if response.get("subtype") == "error":
            raise CLIConnectionError(f"Control request failed: {response.get('error')}")

        return response


=== File: src/claude_code_sdk/client.py ===
"""Claude SDK Client for interacting with Claude Code."""

import os
from collections.abc import AsyncIterable, AsyncIterator
from typing import Any

from ._errors import CLIConnectionError
from .types import ClaudeCodeOptions, Message, ResultMessage


class ClaudeSDKClient:
    """
    Client for bidirectional, interactive conversations with Claude Code.

    This client provides full control over the conversation flow with support
    for streaming, interrupts, and dynamic message sending. For simple one-shot
    queries, consider using the query() function instead.

    Key features:
    - **Bidirectional**: Send and receive messages at any time
    - **Stateful**: Maintains conversation context across messages
    - **Interactive**: Send follow-ups based on responses
    - **Control flow**: Support for interrupts and session management

    When to use ClaudeSDKClient:
    - Building chat interfaces or conversational UIs
    - Interactive debugging or exploration sessions
    - Multi-turn conversations with context
    - When you need to react to Claude's responses
    - Real-time applications with user input
    - When you need interrupt capabilities

    When to use query() instead:
    - Simple one-off questions
    - Batch processing of prompts
    - Fire-and-forget automation scripts
    - When all inputs are known upfront
    - Stateless operations

    Example - Interactive conversation:
        ```python
        # Automatically connects with empty stream for interactive use
        async with ClaudeSDKClient() as client:
            # Send initial message
            await client.query("Let's solve a math problem step by step")

            # Receive and process response
            async for message in client.receive_messages():
                if "ready" in str(message.content).lower():
                    break

            # Send follow-up based on response
            await client.query("What's 15% of 80?")

            # Continue conversation...
        # Automatically disconnects
        ```

    Example - With interrupt:
        ```python
        async with ClaudeSDKClient() as client:
            # Start a long task
            await client.query("Count to 1000")

            # Interrupt after 2 seconds
            await anyio.sleep(2)
            await client.interrupt()

            # Send new instruction
            await client.query("Never mind, what's 2+2?")
        ```

    Example - Manual connection:
        ```python
        client = ClaudeSDKClient()

        # Connect with initial message stream
        async def message_stream():
            yield {"type": "user", "message": {"role": "user", "content": "Hello"}}

        await client.connect(message_stream())

        # Send additional messages dynamically
        await client.query("What's the weather?")

        async for message in client.receive_messages():
            print(message)

        await client.disconnect()
        ```
    """

    def __init__(self, options: ClaudeCodeOptions | None = None):
        """Initialize Claude SDK client."""
        if options is None:
            options = ClaudeCodeOptions()
        self.options = options
        self._transport: Any | None = None
        os.environ["CLAUDE_CODE_ENTRYPOINT"] = "sdk-py-client"

    async def connect(
        self, prompt: str | AsyncIterable[dict[str, Any]] | None = None
    ) -> None:
        """Connect to Claude with a prompt or message stream."""
        from ._internal.transport.subprocess_cli import SubprocessCLITransport

        # Auto-connect with empty async iterable if no prompt is provided
        async def _empty_stream() -> AsyncIterator[dict[str, Any]]:
            # Never yields, but indicates that this function is an iterator and
            # keeps the connection open.
            # This yield is never reached but makes this an async generator
            return
            yield {}  # type: ignore[unreachable]

        self._transport = SubprocessCLITransport(
            prompt=_empty_stream() if prompt is None else prompt,
            options=self.options,
        )
        await self._transport.connect()

    async def receive_messages(self) -> AsyncIterator[Message]:
        """Receive all messages from Claude."""
        if not self._transport:
            raise CLIConnectionError("Not connected. Call connect() first.")

        from ._internal.message_parser import parse_message

        async for data in self._transport.receive_messages():
            yield parse_message(data)

    async def query(
        self, prompt: str | AsyncIterable[dict[str, Any]], session_id: str = "default"
    ) -> None:
        """
        Send a new request in streaming mode.

        Args:
            prompt: Either a string message or an async iterable of message dictionaries
            session_id: Session identifier for the conversation
        """
        if not self._transport:
            raise CLIConnectionError("Not connected. Call connect() first.")

        # Handle string prompts
        if isinstance(prompt, str):
            message = {
                "type": "user",
                "message": {"role": "user", "content": prompt},
                "parent_tool_use_id": None,
                "session_id": session_id,
            }
            await self._transport.send_request([message], {"session_id": session_id})
        else:
            # Handle AsyncIterable prompts
            messages = []
            async for msg in prompt:
                # Ensure session_id is set on each message
                if "session_id" not in msg:
                    msg["session_id"] = session_id
                messages.append(msg)

            if messages:
                await self._transport.send_request(messages, {"session_id": session_id})

    async def interrupt(self) -> None:
        """Send interrupt signal (only works with streaming mode)."""
        if not self._transport:
            raise CLIConnectionError("Not connected. Call connect() first.")
        await self._transport.interrupt()

    async def receive_response(self) -> AsyncIterator[Message]:
        """
        Receive messages from Claude until and including a ResultMessage.

        This async iterator yields all messages in sequence and automatically terminates
        after yielding a ResultMessage (which indicates the response is complete).
        It's a convenience method over receive_messages() for single-response workflows.

        **Stopping Behavior:**
        - Yields each message as it's received
        - Terminates immediately after yielding a ResultMessage
        - The ResultMessage IS included in the yielded messages
        - If no ResultMessage is received, the iterator continues indefinitely

        Yields:
            Message: Each message received (UserMessage, AssistantMessage, SystemMessage, ResultMessage)

        Example:
            ```python
            async with ClaudeSDKClient() as client:
                await client.query("What's the capital of France?")

                async for msg in client.receive_response():
                    if isinstance(msg, AssistantMessage):
                        for block in msg.content:
                            if isinstance(block, TextBlock):
                                print(f"Claude: {block.text}")
                    elif isinstance(msg, ResultMessage):
                        print(f"Cost: ${msg.total_cost_usd:.4f}")
                        # Iterator will terminate after this message
            ```

        Note:
            To collect all messages: `messages = [msg async for msg in client.receive_response()]`
            The final message in the list will always be a ResultMessage.
        """
        async for message in self.receive_messages():
            yield message
            if isinstance(message, ResultMessage):
                return

    async def disconnect(self) -> None:
        """Disconnect from Claude."""
        if self._transport:
            await self._transport.disconnect()
            self._transport = None

    async def __aenter__(self) -> "ClaudeSDKClient":
        """Enter async context - automatically connects with empty stream for interactive use."""
        await self.connect()
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> bool:
        """Exit async context - always disconnects."""
        await self.disconnect()
        return False


=== File: src/claude_code_sdk/py.typed ===


=== File: src/claude_code_sdk/query.py ===
"""Query function for one-shot interactions with Claude Code."""

import os
from collections.abc import AsyncIterable, AsyncIterator
from typing import Any

from ._internal.client import InternalClient
from .types import ClaudeCodeOptions, Message


async def query(
    *,
    prompt: str | AsyncIterable[dict[str, Any]],
    options: ClaudeCodeOptions | None = None,
) -> AsyncIterator[Message]:
    """
    Query Claude Code for one-shot or unidirectional streaming interactions.

    This function is ideal for simple, stateless queries where you don't need
    bidirectional communication or conversation management. For interactive,
    stateful conversations, use ClaudeSDKClient instead.

    Key differences from ClaudeSDKClient:
    - **Unidirectional**: Send all messages upfront, receive all responses
    - **Stateless**: Each query is independent, no conversation state
    - **Simple**: Fire-and-forget style, no connection management
    - **No interrupts**: Cannot interrupt or send follow-up messages

    When to use query():
    - Simple one-off questions ("What is 2+2?")
    - Batch processing of independent prompts
    - Code generation or analysis tasks
    - Automated scripts and CI/CD pipelines
    - When you know all inputs upfront

    When to use ClaudeSDKClient:
    - Interactive conversations with follow-ups
    - Chat applications or REPL-like interfaces
    - When you need to send messages based on responses
    - When you need interrupt capabilities
    - Long-running sessions with state

    Args:
        prompt: The prompt to send to Claude. Can be a string for single-shot queries
                or an AsyncIterable[dict] for streaming mode with continuous interaction.
                In streaming mode, each dict should have the structure:
                {
                    "type": "user",
                    "message": {"role": "user", "content": "..."},
                    "parent_tool_use_id": None,
                    "session_id": "..."
                }
        options: Optional configuration (defaults to ClaudeCodeOptions() if None).
                 Set options.permission_mode to control tool execution:
                 - 'default': CLI prompts for dangerous tools
                 - 'acceptEdits': Auto-accept file edits
                 - 'bypassPermissions': Allow all tools (use with caution)
                 Set options.cwd for working directory.

    Yields:
        Messages from the conversation

    Example - Simple query:
        ```python
        # One-off question
        async for message in query(prompt="What is the capital of France?"):
            print(message)
        ```

    Example - With options:
        ```python
        # Code generation with specific settings
        async for message in query(
            prompt="Create a Python web server",
            options=ClaudeCodeOptions(
                system_prompt="You are an expert Python developer",
                cwd="/home/user/project"
            )
        ):
            print(message)
        ```

    Example - Streaming mode (still unidirectional):
        ```python
        async def prompts():
            yield {"type": "user", "message": {"role": "user", "content": "Hello"}}
            yield {"type": "user", "message": {"role": "user", "content": "How are you?"}}

        # All prompts are sent, then all responses received
        async for message in query(prompt=prompts()):
            print(message)
        ```
    """
    if options is None:
        options = ClaudeCodeOptions()

    os.environ["CLAUDE_CODE_ENTRYPOINT"] = "sdk-py"

    client = InternalClient()

    async for message in client.process_query(prompt=prompt, options=options):
        yield message


=== File: src/claude_code_sdk/types.py ===
"""Type definitions for Claude SDK."""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Literal, TypedDict

from typing_extensions import NotRequired  # For Python < 3.11 compatibility

# Permission modes
PermissionMode = Literal["default", "acceptEdits", "plan", "bypassPermissions"]


# MCP Server config
class McpStdioServerConfig(TypedDict):
    """MCP stdio server configuration."""

    type: NotRequired[Literal["stdio"]]  # Optional for backwards compatibility
    command: str
    args: NotRequired[list[str]]
    env: NotRequired[dict[str, str]]


class McpSSEServerConfig(TypedDict):
    """MCP SSE server configuration."""

    type: Literal["sse"]
    url: str
    headers: NotRequired[dict[str, str]]


class McpHttpServerConfig(TypedDict):
    """MCP HTTP server configuration."""

    type: Literal["http"]
    url: str
    headers: NotRequired[dict[str, str]]


McpServerConfig = McpStdioServerConfig | McpSSEServerConfig | McpHttpServerConfig


# Content block types
@dataclass
class TextBlock:
    """Text content block."""

    text: str


@dataclass
class ThinkingBlock:
    """Thinking content block."""

    thinking: str
    signature: str


@dataclass
class ToolUseBlock:
    """Tool use content block."""

    id: str
    name: str
    input: dict[str, Any]


@dataclass
class ToolResultBlock:
    """Tool result content block."""

    tool_use_id: str
    content: str | list[dict[str, Any]] | None = None
    is_error: bool | None = None


ContentBlock = TextBlock | ThinkingBlock | ToolUseBlock | ToolResultBlock


# Message types
@dataclass
class UserMessage:
    """User message."""

    content: str | list[ContentBlock]


@dataclass
class AssistantMessage:
    """Assistant message with content blocks."""

    content: list[ContentBlock]
    model: str


@dataclass
class SystemMessage:
    """System message with metadata."""

    subtype: str
    data: dict[str, Any]


@dataclass
class ResultMessage:
    """Result message with cost and usage information."""

    subtype: str
    duration_ms: int
    duration_api_ms: int
    is_error: bool
    num_turns: int
    session_id: str
    total_cost_usd: float | None = None
    usage: dict[str, Any] | None = None
    result: str | None = None


Message = UserMessage | AssistantMessage | SystemMessage | ResultMessage


@dataclass
class ClaudeCodeOptions:
    """Query options for Claude SDK."""

    allowed_tools: list[str] = field(default_factory=list)
    max_thinking_tokens: int = 8000
    system_prompt: str | None = None
    append_system_prompt: str | None = None
    mcp_servers: dict[str, McpServerConfig] | str | Path = field(default_factory=dict)
    permission_mode: PermissionMode | None = None
    continue_conversation: bool = False
    resume: str | None = None
    max_turns: int | None = None
    disallowed_tools: list[str] = field(default_factory=list)
    model: str | None = None
    permission_prompt_tool_name: str | None = None
    cwd: str | Path | None = None
    settings: str | None = None
    add_dirs: list[str | Path] = field(default_factory=list)
    extra_args: dict[str, str | None] = field(
        default_factory=dict
    )  # Pass arbitrary CLI flags


=== File: tests/conftest.py ===
"""Pytest configuration for tests."""


# No async plugin needed since we're using sync tests with anyio.run()


=== File: tests/test_changelog.py ===
import re
from pathlib import Path


class TestChangelog:
    def setup_method(self):
        self.changelog_path = Path(__file__).parent.parent / "CHANGELOG.md"

    def test_changelog_exists(self):
        assert self.changelog_path.exists(), "CHANGELOG.md file should exist"

    def test_changelog_starts_with_header(self):
        content = self.changelog_path.read_text()
        assert content.startswith("# Changelog"), (
            "Changelog should start with '# Changelog'"
        )

    def test_changelog_has_valid_version_format(self):
        content = self.changelog_path.read_text()
        lines = content.split("\n")

        version_pattern = re.compile(r"^## \d+\.\d+\.\d+(?:\s+\(\d{4}-\d{2}-\d{2}\))?$")
        versions = []

        for line in lines:
            if line.startswith("## "):
                assert version_pattern.match(line), f"Invalid version format: {line}"
                version_match = re.match(r"^## (\d+\.\d+\.\d+)", line)
                if version_match:
                    versions.append(version_match.group(1))

        assert len(versions) > 0, "Changelog should contain at least one version"

    def test_changelog_has_bullet_points(self):
        content = self.changelog_path.read_text()
        lines = content.split("\n")

        in_version_section = False
        has_bullet_points = False

        for i, line in enumerate(lines):
            if line.startswith("## "):
                if in_version_section and not has_bullet_points:
                    raise AssertionError(
                        "Previous version section should have at least one bullet point"
                    )
                in_version_section = True
                has_bullet_points = False
            elif in_version_section and line.startswith("- "):
                has_bullet_points = True
            elif in_version_section and line.strip() == "" and i == len(lines) - 1:
                # Last line check
                assert has_bullet_points, (
                    "Each version should have at least one bullet point"
                )

        # Check the last section
        if in_version_section:
            assert has_bullet_points, (
                "Last version section should have at least one bullet point"
            )

    def test_changelog_versions_in_descending_order(self):
        content = self.changelog_path.read_text()
        lines = content.split("\n")

        versions = []
        for line in lines:
            if line.startswith("## "):
                version_match = re.match(r"^## (\d+)\.(\d+)\.(\d+)", line)
                if version_match:
                    versions.append(tuple(map(int, version_match.groups())))

        for i in range(1, len(versions)):
            assert versions[i - 1] > versions[i], (
                f"Versions should be in descending order: {versions[i - 1]} should be > {versions[i]}"
            )

    def test_changelog_no_empty_bullet_points(self):
        content = self.changelog_path.read_text()
        lines = content.split("\n")

        for line in lines:
            if line.strip() == "-":
                raise AssertionError("Changelog should not have empty bullet points")


=== File: tests/test_client.py ===
"""Tests for Claude SDK client functionality."""

from unittest.mock import AsyncMock, patch

import anyio

from claude_code_sdk import AssistantMessage, ClaudeCodeOptions, query
from claude_code_sdk.types import TextBlock


class TestQueryFunction:
    """Test the main query function."""

    def test_query_single_prompt(self):
        """Test query with a single prompt."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.client.InternalClient.process_query"
            ) as mock_process:
                # Mock the async generator
                async def mock_generator():
                    yield AssistantMessage(
                        content=[TextBlock(text="4")], model="claude-opus-4-1-20250805"
                    )

                mock_process.return_value = mock_generator()

                messages = []
                async for msg in query(prompt="What is 2+2?"):
                    messages.append(msg)

                assert len(messages) == 1
                assert isinstance(messages[0], AssistantMessage)
                assert messages[0].content[0].text == "4"

        anyio.run(_test)

    def test_query_with_options(self):
        """Test query with various options."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.client.InternalClient.process_query"
            ) as mock_process:

                async def mock_generator():
                    yield AssistantMessage(
                        content=[TextBlock(text="Hello!")],
                        model="claude-opus-4-1-20250805",
                    )

                mock_process.return_value = mock_generator()

                options = ClaudeCodeOptions(
                    allowed_tools=["Read", "Write"],
                    system_prompt="You are helpful",
                    permission_mode="acceptEdits",
                    max_turns=5,
                )

                messages = []
                async for msg in query(prompt="Hi", options=options):
                    messages.append(msg)

                # Verify process_query was called with correct prompt and options
                mock_process.assert_called_once()
                call_args = mock_process.call_args
                assert call_args[1]["prompt"] == "Hi"
                assert call_args[1]["options"] == options

        anyio.run(_test)

    def test_query_with_cwd(self):
        """Test query with custom working directory."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.client.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock the message stream
                async def mock_receive():
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [{"type": "text", "text": "Done"}],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    yield {
                        "type": "result",
                        "subtype": "success",
                        "duration_ms": 1000,
                        "duration_api_ms": 800,
                        "is_error": False,
                        "num_turns": 1,
                        "session_id": "test-session",
                        "total_cost_usd": 0.001,
                    }

                mock_transport.receive_messages = mock_receive
                mock_transport.connect = AsyncMock()
                mock_transport.disconnect = AsyncMock()

                options = ClaudeCodeOptions(cwd="/custom/path")
                messages = []
                async for msg in query(prompt="test", options=options):
                    messages.append(msg)

                # Verify transport was created with correct parameters
                mock_transport_class.assert_called_once()
                call_kwargs = mock_transport_class.call_args.kwargs
                assert call_kwargs["prompt"] == "test"
                assert call_kwargs["options"].cwd == "/custom/path"

        anyio.run(_test)


=== File: tests/test_errors.py ===
"""Tests for Claude SDK error handling."""

from claude_code_sdk import (
    ClaudeSDKError,
    CLIConnectionError,
    CLIJSONDecodeError,
    CLINotFoundError,
    ProcessError,
)


class TestErrorTypes:
    """Test error types and their properties."""

    def test_base_error(self):
        """Test base ClaudeSDKError."""
        error = ClaudeSDKError("Something went wrong")
        assert str(error) == "Something went wrong"
        assert isinstance(error, Exception)

    def test_cli_not_found_error(self):
        """Test CLINotFoundError."""
        error = CLINotFoundError("Claude Code not found")
        assert isinstance(error, ClaudeSDKError)
        assert "Claude Code not found" in str(error)

    def test_connection_error(self):
        """Test CLIConnectionError."""
        error = CLIConnectionError("Failed to connect to CLI")
        assert isinstance(error, ClaudeSDKError)
        assert "Failed to connect to CLI" in str(error)

    def test_process_error(self):
        """Test ProcessError with exit code and stderr."""
        error = ProcessError("Process failed", exit_code=1, stderr="Command not found")
        assert error.exit_code == 1
        assert error.stderr == "Command not found"
        assert "Process failed" in str(error)
        assert "exit code: 1" in str(error)
        assert "Command not found" in str(error)

    def test_json_decode_error(self):
        """Test CLIJSONDecodeError."""
        import json

        try:
            json.loads("{invalid json}")
        except json.JSONDecodeError as e:
            error = CLIJSONDecodeError("{invalid json}", e)
            assert error.line == "{invalid json}"
            assert error.original_error == e
            assert "Failed to decode JSON" in str(error)


=== File: tests/test_integration.py ===
"""Integration tests for Claude SDK.

These tests verify end-to-end functionality with mocked CLI responses.
"""

from unittest.mock import AsyncMock, patch

import anyio
import pytest

from claude_code_sdk import (
    AssistantMessage,
    ClaudeCodeOptions,
    CLINotFoundError,
    ResultMessage,
    query,
)
from claude_code_sdk.types import ToolUseBlock


class TestIntegration:
    """End-to-end integration tests."""

    def test_simple_query_response(self):
        """Test a simple query with text response."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.client.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock the message stream
                async def mock_receive():
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [{"type": "text", "text": "2 + 2 equals 4"}],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    yield {
                        "type": "result",
                        "subtype": "success",
                        "duration_ms": 1000,
                        "duration_api_ms": 800,
                        "is_error": False,
                        "num_turns": 1,
                        "session_id": "test-session",
                        "total_cost_usd": 0.001,
                    }

                mock_transport.receive_messages = mock_receive
                mock_transport.connect = AsyncMock()
                mock_transport.disconnect = AsyncMock()

                # Run query
                messages = []
                async for msg in query(prompt="What is 2 + 2?"):
                    messages.append(msg)

                # Verify results
                assert len(messages) == 2

                # Check assistant message
                assert isinstance(messages[0], AssistantMessage)
                assert len(messages[0].content) == 1
                assert messages[0].content[0].text == "2 + 2 equals 4"

                # Check result message
                assert isinstance(messages[1], ResultMessage)
                assert messages[1].total_cost_usd == 0.001
                assert messages[1].session_id == "test-session"

        anyio.run(_test)

    def test_query_with_tool_use(self):
        """Test query that uses tools."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.client.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock the message stream with tool use
                async def mock_receive():
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [
                                {
                                    "type": "text",
                                    "text": "Let me read that file for you.",
                                },
                                {
                                    "type": "tool_use",
                                    "id": "tool-123",
                                    "name": "Read",
                                    "input": {"file_path": "/test.txt"},
                                },
                            ],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    yield {
                        "type": "result",
                        "subtype": "success",
                        "duration_ms": 1500,
                        "duration_api_ms": 1200,
                        "is_error": False,
                        "num_turns": 1,
                        "session_id": "test-session-2",
                        "total_cost_usd": 0.002,
                    }

                mock_transport.receive_messages = mock_receive
                mock_transport.connect = AsyncMock()
                mock_transport.disconnect = AsyncMock()

                # Run query with tools enabled
                messages = []
                async for msg in query(
                    prompt="Read /test.txt",
                    options=ClaudeCodeOptions(allowed_tools=["Read"]),
                ):
                    messages.append(msg)

                # Verify results
                assert len(messages) == 2

                # Check assistant message with tool use
                assert isinstance(messages[0], AssistantMessage)
                assert len(messages[0].content) == 2
                assert messages[0].content[0].text == "Let me read that file for you."
                assert isinstance(messages[0].content[1], ToolUseBlock)
                assert messages[0].content[1].name == "Read"
                assert messages[0].content[1].input["file_path"] == "/test.txt"

        anyio.run(_test)

    def test_cli_not_found(self):
        """Test handling when CLI is not found."""

        async def _test():
            with (
                patch("shutil.which", return_value=None),
                patch("pathlib.Path.exists", return_value=False),
                pytest.raises(CLINotFoundError) as exc_info,
            ):
                async for _ in query(prompt="test"):
                    pass

            assert "Claude Code requires Node.js" in str(exc_info.value)

        anyio.run(_test)

    def test_continuation_option(self):
        """Test query with continue_conversation option."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.client.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock the message stream
                async def mock_receive():
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [
                                {
                                    "type": "text",
                                    "text": "Continuing from previous conversation",
                                }
                            ],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }

                mock_transport.receive_messages = mock_receive
                mock_transport.connect = AsyncMock()
                mock_transport.disconnect = AsyncMock()

                # Run query with continuation
                messages = []
                async for msg in query(
                    prompt="Continue",
                    options=ClaudeCodeOptions(continue_conversation=True),
                ):
                    messages.append(msg)

                # Verify transport was created with continuation option
                mock_transport_class.assert_called_once()
                call_kwargs = mock_transport_class.call_args.kwargs
                assert call_kwargs["options"].continue_conversation is True

        anyio.run(_test)


=== File: tests/test_message_parser.py ===
"""Tests for message parser error handling."""

import pytest

from claude_code_sdk._errors import MessageParseError
from claude_code_sdk._internal.message_parser import parse_message
from claude_code_sdk.types import (
    AssistantMessage,
    ResultMessage,
    SystemMessage,
    TextBlock,
    ToolResultBlock,
    ToolUseBlock,
    UserMessage,
)


class TestMessageParser:
    """Test message parsing with the new exception behavior."""

    def test_parse_valid_user_message(self):
        """Test parsing a valid user message."""
        data = {
            "type": "user",
            "message": {"content": [{"type": "text", "text": "Hello"}]},
        }
        message = parse_message(data)
        assert isinstance(message, UserMessage)
        assert len(message.content) == 1
        assert isinstance(message.content[0], TextBlock)
        assert message.content[0].text == "Hello"

    def test_parse_user_message_with_tool_use(self):
        """Test parsing a user message with tool_use block."""
        data = {
            "type": "user",
            "message": {
                "content": [
                    {"type": "text", "text": "Let me read this file"},
                    {
                        "type": "tool_use",
                        "id": "tool_456",
                        "name": "Read",
                        "input": {"file_path": "/example.txt"},
                    },
                ]
            },
        }
        message = parse_message(data)
        assert isinstance(message, UserMessage)
        assert len(message.content) == 2
        assert isinstance(message.content[0], TextBlock)
        assert isinstance(message.content[1], ToolUseBlock)
        assert message.content[1].id == "tool_456"
        assert message.content[1].name == "Read"
        assert message.content[1].input == {"file_path": "/example.txt"}

    def test_parse_user_message_with_tool_result(self):
        """Test parsing a user message with tool_result block."""
        data = {
            "type": "user",
            "message": {
                "content": [
                    {
                        "type": "tool_result",
                        "tool_use_id": "tool_789",
                        "content": "File contents here",
                    }
                ]
            },
        }
        message = parse_message(data)
        assert isinstance(message, UserMessage)
        assert len(message.content) == 1
        assert isinstance(message.content[0], ToolResultBlock)
        assert message.content[0].tool_use_id == "tool_789"
        assert message.content[0].content == "File contents here"

    def test_parse_user_message_with_tool_result_error(self):
        """Test parsing a user message with error tool_result block."""
        data = {
            "type": "user",
            "message": {
                "content": [
                    {
                        "type": "tool_result",
                        "tool_use_id": "tool_error",
                        "content": "File not found",
                        "is_error": True,
                    }
                ]
            },
        }
        message = parse_message(data)
        assert isinstance(message, UserMessage)
        assert len(message.content) == 1
        assert isinstance(message.content[0], ToolResultBlock)
        assert message.content[0].tool_use_id == "tool_error"
        assert message.content[0].content == "File not found"
        assert message.content[0].is_error is True

    def test_parse_user_message_with_mixed_content(self):
        """Test parsing a user message with mixed content blocks."""
        data = {
            "type": "user",
            "message": {
                "content": [
                    {"type": "text", "text": "Here's what I found:"},
                    {
                        "type": "tool_use",
                        "id": "use_1",
                        "name": "Search",
                        "input": {"query": "test"},
                    },
                    {
                        "type": "tool_result",
                        "tool_use_id": "use_1",
                        "content": "Search results",
                    },
                    {"type": "text", "text": "What do you think?"},
                ]
            },
        }
        message = parse_message(data)
        assert isinstance(message, UserMessage)
        assert len(message.content) == 4
        assert isinstance(message.content[0], TextBlock)
        assert isinstance(message.content[1], ToolUseBlock)
        assert isinstance(message.content[2], ToolResultBlock)
        assert isinstance(message.content[3], TextBlock)

    def test_parse_valid_assistant_message(self):
        """Test parsing a valid assistant message."""
        data = {
            "type": "assistant",
            "message": {
                "content": [
                    {"type": "text", "text": "Hello"},
                    {
                        "type": "tool_use",
                        "id": "tool_123",
                        "name": "Read",
                        "input": {"file_path": "/test.txt"},
                    },
                ],
                "model": "claude-opus-4-1-20250805",
            },
        }
        message = parse_message(data)
        assert isinstance(message, AssistantMessage)
        assert len(message.content) == 2
        assert isinstance(message.content[0], TextBlock)
        assert isinstance(message.content[1], ToolUseBlock)

    def test_parse_valid_system_message(self):
        """Test parsing a valid system message."""
        data = {"type": "system", "subtype": "start"}
        message = parse_message(data)
        assert isinstance(message, SystemMessage)
        assert message.subtype == "start"

    def test_parse_valid_result_message(self):
        """Test parsing a valid result message."""
        data = {
            "type": "result",
            "subtype": "success",
            "duration_ms": 1000,
            "duration_api_ms": 500,
            "is_error": False,
            "num_turns": 2,
            "session_id": "session_123",
        }
        message = parse_message(data)
        assert isinstance(message, ResultMessage)
        assert message.subtype == "success"

    def test_parse_invalid_data_type(self):
        """Test that non-dict data raises MessageParseError."""
        with pytest.raises(MessageParseError) as exc_info:
            parse_message("not a dict")  # type: ignore
        assert "Invalid message data type" in str(exc_info.value)
        assert "expected dict, got str" in str(exc_info.value)

    def test_parse_missing_type_field(self):
        """Test that missing 'type' field raises MessageParseError."""
        with pytest.raises(MessageParseError) as exc_info:
            parse_message({"message": {"content": []}})
        assert "Message missing 'type' field" in str(exc_info.value)

    def test_parse_unknown_message_type(self):
        """Test that unknown message type raises MessageParseError."""
        with pytest.raises(MessageParseError) as exc_info:
            parse_message({"type": "unknown_type"})
        assert "Unknown message type: unknown_type" in str(exc_info.value)

    def test_parse_user_message_missing_fields(self):
        """Test that user message with missing fields raises MessageParseError."""
        with pytest.raises(MessageParseError) as exc_info:
            parse_message({"type": "user"})
        assert "Missing required field in user message" in str(exc_info.value)

    def test_parse_assistant_message_missing_fields(self):
        """Test that assistant message with missing fields raises MessageParseError."""
        with pytest.raises(MessageParseError) as exc_info:
            parse_message({"type": "assistant"})
        assert "Missing required field in assistant message" in str(exc_info.value)

    def test_parse_system_message_missing_fields(self):
        """Test that system message with missing fields raises MessageParseError."""
        with pytest.raises(MessageParseError) as exc_info:
            parse_message({"type": "system"})
        assert "Missing required field in system message" in str(exc_info.value)

    def test_parse_result_message_missing_fields(self):
        """Test that result message with missing fields raises MessageParseError."""
        with pytest.raises(MessageParseError) as exc_info:
            parse_message({"type": "result", "subtype": "success"})
        assert "Missing required field in result message" in str(exc_info.value)

    def test_message_parse_error_contains_data(self):
        """Test that MessageParseError contains the original data."""
        data = {"type": "unknown", "some": "data"}
        with pytest.raises(MessageParseError) as exc_info:
            parse_message(data)
        assert exc_info.value.data == data


=== File: tests/test_streaming_client.py ===
"""Tests for ClaudeSDKClient streaming functionality and query() with async iterables."""

import asyncio
import sys
import tempfile
from pathlib import Path
from unittest.mock import AsyncMock, patch

import anyio
import pytest

from claude_code_sdk import (
    AssistantMessage,
    ClaudeCodeOptions,
    ClaudeSDKClient,
    CLIConnectionError,
    ResultMessage,
    TextBlock,
    UserMessage,
    query,
)
from claude_code_sdk._internal.transport.subprocess_cli import SubprocessCLITransport


class TestClaudeSDKClientStreaming:
    """Test ClaudeSDKClient streaming functionality."""

    def test_auto_connect_with_context_manager(self):
        """Test automatic connection when using context manager."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                async with ClaudeSDKClient() as client:
                    # Verify connect was called
                    mock_transport.connect.assert_called_once()
                    assert client._transport is mock_transport

                # Verify disconnect was called on exit
                mock_transport.disconnect.assert_called_once()

        anyio.run(_test)

    def test_manual_connect_disconnect(self):
        """Test manual connect and disconnect."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                client = ClaudeSDKClient()
                await client.connect()

                # Verify connect was called
                mock_transport.connect.assert_called_once()
                assert client._transport is mock_transport

                await client.disconnect()
                # Verify disconnect was called
                mock_transport.disconnect.assert_called_once()
                assert client._transport is None

        anyio.run(_test)

    def test_connect_with_string_prompt(self):
        """Test connecting with a string prompt."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                client = ClaudeSDKClient()
                await client.connect("Hello Claude")

                # Verify transport was created with string prompt
                call_kwargs = mock_transport_class.call_args.kwargs
                assert call_kwargs["prompt"] == "Hello Claude"

        anyio.run(_test)

    def test_connect_with_async_iterable(self):
        """Test connecting with an async iterable."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                async def message_stream():
                    yield {"type": "user", "message": {"role": "user", "content": "Hi"}}
                    yield {
                        "type": "user",
                        "message": {"role": "user", "content": "Bye"},
                    }

                client = ClaudeSDKClient()
                stream = message_stream()
                await client.connect(stream)

                # Verify transport was created with async iterable
                call_kwargs = mock_transport_class.call_args.kwargs
                # Should be the same async iterator
                assert call_kwargs["prompt"] is stream

        anyio.run(_test)

    def test_query(self):
        """Test sending a query."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                async with ClaudeSDKClient() as client:
                    await client.query("Test message")

                    # Verify send_request was called with correct format
                    mock_transport.send_request.assert_called_once()
                    call_args = mock_transport.send_request.call_args
                    messages, options = call_args[0]
                    assert len(messages) == 1
                    assert messages[0]["type"] == "user"
                    assert messages[0]["message"]["content"] == "Test message"
                    assert options["session_id"] == "default"

        anyio.run(_test)

    def test_send_message_with_session_id(self):
        """Test sending a message with custom session ID."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                async with ClaudeSDKClient() as client:
                    await client.query("Test", session_id="custom-session")

                    call_args = mock_transport.send_request.call_args
                    messages, options = call_args[0]
                    assert messages[0]["session_id"] == "custom-session"
                    assert options["session_id"] == "custom-session"

        anyio.run(_test)

    def test_send_message_not_connected(self):
        """Test sending message when not connected raises error."""

        async def _test():
            client = ClaudeSDKClient()
            with pytest.raises(CLIConnectionError, match="Not connected"):
                await client.query("Test")

        anyio.run(_test)

    def test_receive_messages(self):
        """Test receiving messages."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock the message stream
                async def mock_receive():
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [{"type": "text", "text": "Hello!"}],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    yield {
                        "type": "user",
                        "message": {"role": "user", "content": "Hi there"},
                    }

                mock_transport.receive_messages = mock_receive

                async with ClaudeSDKClient() as client:
                    messages = []
                    async for msg in client.receive_messages():
                        messages.append(msg)
                        if len(messages) == 2:
                            break

                    assert len(messages) == 2
                    assert isinstance(messages[0], AssistantMessage)
                    assert isinstance(messages[0].content[0], TextBlock)
                    assert messages[0].content[0].text == "Hello!"
                    assert isinstance(messages[1], UserMessage)
                    assert messages[1].content == "Hi there"

        anyio.run(_test)

    def test_receive_response(self):
        """Test receive_response stops at ResultMessage."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock the message stream
                async def mock_receive():
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [{"type": "text", "text": "Answer"}],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    yield {
                        "type": "result",
                        "subtype": "success",
                        "duration_ms": 1000,
                        "duration_api_ms": 800,
                        "is_error": False,
                        "num_turns": 1,
                        "session_id": "test",
                        "total_cost_usd": 0.001,
                    }
                    # This should not be yielded
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [
                                {"type": "text", "text": "Should not see this"}
                            ],
                        },
                        "model": "claude-opus-4-1-20250805",
                    }

                mock_transport.receive_messages = mock_receive

                async with ClaudeSDKClient() as client:
                    messages = []
                    async for msg in client.receive_response():
                        messages.append(msg)

                    # Should only get 2 messages (assistant + result)
                    assert len(messages) == 2
                    assert isinstance(messages[0], AssistantMessage)
                    assert isinstance(messages[1], ResultMessage)

        anyio.run(_test)

    def test_interrupt(self):
        """Test interrupt functionality."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                async with ClaudeSDKClient() as client:
                    await client.interrupt()
                    mock_transport.interrupt.assert_called_once()

        anyio.run(_test)

    def test_interrupt_not_connected(self):
        """Test interrupt when not connected raises error."""

        async def _test():
            client = ClaudeSDKClient()
            with pytest.raises(CLIConnectionError, match="Not connected"):
                await client.interrupt()

        anyio.run(_test)

    def test_client_with_options(self):
        """Test client initialization with options."""

        async def _test():
            options = ClaudeCodeOptions(
                cwd="/custom/path",
                allowed_tools=["Read", "Write"],
                system_prompt="Be helpful",
            )

            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                client = ClaudeSDKClient(options=options)
                await client.connect()

                # Verify options were passed to transport
                call_kwargs = mock_transport_class.call_args.kwargs
                assert call_kwargs["options"] is options

        anyio.run(_test)

    def test_concurrent_send_receive(self):
        """Test concurrent sending and receiving messages."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock receive to wait then yield messages
                async def mock_receive():
                    await asyncio.sleep(0.1)
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [{"type": "text", "text": "Response 1"}],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    await asyncio.sleep(0.1)
                    yield {
                        "type": "result",
                        "subtype": "success",
                        "duration_ms": 1000,
                        "duration_api_ms": 800,
                        "is_error": False,
                        "num_turns": 1,
                        "session_id": "test",
                        "total_cost_usd": 0.001,
                    }

                mock_transport.receive_messages = mock_receive

                async with ClaudeSDKClient() as client:
                    # Helper to get next message
                    async def get_next_message():
                        return await client.receive_response().__anext__()

                    # Start receiving in background
                    receive_task = asyncio.create_task(get_next_message())

                    # Send message while receiving
                    await client.query("Question 1")

                    # Wait for first message
                    first_msg = await receive_task
                    assert isinstance(first_msg, AssistantMessage)

        anyio.run(_test)


class TestQueryWithAsyncIterable:
    """Test query() function with async iterable inputs."""

    def test_query_with_async_iterable(self):
        """Test query with async iterable of messages."""

        async def _test():
            async def message_stream():
                yield {"type": "user", "message": {"role": "user", "content": "First"}}
                yield {"type": "user", "message": {"role": "user", "content": "Second"}}

            # Create a simple test script that validates stdin and outputs a result
            with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as f:
                test_script = f.name
                f.write("""#!/usr/bin/env python3
import sys
import json

# Read stdin messages
stdin_messages = []
while True:
    line = sys.stdin.readline()
    if not line:
        break
    stdin_messages.append(line.strip())

# Verify we got 2 messages
assert len(stdin_messages) == 2
assert '"First"' in stdin_messages[0]
assert '"Second"' in stdin_messages[1]

# Output a valid result
print('{"type": "result", "subtype": "success", "duration_ms": 100, "duration_api_ms": 50, "is_error": false, "num_turns": 1, "session_id": "test", "total_cost_usd": 0.001}')
""")

            Path(test_script).chmod(0o755)

            try:
                # Mock _find_cli to return python executing our test script
                with patch.object(
                    SubprocessCLITransport, "_find_cli", return_value=sys.executable
                ):
                    # Mock _build_command to add our test script as first argument
                    original_build_command = SubprocessCLITransport._build_command

                    def mock_build_command(self):
                        # Get original command
                        cmd = original_build_command(self)
                        # Replace the CLI path with python + script
                        cmd[0] = test_script
                        return cmd

                    with patch.object(
                        SubprocessCLITransport, "_build_command", mock_build_command
                    ):
                        # Run query with async iterable
                        messages = []
                        async for msg in query(prompt=message_stream()):
                            messages.append(msg)

                        # Should get the result message
                        assert len(messages) == 1
                        assert isinstance(messages[0], ResultMessage)
                        assert messages[0].subtype == "success"
            finally:
                # Clean up
                Path(test_script).unlink()

        anyio.run(_test)


class TestClaudeSDKClientEdgeCases:
    """Test edge cases and error scenarios."""

    def test_receive_messages_not_connected(self):
        """Test receiving messages when not connected."""

        async def _test():
            client = ClaudeSDKClient()
            with pytest.raises(CLIConnectionError, match="Not connected"):
                async for _ in client.receive_messages():
                    pass

        anyio.run(_test)

    def test_receive_response_not_connected(self):
        """Test receive_response when not connected."""

        async def _test():
            client = ClaudeSDKClient()
            with pytest.raises(CLIConnectionError, match="Not connected"):
                async for _ in client.receive_response():
                    pass

        anyio.run(_test)

    def test_double_connect(self):
        """Test connecting twice."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                client = ClaudeSDKClient()
                await client.connect()
                # Second connect should create new transport
                await client.connect()

                # Should have been called twice
                assert mock_transport_class.call_count == 2

        anyio.run(_test)

    def test_disconnect_without_connect(self):
        """Test disconnecting without connecting first."""

        async def _test():
            client = ClaudeSDKClient()
            # Should not raise error
            await client.disconnect()

        anyio.run(_test)

    def test_context_manager_with_exception(self):
        """Test context manager cleans up on exception."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                with pytest.raises(ValueError):
                    async with ClaudeSDKClient():
                        raise ValueError("Test error")

                # Disconnect should still be called
                mock_transport.disconnect.assert_called_once()

        anyio.run(_test)

    def test_receive_response_list_comprehension(self):
        """Test collecting messages with list comprehension as shown in examples."""

        async def _test():
            with patch(
                "claude_code_sdk._internal.transport.subprocess_cli.SubprocessCLITransport"
            ) as mock_transport_class:
                mock_transport = AsyncMock()
                mock_transport_class.return_value = mock_transport

                # Mock the message stream
                async def mock_receive():
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [{"type": "text", "text": "Hello"}],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    yield {
                        "type": "assistant",
                        "message": {
                            "role": "assistant",
                            "content": [{"type": "text", "text": "World"}],
                            "model": "claude-opus-4-1-20250805",
                        },
                    }
                    yield {
                        "type": "result",
                        "subtype": "success",
                        "duration_ms": 1000,
                        "duration_api_ms": 800,
                        "is_error": False,
                        "num_turns": 1,
                        "session_id": "test",
                        "total_cost_usd": 0.001,
                    }

                mock_transport.receive_messages = mock_receive

                async with ClaudeSDKClient() as client:
                    # Test list comprehension pattern from docstring
                    messages = [msg async for msg in client.receive_response()]

                    assert len(messages) == 3
                    assert all(
                        isinstance(msg, AssistantMessage | ResultMessage)
                        for msg in messages
                    )
                    assert isinstance(messages[-1], ResultMessage)

        anyio.run(_test)


=== File: tests/test_subprocess_buffering.py ===
"""Tests for subprocess transport buffering edge cases."""

import json
from collections.abc import AsyncIterator
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import anyio
import pytest

from claude_code_sdk._errors import CLIJSONDecodeError
from claude_code_sdk._internal.transport.subprocess_cli import (
    _MAX_BUFFER_SIZE,
    SubprocessCLITransport,
)
from claude_code_sdk.types import ClaudeCodeOptions


class MockTextReceiveStream:
    """Mock TextReceiveStream for testing."""

    def __init__(self, lines: list[str]) -> None:
        self.lines = lines
        self.index = 0

    def __aiter__(self) -> AsyncIterator[str]:
        return self

    async def __anext__(self) -> str:
        if self.index >= len(self.lines):
            raise StopAsyncIteration
        line = self.lines[self.index]
        self.index += 1
        return line


class TestSubprocessBuffering:
    """Test subprocess transport handling of buffered output."""

    def test_multiple_json_objects_on_single_line(self) -> None:
        """Test parsing when multiple JSON objects are concatenated on a single line.

        In some environments, stdout buffering can cause multiple distinct JSON
        objects to be delivered as a single line with embedded newlines.
        """

        async def _test() -> None:
            json_obj1 = {"type": "message", "id": "msg1", "content": "First message"}
            json_obj2 = {"type": "result", "id": "res1", "status": "completed"}

            buffered_line = json.dumps(json_obj1) + "\n" + json.dumps(json_obj2)

            transport = SubprocessCLITransport(
                prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
            )

            mock_process = MagicMock()
            mock_process.returncode = None
            mock_process.wait = AsyncMock(return_value=None)
            transport._process = mock_process

            transport._stdout_stream = MockTextReceiveStream([buffered_line])  # type: ignore[assignment]
            transport._stderr_stream = MockTextReceiveStream([])  # type: ignore[assignment]

            messages: list[Any] = []
            async for msg in transport.receive_messages():
                messages.append(msg)

            assert len(messages) == 2
            assert messages[0]["type"] == "message"
            assert messages[0]["id"] == "msg1"
            assert messages[0]["content"] == "First message"
            assert messages[1]["type"] == "result"
            assert messages[1]["id"] == "res1"
            assert messages[1]["status"] == "completed"

        anyio.run(_test)

    def test_json_with_embedded_newlines(self) -> None:
        """Test parsing JSON objects that contain newline characters in string values."""

        async def _test() -> None:
            json_obj1 = {"type": "message", "content": "Line 1\nLine 2\nLine 3"}
            json_obj2 = {"type": "result", "data": "Some\nMultiline\nContent"}

            buffered_line = json.dumps(json_obj1) + "\n" + json.dumps(json_obj2)

            transport = SubprocessCLITransport(
                prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
            )

            mock_process = MagicMock()
            mock_process.returncode = None
            mock_process.wait = AsyncMock(return_value=None)
            transport._process = mock_process
            transport._stdout_stream = MockTextReceiveStream([buffered_line])
            transport._stderr_stream = MockTextReceiveStream([])

            messages: list[Any] = []
            async for msg in transport.receive_messages():
                messages.append(msg)

            assert len(messages) == 2
            assert messages[0]["content"] == "Line 1\nLine 2\nLine 3"
            assert messages[1]["data"] == "Some\nMultiline\nContent"

        anyio.run(_test)

    def test_multiple_newlines_between_objects(self) -> None:
        """Test parsing with multiple newlines between JSON objects."""

        async def _test() -> None:
            json_obj1 = {"type": "message", "id": "msg1"}
            json_obj2 = {"type": "result", "id": "res1"}

            buffered_line = json.dumps(json_obj1) + "\n\n\n" + json.dumps(json_obj2)

            transport = SubprocessCLITransport(
                prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
            )

            mock_process = MagicMock()
            mock_process.returncode = None
            mock_process.wait = AsyncMock(return_value=None)
            transport._process = mock_process
            transport._stdout_stream = MockTextReceiveStream([buffered_line])
            transport._stderr_stream = MockTextReceiveStream([])

            messages: list[Any] = []
            async for msg in transport.receive_messages():
                messages.append(msg)

            assert len(messages) == 2
            assert messages[0]["id"] == "msg1"
            assert messages[1]["id"] == "res1"

        anyio.run(_test)

    def test_split_json_across_multiple_reads(self) -> None:
        """Test parsing when a single JSON object is split across multiple stream reads."""

        async def _test() -> None:
            json_obj = {
                "type": "assistant",
                "message": {
                    "content": [
                        {"type": "text", "text": "x" * 1000},
                        {
                            "type": "tool_use",
                            "id": "tool_123",
                            "name": "Read",
                            "input": {"file_path": "/test.txt"},
                        },
                    ]
                },
            }

            complete_json = json.dumps(json_obj)

            part1 = complete_json[:100]
            part2 = complete_json[100:250]
            part3 = complete_json[250:]

            transport = SubprocessCLITransport(
                prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
            )

            mock_process = MagicMock()
            mock_process.returncode = None
            mock_process.wait = AsyncMock(return_value=None)
            transport._process = mock_process
            transport._stdout_stream = MockTextReceiveStream([part1, part2, part3])
            transport._stderr_stream = MockTextReceiveStream([])

            messages: list[Any] = []
            async for msg in transport.receive_messages():
                messages.append(msg)

            assert len(messages) == 1
            assert messages[0]["type"] == "assistant"
            assert len(messages[0]["message"]["content"]) == 2

        anyio.run(_test)

    def test_large_minified_json(self) -> None:
        """Test parsing a large minified JSON (simulating the reported issue)."""

        async def _test() -> None:
            large_data = {"data": [{"id": i, "value": "x" * 100} for i in range(1000)]}
            json_obj = {
                "type": "user",
                "message": {
                    "role": "user",
                    "content": [
                        {
                            "tool_use_id": "toolu_016fed1NhiaMLqnEvrj5NUaj",
                            "type": "tool_result",
                            "content": json.dumps(large_data),
                        }
                    ],
                },
            }

            complete_json = json.dumps(json_obj)

            chunk_size = 64 * 1024
            chunks = [
                complete_json[i : i + chunk_size]
                for i in range(0, len(complete_json), chunk_size)
            ]

            transport = SubprocessCLITransport(
                prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
            )

            mock_process = MagicMock()
            mock_process.returncode = None
            mock_process.wait = AsyncMock(return_value=None)
            transport._process = mock_process
            transport._stdout_stream = MockTextReceiveStream(chunks)
            transport._stderr_stream = MockTextReceiveStream([])

            messages: list[Any] = []
            async for msg in transport.receive_messages():
                messages.append(msg)

            assert len(messages) == 1
            assert messages[0]["type"] == "user"
            assert (
                messages[0]["message"]["content"][0]["tool_use_id"]
                == "toolu_016fed1NhiaMLqnEvrj5NUaj"
            )

        anyio.run(_test)

    def test_buffer_size_exceeded(self) -> None:
        """Test that exceeding buffer size raises an appropriate error."""

        async def _test() -> None:
            huge_incomplete = '{"data": "' + "x" * (_MAX_BUFFER_SIZE + 1000)

            transport = SubprocessCLITransport(
                prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
            )

            mock_process = MagicMock()
            mock_process.returncode = None
            mock_process.wait = AsyncMock(return_value=None)
            transport._process = mock_process
            transport._stdout_stream = MockTextReceiveStream([huge_incomplete])
            transport._stderr_stream = MockTextReceiveStream([])

            with pytest.raises(Exception) as exc_info:
                messages: list[Any] = []
                async for msg in transport.receive_messages():
                    messages.append(msg)

            assert isinstance(exc_info.value, CLIJSONDecodeError)
            assert "exceeded maximum buffer size" in str(exc_info.value)

        anyio.run(_test)

    def test_mixed_complete_and_split_json(self) -> None:
        """Test handling a mix of complete and split JSON messages."""

        async def _test() -> None:
            msg1 = json.dumps({"type": "system", "subtype": "start"})

            large_msg = {
                "type": "assistant",
                "message": {"content": [{"type": "text", "text": "y" * 5000}]},
            }
            large_json = json.dumps(large_msg)

            msg3 = json.dumps({"type": "system", "subtype": "end"})

            lines = [
                msg1 + "\n",
                large_json[:1000],
                large_json[1000:3000],
                large_json[3000:] + "\n" + msg3,
            ]

            transport = SubprocessCLITransport(
                prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
            )

            mock_process = MagicMock()
            mock_process.returncode = None
            mock_process.wait = AsyncMock(return_value=None)
            transport._process = mock_process
            transport._stdout_stream = MockTextReceiveStream(lines)
            transport._stderr_stream = MockTextReceiveStream([])

            messages: list[Any] = []
            async for msg in transport.receive_messages():
                messages.append(msg)

            assert len(messages) == 3
            assert messages[0]["type"] == "system"
            assert messages[0]["subtype"] == "start"
            assert messages[1]["type"] == "assistant"
            assert len(messages[1]["message"]["content"][0]["text"]) == 5000
            assert messages[2]["type"] == "system"
            assert messages[2]["subtype"] == "end"

        anyio.run(_test)


=== File: tests/test_transport.py ===
"""Tests for Claude SDK transport layer."""

from unittest.mock import AsyncMock, MagicMock, patch

import anyio
import pytest

from claude_code_sdk._internal.transport.subprocess_cli import SubprocessCLITransport
from claude_code_sdk.types import ClaudeCodeOptions


class TestSubprocessCLITransport:
    """Test subprocess transport implementation."""

    def test_find_cli_not_found(self):
        """Test CLI not found error."""
        from claude_code_sdk._errors import CLINotFoundError

        with (
            patch("shutil.which", return_value=None),
            patch("pathlib.Path.exists", return_value=False),
            pytest.raises(CLINotFoundError) as exc_info,
        ):
            SubprocessCLITransport(prompt="test", options=ClaudeCodeOptions())

        assert "Claude Code requires Node.js" in str(exc_info.value)

    def test_build_command_basic(self):
        """Test building basic CLI command."""
        transport = SubprocessCLITransport(
            prompt="Hello", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
        )

        cmd = transport._build_command()
        assert cmd[0] == "/usr/bin/claude"
        assert "--output-format" in cmd
        assert "stream-json" in cmd
        assert "--print" in cmd
        assert "Hello" in cmd

    def test_cli_path_accepts_pathlib_path(self):
        """Test that cli_path accepts pathlib.Path objects."""
        from pathlib import Path

        transport = SubprocessCLITransport(
            prompt="Hello",
            options=ClaudeCodeOptions(),
            cli_path=Path("/usr/bin/claude"),
        )

        assert transport._cli_path == "/usr/bin/claude"

    def test_build_command_with_options(self):
        """Test building CLI command with options."""
        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(
                system_prompt="Be helpful",
                allowed_tools=["Read", "Write"],
                disallowed_tools=["Bash"],
                model="claude-3-5-sonnet",
                permission_mode="acceptEdits",
                max_turns=5,
            ),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        assert "--system-prompt" in cmd
        assert "Be helpful" in cmd
        assert "--allowedTools" in cmd
        assert "Read,Write" in cmd
        assert "--disallowedTools" in cmd
        assert "Bash" in cmd
        assert "--model" in cmd
        assert "claude-3-5-sonnet" in cmd
        assert "--permission-mode" in cmd
        assert "acceptEdits" in cmd
        assert "--max-turns" in cmd
        assert "5" in cmd

    def test_build_command_with_add_dirs(self):
        """Test building CLI command with add_dirs option."""
        from pathlib import Path

        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(
                add_dirs=["/path/to/dir1", Path("/path/to/dir2")]
            ),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        cmd_str = " ".join(cmd)

        # Check that the command string contains the expected --add-dir flags
        assert "--add-dir /path/to/dir1 --add-dir /path/to/dir2" in cmd_str

    def test_session_continuation(self):
        """Test session continuation options."""
        transport = SubprocessCLITransport(
            prompt="Continue from before",
            options=ClaudeCodeOptions(continue_conversation=True, resume="session-123"),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        assert "--continue" in cmd
        assert "--resume" in cmd
        assert "session-123" in cmd

    def test_connect_disconnect(self):
        """Test connect and disconnect lifecycle."""

        async def _test():
            with patch("anyio.open_process") as mock_exec:
                mock_process = MagicMock()
                mock_process.returncode = None
                mock_process.terminate = MagicMock()
                mock_process.wait = AsyncMock()
                mock_process.stdout = MagicMock()
                mock_process.stderr = MagicMock()

                # Mock stdin with aclose method
                mock_stdin = MagicMock()
                mock_stdin.aclose = AsyncMock()
                mock_process.stdin = mock_stdin

                mock_exec.return_value = mock_process

                transport = SubprocessCLITransport(
                    prompt="test",
                    options=ClaudeCodeOptions(),
                    cli_path="/usr/bin/claude",
                )

                await transport.connect()
                assert transport._process is not None
                assert transport.is_connected()

                await transport.disconnect()
                mock_process.terminate.assert_called_once()

        anyio.run(_test)

    def test_receive_messages(self):
        """Test parsing messages from CLI output."""
        # This test is simplified to just test the parsing logic
        # The full async stream handling is tested in integration tests
        transport = SubprocessCLITransport(
            prompt="test", options=ClaudeCodeOptions(), cli_path="/usr/bin/claude"
        )

        # The actual message parsing is done by the client, not the transport
        # So we just verify the transport can be created and basic structure is correct
        assert transport._prompt == "test"
        assert transport._cli_path == "/usr/bin/claude"

    def test_connect_with_nonexistent_cwd(self):
        """Test that connect raises CLIConnectionError when cwd doesn't exist."""
        from claude_code_sdk._errors import CLIConnectionError

        async def _test():
            transport = SubprocessCLITransport(
                prompt="test",
                options=ClaudeCodeOptions(cwd="/this/directory/does/not/exist"),
                cli_path="/usr/bin/claude",
            )

            with pytest.raises(CLIConnectionError) as exc_info:
                await transport.connect()

            assert "/this/directory/does/not/exist" in str(exc_info.value)

        anyio.run(_test)

    def test_build_command_with_settings_file(self):
        """Test building CLI command with settings as file path."""
        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(settings="/path/to/settings.json"),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        assert "--settings" in cmd
        assert "/path/to/settings.json" in cmd

    def test_build_command_with_settings_json(self):
        """Test building CLI command with settings as JSON object."""
        settings_json = '{"permissions": {"allow": ["Bash(ls:*)"]}}'
        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(settings=settings_json),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        assert "--settings" in cmd
        assert settings_json in cmd

    def test_build_command_with_extra_args(self):
        """Test building CLI command with extra_args for future flags."""
        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(
                extra_args={
                    "new-flag": "value",
                    "boolean-flag": None,
                    "another-option": "test-value",
                }
            ),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        cmd_str = " ".join(cmd)

        # Check flags with values
        assert "--new-flag value" in cmd_str
        assert "--another-option test-value" in cmd_str

        # Check boolean flag (no value)
        assert "--boolean-flag" in cmd
        # Make sure boolean flag doesn't have a value after it
        boolean_idx = cmd.index("--boolean-flag")
        # Either it's the last element or the next element is another flag
        assert boolean_idx == len(cmd) - 1 or cmd[boolean_idx + 1].startswith("--")

    def test_build_command_with_mcp_servers(self):
        """Test building CLI command with mcp_servers option."""
        import json

        mcp_servers = {
            "test-server": {
                "type": "stdio",
                "command": "/path/to/server",
                "args": ["--option", "value"],
            }
        }

        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(mcp_servers=mcp_servers),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()

        # Find the --mcp-config flag and its value
        assert "--mcp-config" in cmd
        mcp_idx = cmd.index("--mcp-config")
        mcp_config_value = cmd[mcp_idx + 1]

        # Parse the JSON and verify structure
        config = json.loads(mcp_config_value)
        assert "mcpServers" in config
        assert config["mcpServers"] == mcp_servers

    def test_build_command_with_mcp_servers_as_file_path(self):
        """Test building CLI command with mcp_servers as file path."""
        from pathlib import Path

        # Test with string path
        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(mcp_servers="/path/to/mcp-config.json"),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        assert "--mcp-config" in cmd
        mcp_idx = cmd.index("--mcp-config")
        assert cmd[mcp_idx + 1] == "/path/to/mcp-config.json"

        # Test with Path object
        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(mcp_servers=Path("/path/to/mcp-config.json")),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        assert "--mcp-config" in cmd
        mcp_idx = cmd.index("--mcp-config")
        assert cmd[mcp_idx + 1] == "/path/to/mcp-config.json"

    def test_build_command_with_mcp_servers_as_json_string(self):
        """Test building CLI command with mcp_servers as JSON string."""
        json_config = '{"mcpServers": {"server": {"type": "stdio", "command": "test"}}}'
        transport = SubprocessCLITransport(
            prompt="test",
            options=ClaudeCodeOptions(mcp_servers=json_config),
            cli_path="/usr/bin/claude",
        )

        cmd = transport._build_command()
        assert "--mcp-config" in cmd
        mcp_idx = cmd.index("--mcp-config")
        assert cmd[mcp_idx + 1] == json_config


=== File: tests/test_types.py ===
"""Tests for Claude SDK type definitions."""

from claude_code_sdk import (
    AssistantMessage,
    ClaudeCodeOptions,
    ResultMessage,
)
from claude_code_sdk.types import (
    TextBlock,
    ThinkingBlock,
    ToolResultBlock,
    ToolUseBlock,
    UserMessage,
)


class TestMessageTypes:
    """Test message type creation and validation."""

    def test_user_message_creation(self):
        """Test creating a UserMessage."""
        msg = UserMessage(content="Hello, Claude!")
        assert msg.content == "Hello, Claude!"

    def test_assistant_message_with_text(self):
        """Test creating an AssistantMessage with text content."""
        text_block = TextBlock(text="Hello, human!")
        msg = AssistantMessage(content=[text_block], model="claude-opus-4-1-20250805")
        assert len(msg.content) == 1
        assert msg.content[0].text == "Hello, human!"

    def test_assistant_message_with_thinking(self):
        """Test creating an AssistantMessage with thinking content."""
        thinking_block = ThinkingBlock(thinking="I'm thinking...", signature="sig-123")
        msg = AssistantMessage(
            content=[thinking_block], model="claude-opus-4-1-20250805"
        )
        assert len(msg.content) == 1
        assert msg.content[0].thinking == "I'm thinking..."
        assert msg.content[0].signature == "sig-123"

    def test_tool_use_block(self):
        """Test creating a ToolUseBlock."""
        block = ToolUseBlock(
            id="tool-123", name="Read", input={"file_path": "/test.txt"}
        )
        assert block.id == "tool-123"
        assert block.name == "Read"
        assert block.input["file_path"] == "/test.txt"

    def test_tool_result_block(self):
        """Test creating a ToolResultBlock."""
        block = ToolResultBlock(
            tool_use_id="tool-123", content="File contents here", is_error=False
        )
        assert block.tool_use_id == "tool-123"
        assert block.content == "File contents here"
        assert block.is_error is False

    def test_result_message(self):
        """Test creating a ResultMessage."""
        msg = ResultMessage(
            subtype="success",
            duration_ms=1500,
            duration_api_ms=1200,
            is_error=False,
            num_turns=1,
            session_id="session-123",
            total_cost_usd=0.01,
        )
        assert msg.subtype == "success"
        assert msg.total_cost_usd == 0.01
        assert msg.session_id == "session-123"


class TestOptions:
    """Test Options configuration."""

    def test_default_options(self):
        """Test Options with default values."""
        options = ClaudeCodeOptions()
        assert options.allowed_tools == []
        assert options.max_thinking_tokens == 8000
        assert options.system_prompt is None
        assert options.permission_mode is None
        assert options.continue_conversation is False
        assert options.disallowed_tools == []

    def test_claude_code_options_with_tools(self):
        """Test Options with built-in tools."""
        options = ClaudeCodeOptions(
            allowed_tools=["Read", "Write", "Edit"], disallowed_tools=["Bash"]
        )
        assert options.allowed_tools == ["Read", "Write", "Edit"]
        assert options.disallowed_tools == ["Bash"]

    def test_claude_code_options_with_permission_mode(self):
        """Test Options with permission mode."""
        options = ClaudeCodeOptions(permission_mode="bypassPermissions")
        assert options.permission_mode == "bypassPermissions"

        options_plan = ClaudeCodeOptions(permission_mode="plan")
        assert options_plan.permission_mode == "plan"

        options_default = ClaudeCodeOptions(permission_mode="default")
        assert options_default.permission_mode == "default"

        options_accept = ClaudeCodeOptions(permission_mode="acceptEdits")
        assert options_accept.permission_mode == "acceptEdits"

    def test_claude_code_options_with_system_prompt(self):
        """Test Options with system prompt."""
        options = ClaudeCodeOptions(
            system_prompt="You are a helpful assistant.",
            append_system_prompt="Be concise.",
        )
        assert options.system_prompt == "You are a helpful assistant."
        assert options.append_system_prompt == "Be concise."

    def test_claude_code_options_with_session_continuation(self):
        """Test Options with session continuation."""
        options = ClaudeCodeOptions(continue_conversation=True, resume="session-123")
        assert options.continue_conversation is True
        assert options.resume == "session-123"

    def test_claude_code_options_with_model_specification(self):
        """Test Options with model specification."""
        options = ClaudeCodeOptions(
            model="claude-3-5-sonnet-20241022", permission_prompt_tool_name="CustomTool"
        )
        assert options.model == "claude-3-5-sonnet-20241022"
        assert options.permission_prompt_tool_name == "CustomTool"

