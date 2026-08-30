#!/bin/bash

# Default exports
NOMOUNT_LATEST=$(git ls-remote --tags --sort=-v:refname https://github.com/maxsteeel/nomount.git | awk 'index($2,"^{}")==0 {sub("refs/tags/","",$2); print $2; exit}')
[ -n "$NOMOUNT_LATEST" ] || { echo "Fatal: could not resolve latest nomount tag!"; exit 1; }

export NOMOUNT_SETUP_URI="https://github.com/maxsteeel/nomount/raw/${NOMOUNT_LATEST}/kernel/setup.sh"
export NOMOUNT_SETUP_BRANCH="$NOMOUNT_LATEST"

cat > /tmp/nomount_resolved.env << RESOLVEDEOF
NOMOUNT_RESOLVED_TAG="${NOMOUNT_LATEST}"
RESOLVEDEOF

echo "-- Running nomount setup script..."
curl -LSs --fail --retry 3 "$NOMOUNT_SETUP_URI" | bash -s "$NOMOUNT_SETUP_BRANCH" &> /dev/null || { echo "Fatal: Nomount setup script failed to download/run!"; exit 1; }

# Enable the necessary Nomount configs
echo "CONFIG_NOMOUNT=y" >> $MAIN_DEFCONFIG

# Allow nomount to compile on C89 environment
echo "ccflags-y += -Wno-declaration-after-statement" >> fs/nomount/Makefile
#!/bin/bash

NOMOUNT_LATEST=$(git ls-remote --tags --sort=-v:refname https://github.com/maxsteeel/nomount.git | awk 'index($2,"^{}")==0 {sub("refs/tags/","",$2); print $2; exit}')
[ -n "$NOMOUNT_LATEST" ] || { echo "Fatal: could not resolve latest nomount tag!"; exit 1; }

export NOMOUNT_SETUP_URI="https://github.com/maxsteeel/nomount/raw/${NOMOUNT_LATEST}/kernel/setup.sh"
export NOMOUNT_SETUP_BRANCH="$NOMOUNT_LATEST"

cat > /tmp/nomount_resolved.env << RESOLVEDEOF
NOMOUNT_RESOLVED_TAG="${NOMOUNT_LATEST}"
RESOLVEDEOF

echo "-- Running nomount setup script..."
curl -LSs --fail --retry 3 "$NOMOUNT_SETUP_URI" | bash -s "$NOMOUNT_SETUP_BRANCH" &> /dev/null || { echo "Fatal: Nomount setup script failed to download/run!"; exit 1; }

# Enable the necessary Nomount configs
echo "CONFIG_NOMOUNT=y" >> $MAIN_DEFCONFIG

# Allow nomount to compile on C89 environment
echo "ccflags-y += -Wno-declaration-after-statement" >> fs/nomount/Makefile
