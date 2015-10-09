#!/bin/bash
# Utility script for git users to cherry-pick commits with a  given issue in
# the commit message.
# Author: Emerson Takahashi <emerson.takahashi@softvaro.com.br>
#
# Feel free to use, modify and share this script in anyway you like.

# This script is intended to get all commits with a given issue in the commit
# message and cherry-pick each one of them to the current branch. It expect 
# that your credentials are cached.

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

branch=${1//[[:blank:]]/}
issue=${2//[[:blank:]]/}
start=${3//[[:blank:]]/}
dry_run=${4//[[:blank:]]/}

commit_list_file="./git-cherry-pick-list-$branch-$issue-$start"
processed_hashs_file="./git-cherry-pick-list-$branch-$issue-$start.processed"
log_file="./git-cherry-pick-list-$branch-$issue-$start.log"

if [[ "$branch" == "" ]] || [[ "$issue" == "" ]]  || [[ "$start" == "" ]] ; then
    echo "Usage: cherrypick <branch> <issue> <start-date>"
    echo "All parameters are mandatory."
    echo "Ex.: cherrypick \"DEV\" \"ABC-123\" \"2015-01-01\""
    exit 1;
fi

#echo "branch " $branch
#echo "issue " $issue
#echo "start " $start

commits=`git log "$branch" --pretty=oneline --after="$start" --grep="$issue" --reverse`   

printf "\n------------- Execution on `date` ------------- \n" >> "$commit_list_file"
printf "$commits" >> "$commit_list_file"

shopt -s nocasematch
if [[ "$dry_run" != "DRYRUN" ]]; then
	if [[ ! -z "$commits" ]]; then
		printf "\n-------------- Processed hashs on `date` -------------- \n" >> "$processed_hashs_file"
		printf "\n------------ Results of execution on `date` ------------ \n" >> "$log_file"
		while read -r commit; do
			hash=`echo "$commit"  | cut -f1 -d' '`
			echo "Processing $commit"
			git cherry-pick $hash >> "$log_file"
			if [ $? -ne 0 ]; then
				exit 1
			fi
			echo "$hash" >> "$processed_hashs_file"
		done <<< "$commits"
	fi
fi
exit 0
