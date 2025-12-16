#!/bin/sh
# #############################################################################
# THIS is RUNALP container launcher utility. It may contain application
# specific code in the `container_prerun` function. See
# github.com/pocomane/runalp for more information.
# #############################################################################
# RUNALP start
set -e
SCRDIR="$(readlink -f "$(dirname "$0")")"

# RUNAPL config
HOST_SCRIPT_DIR="$SCRDIR"
CONT_SCRIPT_DIR="/runalp"
CONT_WORK_DIR="/workdir"
IMAGE_FS="containerfs"
LAUNCHER_SH="run.sh"
HOST_LAUNCHER="$HOST_SCRIPT_DIR/$IMAGE_FS/$LAUNCHER_SH"
IMAGE_URL="https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/alpine-minirootfs-3.21.3-x86_64.tar.gz"

# RUNALP utility

download_container(){
  mkdir -p "$HOST_SCRIPT_DIR/$IMAGE_FS"
  cd "$HOST_SCRIPT_DIR/$IMAGE_FS"
  curl "$IMAGE_URL" --output - | tar -xzf -
  LD_LIBRARY_PATH="./lib:./usr/lib" "./lib/ld-musl-x86_64.so.1" -- "./sbin/apk" -p . add bubblewrap
  cd -
}

generate_container_runner(){

  touch "$HOST_LAUNCHER"
  chmod ugo+x "$HOST_LAUNCHER"

  set +x
  echo "extract "$HOST_LAUNCHER""
  cat > "$HOST_LAUNCHER" << EOF
#!/bin/sh

# Put in the RUNALP_X environment variable "yes" to enable X server applications
# Put in the RUNALP_ATTACH environment variable a pid to attach to its container

set -e

CONTROOT="\$(readlink -f "\$(dirname "\$0")")"
if [ "\$CONTROOT" = "" ] ; then
  CONTROOT="."
fi

if [ "\$#" -lt 1 ] ; then
  set -- -- sh
fi

#    note:
#    - "--cap-add ALL" should be removed for security reason (but it neess some time to find a
#      good set of capability to keep)
#    - "--newsession" should be add to avoid guest injecting command in the host terminal (but it
#      give issues when you want use the container throug the host terminal)
#    - instead of "--newsession", at least the TIOCSTI capability should be dropped
#

if [ "\$RUNALP_EXTRA_BIND_SOURCE" != "" -a "\$RUNALP_EXTRA_BIND_DESTINATION" != "" ] ; then
  set -- --bind "\$RUNALP_EXTRA_BIND_SOURCE"/ "\$RUNALP_EXTRA_BIND_DESTINATION"/ "\$@"
fi

if [ "\$RUNALP_X" = "yes" ] ; then
  if [ "\$XAUTHORITY" = "" ] ; then XAUTHORITY="\$HOME/.Xauthority"; fi
  set -- \\
    --setenv DISPLAY "\$DISPLAY" \\
    --bind "\$XAUTHORITY" /root/.Xauthority \\
    "\$@"
fi

set -- \\
  --cap-add ALL \\
  --uid "0" \\
  --gid "0" \\
  --die-with-parent \\
  \\
  --unshare-ipc \\
  --unshare-uts \\
  --unshare-cgroup \\
  --clearenv \\
  \\
  --bind "\$CONTROOT"/ / \\
  --dev /dev \\
  --tmpfs /run \\
  --tmpfs /tmp \\
  --bind /sys /sys \\
  --proc /proc \\
  --tmpfs /dev/shm \\
  --bind /sys /sys \\
  \\
  --chdir "$CONT_WORK_DIR" \\
  --setenv HOME /root \\
  --setenv PATH /bin:/usr/bin:/sbin:/usr/sbin \\
  --ro-bind /etc/resolv.conf /etc/resolv.conf \\
  --ro-bind /etc/hosts /etc/hosts \\
  --ro-bind /etc/services /etc/services \\
  \\
  --bind "$HOST_SCRIPT_DIR" "$CONT_SCRIPT_DIR" \\
  --bind "./" "$CONT_WORK_DIR" \\
  \\
  "\$@"
    
# --unshare-all
# --share-net
    
if [ "\$RUNALP_ATTACH" = "" ] ; then
  exec 3>&1
  set -- \\
    --info-fd 3 \\
    --unshare-user \\
    --unshare-pid \\
    "\$@"
else
  exec 3>&1
  exec 4</proc/"\$RUNALP_ATTACH"/ns/user
  exec 5</proc/"\$RUNALP_ATTACH"/ns/pid
  # What to do with other namespace? cgroup ipc mnt net pid_for_children time
  # time_for_children uts
  set -- \\
    --info-fd 3 \\
    --userns 4 \\
    --pidns 5 \\
    "\$@"
fi

#set -x
LD_LIBRARY_PATH="\$CONTROOT/lib:\$CONTROOT/usr/lib" exec "\$CONTROOT/lib/ld-musl-x86_64.so.1" -- "\$CONTROOT/usr/bin/bwrap" "\$@"

EOF
  set -x

  "$HOST_LAUNCHER" /sbin/apk fix -drux
  rm -f "./var/cache/apk"/*
}

run_in_container(){
  "$HOST_LAUNCHER" "$@"
}

container_main(){
  container_prerun "$@"
  "$@"
}

main(){
  ASK_CONTAINER_PRERUN="dflqkb5gf8a93btngla93u23k5j5bygqqwer4"
  if [ "$1" = "$ASK_CONTAINER_PRERUN" ] ; then
    shift
    container_main "$@"
  else
    basic_image_check="$HOST_SCRIPT_DIR/$IMAGE_FS/container.done"
    if [ ! -e "$basic_image_check" ] ; then
      set -x
      download_container
      generate_container_runner
      touch "$basic_image_check"
    fi
    run_in_container "./$0" "$ASK_CONTAINER_PRERUN" "$@"
  fi
}

# RUNAL end
# #############################################################################

container_prerun(){
  apk add zip make binutils curl git
  chmod ugo+x pack.sh build.sh

  # export TARGET="linux"
  # ./pack.sh update
  # ./build.sh
  
  # export TARGET="windows"
  # ./pack.sh update
  # ./build.sh

  # export TARGET="arm_linux"
  # ./pack.sh update
  # TARGET="arm_linux" ./build.sh
}

# #############################################################################
# RUNALP main dispatcher
main "$@"

