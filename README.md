# 🚀 Claude Code Project Template

> **Transform your ideas into reality 10x faster—while keeping your unique creative vision.**

This isn't just another project template. It's a complete AI-first development environment that amplifies your capabilities while preserving what makes your work uniquely yours.

## ✨ What if you could...

- 🔔 **Never break flow** with desktop notifications when AI needs input
- ✅ **Stop thinking about quality** with automated checks on every change
- 🧠 **Code your way** with philosophy-driven development built-in
- 📚 **Feed AI perfectly** with smart context management tools
- ⚡ **Start building in 5 minutes** instead of setting up for hours

**You can. Starting right now.**

## 🎬 See It In Action

```bash
# 1. Clone this template
git clone https://github.com/[your-username]/claude-code-project-template my-next-big-idea
cd my-next-big-idea

# 2. Make it yours
rm -rf .git && git init
git add . && git commit -m "Initial commit from template"

# 3. In Claude Code, run:
/prime

# 4. Start building!
/ultrathink-task Help me build a web app that [your amazing idea here]
```

**That's it.** You're now developing at AI velocity with human creativity.

## 🎯 Who This Is For

### 🎨 **Product Managers & Designers**
Finally, you can prototype as fast as you can imagine. Natural language to working code in minutes.

### 👩‍💻 **Engineers**
Stop context switching. Automated quality checks and smart notifications keep you in deep work.

### 🏗️ **Architects**
Build platforms, not just projects. Your expertise becomes your team's capability.

### 🚀 **Startups & Innovators**
Move at the speed of thought. Test ideas in hours, not weeks.

## 💎 What Makes This Special

### 🔔 **Desktop Notifications That Keep You In Flow**
Never check your terminal again. Get native notifications when:
- Claude Code needs permission to proceed
- Tasks complete successfully
- Errors need your attention

Works seamlessly on Mac, Linux, Windows, and WSL.

### 🤖 **Multi-Agent Problem Solving**
The `/ultrathink-task` command orchestrates specialized AI agents:
- **Architect Agent**: Designs high-level approach
- **Research Agent**: Gathers knowledge and best practices
- **Coder Agent**: Implements solutions
- **Tester Agent**: Validates and verifies

Complex problems solved systematically, every time.

### ✅ **Automated Quality, Zero Friction**
Every code change triggers quality checks automatically:
- Formatting fixed
- Linting applied
- Type checking run
- Tests executed

You focus on creating. Quality happens automatically.

### 🧠 **Philosophy-Driven Development**
Your development principles embedded in every interaction:
- **Simplicity First**: Clean, maintainable code by default
- **Human-Centric**: AI amplifies, never replaces your creativity
- **Pragmatic Choices**: Real-world solutions, not academic exercises

### 📚 **Smart Context Management**
Feed AI the right information at the right time:
- `ai_context/` - Store persistent reference docs
- `ai_working/` - Workspace for AI planning and iteration
- Auto-generate project documentation
- Fetch external library docs on demand

### 🛠️ **Production-Ready Setup**
- Python/TypeScript pre-configured with modern tools
- Recursive Make system for monorepos
- Git-ignored temp spaces for experimentation
- Cross-platform compatibility guaranteed

## 📦 Complete Feature List

### **AI Amplification**
- ✅ `/ultrathink-task` - Multi-agent orchestration for complex problems
- ✅ `/prime` - Philosophy-aligned environment setup
- ✅ `/test-webapp-ui` - Automated UI testing with browser control
- ✅ MCP Servers - Extended capabilities (docs lookup, browser automation)
- ✅ Custom command framework - Build your own workflows

### **Developer Experience**
- ✅ Desktop notifications - Stay in flow (all platforms)
- ✅ Auto quality checks - Format, lint, type-check automatically
- ✅ Smart Make system - Works with monorepos
- ✅ Pre-configured permissions - Security with productivity
- ✅ Philosophy documents - Guide AI to code your way

