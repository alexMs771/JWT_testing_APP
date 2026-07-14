################################################################
# ColdBox Docker Image
# You can use this docker image to build your own
# You can use the following to build the image
# docker build --no-cache -t my-coldbox-app -f ./Dockerfile ./
# You can use the following to run the image
# docker run -it -p 8080:8080 my-coldbox-app
################################################################

# Lucee 6 (free, open-source CFML engine). Lucee runs ColdBox reliably and
# honors Application.cfc this.mappings during onApplicationStart, unlike the
# baked BoxLang engine in this image family, whose class resolver does not
# register those mappings in time for the framework to bootstrap.
# https://hub.docker.com/r/ortussolutions/commandbox
FROM ortussolutions/commandbox:lucee6

# Metadata
LABEL maintainer="Ortus Solutions <info@ortussolutions.com>"
LABEL repository="https://github.com/Ortus-Solutions/docker-commandbox"

# Force the engine for the container (the base image env overrides server.json,
# which stays on boxlang for local development).
# Pin an EXACT version: with a loose version like "lucee@6", CommandBox makes a
# ForgeBox network call at every server start ("determining the latest version").
# On Render's deploy network that call stalls, so the startup script is never
# generated and the server never binds a port ("No open ports detected"). An
# exact version skips the lookup and starts deterministically offline.
ENV BOX_SERVER_APP_CFENGINE="lucee@6.2.7"

# Relocate the app off the default /app directory. This app's ColdBox mapping is
# "/app" (-> <root>/app), so hosting the code at the OS path /app collides: any
# absolute path the framework builds (e.g. /app/app/helpers/ApplicationHelper.cfm)
# starts with "/app" and gets re-mapped, producing a broken /app/app/app/... path.
# A non-colliding root avoids this entirely.
ENV APP_DIR="/srv/coldbox"

# ColdBox Healthcheck
ENV HEALTHCHECK_URI="http://127.0.0.1:${PORT}/healthcheck"

# Copy application files to root - Uses .dockerignore to ignore files
COPY ./ ${APP_DIR}/

# Make sure dependencies are installed
RUN cd ${APP_DIR} && box install --production

# WARM UP THE SERVER
RUN ${BUILD_DIR}/util/warmup-server.sh

# Run it
CMD ["/bin/bash", "-c", "$BUILD_DIR/run.sh"]
