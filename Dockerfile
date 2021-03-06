FROM ubuntu:14.04.4
MAINTAINER Tomaz Curk <tomazc@gmail.com>

# thanks to https://github.com/bschiffthaler/ngs/blob/master/base/Dockerfile
# and https://github.com/AveraSD/ngs-docker-star/blob/master/Dockerfile

ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

RUN useradd -u 1010 -m -d /home/enuser enuser

# Append repository to get the latest R version
# Details: https://cloud.r-project.org/bin/linux/ubuntu/
RUN gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys E084DAB9; true
RUN gpg -a --export E084DAB9 | apt-key add -
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list

# update system and install prerequisites
# avoid apt-get upgrade -y
RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y g++
RUN apt-get install -y zlib1g-dev
RUN apt-get install -y libzmq-dev
RUN apt-get install -y make
RUN apt-get install -y python3
RUN apt-get install -y python3-pip
RUN apt-get install -y python3-setuptools
RUN apt-get install -y python-virtualenv
RUN apt-get install -y python-pip
RUN apt-get install -y git
RUN apt-get install -y r-base
RUN apt-get install -y default-jre
RUN apt-get install -y libxml2-dev
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y build-essential
RUN apt-get install -y python2.7-dev
RUN apt-get install -y libfreetype6-dev

RUN apt-get autoclean -y && \
    apt-get autoremove -y

# Default R library location ; must be modified as root
RUN echo "R_LIBS=/home/enuser/.R" >> /etc/R/Renviron.site


##################
#### Install python2.7 requirements (for DEXSeq)
RUN pip install numpy
RUN pip install freetype-py
RUN pip install matplotlib
RUN pip install HTSeq


#################
### RNA-star

# Compile STAR from source
WORKDIR /tmp/STAR
RUN wget https://github.com/alexdobin/STAR/archive/STAR_2.4.2a.tar.gz
RUN tar -xvzf STAR_2.4.2a.tar.gz
WORKDIR /tmp/STAR/STAR-STAR_2.4.2a/source
RUN make STAR
RUN mkdir -p /home/enuser/bin && cp STAR /home/enuser/bin
WORKDIR /tmp
RUN rm -rfv STAR


#################
### Git LFS
WORKDIR /tmp/git-lfs
RUN wget https://github.com/git-lfs/git-lfs/releases/download/v1.5.4/git-lfs-linux-386-1.5.4.tar.gz
RUN tar -xvzf git-lfs-linux-386-1.5.4.tar.gz
WORKDIR /tmp/git-lfs/git-lfs-1.5.4/
RUN ./install.sh
WORKDIR /tmp/
RUN rm -Rf git-lfs


#################
#### enCount
USER enuser
WORKDIR /home/enuser
ADD requirements.txt /home/enuser
RUN virtualenv -p python3 /home/enuser/.encountenv
RUN .encountenv/bin/pip install --upgrade -r requirements.txt

USER root
ADD . /home/enuser/enCount
RUN chown -R enuser.enuser /home/enuser

RUN mkdir /endata
RUN chown -R enuser.enuser /endata

USER enuser
WORKDIR /home/enuser/enCount
RUN ../.encountenv/bin/pip install -e .


#################
### Set up R env
USER enuser
RUN mkdir /tmp/Renv
WORKDIR /tmp/Renv
RUN export R_LIBS=/home/enuser/.R
RUN mkdir -p /home/enuser/.R
RUN wget "https://github.com/hartleys/QoRTs/releases/download/v1.1.8/QoRTs_1.1.8.tar.gz"
RUN Rscript /home/enuser/enCount/install/install.R
RUN rm QoRTs_1.1.8.tar.gz
WORKDIR /tmp
RUN rm -Rf Renv

WORKDIR /home/enuser/
CMD ["/home/enuser/.encountenv/bin/python3", "-m", "enCount.process_loop"]


