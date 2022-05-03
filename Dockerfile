FROM centos:7.9.2009

LABEL maintainer="Yogesh Rajashekharaiah"


# Jupyter notebook user is hardcoded, don't change

ARG JP_USER="jovyan"
ARG TMPDIR="/tmp"
ARG CONDA_DIR="/home/${JP_USER}/miniconda3"
ARG CONDA_SITE_PKGS="${CONDA_DIR}/lib/python3.9/site-packages"
ARG JP_PORT=8888
ARG JPDOCK="https://raw.githubusercontent.com/jupyter/docker-stacks/master/base-notebook"
ARG JPPWD='argon2:$argon2id$v=19$m=10240,t=10,p=8$9RPUJx8eqkRcb/PX191/ew$sRgcQwm6Wo7NZje/ZG/w3LNRKwbpET+DT4hifDu1+ms'

# Args for conda repo locations, in case you want to use local repo for conda install
# Similar to conda local repo, yum local repo can be used

ARG BASE_REPO="https://repo.anaconda.com"
ARG CONDA_FILE="Miniconda3-py39_4.11.0-Linux-x86_64.sh"

ENV LANG=en_US.UTF-8 \
    PATH=${CONDA_DIR}/bin:$PATH \
    USER=${JP_USER} \
    NB_USER=${JP_USER} \
    NB_UID=1000 \
    NB_GID=1000 \
    CONDA_DIR=${CONDA_DIR}

# Download and install conda, java, crond, sudo, bzip2, ntp
# Make changes ntp servers, as required
# Edit /etc/pam.d/crond, /etc/cron.allow to avoid auth errors on cron
# Add /usr/local/bin, $CONDA_DIR to secure path for root to launch jupyter as $JPUSER
# Change /var/spool/cron permissions to for direct edit of crontab file

USER root
RUN useradd -m -s /bin/bash ${JP_USER} && \
    yum install -y bzip2 ntp sudo cronie && \
    yum clean all && \
    systemctl enable ntpd  && \
    sed -i '/account    required   pam_access.so/c\account    sufficient pam_succeed_if.so uid = 1000 quiet' /etc/pam.d/crond && \
    sed -i "s|^Defaults    secure_path = .*|&:/usr/local/bin:${CONDA_DIR}/bin|" /etc/sudoers && \
    chmod o+rx /var/spool/cron; echo ${JP_USER} > /etc/cron.allow && \
    touch /var/spool/cron/${JP_USER} ; chown ${JP_USER}:${JP_USER} /var/spool/cron/${JP_USER} && \
    for fl in "start.sh" "start-notebook.sh" "start-singleuser.sh"; do curl -L "${JPDOCK}/$fl" -o /usr/local/bin/${fl}; done && \
    for fl in pyspark spark-shell spark-submit; do ln -sf /opt/cloudera/parcels/CDH/bin/$fl /usr/local/bin/$fl; done  && \
    for fl in pyspark3  spark3-shell  spark3-submit; do ln -sf /opt/cloudera/parcels/SPARK3/bin/$fl /usr/local/bin/$fl; done  && \
    echo -e '#!/bin/bash\n\n\
set -e\n\
echo "starting cron daemon"\n\
crond -m off\n\
echo "starting jupyter notebook"\n\
start-notebook.sh "$@"\n' > /usr/local/bin/start-process.sh && \
    chmod 0755 /usr/local/bin/start*.sh

# Conda related installation
# conda cofig changes 1) create jupyter_notebook_config.py 2) create env vars in conda envs folders
# 1) Refer https://jupyter-server.readthedocs.io/en/latest/other/full-config.html#other-full-config
# 2) Refer https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#macos-and-linux

USER ${JP_USER}
RUN cd ${TMPDIR} && \
    curl -L ${BASE_REPO}/miniconda/${CONDA_FILE} -o ${CONDA_FILE} && \
    /bin/bash ./${CONDA_FILE} -f -b -p ${CONDA_DIR} && \
    conda config --system --set auto_update_conda false && \
    conda install -y -n base jupyterlab seaborn scikit-learn-intelex protobuf && \
    pip install pyspark==3.2.1 && \
    conda install -y -n base r-base r-caret r-randomforest r-plyr r-reshape2 r-irkernel   && \
    rm -f ${CONDA_FILE}  && \
    pip cache purge && \
    conda clean --all --quiet --yes -f && \
    mkdir /home/${JP_USER}/.jupyter && \
    echo -e 'import os\n\n\
os.umask(0o022)\n\n\
c = get_config()\n\
c.ServerApp.ip = "*"\n\
c.NotebookApp.open_browser = False\n\
c.ServerApp.port = 8888\n\
c.ServerApp.notebook_dir = "/home/'"${JP_USER}"'"\n\
c.FileContentsManager.delete_to_trash = False\n\
c.ServerApp.password = '\""$JPPWD"\" > /home/${JP_USER}/.jupyter/jupyter_notebook_config.py && \
    mkdir -p $CONDA_DIR/etc/conda/deactivate.d $CONDA_DIR/etc/conda/activate.d && \
    echo -e '#!/bin/bash\n\n\
export PYTHONPATH=/opt/cloudera/parcels/SPARK3/lib/spark3/python:/opt/cloudera/parcels/SPARK3/lib/spark3/python/lib/py4j-0.10.9-src.zip\n\
export JAVA_HOME=\n\
export SPARK_CONF_DIR=/etc/spark3/conf'  > $CONDA_DIR/etc/conda/activate.d/env_vars.sh && \
    echo -e '#!/bin/bash\n\n\
unset PYTHONPATH\n\
unset JAVA_HOME\n\
unset SPARK_CONF_DIR'  > $CONDA_DIR/etc/conda/deactivate.d/env_vars.sh && \
    mv  $CONDA_DIR/share/jupyter/kernels/python3/kernel.json $CONDA_DIR/share/jupyter/kernels/python3/kernel.json.1 && \
	head -n -2 $CONDA_DIR/share/jupyter/kernels/python3/kernel.json.1 > $CONDA_DIR/share/jupyter/kernels/python3/kernel.json && \
    echo -e ' },\
 "env": { \
  "PYTHONPATH": "${PYTHONPATH}:/opt/cloudera/parcels/SPARK3/lib/spark3/python:/opt/cloudera/parcels/SPARK3/lib/spark3/python/lib/py4j-0.10.9-src.zip", \
  "JAVA_HOME":\
 }\
}' >> $CONDA_DIR/share/jupyter/kernels/python3/kernel.json  && \
    mkdir -p $CONDA_DIR/envs/py2/etc/conda/deactivate.d $CONDA_DIR/envs/py2/etc/conda/activate.d && \
    echo -e '#!/bin/bash\n\n\
export PYTHONPATH=/opt/cloudera/parcels/CDH/lib/spark/python:/opt/cloudera/parcels/CDH/lib/spark/python/lib/py4j-0.10.7-src.zip\n\
export JAVA_HOME=\n\
export SPARK_CONF_DIR=/etc/spark/conf'  > $CONDA_DIR/envs/py2/etc/conda/activate.d/env_vars.sh && \
    echo -e '#!/bin/bash\n\n\
unset PYTHONPATH\n\
unset JAVA_HOME\n\
unset SPARK_CONF_DIR'  > $CONDA_DIR/envs/py2/etc/conda/deactivate.d/env_vars.sh

USER root
WORKDIR /home/${JP_USER}
EXPOSE ${JP_PORT}
CMD ["start-process.sh"]

# Do not change -l, login shell
ENTRYPOINT ["/bin/bash", "-l"]
