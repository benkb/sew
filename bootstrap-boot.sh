








































































































































































































































































































































































































































































#!/bin/sh

set -u

USAGE='<source-file> <target-file>'

source_file="${1:-}"
target_file="${2:-}"


script_name='sew'
script_ext='.pl'

mkdir -p build

script_build="build/${script_name}${script_ext}"
script_boot="${script_name}-boot${script_ext}"

die() { echo "$@" >&2; exit 1; }

[ -n "$source_file" ] || die "usage: $USAGE" 
[ -n "$target_file" ] || die "usage: $USAGE" 

[ -n "$source_file" ] || die "Err: no source file found" 


if [ -f "$target_file" ] ; then
   target_archive="${target_file}.bak"
   if [ -f "$target_archive" ]; then
      die "Err: cannot remove '$target_file', there is already an archive file under '$target_archive'"
   else
      echo "Archive from '$target_file' '$target_archive'"
      mv "$target_file" "$target_archive"
   fi
fi



generate_build_target(){
   local script="${1:-}"
   local name="${2:-}"
   local ext="${3:-}"

   [ -n "$script" ] || die "Err: got no script"
   [ -n "$name" ] || die "Err: got no name"
   [ -n "$ext" ] || die "Err: got no ext"

   [ -f "$script" ] || die "Err: script '$script' not exists"

   local target="${name}${ext}"
   local build_target="build/${target}"


   stamp="$(date +'%s')"
   [ -n "$stamp" ] || die "Err: could not set stamp"
   build_target_v="build/${name}_${stamp}$ext"

   if [ -f "$build_target_v" ]; then
      sleep 1
      stamp="$(date +'%s')"
      [ -n "$stamp" ] || die "Err: could not set stamp"
      build_target_v="build/${name}_${stamp}${ext}"
      [ -f "$build_target_v" ] && die "Err: there is still already a target file '$build_target_v'"
   fi

   local tag="#$name"

   echo perl "${script}" tangle "$source_file" "$tag" 
   perl "${script}" tangle "$source_file" "$tag" || die "Err: could not generate '$target'"

   if [ -f "$target" ]; then
      cp "$target" "$build_target_v"
      cp "$target" "$build_target"
      rm -f "$target"
      echo "'$target' generated into  '$build_target' and '$build_target_v'"
   else
      die "Err: could not generate '$target'"
   fi
}

[ -f "$script_build" ] || {
   [ -f "$script_boot" ] || die "Err: there is no boot script in '$script_boot'"
   generate_build_target "$script_boot" "$script_name" "$script_ext"
   [ -f "$script_build" ] || die "Err: build script would not be generated in '$script_build'"
}

target_name=
target_ext=
case "$target_file" in
   */*) die "Err: target file only in the basename form without folder";;
   *.*)
      target_name="${target_file%.*}"
      target_ext=".${target_file##*.}"
      ;;
   *) 
      target_name="${target_file}"
      target_ext=''
      ;;
esac



generate_build_target "${script_build}" "$target_name" "$target_ext"




