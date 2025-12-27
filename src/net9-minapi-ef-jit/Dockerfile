FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5002

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["Project.csproj", "."]
RUN dotnet restore "./Project.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "Project.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Project.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Project.dll"]
