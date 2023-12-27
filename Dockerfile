# Use Alpine Linux as the base image
FROM mikefarah/yq as yq

FROM ubuntu:latest

RUN apt update && apt install -y curl

# Install yq (YAML processor) using wget
COPY --from=yq /usr/bin/yq  /usr/bin/yq
RUN chmod +x /usr/bin/yq

# tomlq functionality is provided by yq, so no separate installation is needed

# Copy configurator.sh script into the image
COPY configurator.sh /configurator.sh

# Make the script executable
RUN chmod +x /configurator.sh

# Set the CMD to execute the configurator.sh script
CMD ["/bin/bash", "/configurator.sh"]
