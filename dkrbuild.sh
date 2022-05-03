#!/usr/bin/bash

# Change the docker image, as required
DKR_IMAGE=cdp_ml:v1
DKR_FILE=Dockerfile

# Below If clauses and sed order matters, don't change
# If java is not installed on host, install on Docker; set JAVA_HOME in spark-env.sh
if [ X$(readlink -f /usr/bin/java) == "X" ]; then
  echo "Add Java install"
  sed -i.bak1 "s/sudo cronie/sudo cronie java-1.8.0-openjdk-1.8.0.322.b06-1.el7_9.x86_64/" $DKR_FILE
  sed -i '/rm -f / a \    echo JAVA_HOME=$(readlink -f /usr/bin/java |sed "s|/bin/java||") >> $CONDA_SITE_PKGS/pyspark/conf/spark-env.sh  && \\' $DKR_FILE
else
  # Host JAVA_HOME needs to be updated against JAVA_HOME variables in 2 places, and 
  # if pyspark is installed (no CDP installation), add JAVA_HOME in spark-env
  JH=$(readlink -f /usr/bin/java |sed "s/\/bin\/java//")
  echo "Java is available on host: $JH"
  sed -i.bak1 "s|export JAVA_HOME=|export JAVA_HOME=$JH|" $DKR_FILE
  sed -i 's|"JAVA_HOME":|"JAVA_HOME":"'"$JH"'"|' $DKR_FILE
  
  sed -i '/rm -f / a \    echo JAVA_HOME='"$JH"' >> $CONDA_SITE_PKGS/pyspark/conf/spark-env.sh  && \\' $DKR_FILE
fi

# If cloudera parcels are not installed; Add a few properties to spark-defaults.conf file
# If cloudera parcels is installed; don't install pyspark and don't create spark-env.sh, install python2 env and ML packages
if ! [ -d  /opt/cloudera/parcels/CDH ]; then
  echo "Add basic spark configs install" 
  sed -i.bak2 '/spark-submit/d' $DKR_FILE
  sed -i '/spark3-submit/d' $DKR_FILE
  sed -i '/mkdir -p $CONDA_DIR\/etc/,+25d' $DKR_FILE
  sed -i 's|jupyter_notebook_config.py && \\|jupyter_notebook_config.py |' $DKR_FILE
  sed -i '/echo JAVA_HOME=/ i \    mkdir -p $CONDA_SITE_PKGS/pyspark/conf && \\\n    echo -e "spark.master local\\nspark.submit.deployMode client\\nspark.sql.session.timeZone UTC" >> $CONDA_SITE_PKGS/pyspark/conf/spark-defaults.conf  && \\ ' $DKR_FILE
else
  echo "CDH installation found."
  echo "create conda python2.7 env" 
  sed -i.bak2 '/pip install / i \    conda init bash && \\\n    conda create -n py2 python=2.7 && \\\n    conda install -y -n py2 seaborn scikit-learn protobuf && \\' $DKR_FILE
  echo "Remove java, pyspark install and spark env config"
  sed -i '/pip /d' $DKR_FILE
  sed -i '/echo JAVA_HOME=/d' $DKR_FILE
  # If spark3 is not available remove spark3 configs
  if ! [ -d  /opt/cloudera/parcels/SPARK3 ]; then
    echo "CDH SPARK3 is not installed"
    echo "Remove SPARK3 configs"
	sed -i.bak3 '/mkdir -p $CONDA_DIR\/etc/,+16d' $DKR_FILE
	sed -i '/spark3-submit/d' $DKR_FILE
  fi
fi

# Build the image
docker build -t $DKR_IMAGE .
