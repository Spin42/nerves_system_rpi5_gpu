# Nerves Buildroot image with the container user remapped to the host user.
#
# The upstream image runs builds as `nerves` (uid 1005), which can't write to
# the bind-mounted dependencies and download cache on a Linux host where the
# user has another uid. Built automatically by mix.exs (see build_runner_config)
# with the host's uid/gid; to build it by hand:
#
#   docker build --build-arg HOST_UID=$(id -u) --build-arg HOST_GID=$(id -g) \
#     -t nerves_system_br_uid$(id -u):1.33.0 support/docker

ARG BASE=ghcr.io/nerves-project/nerves_system_br:1.33.0
FROM ${BASE}

ARG HOST_UID=1000
ARG HOST_GID=1000

USER root
RUN set -e; \
    other_user=$(getent passwd "$HOST_UID" | cut -d: -f1 || true); \
    if [ -n "$other_user" ] && [ "$other_user" != nerves ]; then userdel -r "$other_user" 2>/dev/null || userdel "$other_user"; fi; \
    other_group=$(getent group "$HOST_GID" | cut -d: -f1 || true); \
    if [ -n "$other_group" ] && [ "$other_group" != nerves ]; then groupdel "$other_group"; fi; \
    groupmod -g "$HOST_GID" nerves; \
    usermod -u "$HOST_UID" -g "$HOST_GID" nerves; \
    chown -R nerves:nerves /home/nerves
USER nerves
