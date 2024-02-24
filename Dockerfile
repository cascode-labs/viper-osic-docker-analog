#######################################################################
# Setup base image
#######################################################################
ARG BASE_IMAGE=ubuntu:jammy
FROM ${BASE_IMAGE} as base
ARG CONTAINER_TAG=unknown
ENV OSIC_DOCKER_ANALOG_VERSION=${CONTAINER_TAG} \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    TOOLS=/foss/tools \
    PDK_ROOT=/foss/pdks \
    DESIGNS=/foss/designs \
    EXAMPLES=/foss/examples

RUN apt-get -y update
RUN apt-get -y upgrade
COPY tools/xschem/install_base install_xschem_base
RUN bash install_xschem_base

#######################################################################
# Create open_pdks (part of OpenLane)
#######################################################################
FROM base as open_pdks
ARG OPEN_PDKS_REPO_URL="https://github.com/RTimothyEdwards/open_pdks"
ARG OPEN_PDKS_REPO_COMMIT="cd1748bb197f9b7af62a54507de6624e30363943"
ARG OPEN_PDKS_NAME="open_pdks"
COPY tools/open_pdks/install install
RUN bash install

#######################################################################
# Compile ngspice
#######################################################################
FROM open_pdks as ngspice
ARG NGSPICE_REPO_URL="https://github.com/danchitnis/ngspice-sf-mirror"
ARG NGSPICE_REPO_COMMIT="ngspice-42"
ARG NGSPICE_NAME="ngspice"
COPY tools/ngspice/install.sh install.sh
RUN bash install.sh

#######################################################################
# Compile xschem
#######################################################################
FROM base as xschem
ARG XSCHEM_REPO_URL="https://github.com/StefanSchippers/xschem.git"
ARG XSCHEM_REPO_COMMIT="a1c256950676b594bd751636b3b99dc12af63c21"
ARG XSCHEM_NAME="xschem"
COPY tools/xschem/install install
RUN bash install

#######################################################################
# Compile xyce & xyce-xdm
#######################################################################
# FIXME build trilinos as own image, clean with commit etc.

# FROM base as xyce
# ARG XYCE_REPO_URL="https://github.com/Xyce/Xyce.git"
# ARG XYCE_REPO_COMMIT="Release-7.8.0"
# ARG XYCE_NAME="xyce"
# COPY images/xyce/scripts/trilinos.reconfigure.sh /trilinos.reconfigure.sh
# COPY images/xyce/scripts/xyce.reconfigure.sh /xyce.reconfigure.sh
# COPY images/xyce/scripts/install.sh install.sh
# RUN bash install.sh

# FROM xyce as xyce-xdm
# ARG XYCE_XDM_REPO_URL="https://github.com/Xyce/XDM"
# ARG XYCE_XDM_REPO_COMMIT="Release-2.7.0"
# ARG XYCE_XDM_NAME="xyce-xdm"
# COPY images/xyce-xdm/scripts/install.sh install.sh
# RUN bash install.sh


#######################################################################
# Final output container
#######################################################################
FROM base as osic-docker-analog

# Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:80/?password=start
ENV VNC_PORT=5901 \
    NO_VNC_PORT=80 \
    JUPYTER_PORT=8888
EXPOSE $VNC_PORT $NO_VNC_PORT $JUPYTER_PORT

# Environment config
# ENV HOME=/headless \
#     TERM=xterm \
#     STARTUPDIR=/dockerstartup \
#     NO_VNC_HOME=/usr/share/novnc \
#     VNC_COL_DEPTH=24 \
#     VNC_RESOLUTION=1680x1050 \
#     VNC_PW=abc123 \
#     VNC_VIEW_ONLY=false
# FIXME workaround for OpenMPI throwing errors when run inside a container without Capability "SYS_PTRACE".
ENV OMPI_MCA_btl_vader_single_copy_mechanism=none

# Copy all layers into the final container
COPY --from=open_pdks                    ${PDK_ROOT}/           ${PDK_ROOT}/
COPY --from=ngspice                      ${TOOLS}/              ${TOOLS}/
COPY --from=xschem                       ${TOOLS}/              ${TOOLS}/
# COPY --from=xyce                         ${TOOLS}/              ${TOOLS}/
# COPY --from=xyce-xdm                     ${TOOLS}/              ${TOOLS}/


# Allow scripts to be executed by any user
# RUN find $STARTUPDIR/scripts -name '*.sh' -exec chmod a+x {} +

# # Install all APT and PIP packages, as well as noVNC from sources
# RUN $STARTUPDIR/scripts/install.sh


# # Finalize setup/install
# RUN $STARTUPDIR/scripts/post_install.sh

# WORKDIR ${DESIGNS}
# USER 1000:1000
# ENTRYPOINT ["/dockerstartup/scripts/ui_startup.sh"]
# CMD ["--wait"]