### **Context & Workspace**
- ✅ AI context tools - Generate and manage documentation
- ✅ Git collector - Fetch external library docs
- ✅ Working spaces - Persistent and temporary AI workspaces
- ✅ File collectors - Smart project documentation generation

## 🚀 Quick Start Guide

### Prerequisites
- [Claude Code](https://claude.ai/code) installed
- Python 3.11+ or Node.js 18+
- Git

### 1. Create Your Project

```bash
# Clone the template
git clone https://github.com/[your-username]/claude-code-project-template my-project
cd my-project

# Make it yours
rm -rf .git
git init
git add .
git commit -m "Initial commit from Claude Code template"
```

### 2. First Claude Code Session

```
# In Claude Code, run:
/prime

# This will:
# - Install all dependencies
# - Activate your environment
# - Load philosophy documents
# - Run initial checks
# - Confirm everything works
```

### 3. Try Your First Task

```
/ultrathink-task Create a simple web API that:
- Has a health check endpoint
- Stores data in memory
- Returns JSON responses
- Includes proper error handling
- Has tests

Follow our philosophy of simplicity and pragmatism.
```

Watch as multiple AI agents collaborate to build your API with tests, error handling, and documentation.

### 4. Experience the Flow

Make any code change and watch:
- 🔔 Desktop notification when complete
- ✅ Automatic quality checks run
- 📝 Clear feedback in your terminal
- 🎯 Stay focused on your next idea

## 📖 User Guides

### 🎨 For Product Managers

**Your New Superpower: Prototype at the Speed of Thought**

```
/ultrathink-task I need a dashboard that shows:
- User growth over time with a nice chart
- Current active users in real-time
- Revenue metrics with month-over-month change
- Mobile responsive design
- Export to PDF functionality

Make it look professional but keep it simple.
```

**What Happens Next:**
1. Architect designs the component structure
2. Research finds best charting libraries
3. Coder implements with your requirements
4. Tester ensures it all works
5. You get a working dashboard in minutes

**Pro Tips:**
- Drop mockups in `ai_working/` for reference
- Use `/test-webapp-ui` to see it in action
- Iterate with natural language: "Make the charts bigger"

### 👩‍💻 For Engineers

**Your New Reality: Deep Work Without Interruptions**

```bash
# Set up context for your feature
echo "API Schema: ..." > ai_context/api-spec.md
echo "Database Models: ..." > ai_context/models.md

# Let AI help with implementation
/ultrathink-task Implement the user authentication system based on:
@ai_context/api-spec.md
@ai_context/models.md

Use JWT tokens, include refresh logic, and add rate limiting.
```

**Automation That Backs You Up:**
- Every save triggers quality checks
- Desktop notifications for important events
- Philosophy guides ensure consistent code style
- Context persistence across sessions

**Level Up Your Workflow:**
1. Create custom commands for repetitive tasks
2. Add project-specific hooks for your stack
3. Share configs with your team via Git

### 🏗️ For Architects

**Your New Platform: Scalable AI-Assisted Development**

```bash
# Create team-wide commands
cat > .claude/commands/create-microservice.md << 'EOF'
## Usage
`/create-microservice <service-name>`

## Process
1. Create service directory structure
2. Set up Docker configuration
3. Create base API with health checks
4. Set up testing framework
5. Add to docker-compose
6. Create README with setup instructions
EOF

# Share with your team
git add .claude/
git commit -m "Add team microservice generator"
git push
```

**Build Your Platform:**
- Encode architectural decisions in commands
- Automate compliance and standards
- Share expertise through configuration
- Scale your impact across teams

## 🧠 The Philosophy

This template embodies a philosophy of **"Human Creativity, AI Velocity"**:

### Core Principles

1. **You Are The Visionary**
   - AI handles implementation details
   - You focus on what to build, not how
   - Your creativity remains uniquely yours

2. **Philosophy Over Process**
   - Principles guide every decision
   - Simplicity beats complexity
   - Pragmatism over perfection

3. **Flow State Is Sacred**
   - No unnecessary interruptions
   - Automation handles the mundane
   - Notifications only when essential

4. **Built To Share**
   - Your setup helps your team
   - Knowledge embedded in tools
   - Success patterns spread naturally

Read more in [Philosophy Deep Dive](.claude/docs/philosophy.md)

## 🎯 Real-World Usage Patterns

### Starting a New Feature
```bash
# 1. Set up context
mkdir -p ai_working/feature-x
echo "Feature requirements..." > ai_working/feature-x/spec.md

# 2. Prime your environment
/prime

# 3. Build with guidance
/ultrathink-task Implement feature X based on @ai_working/feature-x/spec.md
```

### Debugging Complex Issues
```bash
# 1. Capture the problem
echo "Error details..." > ai_working/tmp/debug-notes.md

# 2. Analyze systematically
/ultrathink-task Debug this issue:
- Error: [paste error]
- Context: @ai_working/tmp/debug-notes.md
- Check our patterns in @ai_context/IMPLEMENTATION_PHILOSOPHY.md
```

### Building UI Components
```bash
# 1. Describe what you want
/ultrathink-task Create a data table component that:
- Handles large datasets efficiently
- Has sorting and filtering
- Exports to CSV
- Looks good on mobile

# 2. Test it immediately
/test-webapp-ui

# 3. Iterate quickly
Actually, add pagination and make the rows clickable
```

## 🔧 Customization

### Add Your Philosophy
1. Edit `ai_context/IMPLEMENTATION_PHILOSOPHY.md`
2. Add domain-specific principles
3. Include coding standards
4. Document decision patterns

### Create Custom Commands
```bash
# Create .claude/commands/your-command.md
# See existing commands for examples
```

### Configure Notifications
- Edit `.claude/tools/notify.sh` for custom messages
- Adjust notification triggers in settings
- Add sound alerts if desired

### Extend Automation
```json
// In .claude/settings.json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "YourCustomTool",
      "hooks": [{"command": "your-script.sh"}]
    }]
  }
}
```

## 🤝 Contributing

This template is meant to evolve with community input:

1. **Share Your Commands**: Created an awesome command? PR it!
2. **Improve Notifications**: Make them work better on your platform
3. **Add Stack Support**: Python/TypeScript are first, what's next?
4. **Document Patterns**: Share what works for you

See [Contributing Guide](CONTRIBUTING.md)

## 📚 Learn More

### Deep Dives
- [Command Reference](.claude/docs/commands.md) - All commands explained
- [Automation Guide](.claude/docs/automation.md) - Hooks and quality checks
- [Context Management](.claude/docs/ai-context.md) - Feeding AI effectively
- [Team Scaling](.claude/docs/team-guide.md) - Share with your team
- [Philosophy Guide](.claude/docs/philosophy.md) - Why this approach works

### Get Help
- [Troubleshooting](.claude/docs/troubleshooting.md)
- [Discord Community](https://discord.gg/claude-code-template)
- [GitHub Discussions](https://github.com/[username]/claude-code-project-template/discussions)

## 🌟 Success Stories

> "I prototyped our entire MVP in a weekend. What used to take months now takes days." - Startup Founder

> "The desktop notifications changed everything. I stay in flow for hours." - Senior Engineer

> "My team adopted this and our velocity doubled. Same developers, amplified output." - Tech Lead

## 🚀 Start Your Journey

You're 5 minutes away from developing at a new level. Your creativity, amplified by AI, guided by philosophy, and backed by automation.

**The future of development isn't about AI replacing developers.**
**It's about developers achieving what was previously impossible.**

Welcome to AI-amplified development. Let's build something amazing.

---

<p align="center">
Made with ❤️ by developers, for developers<br>
Star this repo if it helps you build faster
</p>