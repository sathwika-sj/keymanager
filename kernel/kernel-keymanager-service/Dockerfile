FROM openjdk:11

ARG SOURCE
ARG COMMIT_HASH
ARG COMMIT_ID
ARG BUILD_TIME
LABEL source=${SOURCE}
LABEL commit_hash=${COMMIT_HASH}
LABEL commit_id=${COMMIT_ID}
LABEL build_time=${BUILD_TIME}

# Environment variables
ARG spring_config_label
ARG active_profile
ARG spring_config_url
ARG is_glowroot
ARG artifactory_url
ARG hsm_client_zip_path

ENV active_profile_env=${active_profile}
ENV spring_config_label_env=${spring_config_label}
ENV spring_config_url_env=${spring_config_url}
ENV is_glowroot_env=${is_glowroot}
ENV artifactory_url_env=${artifactory_url}
ENV hsm_zip_file_path=${hsm_client_zip_path}

# Define working directory
WORKDIR /app

ARG loader_path=/app/additional_jars/
RUN mkdir -p ${loader_path}
ENV loader_path_env=${loader_path}

# Install required packages
RUN apt-get update && apt-get install -y unzip wget && rm -rf /var/lib/apt/lists/*

# Add necessary files
ADD configure_start.sh configure_start.sh
ADD ./lib/* "${loader_path_env}"/
ADD ./target/*.jar /app/

# Make script executable
RUN chmod +x configure_start.sh

# Move JAR file to correct location
RUN find /app -name '*.jar' -executable -type f "-print0" | xargs "-0" mv -t /app/ \
    && rm -rf /app/target \
    && mv /app/*.jar /app/kernel-keymanager-service.jar

# Expose required ports
EXPOSE 8088
EXPOSE 9010

# Ensure root user is used (No `USER` directive)
ENTRYPOINT ["./configure_start.sh"]
CMD if [ "$is_glowroot_env" = "present" ]; then \
    wget -q "${artifactory_url_env}/artifactory/libs-release-local/io/mosip/testing/glowroot.zip" -O /app/glowroot.zip; \
    unzip /app/glowroot.zip -d /app/ ; \
    rm -rf /app/glowroot.zip ; \
    sed -i 's/<service_name>/kernel-keymanager-service/g' /app/glowroot/glowroot.properties ; \
    wget -q "${iam_adapter_url_env}" -O "${loader_path_env}/kernel-auth-adapter.jar"; \
    java -jar -javaagent:/app/glowroot/glowroot.jar -Dloader.path="${loader_path_env}" \
    -Dspring.cloud.config.label="${spring_config_label_env}" \
    -Dspring.profiles.active="${active_profile_env}" \
    -Dspring.cloud.config.uri="${spring_config_url_env}" \
    -XX:HeapDumpPath=/app/ /app/kernel-keymanager-service.jar ; \
    else \
    wget -q "${iam_adapter_url_env}" -O "${loader_path_env}/kernel-auth-adapter.jar"; \
    java -jar -Dloader.path="${loader_path_env}" \
    -Dspring.cloud.config.label="${spring_config_label_env}" \
    -Dspring.profiles.active="${active_profile_env}" \
    -Dspring.cloud.config.uri="${spring_config_url_env}" \
    /app/kernel-keymanager-service.jar ; \
    fi
 
