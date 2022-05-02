# centos-jupyterlab-docker
JupyterLab docker container with Python3, R packages and crond scheduler


## Overview
This repository contains the Dockerfile and scripts to create, run a JupyterLab docker container with the below components.
 

## Installation
Following are installed on the container
- Python3:  With JupyterLab, pyspark, scipy, seaborn and scikit-learn-intelex packages
- R: With data processing packages
- crond: To run jobs in the background from the container
- Java: Is installed on the container, if Java is not available on the host

If Cloudera Data Platform(CDP) is installed on the host, then the container will also have
- Python2: With scipy, seaborn and scikit-learn packages, as a separate conda environment py2
- pyspark will not be installed, but CDP pyspark(2) will be configured on py2
- pyspark(2) can be used from the terminal only, not with a notebook kernel. See example below
- pyspark(3) will not be configured

If SPARK3 is also installed on CDP, then
- pyspark(3) is configured
- pyspark(3) can be used on the notebook or from the terminal

## Building the image
Do not run "docker build" directly against the Dockerfile. Always use dkrbuild.sh script

```
[root@]# ./dkrbuild.sh
Java is available on host: /usr/java/jdk1.8.0_232-cloudera
CDH installation found.
create conda python2.7 env
Remove java, pyspark install and spark env config
Sending build context to Docker daemon  29.18kB
Step 1/24 : FROM centos:7.9.2009
 ---> eeb6ee3f44bd

```

## Running the image
Do not run "docker run" directly. Always use rundkr.sh script. Script checks 
- Java, CDP and SPARK3 installation on the host, and adds the required mounts for the container
- Available port to launch JupyterLab
- /etc/ krb5.conf and ntp.conf, and adds the files as mounts for the container

```
[root@]# ./rundkr.sh
Java is available on host: /usr/java/jdk1.8.0_232-cloudera
Add CDP mounts
Add SPARK3 mounts
launching container on 8878, with the mounts:   --mount type=bind,source=/usr/java/jdk1.8.0_232-cloudera,target=/usr/java/jdk1.8.0_232-cloudera,readonly --mount type=bind,source=/usr/share/java,target=/usr/share/java,readonly  --mount type=bind,source=/opt/cloudera/parcels/CDH,target=/opt/cloudera/parcels/CDH,readonly  --mount type=bind,source=/opt/cloudera/parcels/CDH-7.1.7-1.cdh7.1.7.p1000.24102687,target=/opt/cloudera/parcels/CDH-7.1.7-1.cdh7.1.7.p1000.24102687,readonly  --mount type=bind,source=/etc/hadoop/conf,target=/etc/hadoop/conf,readonly --mount type=bind,source=/etc/hive/conf,target=/etc/hive/conf,readonly --mount type=bind,source=/etc/spark/conf,target=/etc/spark/conf,readonly  --mount type=bind,source=/opt/cloudera/parcels/SPARK3,target=/opt/cloudera/parcels/SPARK3,readonly  --mount type=bind,source=/opt/cloudera/parcels/SPARK3-3.1.1.3.1.7270.0-253-1.p0.11638568,target=/opt/cloudera/parcels/SPARK3-3.1.1.3.1.7270.0-253-1.p0.11638568,readonly  --mount type=bind,source=/etc/spark3/conf,target=/etc/spark3/conf,readonly   --mount type=bind,source=/etc/ntp.conf,target=/etc/ntp.conf,readonly

Docker container id is:
cce067383567f068dc431addcdde8e29c4c84302a5922b2cbca793c711840b37

*******JupyterLab is available at*********

http://<host>:8878

```

## Running pyspark2 against CDP from terminal
__Notice:__ Activate py2 env before running python2 or pyspark(2)

```
(base) [jovyan@m4 ~]$ conda activate py2
(py2) [jovyan@m4 ~]$ python
Python 2.7.18 |Anaconda, Inc.| (default, Jun  4 2021, 14:47:46) 
[GCC 7.3.0] on linux2
Type "help", "copyright", "credits" or "license" for more information.
>>> from sklearn.svm import SVC
>>> from pyspark.sql import SparkSession, types, functions as f


spark = SparkSession.builder\
                .enableHiveSupport()\
                .appName("Test")\
                .getOrCreate()
>>> 
>>> dir()
['SVC', 'SparkSession', '__builtins__', '__doc__', '__name__', '__package__', 'f', 'types']
>>> exit()
(py2) [jovyan@m4 ~]$  


```

Or launch pyspark2 directly from terminal

```
(py2) [jovyan@m4 ~]$ pyspark
Python 2.7.18 |Anaconda, Inc.| (default, Jun  4 2021, 14:47:46) 
[GCC 7.3.0] on linux2
Type "help", "copyright", "credits" or "license" for more information.
2022-05-02 18:35:50,026 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
2022-05-02 18:35:51,991 WARN util.Utils: Service 'SparkUI' could not bind on port 4040. Attempting port 4041.
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 2.4.7.7.1.7.1000-141
      /_/

Using Python version 2.7.18 (default, Jun  4 2021 14:47:46)
SparkSession available as 'spark'.
>>> 

```


## Running pyspark(3) against CDP from terminal

```
(base) [jovyan@m4 ~]$ python
Python 3.9.7 (default, Sep 16 2021, 13:09:58) 
[GCC 7.5.0] :: Anaconda, Inc. on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> from sklearnex.svm import SVC
>>> from pyspark.sql import SparkSession, types, functions as f
>>> spark = SparkSession.builder\
...             .enableHiveSupport()\
...             .appName("Test")\
...             .getOrCreate()
22/05/02 16:06:39 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Using Spark's default log4j profile: org/apache/spark/log4j-defaults.properties
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
>>> exit()

```
Or launch pyspark3 directly from terminal

```
(base) [jovyan@m4 ~]$ pyspark3
Python 3.9.7 (default, Sep 16 2021, 13:09:58) 
[GCC 7.5.0] :: Anaconda, Inc. on linux
Type "help", "copyright", "credits" or "license" for more information.
22/05/02 16:07:06 WARN NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
Using Spark's default log4j profile: org/apache/spark/log4j-defaults.properties
Setting default log level to "WARN".
To adjust logging level use sc.setLogLevel(newLevel). For SparkR, use setLogLevel(newLevel).
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /__ / .__/\_,_/_/ /_/\_\   version 3.1.1.3.1.7270.0-253
      /_/

Using Python version 3.9.7 (default, Sep 16 2021 13:09:58)
Spark context Web UI available at http://m4.my.site:4040
Spark context available as 'sc' (master = local[*], app id = local-1651507628332).
SparkSession available as 'spark'.
>>> 

```

## Running cron jobs in the Container

To list the scheduled jobs, use crontab -l. To edit the scheduler, use crontab -e.

e.g. Run date command every min and output to /tmp/date.out file

```
(base) [jovyan@m4 ~]$ crontab -e
crontab: installing new crontab
(base) [jovyan@m4 ~]$ crontab -l
* * * * * date >>/tmp/date.out
(base) [jovyan@m4 ~]$ cat /tmp/date.out
Mon May  2 14:26:01 UTC 2022
Mon May  2 14:27:01 UTC 2022
Mon May  2 14:28:01 UTC 2022

```
