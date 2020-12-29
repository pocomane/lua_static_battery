#/usr/bin/env bash

TREE_PATH="./build"
PACKAGE_UPDATER_OWNER="github.com/pocomane"
PACKAGE_UPDATER_NAME="lua_static_battery"
PACKAGE_UPDATER_TYPE="git.url"
UPDATER_BASE_NAME="pack"
SCRIPT_SUB="Scripts"
MISC_SUB="."
HOOK_SUB="hook"
ACTION_HOOK="action"
BOOT_HOOK="boot"

# ---------------------------------------------------------------------------------

TMPFILE="./.download.tmp"
CURL=" curl -L -k "
# TAR=" tar --no-same-owner --no-same-permissions "
TAR=" tar --no-same-owner "
GITCLONE=" git clone "

die(){
  echo "ERROR $1"
  exit 127
}

TREE_PATH="$(readlink -f "$TREE_PATH")"

# All the function use the following suffix (from "Updater Script"): us_

us_init() {
  echo ""
}

us_is_default_argument() {
  if [ "$1" = "" -o "$1" = "." ]; then
    return 0 # true when checked in a "if"
  fi
  return 1 # false when checked in a "if"
}

us_set_package_info() {

  PACKAGE_OWNER="$1"
  PACKAGE_NAME="$2"
  PACKAGE_PATTERN="$3"
  PACKAGE_TYPE="$4"
  PACKAGE_SIMPLENAME="$5"

  # Fallback to UPDATER package (the one containing this file) when the first two
  # arguments are empty
  if us_is_default_argument "$PACKAGE_OWNER"; then
    PACKAGE_OWNER="$PACKAGE_UPDATER_OWNER"
    if us_is_default_argument "$PACKAGE_TYPE"; then
      PACKAGE_TYPE="$PACKAGE_UPDATER_TYPE"
    fi
  fi
  if us_is_default_argument "$PACKAGE_NAME"; then
    PACKAGE_NAME="$PACKAGE_UPDATER_NAME"
  fi

  if us_is_default_argument "$PACKAGE_PATTERN"; then
    PACKAGE_PATTERN="$PACKAGE_NAME"
  fi

  if us_is_default_argument "$PACKAGE_TYPE"; then
    PACKAGE_TYPE="github.release.tgz"
  fi

  if us_is_default_argument "$PACKAGE_SIMPLENAME"; then
    PACKAGE_SIMPLENAME="$PACKAGE_NAME"
  fi

  SCRIPT_DIR="$TREE_PATH/$SCRIPT_SUB"

  PACKAGE_REPO="$PACKAGE_OWNER/$PACKAGE_NAME"
  PACKAGE_WORKING_DIR="$TREE_PATH/$MISC_SUB/$PACKAGE_SIMPLENAME"
  UPDATER_SCRIPT_NAME="$UPDATER_BASE_NAME.sh"
  UPDATER_SCRIPT="$PACKAGE_WORKING_DIR/$UPDATER_SCRIPT_NAME"
  PACKAGE_ACTION="$PACKAGE_WORKING_DIR/$HOOK_SUB/$ACTION_HOOK"
  PACKAGE_BOOT="$PACKAGE_WORKING_DIR/$HOOK_SUB/$BOOT_HOOK"
}

us_remove() {
  echo "Removing $PACKAGE_NAME..."

  # Remove action hooks in the Script dir
  for HOOK in $(ls "$PACKAGE_ACTION" 2>/dev/null) ; do
    # Print error when not found, but DO NOT stop the process !
    rm "$SCRIPT_DIR/${PACKAGE_SIMPLENAME}_$HOOK"
  done

  # Remove package content
  rm -fR "$PACKAGE_WORKING_DIR"
}

us_donwload_github_release() {
  PACKAGE_REPO_API="https://api.github.com/repos/$PACKAGE_REPO"
  PACKAGE_REPO_URL="https://github.com/$PACKAGE_REPO"
  PACK_LIST=$($CURL -L -s $PACKAGE_REPO_API/releases/latest | sed -ne 's|^[ "]*browser_download_url[ "]*:[ "]*\([^"]*\)[ ",\t]*$|\1|p')
  PACK_URL=$(echo "$PACK_LIST" | grep "$PACKAGE_PATTERN" | head -n 1)
  PACKAGE_INFO="repo '$PACKAGE_REPO_URL' / file '$PACK_URL'"
  $CURL "$PACK_URL" -o "$TMPFILE" ||die "can not download $PACKAGE_INFO"
}

