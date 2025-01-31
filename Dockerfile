FROM jupyter/base-notebook:latest

USER root
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.3-linux-x86_64.tar.gz && \
    tar -xvzf julia-1.8.3-linux-x86_64.tar.gz && \
    mv julia-1.8.3 /opt/ && \
    ln -s /opt/julia-1.8.3/bin/julia /usr/local/bin/julia && \
    rm julia-1.8.3-linux-x86_64.tar.gz

ENV mainpath ./
RUN mkdir -p ${mainpath}

USER ${NB_USER}

COPY --chown=${NB_USER}:users ./src ${mainpath}/src
COPY --chown=${NB_USER}:users ./src/plutoserver ${mainpath}/plutoserver

RUN cp ${mainpath}/src/setup.py ${mainpath}/setup.py
RUN cp ${mainpath}/src/runpluto.sh ${mainpath}/runpluto.sh
RUN cp ${mainpath}/src/Project.toml ${mainpath}/Project.toml
 
ENV USER_HOME_DIR /home/${NB_USER}
ENV JULIA_PROJECT ${USER_HOME_DIR}
ENV JULIA_DEPOT_PATH ${USER_HOME_DIR}/.julia

RUN conda config --env --add channels conda-forge
RUN conda config --env --add channels r
RUN conda install numpy xarray dask pandas octave_kernel texinfo r-irkernel
RUN julia -e "import Pkg; Pkg.Registry.update(); Pkg.instantiate();"

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    apt-get install -y --no-install-recommends vim && \
    apt-get install -y --no-install-recommends git && \
    apt-get install -y --no-install-recommends unzip && \
    apt-get install -y --no-install-recommends gfortran && \
    apt-get install -y --no-install-recommends gnuplot && \
    apt-get install -y --no-install-recommends openmpi-bin && \
    apt-get install -y --no-install-recommends openmpi-doc && \
    apt-get install -y --no-install-recommends libopenmpi-dev && \
    apt-get install -y --no-install-recommends mpich && \
    apt-get install -y --no-install-recommends libnetcdf-dev && \
    apt-get install -y --no-install-recommends libnetcdff-dev && \
    apt-get install -y --no-install-recommends octave octave-doc && \
    apt-get install -y --no-install-recommends octave-io && \
    apt-get install -y --no-install-recommends octave-optim && \
    apt-get install -y --no-install-recommends octave-statistics && \
    apt-get install -y --no-install-recommends liboctave-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_USER}

RUN jupyter labextension install @jupyterlab/server-proxy && \
    jupyter lab build && \
    jupyter lab clean && \
    pip install ${mainpath} --no-cache-dir && \
    rm -rf ~/.cache

RUN julia --project=${mainpath} -e "import Pkg; Pkg.instantiate();"
RUN julia ${mainpath}/src/download_stuff.jl

ENV MPI_INC_DIR /usr/lib/x86_64-linux-gnu/openmpi/include
RUN source ./src/build_MITgcm_ECCO.sh

