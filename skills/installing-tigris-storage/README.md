# Installing Tigris Storage

A Claude skill for setting up and configuring @tigrisdata/storage in new projects.

## About

Tigris Storage is a high-performance object storage system for multi-cloud environments. This skill guides through:

- Installing the @tigrisdata/storage package
- Creating Tigris account resources (buckets, access keys)
- Configuring environment variables
- Setting up authentication

## Installation

### Claude Code

```bash
cp -r skills/installing-tigris-storage ~/.claude/skills/
```

### claude.ai

Add the `SKILL.md` file to your project knowledge or paste its contents into the conversation.

## Usage

When you need to set up Tigris Storage in a project, trigger with:

- "Install Tigris Storage"
- "Setup object storage"
- "Configure @tigrisdata/storage"
- "Add Tigris to my project"

## Quick Start

```bash
# Install the package
npm install @tigrisdata/storage

# Set environment variables
TIGRIS_CLIENT_ID=your_client_id
TIGRIS_CLIENT_SECRET=your_client_secret
```

## Links

- **Sign up**: https://storage.new
- **Console**: https://console.tigris.dev
- **Create bucket**: https://console.tigris.dev/createbucket
- **Access keys**: https://console.tigris.dev/createaccesskey
- **Docs**: https://www.tigrisdata.com/docs

## License

MIT