us_donwload_tar_gz() {
  $CURL "$PACKAGE_REPO" -o "$TMPFILE" ||die "can not download $PACK_URL"
}

us_donwload_git_url() {
  $GITCLONE http://"$PACKAGE_REPO" ./ ||die "can not download $PACK_URL"
}

us_install(){
  echo "Updating $PACKAGE_NAME..."

  mkdir -p "$PACKAGE_WORKING_DIR" ||die "can not create the working directory '$PACKAGE_WORKING_DIR'"
  cd "$PACKAGE_WORKING_DIR" ||die "can not enter in the working direrctory '$PACKAGE_WORKING_DIR'"

  # extract
  case $PACKAGE_TYPE in
    "copy")
      cp -Rf "$PACKAGE_OWNER"/* ./ ||die "can not unpack $PACKAGE_INFO"
      ;;
    "url.tar.gz")
      us_donwload_tar_gz
      $TAR -xf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "url.tar.gz.sub")
      us_donwload_tar_gz
      $TAR -xf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      DIR="$(ls | head -n 1)"
      mv ./"$DIR"/* ./ ||die "can not unpack $PACKAGE_INFO"
      rmdir "$DIR" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "git.url")
      us_donwload_git_url
      ;;
    "github.bare")
      us_donwload_github_release
      ;;
    "github.uudecode.xz")
      us_donwload_github_release
      uudecode -o "$TMPFILE.xz" "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      rm "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      xz --decompress "$TMPFILE.xz" ||die "can not unpack $PACKAGE_INFO"
      cp "$TMPFILE" "$PACKAGE_NAME" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "github.tar.gx")
      us_donwload_github_release
      $TAR -xzf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      ;;
    "github.tar")
      us_donwload_github_release
      $TAR -xf "$TMPFILE" ||die "can not unpack $PACKAGE_INFO"
      ;;
    *)
      false ||die "unsupported package type"
      ;;
  esac

  if [ "$?" != "0" ]; then
    false ||die "Installation failed"
  fi
  
  rm -f "$TMPFILE"
}

us_show_shortcut() {
  PACKAGE_REPO_CONTENT="https://raw.githubusercontent.com/$PACKAGE_OWNER/$PACKAGE_NAME"
cat << EOF
#!/usr/bin/env bash

  # Test internet
  ping -c 1 www.google.com > /dev/null
  if [ "\$?" != "0" ]; then
    echo "Network not found: check your internet connection or try later"
    exit 126
  fi

  # vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
  # You can simply run the following command instead of running this file
  #
  curl -L -k "$PACKAGE_REPO_CONTENT/master/$UPDATER_SCRIPT_NAME" | bash -s update
  #
  # ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  X=("\${PIPESTATUS[@]}")
  EXIT_CODE=\${X[0]}
  if [ "\$EXIT_CODE" = "0" ]; then
    EXIT_CODE=\${X[1]}
  fi
  if [ "\$EXIT_CODE" != "0" ]; then
    echo "Error downloading the package (\$EXIT_CODE)"
  fi

  read -n 1 -s -r -p "Press any key to continue"
  echo ""
  exit \$EXIT_CODE
EOF
}

us_generate_wrapper() {
cat << EOF
#!/usr/bin/env bash
  cd "$PACKAGE_WORKING_DIR"
  "$1"
  EXIT_CODE="\$?"
  read -n 1 -s -r -p "Press any key to continue"
  echo ""
  exit \$EXIT_CODE
EOF
}

us_is_updater_package(){
  if [ "$PACKAGE_OWNER" = "$PACKAGE_UPDATER_OWNER" -a "$PACKAGE_NAME" = "$PACKAGE_UPDATER_NAME" ]; then
    return 0 # true when checked in a "if"
  fi
  return 1 # false when checked in a "if"
}

us_config() {

  # Add action hooks in the Script dir
  for HOOK in $(ls "$PACKAGE_ACTION" 2>/dev/null) ; do
    us_generate_wrapper "$PACKAGE_ACTION/$HOOK" > "$SCRIPT_DIR/${PACKAGE_SIMPLENAME}_$HOOK" ||die
  done

  if us_is_updater_package; then
    # This is done with a wrapper for other packages, however the Updater is
    # an exception since the "Shortcut" MUST work also withou any installation)
    us_show_shortcut > "$SCRIPT_DIR/${PACKAGE_NAME}_update.sh" ||die
  fi

  # TODO : other configs ? boot hooks ?
}

us_finish(){
  echo "Done."
}

us_package_do() {
  ACTION="$1"
  shift

  # This will fallback to the UPDATER package (i.e. the one containing this
  # file) when no other parameter are given
  us_set_package_info $@

  "us_$ACTION"
}

# PACKAGE LIST
us_do_for_other() {
  
  # us_package_do "$1" /media/data/devel/luaproc-extended luaproc-extended . copy
  # us_package_do "$1" /media/data/devel/luachild luachild . copy

  us_package_do "$1" www.lua.org/ftp lua-5.4.1.tar.gz . url.tar.gz.sub 'lua'
  us_package_do "$1" github.com/keplerproject luafilesystem . git.url
  us_package_do "$1" github.com/diegonehab luasocket . git.url
  us_package_do "$1" github.com/pocomane luachild . git.url
  us_package_do "$1" github.com/pocomane luaproc-extended . git.url
  us_package_do "$1" github.com/pocomane glua . git.url
  
  if   [ "$TARGET" = "" ]; then
    us_package_do "$1" musl.cc i686-linux-musl-native.tgz . url.tar.gz.sub 'muslcc'
  elif [ "$TARGET" = "linux" ]; then
    us_package_do "$1" musl.cc i686-linux-musl-native.tgz . url.tar.gz.sub 'muslcc'
  elif [ "$TARGET" = "windows" ]; then
    us_package_do "$1" musl.cc i686-w64-mingw32-cross.tgz . url.tar.gz.sub 'muslcc'
  elif [ "$TARGET" = "mac" ]; then
    echo "using default compiler for mac"
  elif [ "$TARGET" = "arm_linux" ]; then
    us_package_do "$1" musl.cc arm-linux-musleabihf-cross.tgz . url.tar.gz.sub 'muslcc'
  else
    die 'Invalid TARGET '$TARGET''
  fi
}

us_do_for_updater() {
  us_package_do "$1"
}

us_do_for_all() {
  us_do_for_updater $1
  us_do_for_other $1
}

us_info(){
  echo "Usage Summary."
  echo "To download and update the software:"
  echo "  $0 update"
  echo "To remove the software:"
  echo "  $0 remove"
  echo "To configure the software:"
  echo "  $0 config"
  echo "To view a simple Updater Shortcut script:"
  echo "  $0 show_shortcut"
}

us_is_updater_installed() {
  us_set_package_info
  if [[ -x "$UPDATER_SCRIPT" ]]; then
    return 0 # true when checked in a "if"
  fi
  return 1 # false when checked in a "if"
}

us_run_installed_updater() {
  us_set_package_info

  # For release
  "$UPDATER_SCRIPT" $@ ||die

  # For development
  # us_main_dispatch $@
}

us_update() {
  us_set_package_info
  mkdir -p "$SCRIPT_DIR" ||die "can not create the script directory '$SCRIPT_DIR'"

  if us_is_updater_installed; then
    us_run_installed_updater remove
  else
    us_do_for_all remove  # it will call us_remove
  fi

  us_do_for_updater install
  us_run_installed_updater internal_installer_for_update
}

us_main_dispatch() {
  if [ "$#" = "0" ]; then
    us_info
  else
    case $1 in

      "update")
         us_update
         ;;
      "remove")
         us_do_for_all remove           # it will call us_remove
         ;;
      "internal_installer_for_update")
         us_do_for_other install          # it will call us_install
         us_do_for_all config           # it will call us_config
         ;;
      "config")
         us_do_for_all config           # it will call us_config
         ;;
      "show_shortcut")
         us_set_package_info
         us_show_shortcut
         ;;
      *)
         echo "Invalid option"
         us_info
         false ||die "invalid option"
         ;;
    esac
  fi
}

us_init
us_main_dispatch $@
us_finish

