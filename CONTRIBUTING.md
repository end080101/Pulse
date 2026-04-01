# Contributing to Pulse

Thanks for your interest in contributing to Pulse.

## Development principles

- Preserve the existing Pulse UI direction unless a change is explicitly discussed
- Prefer small, reviewable pull requests
- Keep monitoring logic separate from SwiftUI views
- Avoid introducing privileged behavior without documenting the tradeoffs

## Local workflow

```bash
swift build
swift test
```

If you touch packaging or helper behavior, also verify:

```bash
./package.sh
```

## Code organization

- `Models/`: shared state and domain data
- `Monitoring/`: system metric collectors and helper integrations
- `Support/`: formatting and app metadata helpers
- `Resources/`: bundled assets

## Pull request checklist

- Build passes locally
- Tests pass locally
- New logic has tests where practical
- README is updated if behavior changes
- No unrelated cleanup is mixed into the change

## Reporting issues

When opening an issue, include:

- macOS version
- Mac model
- Pulse version
- Steps to reproduce
- Screenshot or screen recording if UI-related
