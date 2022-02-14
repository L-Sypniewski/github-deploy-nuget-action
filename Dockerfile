FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

LABEL "repository"="https://github.com/L-Sypniewski/github-deploy-nuget-action"
LABEL "homepage"="https://github.com/aL-Sypniewski/github-deploy-nuget-action"
LABEL "maintainer"="Łukasz Sypniewski"

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
