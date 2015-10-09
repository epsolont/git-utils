#!/bin/bash
issue=${1//[[:blank:]]/}
sourceBranch=${2//[[:blank:]]/}
targetBranch=${3//[[:blank:]]/}

if [[ "$issue" == "" ]] ; then
    printf "Usage: intersect <issue> <source_branch> <target_branch>"
    printf "All parameters are mandatory."
	printf "Ex.: intersect \"TIWS-1\" \"DEV\" \"HOMO\""
    exit 1;
fi

# get issue's creation date on jira
startDate=`curl -s -X GET -H "Authorization: Basic amVua2luczpzb2Z0dkA0ZG1pbg==" -H "Content-Type: application/json" \
"http://ubuntuserver:8090/rest/api/2/search?jql=key=$issue+order+by+duedate&fields=created&maxResults=1" \
| jq -r .issues[0].fields.created`

printf "start date $startDate \n" 

# get commits related to issue searching in the commit message for the issue
commits=`git log --oneline $targetBranch..$sourceBranch --grep=$issue --after="$startDate"`

printf "commits $commits \n"

# iterate over commits getting the updated files in each commit
issueFiles=()
while read -r commit; do
 #   echo "$commit"
	hash=`echo "$commit"  | cut -f1 -d' '`
#	printf "Processing $commit"
#	printf " files ->> `git diff-tree --no-commit-id --name-only -r $hash` <<-"

	# put the file list in commit in an array
	mapfile -t commitFiles < <( git diff-tree --no-commit-id --name-only -r $hash)

	# copy the file list to the final array
	for fileName in "${commitFiles[@]}"; do
	   issueFiles+=( "$fileName" )
	done
done <<< "$commits"

# remove null items 
for i in "${!issueFiles[@]}"; do
  [ -n "${issueFiles[$i]//}" ] || unset "issueFiles[$i]"
done

echo "issueFiles: ${issueFiles[@]} \n"

# remove duplicated files
uniqueFiles=($(printf "%s\n" "${issueFiles[@]}" | sort -u))

# for each file, search for other issues that updated the file
for file in "${uniqueFiles[@]}"; do
	if [ -f $file ]; then
#		printf "git log --oneline --grep=$issue --invert-grep --follow $file";
		fileLogs="`git log --oneline --grep=$issue --invert-grep --follow $file`"
		if [ ! -z "$fileLogs" ]; then
			printf "\n file $file also updated in $fileLogs\n";
		fi
	fi
done
