#!/bin/bash
# shellcheck disable=SC2153,2164

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
apiKey=${API_KEY}
project_subfolder=${PROJECT_SUBFOLDER}

# Print config
echo "*** CONFIGURATION ***"
echo -e "\tVERSION: ${version}"
echo -e "\tPROJECT_NAME: ${project_name}"
echo -e "\tSOURCE_NAME: ${sourceName}"
echo -e "\tSOURCE_URL: ${sourceUrl}"
echo -e "\tSOURCE_USERNAME: ${sourceUsername}"
echo -e "\tPROJECT_SUBFOLDER: ${project_subfolder}"

echo "Preparing NuGet package of $project_name project"

cd /github/workspace

if [ -z "$sourceUsername" ] || [ -z "$sourcePassword" ]; then
    echo "Source username or password is empty - they will not be set in nugetconfig"
    dotnet nuget add source "${sourceUrl}" -n "${sourceName}"
else
    echo "Source username and password are not empty - they will be set in nugetconfig"
    dotnet nuget add source "${sourceUrl}" -n "${sourceName}" -u "${sourceUsername}" -p "${sourcePassword}" --store-password-in-clear-text
fi

#Create package

CSPROJ_PATH="${project_name}/${project_name}.csproj"

if [ -n "$project_subfolder" ]; then
    CSPROJ_PATH="${project_name}/$project_subfolder/${project_name}.csproj"
fi

dotnet pack "$CSPROJ_PATH" -c Release -p:RepositoryCommit="${commit_id}" -p:PackageVersion="${version}" --output nuget-packages/"${project_name}"

#Publish package
echo "Publishing NuGet package of $project_name project"

if [ -z "$apiKey" ]; then
    echo "API key has not been provided, password will be used instead for 'nuget push'"
    dotnet nuget push nuget-packages/"${project_name}"/*.nupkg --api-key "${sourcePassword}" --source "${sourceName}"
else
    echo "API key has been provided, it will be used for 'nuget push'"
    dotnet nuget push nuget-packages/"${project_name}"/*.nupkg --api-key "${apiKey}" --source "${sourceName}"
fi
