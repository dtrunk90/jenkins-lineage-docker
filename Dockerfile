FROM jenkins/jenkins:lts

USER root

# Install the build packages
RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y bc bison build-essential ccache curl flex \
			g++-multilib gcc-multilib git gnupg gperf imagemagick \
			lib32ncurses5-dev lib32readline-dev lib32z1-dev \
			liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev \
			libssl-dev libwxgtk3.0-dev libxml2 libxml2-utils lzop \
			pngcrush rsync schedtool squashfs-tools xsltproc zip \
			zlib1g-dev

# Install the repo command
RUN curl -o /usr/local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo \
	&& chmod a+x /usr/local/bin/repo

USER jenkins

COPY jenkins.yaml $JENKINS_HOME

RUN jenkins-plugin-cli --plugins \
	configuration-as-code \
	extended-choice-parameter \
	git \
	job-dsl \
	list-git-branches-parameter \
	validating-string-parameter
