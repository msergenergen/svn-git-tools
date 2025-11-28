#!/bin/bash
#title: svn2git.sh
#description: This script will commit last svn changes to git for a bash script.
#author: Mehmet Sergen ERGEN (mergen)
#usage: bash svn2git.sh <svn-repo-url> <git-repo-url> <branch-name> [commit-message:Optional]
#example: bash svn2git.sh  <svn-repo-url> <git-repo-url> bugfix/ADV-29814-release 
#date: 2024/09/24
#version: 0.0.3


DEBUG='\033[32;49;1m'
ERROR='\033[31;49;1m'
WARN='\033[33;49;1m'
NOCOLOR='\033[0m'

# Check usage
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo -e "${WARN}Usage: $0 <svn-repo-url> <git-repo-url> <branch-name> [commit-message:Optional]${NOCOLOR}"
    echo -e "${WARN}Branch Name: bugfix-feature/ADV-xxxxx-release${NOCOLOR}"
    exit 1
fi

# Clean up and exit on error
cleanup() {
    echo -e "${ERROR}Cleaning up...${NOCOLOR}"
    rm -rf $TEMP_DIR
    exit 1
}

# Accept SVN and Git repository URLs
SVN_REPO_URL=$1
GIT_REPO_URL=$2
BRANCH_NAME=$3
COMMIT_MSG=${4:-$(svn log -l 1 $SVN_REPO_URL | sed -n '4p')}

# If no commit message is provided, use the last commit message from the SVN repository
if [ -z "$4" ]; then
    echo -e "${WARN}Commit message is not provided. Using last commit message as below.${NOCOLOR}"
    echo -e "${DEBUG} $COMMIT_MSG ${NOCOLOR}"
fi

# Create a temporary directory and move into it
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR || cleanup

# Clone the SVN repository
svn checkout $SVN_REPO_URL svn_repo || cleanup

# Clone the Git repository
git clone $GIT_REPO_URL git_repo || cleanup

# Check the given branch name from remote, pull last changes from branch
cd $TEMP_DIR/git_repo

EXISTED_IN_REMOTE=$(git ls-remote --heads origin $BRANCH_NAME)

if [[ -n ${EXISTED_IN_REMOTE} ]]; then
	git switch $BRANCH_NAME || cleanup
	git pull origin $BRANCH_NAME || cleanup
else
	echo -e "${ERROR}The $BRANCH_NAME is not existed in Git.${NOCOLOR}"
    cleanup
fi

cd $TEMP_DIR/svn_repo || cleanup
svn update || cleanup

# Create directories to prepare Git and SVN project directories
GIT_EXPORT_DIR=$TEMP_DIR/git_export
SVN_EXPORT_DIR=$TEMP_DIR/svn_export

mkdir -p $GIT_EXPORT_DIR $SVN_EXPORT_DIR || cleanup

# Export SVN contents
rsync -a --exclude='.svn' . $TEMP_DIR/svn_repo/ $SVN_EXPORT_DIR || cleanup

# Export Git contents
cd $TEMP_DIR/git_repo || cleanup
git archive HEAD | tar -x -C $GIT_EXPORT_DIR || cleanup

# Compare Git and SVN contents
diff -qr $GIT_EXPORT_DIR $SVN_EXPORT_DIR
if [ $? -eq 0 ]; then
    echo -e "${ERROR}No changes to commit. Exiting...${NOCOLOR}"
    cleanup
fi

# Copy SVN contents to Git directory
rsync -a --delete $SVN_EXPORT_DIR/ $GIT_EXPORT_DIR || cleanup

# Copy Git export contents to Git repo
cd $TEMP_DIR/git_repo || cleanup
rsync -a --exclude='.git' --exclude='.gitkeep' --delete --force $GIT_EXPORT_DIR/ . || cleanup

# Commit and push changes to Git repository
git add --all || cleanup
git commit -m "$COMMIT_MSG" || cleanup
git push origin $BRANCH_NAME || cleanup

# Clean up the temporary directory
rm -rf $TEMP_DIR

echo -e "${GREEN}Successfully applied the latest SVN commit to the $BRANCH_NAME branch in Git.${NOCOLOR}"
exit 0