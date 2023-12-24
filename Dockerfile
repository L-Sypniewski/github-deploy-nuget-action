FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

LABEL "repository"="https://github.com/L-Sypniewski/github-deploy-nuget-action"
LABEL "homepage"="https://github.com/aL-Sypniewski/github-deploy-nuget-action"
LABEL "maintainer"="Łukasz Sypniewski"

COPY install-packages.sh .
RUN chmod +x ./install-packages.sh
RUN ./install-packages.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
