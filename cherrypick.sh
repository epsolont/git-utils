#!/bin/bash
# Utility script for git users to cherry-pick commits with a  given issue in
# the commit message.
# Author: Emerson Takahashi <emerson.takahashi@softvaro.com.br>
#
# Feel free to use, modify and share this script in anyway you like.

# This script is intended to get all commits with a given issue in the commit
# message and cherry-pick each one of them to the current branch.

# It receives three parameters, the branch from which you want to cherry-pick
# the commits, the issue and a date to start searching for the issue in the 
# log.

# Ex.: cherrypick "DEV" "ABC-123" "2015-01-01"
# 
# In this example, it will search for commit messages with the string 
# "ABC-123" in the branch DEV whose commits were done after 2015-01-01
# The commits will be picked in reverse order so that the original
# order is kept.

# If a conflict occurs, you should manually solve it :-) and cherry-pick
# accordingly the git-cherry-pick-list-<issue>-<date> file
# The processed list will be logged into the
# git-cherry-pick-list-<issue>-<date>.processed file

BRANCH=${1//[[:blank:]]/}
ISSUE=${2//[[:blank:]]/}
START=${3//[[:blank:]]/}
DRY_RUN=${4//[[:blank:]]/}

COMMIT_LIST_FILE="./git-cherry-pick-list-$BRANCH-$ISSUE-$START"
PROCESSED_HASHS_FILE="./git-cherry-pick-list-$BRANCH-$ISSUE-$START.processed"
LOG_FILE="./git-cherry-pick-list-$BRANCH-$ISSUE-$START.log"

if [[ "$BRANCH" == "" ]] || [[ "$ISSUE" == "" ]]  || [[ "$START" == "" ]] ; then
    echo "Usage: cherrypick <branch> <issue> <start-date>"
    echo "All parameters are mandatory."
	 echo "Ex.: cherrypick \"DEV\" \"ABC-123\" \"2015-01-01\""
    exit 1;
fi

#echo "branch " $BRANCH
#echo "issue " $ISSUE
#echo "start " $START

COMMITS=`git log --branches="$BRANCH" --pretty=oneline --after="$START" --grep="$ISSUE" --reverse`   

printf "\n------------- Execution on `date` ------------- \n" >> "$COMMIT_LIST_FILE"
printf "$COMMITS" >> "$COMMIT_LIST_FILE"

shopt -s nocasematch
if [[ "$DRY_RUN" != "DRYRUN" ]]; then
printf "\n-------------- Processed hashs on `date` -------------- \n" >> "$PROCESSED_HASHS_FILE"
printf "\n------------ Results of execution on `date` ------------ \n" >> "$LOG_FILE"
while read -r commit; do
	hash=`echo "$commit"  | cut -f1 -d' '`
    echo "Processing $commit"
	git cherry-pick $hash >> "$LOG_FILE"
    if [ $? -ne 0 ]; then
        exit 1
    fi
	echo "$hash" >> "$PROCESSED_HASHS_FILE"
done <<< "$COMMITS"
fi
exit 0
