# Multi Timer

**English** | [日本語](README.ja.md)

> [!IMPORTANT]
> **This portfolio project was developed with 100% of the implementation delegated to AI agents.**  
> The source code, tests, design documents, and development and distribution scripts were created by AI. It is not presented as evidence of code handwritten by the owner. Instead, it demonstrates the ability to define requirements and constraints for AI, validate its output, and turn that output into a working application.

A native macOS application for managing multiple countdown timers simultaneously.

## AI-Driven Development

### AI Used

- **Claude (Opus 4.7)**: The primary implementation agent. It followed detailed plans designed to work without relying on conversation history and progressed through each phase, including design, Swift implementation, testing, building, and distribution
- **OpenAI Codex**: Assisted with maintenance, reviews, documentation improvements, and validation while inspecting the repository directly and following its development rules

### Human and AI Responsibilities

| Human (Owner)                                                             | AI Agents                                                                      |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Defines the desired experience, requirements, priorities, and constraints | Creates design proposals, implementation plans, code, tests, and documentation |
| Resolves ambiguous requirements and trade-offs                            | Investigates existing specifications and presents options, impacts, and risks  |
| Verifies behavior on real hardware and accepts deliverables               | Runs builds and automated tests, then reports results and remaining issues     |
| Approves commits, merges, and releases                                    | Operates the repository only within explicitly authorized boundaries           |

Rather than issuing a single broad instruction to “build an app,” the project treats its [requirements, specifications, and design](docs/design-docs/README.md) as the source of truth, taking precedence over conversation history. The work was then divided into a [phase-based implementation plan](docs/plans/README.md) with explicit completion criteria. This allows work to resume from the same context even when the agent or conversation changes, reducing inconsistent decisions and ad hoc implementation.

### How the AI Was Controlled

- **Specification-driven control**: Expected behavior, out-of-scope items, dependency direction, and data formats were documented before implementation; the design documents take precedence when conflicts arise
- **Small completion units**: Work was divided into Core, persistence, Platform, UI, application assembly, and distribution, with each phase beginning only after the previous phase passed validation
- **Permission boundaries**: AI may not independently commit, push, open pull requests, or merge `dev` into `main`; explicit human direction and review are required
- **Visible progress**: Implementation tasks and test-case status are tracked in a [progress JSON file](docs/plans/progress-list.json), so incomplete or blocked work remains visible

### How Quality Was Assured

- **Testable architecture**: Pure logic is separated from the UI and OS integrations. Time, storage locations, notifications, and sound can be substituted so AI-generated implementations can be tested deterministically
- **Requirements-to-test traceability**: 73 test-case IDs covering time conversion, input clamping, state transitions, notification text, persistence, and other behavior are assigned to implementation phases; `swift build` and `swift test` are completion criteria
- **Machine-checked documentation**: `./scripts/agent-docs-check.sh` combines Prettier, markdownlint, textlint, shfmt, and ShellCheck to inspect AI-generated documentation and scripts
- **Final human verification**: UI behavior, notifications, sound, and window operations that are difficult to automate are accepted on real hardware using 11 black-box tests and 3 non-functional checks

See the [development workflow](docs/WORKFLOW.md) for operating rules and the [test strategy](docs/design-docs/60-testing/strategy.md) for the quality approach.

## Features

- Start, stop, reset, and clear up to 12 timers independently
- Edit each `HH:MM:SS` segment directly, up to `99:59:59`
- Set titles and add or remove individual timers
- Play a chime and show a macOS notification when a timer finishes
- Highlight completed timers in yellow and automatically restore their configured duration
- Save titles and configured durations automatically and restore them after relaunch
- Scale the UI and provide vertical scrolling based on the window size
- Distribute a Universal build for both Apple Silicon and Intel Macs

See the [functional requirements](docs/design-docs/10-requirements/functional.md) and [specification index](docs/design-docs/README.md) for detailed behavior.

## Requirements

- macOS 13 Ventura or later
- Xcode or Xcode Command Line Tools with Swift 5.9 or later for development

The application uses only standard macOS frameworks and does not perform network communication or telemetry.

## Installation

Open the distributed `Multi Timer-<version>-universal.dmg`, then drag `Multi Timer.app` into the `Applications` folder.

The current distribution is ad hoc signed, so macOS requires an approval step on first launch. See the [installation guide](docs/インストール手順.md) for detailed instructions, including checksum verification.

To receive notifications when timers finish, allow macOS notifications on first launch. Timers and chimes continue to work if notification permission is declined.

## Basic Usage

1. Click the hour, minute, or second value and enter a duration.
2. Edit the timer title if needed.
3. Click `Start` to begin the countdown.
4. Use `Stop`, `Reset`, or `Clear` to control the timer.

Use the `+` button at the bottom of the window to add a timer and the red `×` beside a title to remove one.

## Development

### Run the Application

From the repository root, run:

```bash
./scripts/run-dev.sh
```

This script creates a debug `.app` bundle and launches it as a normal macOS application. Running `swift run multi-timer` starts the executable directly, which may prevent the window from appearing in the foreground.

### Tests

```bash
swift test
```

Automated tests cover time conversion, state transitions, input normalization, persistence, and related logic. UI behavior, notifications, sound, and window operations are covered by the [black-box test guide](docs/design-docs/60-testing/blackbox-test-guide.md).

### Documentation Validation

Install the Node.js dependencies, `shfmt`, and `shellcheck` once:

```bash
npm install
brew install shfmt shellcheck
```

After modifying Markdown or related documentation, run the repository validation:

```bash
./scripts/agent-docs-check.sh
```

## Build and Distribution

To create the Universal application and DMG, run:

```bash
./scripts/build-app.sh
```

Artifacts are generated in `dist/`. The script builds release binaries for arm64 and x86_64, assembles the `.app`, applies an ad hoc signature, creates the DMG, and prints its SHA-256 checksum.

To increment the application version before building, specify the version component. Omitting the argument increments the patch version.

```bash
./scripts/patch-build.sh
./scripts/patch-build.sh minor
./scripts/patch-build.sh major
```

`patch-build.sh` updates the source file that owns the version, launches the application, and generates `dist/sha-256.txt`. See [Build, Signing, and Distribution](docs/design-docs/70-packaging/build-and-distribution.md) for the distribution policy.

## Project Structure

| Path                         | Responsibility                                                    |
| ---------------------------- | ----------------------------------------------------------------- |
| `Sources/MultiTimerCore/`    | Timer logic independent of UI and OS integrations                 |
| `Sources/MultiTimerStorage/` | JSON persistence                                                  |
| `Sources/MultiTimerApp/`     | SwiftUI, notifications, sound, and window control                 |
| `Tests/`                     | Core unit tests and Storage integration tests                     |
| `docs/design-docs/`          | Source of truth for requirements, design, tests, and distribution |
| `scripts/`                   | Development, validation, build, and DMG scripts                   |

See the [module structure](docs/design-docs/40-architecture/module-structure.md) for dependency direction and layer responsibilities.

## Data Storage

Timer titles and configured durations are stored in the following JSON file:

```text
~/Library/Application Support/multi-timer/timer.json
```

Remaining time, running state, and the yellow completed state are not persisted. If the saved JSON is corrupted, the application moves it aside in the same directory and starts with an empty state.

## Documentation

- [Design documentation index](docs/design-docs/README.md)
- [Development workflow](docs/WORKFLOW.md)
- [Documentation guide](docs/DOCUMENTATION_GUIDE.md)
- [Installation guide](docs/インストール手順.md)
