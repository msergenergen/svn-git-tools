#!/bin/bash

DEBUG='\033[32;49;1m'
ERROR='\033[31;49;1m'
WARN='\033[33;49;1m'
NOCOLOR='\033[0m'

# Check usage
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo -e "${WARN}Usage: $0 <git-repo-url> <svn-repo-url>  [commit-message:Optional]${NOCOLOR}"
    exit 1
fi

# Accept SVN and Git repository URLs
GIT_REPO_URL=$1
SVN_REPO_URL=$2
COMMIT_MSG=$3

# Clean up and exit on error
cleanup() {
    echo -e "${ERROR}Cleaning up...${NOCOLOR}"
    rm -rf $TEMP_DIR
    exit 1
}

# Create a temporary directory and move into it
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR || cleanup

# If no commit message is provided, use the last commit message from the Git repository
if [-z "COMMIT_MSG"]; then
    echo -e "${WARN}Commit message is not provided. Using last commit message${NOCOLOR}"
    COMMIT_MSG=$(git log -1 --pretty=%B)
fi

# Create directories to prepare Git and SVN project directories
GIT_EXPORT_DIR=$TEMP_DIR/git_export
SVN_EXPORT_DIR=$TEMP_DIR/svn_export

mkdir -p $GIT_EXPORT_DIR $SVN_EXPORT_DIR || cleanup

# Clone the Git repository
git clone $GIT_REPO_URL git_repo || cleanup
cd $TEMP_DIR/git_repo || cleanup

# Switch master branch and update 
git switch master || cleanup
git pull origin master || cleanup

# Export Git contents
git archive HEAD || tar -x --exclude='.git*' -C $GIT_EXPORT_DIR || cleanup

cd $TEMP_DIR || cleanup

# Checkout the SVN repository
svn checkout $SVN_REPO_URL svn_repo || cleanup
cd svn_repo || cleanup

# Export SVN contents
rsync -a --exclude='.svn' $TEMP_DIR/svn_repo/ $SVN_EXPORT_DIR || cleanup

# Compare Git and SVN contents
diff -qr $GIT_EXPORT_DIR $SVN_EXPORT_DIR
if [ $? -eq 0 ]; then
    echo -e "${ERROR}No changes to commit. Exiting...${NOCOLOR}"
    cleanup
fi

# Copy Git contents to SVN directory
rsync -a --delete $GIT_EXPORT_DIR/  $SVN_EXPORT_DIR|| cleanup

# Copy SVN contents to Git directory
cd $TEMP_DIR/svn_repo
rsync -a --delete --force $SVN_EXPORT_DIR/ . || cleanup

# Add new and remove deleted files in SVN
svn add --force . || cleanup
svn rm $(svn status | awk '/^!/ {print $2}') 2> /dev/null

# Commit changes to SVN repository
svn commit -m "AUTO_SYNC_MSG: $COMMIT_MSG from Git." || cleanup

# Clean up the temporary directory
rm -rf $TEMP_DIR

echo -e "${GREEN}Successfully applied the latest Git commit from master branch to the trunk branch in SVN.${NOCOLOR}"
exit 0