#!/bin/bash

set -o pipefail

# config
version=$VERSION
project_name=${PROJECT_NAME}
commit_id=${COMMIT_ID}
repo_owner=${REPO_OWNER}
sourceName=${SOURCE_NAME:-github}
sourceUrl=${SOURCE_URL:-https://nuget.pkg.github.com/"$repo_owner"/index.json}
sourceUsername=${SOURCE_USERNAME}
sourcePassword=${SOURCE_PASSWORD}


# Print config
echo "*** CONFIGURATION ***"
echo -e "\tVERSION: ${version}"
echo -e "\tPROJECT_NAME: ${project_name}"
echo -e "\tSOURCE_NAME: ${sourceName}"
echo -e "\tSOURCE_URL: ${sourceUrl}"
echo -e "\tSOURCE_USERNAME: ${sourceUsername}"

echo "Preparing NuGet package of $project_name project"


cd /github/workspace

if [ -z "$sourceUsername"] | [ -z "$sourcePassword" ]; then
    echo "Source username or password is empty - they will not be set in nugetconfig"
    dotnet nuget add source ${sourceUrl} -n ${sourceName}
else 
    echo "Source username and password are not empty - they will be set in nugetconfig"
    dotnet nuget add source ${sourceUrl} -n ${sourceName} -u ${sourceUsername} -p ${sourcePassword} --store-password-in-clear-text
fi

#Create package 

dotnet pack "${project_name}/${project_name}.csproj" -c Release -p:RepositoryCommit="${commit_id}" -p:Version=${version} --output nuget-packages/"${project_name}" --include-symbols 


#Publish package
echo "Publishing NuGet package of $project_name project"

dotnet nuget push nuget-packages/"${project_name}"/*.nupkg --api-key ${GITHUB_TOKEN} --source ${sourceName} --skip-duplicate