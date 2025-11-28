# SVN ↔ Git Tools

This repository provides two Bash scripts to simplify conversions and synchronization between SVN and Git:

- `svn2git.sh` → Commits the latest changes from an SVN repository into a Git repository
- `git2svn.sh` → Commits the latest changes from a Git repository into an SVN repository

---

## 🚀 Installation
Clone the repository and make the scripts executable:
```bash
git clone https://github.com/<your-username>/svn-git-tools.git
cd svn-git-tools/scripts
chmod +x svn2git.sh git2svn.sh
```
## 📖 Usage

### `svn2git.sh`

**Syntax:**
```bash
bash svn2git.sh <svn-repo-url> <git-repo-url> <branch-name> [commit-message]
```
- svn-repo-url → URL of the source SVN repository

- git-repo-url → URL of the target Git repository

- branch-name → Target Git branch name (e.g., main, develop, bugfix)

- [commit-message] (optional) → Custom commit message. If omitted, a default message will be used.


### `git2svn.sh`

**Syntax:**
```bash
bash git2svn.sh <git-repo-url> <svn-repo-url> [commit-message]
```

- git-repo-url → URL of the source Git repository

- svn-repo-url → URL of the target SVN repository

- [commit-message] (optional) → Custom commit message. If omitted, a default message will be used.
