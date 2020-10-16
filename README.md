# Docker image for Jenkins

This is a fully functional pre-configured [Jenkins](https://jenkins.io) server with pre-installed plugins for building LineageOS.

## Usage

### Running
`docker run -d -v jenkins_lineage_home -p 80:8080 dtrunk90/jenkins-lineage`

### Building LineageOS
1. Open [http://localhost](http://localhost)
2. Login with username `admin` and password `admin`
3. Click on the "lineage" job
4. Click on "Build Now" and wait until the build aborts
5. Reload the page and click on "Build with Parameters"
6. Follow the warnings by approving the In-process script
7. Get back to the job and click on "Build with Parameters" again
8. Fill in the parameters form (see below for details)
9. Click on "Build"

### Parameters
BRANCH
: The branch you want to build.

SYNC_THREADS
: The number of simultaneous threads/connections while downloading the source code.

VENDOR_REPOSITORY_REMOTE
: Where is the vendor repository hosted?

VENDOR_REPOSITORY_NAME
: Vendor repository name, e.g. TheMuppets/proprietary_vendor_samsung.

DEVICE_REPOSITORY_REMOTE
: Where is the device repository hosted?

DEVICE_REPOSITORY_NAME
: Device repository name, e.g. LineageOS/android_device_samsung_klte.

OVERRIDE_DEVICE_DEPENDENCIES
: If you need to override device dependencies because they are outdated. One repository name per line, e.g. Galaxy-MSM8916/android_device_samsung_msm8916-common. In most cases you can leave it blank.

BUILD_VARIANT
: See [build variants](https://source.android.com/setup/develop/new-device#build-variants) for more information.

CCACHE_SIZE
: Using the compiler cache will result in very noticeably increased build speeds. 25GB-50GB is fine.

CCACHE_COMPRESSION
: This may involve a slight performance slowdown, but it increases the number of files that fit in the cache.

BUILD_THREADS
: The number of simultaneous threads while building.
