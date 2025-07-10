# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# Base stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
# Create non-root user
RUN adduser --disabled-password --gecos "" --home /app appuser && \
    chown -R appuser:appuser /app
WORKDIR /app
EXPOSE 81

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["GadgetsOnline/GadgetsOnline.csproj", "GadgetsOnline/"]
RUN dotnet restore "./GadgetsOnline/GadgetsOnline.csproj"
COPY . .
WORKDIR "/src/GadgetsOnline"
RUN dotnet build "./GadgetsOnline.csproj" -c $BUILD_CONFIGURATION -o /app/build

# Publish stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./GadgetsOnline.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Final stage
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Create necessary directories with proper permissions
RUN mkdir -p /application_transformation_service_sync_files && \
    chown -R appuser:appuser /application_transformation_service_sync_files && \
    chmod 755 /application_transformation_service_sync_files

# Ensure all files have proper permissions
RUN chown -R appuser:appuser /app && \
    chmod -R 755 /app

# Switch to non-root user
USER appuser

ENTRYPOINT ["dotnet", "GadgetsOnline.dll"]
