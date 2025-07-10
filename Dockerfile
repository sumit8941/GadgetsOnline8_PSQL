# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
# Create required directories and set permissions
RUN mkdir -p /application_transformation_service_sync_files /var/scratch /app && \
    chmod 777 /application_transformation_service_sync_files && \
    chmod 777 /var/scratch && \
    chmod 777 /app
WORKDIR /app
EXPOSE 81

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["GadgetsOnline/GadgetsOnline.csproj", "GadgetsOnline/"]
RUN dotnet restore "./GadgetsOnline/GadgetsOnline.csproj"
COPY . .
WORKDIR "/src/GadgetsOnline"
RUN dotnet build "./GadgetsOnline.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./GadgetsOnline.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
# Ensure all application files are accessible
RUN chmod -R 777 . && \
    chmod -R 777 /application_transformation_service_sync_files && \
    chmod -R 777 /var/scratch
ENTRYPOINT ["dotnet", "GadgetsOnline.dll"]
