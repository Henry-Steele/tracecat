# Running env.sh on Windows

This script helps set up the necessary environment variables for the project by creating a `.env` file. To run it successfully on Windows, you need a Linux-like environment and specific dependencies.

## Prerequisites

1. **Git Bash:**
    * Install Git for Windows, which includes Git Bash: [https://git-scm.com/download/win](https://git-scm.com/download/win)
    * Git Bash provides the necessary shell environment (like `bash`, `sed`, `cp`, etc.) to execute the script.
    * You **must** run the `env.sh` script from within a Git Bash terminal, not the standard Windows Command Prompt or PowerShell.

2. **OpenSSL (Full Version):**
    * The script requires OpenSSL to generate security keys.
    * Download and install a **full (non-light)** version of OpenSSL for Windows. A common source is Shining Light Productions: [https://slproweb.com/products/Win32OpenSSL.html](https://slproweb.com/products/Win32OpenSSL.html) (choose a Win64 installer, e.g., `Win64 OpenSSL v3.x.x`).
    * **Installation Options:**
        * During installation, when asked "Copy OpenSSL DLLs to:", choose **"The OpenSSL binaries (/bin) directory"**.
        * Crucially, if available, ensure you  select the option to **"Add OpenSSL installation directory to the system PATH"** during setup. This is the most reliable way for Git Bash and the script to find it.

## Adding OpenSSL to PATH Manually (If Needed)

The `env.sh` script attempts to automatically detect common OpenSSL installation locations. However, if the script still fails with an OpenSSL error, manually adding it to your PATH is the best solution:

1. **Find the OpenSSL `bin` Directory:** Locate your OpenSSL installation folder (e.g., `C:\Program Files\OpenSSL-Win64`). Inside, find the `bin` directory. Copy this full path (e.g., `C:\Program Files\OpenSSL-Win64\bin`).
2. **Open System Environment Variables:**
    * Press `Win`, type `environment variables`, click "Edit the system environment variables".
    * Click the "Environment Variables..." button.
3. **Edit System `Path`:**
    * Under "System variables", find and select the `Path` variable.
    * Click "Edit...".
4. **Add the Path:**
    * Click "New".
    * Paste the OpenSSL `bin` path you copied.
    * Click "OK" on all windows to save.
5. **Restart Git Bash:** Close **all** Git Bash windows and open a new one for the changes to take effect.

## Running the Script

1. Open Git Bash.
2. Navigate (`cd`) to the project's root directory where `env.sh` is located.
3. Run the script using: `bash env.sh` or `./env.sh`
4. Follow the prompts within the script. 