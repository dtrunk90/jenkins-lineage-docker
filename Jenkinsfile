@NonCPS
def roomservice(String vendor, String device) {
	def manifest = readFile "${LOCAL_MANIFESTS_FILE}"

	def appendProjectNode
	appendProjectNode = { projects, name, path ->
		if (!projects.project.any { it['@path'] == "${path}" }) {
			projects.appendNode(new XmlSlurper().parseText("<project name=\"${name}\" path=\"${path}\" remote=\"github\" />"))
			writeFile file: "${LOCAL_MANIFESTS_FILE}", text: groovy.xml.XmlUtil.serialize(projects)

			sh("""#!/bin/bash
			repo sync -j ${params.SYNC_THREADS} "${path}"
			""")

			if (fileExists("${path}/lineage.dependencies")) {
				def dependencies = readFile "${path}/lineage.dependencies"
				new groovy.json.JsonSlurper().parseText(dependencies).each {
					appendProjectNode(projects, "${name.tokenize('/').first()}/${it['repository']}", it['target_path'])
				}
			}
		}
	}

	def projects = new XmlSlurper().parseText(manifest)

	appendProjectNode(projects, "${params.VENDOR_REPOSITORY_NAME}", "vendor/${vendor}")
	appendProjectNode(projects, "${params.DEVICE_REPOSITORY_NAME}", "device/${vendor}/${device}")
}

pipeline {
	agent any
	environment {
		REPOSITORY_URL = 'https://github.com/LineageOS/android.git'
		LOCAL_MANIFESTS_FILE = '.repo/local_manifests/roomservice.xml'
	}
	parameters {
		listGitBranches branchFilter: 'refs/heads/(lineage-.*)',
				credentialsId: '',
				defaultValue: 'lineage-17.1',
				description: 'The branch you want to build.',
				name: 'BRANCH',
				remoteURL: 'https://github.com/LineageOS/android.git',
				sortMode: 'DESCENDING',
				type: 'PT_BRANCH'
		extendedChoice defaultValue: '4',
				description: 'The number of simultaneous threads/connections while downloading the source code.',
				groovyScript: 'return 2..Runtime.getRuntime().availableProcessors()',
				name: 'SYNC_THREADS',
				type: 'PT_SINGLE_SELECT'
		validatingString defaultValue: '',
				description: 'GitHub vendor repository name, e.g. TheMuppets/proprietary_vendor_samsung.',
				failedValidationMessage: 'Invalid value',
				name: 'VENDOR_REPOSITORY_NAME',
				regex: '[^\\/]+\\/(android|proprietary)_vendor_[^_]+(_.*)?'
		validatingString defaultValue: '',
				description: 'GitHub device repository name, e.g. LineageOS/android_device_samsung_klte.',
				failedValidationMessage: 'Invalid value',
				name: 'DEVICE_REPOSITORY_NAME',
				regex: '[^\\/]+\\/android_device_[^_]+_[^_]+'
		extendedChoice defaultValue: 'userdebug',
				description: 'See https://source.android.com/setup/develop/new-device#build-variants for more information.',
				name: 'BUILD_VARIANT',
				type: 'PT_SINGLE_SELECT',
				value: 'eng, user, userdebug'
		validatingString defaultValue: '50G',
				description: 'Using the compiler cache will result in very noticeably increased build speeds. 25GB-50GB is fine.',
				failedValidationMessage: 'Invalid value',
				name: 'CCACHE_SIZE',
				regex: '[0-9]+G'
		booleanParam name: 'CCACHE_COMPRESSION',
				defaultValue: false,
				description: 'This may involve a slight performance slowdown, but it increases the number of files that fit in the cache.'
		extendedChoice defaultValue: '4',
				description: 'The number of simultaneous threads while building.',
				groovyScript: 'return 2..Runtime.getRuntime().availableProcessors()',
				name: 'BUILD_THREADS',
				type: 'PT_SINGLE_SELECT'
	}
	stages {
		stage('Initialize') {
			steps {
				// ugly workaround for a known jenkins bug: https://issues.jenkins-ci.org/browse/JENKINS-41929
				script {
					if (env.BUILD_NUMBER.equals("1") && currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause') != null) {
						currentBuild.displayName = 'Parameter loading'
						currentBuild.description = 'Please restart pipeline'
						currentBuild.result = 'ABORTED'
						error('Stopping initial manually triggered build as we only want to get the parameters')
					}
				}

				sh """#!/bin/bash
				repo init -u ${REPOSITORY_URL} -b ${params.BRANCH}
				if [[ ! -e "${LOCAL_MANIFESTS_FILE}" ]]; then
					mkdir -p "\$(dirname "${LOCAL_MANIFESTS_FILE}")"
					tee "${LOCAL_MANIFESTS_FILE}" <<-EOF
					<?xml version="1.0" encoding="UTF-8"?>
					<manifest />
					EOF
				fi
				"""

				script {
					vendor = (params.VENDOR_REPOSITORY_NAME =~ /([^\/]+)\/(?:android|proprietary)_vendor_([^_]+)(?:_.*)?/)[-1][2]
					device = (params.DEVICE_REPOSITORY_NAME =~ /([^\/]+)\/android_device_([^_]+)_([^_]+)/)[-1][3]
					roomservice(vendor, device)
				}

				sh """#!/bin/bash
				repo sync -j ${params.SYNC_THREADS}
				source build/envsetup.sh
				add_lunch_combo lineage_${device}-${params.BUILD_VARIANT}
				lunch lineage_${device}-${params.BUILD_VARIANT}
				"""
			}
		}
		stage('Build') {
			steps {
				sh """#!/bin/bash
				export USE_CCACHE=1
				export CCACHE_EXEC=/usr/bin/ccache
				ccache -M ${params.CCACHE_SIZE}
				${params.CCACHE_COMPRESSION} && ccache -o compression=true
				mka bacon -j ${params.BUILD_THREADS}
				"""
			}
			post {
				always {
					archiveArtifacts allowEmptyArchive: false, artifacts: "out/target/product/${device}/recovery.img, out/target/product/${device}/*.zip", onlyIfSuccessful: true
				}
				cleanup {
					dir('out') {
						deleteDir()
					}
				}
			}
		}
	}
}
