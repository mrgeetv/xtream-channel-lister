# Xtream Channel Lister

A comprehensive bash utility for browsing and listing live TV channels from Xtream Codes IPTV providers. Perfect for testing provider credentials, exploring available content, and troubleshooting IPTV setups.

## ✨ Features

- 📺 **Channel Browsing** - List all live TV channels organized by category
- 🔍 **Smart Filtering** - Filter categories by prefix, contains text, or both
- 🔒 **Secure Authentication** - Prompts for passwords (no plaintext in command history)
- 🛠️ **Robust Error Handling** - Comprehensive diagnostics for common IPTV issues
- ⚡ **Lightweight** - Zero dependencies except `curl` and `jq`
- 🌐 **Cross-Platform** - Works on Linux, macOS, WSL, and any Unix-like system
- 📊 **Detailed Output** - Channel counts, category organization, and verbose debugging

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/mrgeetv/xtream-channel-lister.git
cd xtream-channel-lister

# Make executable
chmod +x list-iptv-channels.sh

# List all channels (password will be prompted)
./list-iptv-channels.sh -H http://your-provider.com:8000 -u your_username
```

## 📋 Requirements

- `curl` - For API requests
- `jq` - For JSON parsing
- Bash 4.0+ - For script execution

**Install dependencies:**

```bash
# Ubuntu/Debian
sudo apt install curl jq

# macOS (with Homebrew)
brew install curl jq

# CentOS/RHEL/Fedora
sudo yum install curl jq
```

## 🎯 Usage Examples

### Basic Usage

```bash
# List all channels with password prompt
./list-iptv-channels.sh -H http://provider.com:8000 -u myusername
```

### Advanced Filtering

```bash
# PREFIX (-P): Show categories that START WITH specified text
./list-iptv-channels.sh -H http://provider.com:8000 -u myuser -P "US|"
# Matches: "US| Entertainment", "US| News", "US| Sports"
# Does NOT match: "Sports US" or "UK US Channels"

# CONTAINS (-c): Show categories that CONTAIN specified text anywhere
./list-iptv-channels.sh -H http://provider.com:8000 -u myuser -c "movie"
# Matches: "Movies HD", "24/7 Movies", "Action Movies", "UK Movies"

# COMBINED: Categories that START WITH "UK" AND CONTAIN "news"
./list-iptv-channels.sh -H http://provider.com:8000 -u myuser -P "UK" -c "news"
# Matches: "UK News HD", "UK Local News"
# Does NOT match: "UK Sports" or "International News"

# CASE-SENSITIVE: Exact case matching (default is case-insensitive)
./list-iptv-channels.sh -H http://provider.com:8000 -u myuser -P "USA" -s
# Matches: "USA Network" but NOT "usa today" or "Usa channels"
```

### Debugging & Troubleshooting

```bash
# Verbose output for debugging
./list-iptv-channels.sh -H http://provider.com:8000 -u myuser -v

# Custom timeout for slow providers
./list-iptv-channels.sh -H http://provider.com:8000 -u myuser -t 30
```

## 🎯 Understanding Category Filtering

### Prefix vs Contains Filtering

**Prefix Filtering (`-P`):**

- Matches categories that **begin** with your text
- Example: `-P "UK"` matches "UK Sports", "UK News", "UK Movies"
- Does NOT match: "Sports UK", "Best UK Channels"

**Contains Filtering (`-c`):**

- Matches categories that have your text **anywhere** in the name
- Example: `-c "HD"` matches "Movies HD", "HD Sports", "UK HD News"
- More inclusive than prefix filtering

**Combined Filtering:**

- Use both `-P` and `-c` together for precise control
- Example: `-P "US" -c "sports"` finds categories starting with "US" AND containing "sports"
- Perfect for organized IPTV providers with consistent naming

**Real-World IPTV Category Examples:**

```
Common IPTV category patterns:
- "US| Entertainment", "US| Sports", "US| News"
- "UK: Movies HD", "UK: Documentary", "UK: Kids"
- "FR | Cinema", "FR | Sport", "FR | Actualités"
- "24/7 Movies", "24/7 Cartoons", "24/7 Music"
```

## 🔧 Command Line Options

| Option            | Description                                                                     |
| ----------------- | ------------------------------------------------------------------------------- |
| `-H, --host`      | **Required.** Xtream Codes provider URL (e.g., `http://provider.com:8000`)      |
| `-u, --username`  | **Required.** Your IPTV username                                                |
| `-p, --password`  | IPTV password (prompted securely if not provided)                               |
| `-P, --prefix`    | Filter categories that **START WITH** specified text (e.g., `-P "US\|"`)        |
| `-c, --contains`  | Filter categories that **CONTAIN** specified text anywhere (e.g., `-c "movie"`) |
| `-s, --sensitive` | Enable case-sensitive filtering (default is case-insensitive)                   |
| `-t, --timeout`   | Connection timeout in seconds (default: 10)                                     |
| `-v, --verbose`   | Enable detailed debugging output                                                |
| `--help`          | Show detailed help and examples                                                 |

## 💡 Use Cases

### For IPTV Users

- **Provider Testing** - Verify new IPTV service credentials before configuring players
- **Content Discovery** - Browse available channels and categories
- **Service Comparison** - Compare channel offerings between different providers

### For Developers & Admins

- **API Debugging** - Test Xtream Codes API connectivity and responses
- **Service Monitoring** - Automated checks for IPTV service availability
- **Documentation** - Generate channel lists for service documentation

### For Troubleshooting

- **Connection Issues** - Diagnose network connectivity problems
- **Authentication Problems** - Verify credential validity
- **Provider Issues** - Identify server-side problems with detailed error messages

## 🔍 Sample Output

```
Fetching IPTV data...

Filtering for categories starting with "US|" (case-insensitive):
---------------------------------------------------

Category: US| Entertainment (ID: 1001)
  Entertainment Channel 1
  Drama Network HD
  Comedy Stream Network
  Reality TV Stream

Category: US| Local News (ID: 1003)
  Local News Channel
  Regional News HD
  City News Network

---------------------------------------------------
Summary:
  Categories matching criteria (prefix "US|", case-insensitive): 2
  Overall total channels listed: 7

Done.
```

## 🛠️ Error Handling

The script provides detailed diagnostics for common issues:

- **Connection Timeouts** - Network connectivity problems
- **HTTP 404 Errors** - Incorrect URLs or provider configuration
- **Authentication Failures** - Invalid credentials or account issues
- **Invalid JSON** - Provider API problems or unexpected responses
- **Missing Dependencies** - Checks for required tools before execution

## 🔒 Security Features

- **No Password Storage** - Passwords are never stored or logged
- **Secure Prompting** - Hidden input when entering passwords interactively
- **Clean Process Lists** - Credentials masked in verbose output
- **Temporary Files** - Secure handling of API responses

## 🤝 Contributing

Issues and pull requests welcome! This script is designed to be:

- **Reliable** - Handles edge cases and provider quirks
- **User-Friendly** - Clear error messages and helpful output
- **Maintainable** - Well-structured bash code with comprehensive comments
