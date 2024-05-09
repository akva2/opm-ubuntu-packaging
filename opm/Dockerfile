ARG ubuntu_ver=jammy
FROM ubuntu:${ubuntu_ver} AS stage1
ARG build_threads=4
ARG ubuntu_ver=jammy
ARG ppa=ppa
ARG email
ARG opm_version=1
WORKDIR /tmp/opm
ADD . .
RUN mkdir /tmp/opm/output
RUN useradd builder
RUN chown builder:builder /tmp/opm -R
RUN echo "Configuring build environment"
RUN /bin/bash /tmp/opm/scripts/setup_buildenv.sh ${ppa}
RUN echo "Making debs"
RUN /bin/bash /tmp/opm/scripts/make_debs.sh /tmp/opm ${ubuntu_ver} ${build_threads} "${email}" ${opm_version}
FROM scratch AS export_stage
COPY --from=stage1 /tmp/opm/output/* .
