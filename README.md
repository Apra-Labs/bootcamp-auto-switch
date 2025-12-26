# T2 Mac Dual-Boot Automation

Automate switching between macOS and Windows on T2 chip MacBooks (2018-2020 Intel Macs with Boot Camp).

## The Problem

Apple's T2 security chip blocks all command-line methods for changing the startup disk (`bless`, `nvram`, `bcdedit`). Only Apple's signed GUI apps can communicate with the T2 chip to change boot settings.

## The Solution

GUI automation scripts for each OS:
- `switch-to-windows.sh` - Run on macOS, reboots to Windows
- `switch-to-macos.ps1` - Run on Windows, reboots to macOS

## Requirements

### macOS
```bash
brew install cliclick
```

**First-time setup:** Grant accessibility permissions to the app running the script:

1. Run the script once - it will fail but trigger the permission prompt
2. Go to **System Settings → Privacy & Security → Accessibility**
3. Enable the app that's running the script:
   - **Terminal.app** - if running from Terminal
   - **iTerm** - if using iTerm
   - **GitHub Runner** - if running via GitHub Actions (usually located in `~/actions-runner`)
4. Run the script again

Without accessibility permissions, cliclick cannot send clicks/keystrokes.

### Windows
```powershell
winget install AutoHotkey.AutoHotkey
```

**First-time setup:** Ensure Boot Camp icon is in the system tray overflow area (click the `^` arrow in taskbar to verify).

## Usage

```bash
# On macOS - switch to Windows
export MACOS_PASSWORD="your-password"
./switch-to-windows.sh

# On Windows - switch to macOS
.\switch-to-macos.ps1
```

## Configuration

macOS password is needed for Startup Disk authentication:

```bash
# Option 1: Environment variable (recommended for CI)
export MACOS_PASSWORD="your-password"
./switch-to-windows.sh

# Option 2: Edit script directly
# Edit switch-to-windows.sh line 5
MACOS_PASSWORD="your-password-here"
```

## GitHub Actions Integration

Use a single Mac as a dual-OS self-hosted runner. The workflow re-queues itself before rebooting, so the job automatically retries on the correct OS.

### Setup

1. **Install `gh` CLI on the runner (both OSes)**
   ```bash
   # macOS
   brew install gh
   
   # Windows (in admin PowerShell)
   winget install GitHub.cli
   ```

2. **Create a Personal Access Token (PAT)**
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
   - Create token with these permissions:
     - `repo` - Full control (for workflow access)
     - `workflow` - Update GitHub Action workflows
   - Or use classic token with `repo` and `workflow` scopes

3. **Add repository secrets**
   - Go to your repo → Settings → Secrets and variables → Actions
   - Add these secrets:
     - `WORKFLOW_PAT` - Your PAT from step 2
     - `MACOS_PASSWORD` - Your Mac login password (for Startup Disk auth)

4. **Copy workflow file**
   ```bash
   cp dual-os-build.yml .github/workflows/
   ```

### How it works

```
1. Workflow triggered with target_os=windows
2. Job starts on macOS (wrong OS)
3. gh workflow run queues new run
4. switch-boot.sh reboots to Windows
5. Job fails (machine rebooted)
6. Machine boots to Windows
7. New queued job starts on Windows
8. Correct OS - build proceeds
```

### Example workflow

```yaml
- name: Switch to Windows (from macOS)
  if: runner.os == 'macOS' && inputs.target_os == 'windows'
  env:
    GH_TOKEN: ${{ secrets.WORKFLOW_PAT }}
    MACOS_PASSWORD: ${{ secrets.MACOS_PASSWORD }}
  run: |
    gh workflow run "${{ github.workflow }}" -f target_os=windows
    sleep 5
    ./switch-to-windows.sh
    exit 1

- name: Switch to macOS (from Windows)
  if: runner.os == 'Windows' && inputs.target_os == 'macos'
  env:
    GH_TOKEN: ${{ secrets.WORKFLOW_PAT }}
  shell: pwsh
  run: |
    gh workflow run "${{ github.workflow }}" -f target_os=macos
    Start-Sleep -Seconds 5
    .\switch-to-macos.ps1
    exit 1
```

### Security notes

- `MACOS_PASSWORD` is passed as environment variable, not command-line argument
- Secrets are masked in GitHub Actions logs
- Consider using a dedicated CI user account with limited permissions

## Tested Hardware

- MacBook Pro 16,1 (2019) with T2 chip

## Troubleshooting

### macOS

**"cliclick" cannot be opened because it is from an unidentified developer**
```bash
xattr -d com.apple.quarantine $(which cliclick)
```

**Script runs but nothing happens**
- Check accessibility permissions: System Settings → Privacy & Security → Accessibility
- Ensure Terminal/iTerm/runner app is listed and enabled
- Try removing and re-adding the app from the list

**Clicks go to wrong location**
- Display resolution may differ from script coordinates
- Edit `switch-to-windows.sh` and adjust coordinates for your setup

### Windows

**Boot Camp not found**
- Ensure Boot Camp icon is in the overflow tray (click `^` in taskbar)
- Check no other tray icon starts with 'B' (keyboard shortcut conflict)
- Verify AutoHotkey v2 is installed (not v1)

**AutoHotkey not found**
```powershell
winget install AutoHotkey.AutoHotkey
```

### Boot issues

- **Manual selection:** Hold `Option` at startup to pick boot disk
- **Recovery:** Hold `Cmd+R` at startup for Recovery Mode
- **NVRAM reset:** Hold `Option+Cmd+P+R` for 20 seconds

## License

MIT
