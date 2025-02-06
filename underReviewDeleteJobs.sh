#!/bin/bash
##########variables##########
asocApiKeyId='xxxxxxxxxxxxxxxxxxxxxxxxx'
asocApiKeySecret='xxxxxxxxxxxxxxxxxxxxxxxxx'
#############################

asocToken=$(curl -k -s -X POST --header 'Content-Type:application/json' --header 'Accept:application/json' -d '{"KeyId":"'"$asocApiKeyId"'","KeySecret":"'"$asocApiKeySecret"'"}' "https://cloud.appscan.com/api/v4/Account/ApiKeyLogin" | grep -oP '(?<="Token":\ ")[^"]*')

if [ -z "$asocToken" ]; then
	echo "The token variable is empty. Check the authentication process.";
    exit 1
fi

scans=$(curl -k -X 'GET' -H 'accept:application/json' -H "Authorization:Bearer $asocToken" "https://cloud.appscan.com/api/v4/Scans?filter=((LatestExecution/ExecutionProgress%20eq%20%27UnderReview%27))and((Technology%20eq%20%27StaticAnalyzer%27))")

totalScans=$(echo "$scans" | jq '.Items | length')

for ((a=0; a<totalScans; a++)); do
    scanId=$(echo "$scans" | jq -r ".Items[$a].Id")
    scanName=$(echo "$scans" | jq -r ".Items[$a].Name")
    executions=$(curl -k -s -X 'GET' "https://cloud.appscan.com/api/v4/Scans/$scanId/Executions" -H 'accept: application/json' -H "Authorization: Bearer $asocToken")
    echo $scanName >> deletedScanJobs.txt
    totalExecutions=$(echo "$executions" | jq '. | length')
    for ((i=0; i<totalExecutions; i++)); do
        executionId=$(echo "$executions" | jq -r ".[$i].Id")
        echo $executionId >> deletedScanJobs.txt
        curl -X 'DELETE' "https://cloud.appscan.com/api/v4/Scans/Execution/$executionId" -H 'accept: */*' -H "Authorization: Bearer $asocToken"
    done
done
