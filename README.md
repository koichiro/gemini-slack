# Gemini Slack Notifier

A Ruby-based CLI tool that bridges Google Cloud Vertex AI (Gemini) and Slack. It provides an interactive terminal interface for chatting with Gemini, while automatically mirroring the conversation to Slack.

## Features

- **Interactive CLI**: Real-time chat with Gemini via terminal.
- **Slack Integration**: Every question starts a **new Slack thread**, and the response is posted as a reply within that thread.
- **Environment Driven**: Easily configured via `.env` file.
- **Tested & Covered**: Includes a comprehensive test suite with >80% code coverage.

## Prerequisites

- Ruby 3.0 or higher.
- A Google Cloud Project with Vertex AI API enabled.
- A Slack Bot Token with `chat:write` permissions.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/gemini-slack.git
   cd gemini-slack
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup environment variables:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and fill in your credentials.

## Usage

Start the interactive CLI:
```bash
ruby main.rb
```

Type your prompt and press Enter. The conversation will be mirrored to your specified Slack channel in a threaded format. Type `exit` or `quit` to end the session.

## Development

### Running Tests
We use Minitest and Mocha for testing. To run the test suite:
```bash
bundle exec rake
```

### Coverage
Code coverage reports are generated automatically in the `coverage/` directory after running tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
