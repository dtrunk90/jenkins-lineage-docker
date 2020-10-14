FROM jenkins/jenkins:lts-jdk11

USER root

# Install the build packages
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y bc bison build-essential ccache curl flex \
			g++-multilib gcc-multilib git gnupg gperf imagemagick \
			lib32ncurses5-dev lib32readline-dev lib32z1-dev \
			liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev \
			libssl-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop \
			pngcrush python2 rsync schedtool squashfs-tools xsltproc \
			zip zlib1g-dev

# Set python2 as default python
RUN ln -s /usr/bin/python2 /usr/bin/python

# Install the repo command
RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
	&& chmod a+x /usr/local/bin/repo

USER jenkins

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY jenkins.yaml /opt/jenkins/jenkins.yaml

RUN chmod a+x /usr/local/bin/entrypoint.sh

RUN jenkins-plugin-cli --plugins \
	configuration-as-code \
	extended-choice-parameter \
	git \
	http_request \
	job-dsl \
	list-git-branches-parameter \
	pipeline-utility-steps \
	validating-string-parameter \
	workflow-aggregator

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
