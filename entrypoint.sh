#!/bin/bash
# shellcheck disable=SC2153,2164

set -o pipefail

# config
version=$VERSION
project_name=${PROJECT_NAME}
commit_id=${COMMIT_ID}
repo_owner=${REPO_OWNER}
sourceName=${SOURCE_NAME:-github}
overwrite_if_already_exists=${OVERWRITE_IF_ALREADY_EXISTS:-false}
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
echo -e "\OVERWRITE_IF_ALREADY_EXISTS: ${overwrite_if_already_exists}"

echo "Preparing NuGet package of $project_name project"

cd /github/workspace

if [ -z "$sourceUsername" ] || [ -z "$sourcePassword" ]; then
    echo "Source username or password is empty - they will not be set in nugetconfig"
    dotnet nuget add source "${sourceUrl}" -n "${sourceName}"
else
    echo "Source username and password are not empty - they will be set in nugetconfig"
    dotnet nuget add source "${sourceUrl}" -n "${sourceName}" -u "${sourceUsername}" -p "${sourcePassword}" --store-password-in-clear-text
fi

#Build solution first
dotnet build -c Release -p:Version="${version}"

#Create package

CSPROJ_PATH="${project_name}/${project_name}.csproj"

if [ -n "$project_subfolder" ]; then
    CSPROJ_PATH="${project_name}/$project_subfolder/${project_name}.csproj"
fi

dotnet pack "$CSPROJ_PATH" -c Release --no-build -p:RepositoryCommit="${commit_id}" --output nuget-packages/"${project_name}"

#Publish package
echo "Publishing NuGet package of $project_name project"

if [ -z "$apiKey" ]; then
    echo "API key has not been provided, password will be used instead for 'nuget push'"
    result="$(dotnet nuget push nuget-packages/"${project_name}"/*.nupkg --api-key "${sourcePassword}" --source "${sourceName}" --skip-duplicate)"
else
    echo "API key has been provided, it will be used for 'nuget push'"
    result="$(dotnet nuget push nuget-packages/"${project_name}"/*.nupkg --api-key "${apiKey}" --source "${sourceName}" --skip-duplicate)"
fi

if [[ $result =~ Version\ ([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+)\ of\ \"(.+)\"\ has\ already\ been\ pushed ]]; then
    echo "The version $version for package $app_name already exists"
    version="${BASH_REMATCH[1]}"
    app_name="${BASH_REMATCH[2]}"

    existing_packages=$(curl -s --location "https://api.github.com/orgs/$REPO_OWNER/packages/nuget/$app_name/versions" \
        --header 'Accept: application/vnd.github+json' \
        --header "Authorization: Bearer ${sourcePassword}" \
        --header 'X-GitHub-Api-Version: 2022-11-28')
    versionId=$(echo "$existing_packages" | jq ".[] | select(.name == \""$version"\") | .id")

    if [[ "$overwrite_if_already_exists" == "false" ]]; then
        echo "The version $version for package $app_name will not be overwritten as OVERWRITE_IF_ALREADY_EXISTS is set to false"
    else
        echo "OVERWRITE_IF_ALREADY_EXISTS is set to true, and the package already exists. The package will be ovewritten"

        STATUS=$(curl -s -o /dev/null -w '%{http_code}' -s --location --request DELETE "https://api.github.com/orgs/$REPO_OWNER/packages/nuget/$app_name/versions/$versionId" --header 'Accept: application/vnd.github+json' --header "Authorization: Bearer ${sourcePassword}" --header 'X-GitHub-Api-Version: 2022-11-28')

        if [ "$STATUS" -eq 204 ]; then
            echo "Got 204 - package successfully deleted."
        else
            echo "Got $STATUS. Application will terminate with an error"
            exit 1
        fi
    fi
else
    echo "Package has been uploaded successfully"
    exit 0
fi

# Publish again, after removing package with already existing tag
if [ -z "$apiKey" ]; then
    dotnet nuget delete "${app_name}" "${version}" --api-key "${sourcePassword}" --source "${sourceName}" --non-interactive
    dotnet nuget push nuget-packages/"${project_name}"/*.nupkg --api-key "${sourcePassword}" --source "${sourceName}" --skip-duplicate
else
    dotnet nuget delete "${app_name}" "${version}" --api-key "${apiKey}" --source "${sourceName}" --non-interactive
    dotnet nuget push nuget-packages/"${project_name}"/*.nupkg --api-key "${apiKey}" --source "${sourceName}" --skip-duplicate
fi

echo "Package has been uploaded successfully"
