# Use an official Flutter image
FROM cirrusci/flutter:latest

# Install Firebase CLI
RUN apt-get update && apt-get install -y \
    curl \
    && curl -sL https://firebase.tools | bash

# Set the working directory
WORKDIR /app

# Copy the pubspec.yaml and pubspec.lock for dependency caching
COPY pubspec.* ./

# Get Flutter dependencies
RUN flutter pub get

# Copy the rest of the application code
COPY . .

# Expose the port (if needed)
EXPOSE 8080

# Specify the command to run when the container starts (optional)
CMD ["flutter", "run"] # You might not need this for Jenkins, it's optional.

