@NonCPS
def appendOrReplaceProject(String lineageManifest, String manifest, String name, String path, String remote) {
	def xmlParser = new XmlParser()
	def manifestXml = xmlParser.parseText(manifest)

	if (!xmlParser.parseText(lineageManifest).children().any { it['@path'] == path }) {
		def project = manifestXml.children().find { it['@path'] == path }
		def newProject = new NodeBuilder().project(name: name, path: path, remote: remote)

		if (project) {
			project.replaceNode(newProject)
		} else {
			manifestXml.append(newProject)
		}
	}

	return groovy.xml.XmlUtil.serialize(manifestXml)
}

pipeline {
	agent any
	environment {
		REPOSITORY_URL = 'https://github.com/LineageOS/android.git'
		LOCAL_MANIFEST_FILE = '.repo/local_manifests/roomservice.xml'
		LINEAGE_SNIPPET_MANIFEST_FILE = '.repo/manifests/snippets/lineage.xml'
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
		extendedChoice defaultValue: 'github',
				description: 'Where is the vendor repository hosted?',
				name: 'VENDOR_REPOSITORY_REMOTE',
				type: 'PT_RADIO',
				value: 'github, gitlab'
		validatingString defaultValue: '',
				description: 'Vendor repository name, e.g. TheMuppets/proprietary_vendor_samsung.',
				failedValidationMessage: 'Invalid value',
				name: 'VENDOR_REPOSITORY_NAME',
				regex: '[^\\/]+\\/(android|proprietary)_vendor_[^_]+(_.*)?'
		extendedChoice defaultValue: 'github',
				description: 'Where is the device repository hosted?',
				name: 'DEVICE_REPOSITORY_REMOTE',
				type: 'PT_RADIO',
				value: 'github, gitlab'
		validatingString defaultValue: '',
				description: 'GitHub device repository name, e.g. LineageOS/android_device_samsung_klte.',
				failedValidationMessage: 'Invalid value',
				name: 'DEVICE_REPOSITORY_NAME',
				regex: '[^\\/]+\\/android_device_[^_]+_[^_]+'
		text defaultValue: '',
				description: 'If you need to override device dependencies because they are outdated. One repository name per line, e.g. Galaxy-MSM8916/android_device_samsung_msm8916-common. In most cases you can leave it blank.',
				name: 'OVERRIDE_DEVICE_DEPENDENCIES'
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
					if ('1'.equals(env.BUILD_NUMBER) && currentBuild.getBuildCauses('hudson.model.Cause$UserIdCause') != null) {
						currentBuild.displayName = 'Parameter loading'
						currentBuild.description = 'Please restart pipeline'
						currentBuild.result = 'ABORTED'

						error 'Stopping initial manually triggered build as we only want to get the parameters'
					}
				}

				sh """#!/bin/bash
				repo init -u ${REPOSITORY_URL} -b ${params.BRANCH} --depth=1
				repo sync -j ${params.SYNC_THREADS} --force-sync

				if [[ ! -e "${LOCAL_MANIFEST_FILE}" ]]; then
					mkdir -p "\$(dirname "${LOCAL_MANIFEST_FILE}")"
					tee "${LOCAL_MANIFEST_FILE}" > /dev/null <<-EOF
					<?xml version="1.0" encoding="UTF-8"?>
					<manifest>
					  <remote name="gitlab" fetch="https://gitlab.com" />
					</manifest>
					EOF
				fi
				"""

				script {
					vendor = (params.VENDOR_REPOSITORY_NAME =~ /([^\/]+)\/(?:android|proprietary)_vendor_([^_]+)(?:_.*)?/)[-1][2]
					device = (params.DEVICE_REPOSITORY_NAME =~ /([^\/]+)\/android_device_([^_]+)_([^_]+)/)[-1][3]

					deviceDependencies = params.OVERRIDE_DEVICE_DEPENDENCIES.tokenize('\n').collectEntries {
						def repository = it.tokenize('/')
						return [(repository.last()): repository.init().join('/')]
					}

					def roomservice
					roomservice = { lineageManifest, name, path, remote ->
						def manifest = readFile "${LOCAL_MANIFEST_FILE}"

						writeFile file: "${LOCAL_MANIFEST_FILE}",
							text: appendOrReplaceProject(lineageManifest, manifest, name, path, remote)

						sh("""#!/bin/bash
						repo sync -j ${params.SYNC_THREADS} --force-sync "${path}"
						""")

						if (fileExists("${path}/lineage.dependencies")) {
							def remoteBaseUrl = 'https://github.com'

							if ("gitlab".equals(remote)) {
								remoteBaseUrl = 'https://gitlab.com'
							}

							readJSON(file: "${path}/lineage.dependencies").each {
								def dependencyName = "${deviceDependencies.get(it['repository'], name.tokenize('/').init().join('/'))}/${it['repository']}"
								def response = httpRequest url: "${remoteBaseUrl}/${dependencyName}", quiet: true, validResponseCodes: '100:404'
								def dependencyRemote = remote

								if (response.status == 404) {
									dependencyName = "LineageOS/${it['repository']}"
									dependencyRemote = 'github'
								}

								roomservice(lineageManifest, dependencyName, it['target_path'], dependencyRemote)
							}
						}
					}

					def lineageManifest = readFile "${LINEAGE_SNIPPET_MANIFEST_FILE}"
					roomservice(lineageManifest, params.VENDOR_REPOSITORY_NAME, "vendor/${vendor}", params.VENDOR_REPOSITORY_REMOTE)
					roomservice(lineageManifest, params.DEVICE_REPOSITORY_NAME, "device/${vendor}/${device}", params.DEVICE_REPOSITORY_REMOTE)
				}
			}
		}
		stage('Build') {
			steps {
				sh """#!/bin/bash
				export USE_CCACHE=1
				export CCACHE_EXEC=/usr/bin/ccache
				ccache -M ${params.CCACHE_SIZE}
				${params.CCACHE_COMPRESSION} && ccache -o compression=true
				source build/envsetup.sh
				add_lunch_combo lineage_${device}-${params.BUILD_VARIANT}
				lunch lineage_${device}-${params.BUILD_VARIANT}
				mka bacon -j ${params.BUILD_THREADS}
				"""
			}
			post {
				always {
					archiveArtifacts allowEmptyArchive: false, artifacts: "out/target/product/${device}/recovery.img, out/target/product/${device}/*.zip", onlyIfSuccessful: true
				}
				cleanup {
					sh """#!/bin/bash
					source build/envsetup.sh
					mka clean
					"""
				}
			}
		}
	}
}
