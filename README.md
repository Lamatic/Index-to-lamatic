# Webhook Action Lamatic Index Flow

This GitHub Action detects changes to specified file types in your repository and sends the file content to a webhook. It’s ideal for scenarios where you need to synchronize or process modified files with an external service.

## 📌 Features

- **File Change Detection**: Monitors specific file types (e.g., `.mdx`, `.json`) and detects newly added or modified files.
- **Webhook Integration**: Sends file content to a specified webhook URL with an authorization key.
- **Configurable**: Easily specify the file type you want to track.

## 🚀 Usage

### Prerequisites

1. **Webhook URL** and **Webhook Key**: Obtain the webhook URL from lamatic Flow, read [this doc](https://lamatic.ai/docs/interface/webhooks) on how to build a flow with webhooks as a trigger or use this [template](https://hub.lamatic.ai/templates/index-from-github) . 
2. **GitHub Secrets**: Store sensitive data such as `WEBHOOK_URL` and `WEBHOOK_KEY` in your repository secrets.

### Workflow Example

To use this action, add the following YAML to a GitHub Actions workflow file, such as `.github/workflows/lamatic-index-flow.yml`:

```yaml
name: Lamatic Index Flow

on:
  push:
    branches:
      - main  # Replace with your branch if necessary
    paths: 
      - '**.mdx'  # Adjust to only trigger for changes to specific file types

jobs:
  send-changes:
    runs-on: ubuntu-latest
    
    steps:
    - name: Send File Changes to Webhook
      uses: Lamatic/Index-to-lamatic@v1.6  # Uses action
      with:
        webhook_url: ${{ secrets.WEBHOOK_URL }}  # Replace with your secret
        webhook_key: ${{ secrets.WEBHOOK_KEY }}   # Replace with your secret
        github_ref: ${{ github.ref }}
        file_type: "mdx"  # Adjust the file type as needed
        mode: "incremental"  # or "full-refresh"
        verbose: "true"  # or "false"
```

### Inputs

| Input         | Description                                          | Required | Example                      |
|---------------|------------------------------------------------------|----------|------------------------------|
| `webhook_url` | The URL of the webhook to send data to               | Yes      | `https://example.com/webhook`|
| `webhook_key` | The authorization key for the webhook                | Yes      | `your_webhook_key`           |
| `github_ref`  | The GitHub reference (branch) to work with           | Yes      | `refs/heads/main`            |
| `file_type`   | The file extension to detect and send (e.g., `mdx`)  | Yes      | `mdx`                        |
| `mode`        | The mode to operate in: `full-refresh` to send all files, or `incremental` to send only new/modified from the last commit.  | Yes      | `incremental` or `full-refresh ` |    
| `verbose`     | Enable verbose output (true or false). Default -  False | No      | `True`                      |

### Example Scenarios

- **Monitor Markdown Files**: Set `file_type: "mdx"` to monitor changes in markdown files and send updates to a content management system.
- **Sync JSON Configurations**: Set `file_type: "json"` to detect and sync JSON configuration changes with an external service.

### Versioning

To use a specific version, reference it in your workflow like so:

```yaml
- uses: Lamatic/Index-to-lamatic@v1.6
```

## Changelog

### v1.6.0

- Initial release of `Webhook Action Lamatic Index Flow`.
- Supports monitoring and sending changes for specified file types.
- Integration with webhooks using URL and authorization key.

---

This Action introduces the core functionality of monitoring file changes and sending them to a webhook, making it ideal for keeping external services up to date with file modifications in your GitHub repository.
