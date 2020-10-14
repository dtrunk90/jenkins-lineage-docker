#!/bin/sh
# Create symlink in JENKINS_HOME to /opt/jenkins/jenkins.yaml if it doesn't exist
if ! -e "${JENKINS_HOME}/jenkins.yaml"; then
	ln -s /opt/jenkins/jenkins.yaml "${JENKINS_HOME}/jenkins.yaml"
fi

# Run Jenkins
/usr/local/bin/jenkins.sh
