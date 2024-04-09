## bootstrap.sh 


```bash
#!/bin/sh

set -u

USAGE='<source-file> <target-file>'

source_file="${1:-}"
target_file="${2:-}"

compiler='sew.pl'

compiler_name="${compiler%.*}"
compiler_ext="${compiler##*.}"
compiler_source="${compiler_name}.md"

mkdir -p build

compiler_built="build/${compiler}"
compiler_boot="${compiler_name}-boot.${compiler_ext}"

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


```
### move to build

Check if a given compiler run the testst successfully
If yes, move to build folder:
- top:          ./build/compiler.pl
- versioned:    ./build/compiler_nnnnnnn.pl

```bash

baseline_test(){
    local compiler="${1:-}"
    [ -n "$compiler" ] || die "Err: no compiler"

   rm -f baseline.md.md
   perl "${compiler}" "$compiler_source" weave "#baseline" || die "Err: could not generate '$target'"
   [ -f 'baseline.md.md' ] || die "Err: could not extract the baseline test"

    # delete leading empty lines
    perl -i -ne 'BEGIN{ $p; } $p = 1 unless /^\s*$/; print "$_" if $p;' baseline.md.md

    diff baseline.md.md baseline.weave || die "Err: baseline not matching with .weave"
}

move_into_build(){
    local artefact="${1:-}"

   [ -n "$artefact" ] || die "Err: got no artefact"

   [ -f "$artefact" ] || die "Err: invalid artefact '$artefact'"


    local name="${artefact%.*}"
    local ext="${artefact##*.}"

   local build_artefact="build/${artefact}"
   local stamp="$(date +'%s')"
   [ -n "$stamp" ] || die "Err: could not set stamp"
   local build_artefact_v="build/${name}_${stamp}.${ext}"

   if [ -f "$build_artefact_v" ]; then
      sleep 1
      local stamp2="$(date +'%s')"
      [ -n "$stamp2" ] || die "Err: could not set stamp"
      build_artefact_v="build/${name}_${stamp2}.${ext}"
      [ -f "$build_artefact_v" ] && die "Err: there is still already a artefact file '$build_artefact_v'"
   fi
   
    cp "$artefact" "$build_artefact_v"
    cp "$artefact" "$build_artefact"
    rm -f "$artefact"
    echo "'$artefact' moved into  '$build_artefact' and '$build_artefact_v'"

}
```

### The generator

```bash
generate_build_target(){
   local compiler="${1:-}"
   local target="${2:-}"

   [ -n "$compiler" ] || die "Err: got no compiler"
   [ -n "$target" ] || die "Err: got no target"

   [ -f "$compiler" ] || die "Err: compiler '$compiler' not exists"

   local build_target="build/${target}"

    local name="${target%.*}"
   local tag="#$name"

    #### Perl calls the compiler

   echo perl "${compiler}" tangle "$source_file" "$tag" 
   perl "${compiler}" "$source_file" tangle "$tag" || die "Err: could not generate '$target'"

   [ $? -eq 0 ] || die "Err: something wrong with the compiler"
   [ -f "$target" ] || die "Err: could not generate '$target'"
}

```

### The main part

```bash

if [ ! -f "$compiler_built" ]; then 
    [ -f "$compiler_boot" ] || die "Err: there is no boot script in '$compiler_boot'"
    generate_build_target "$compiler_boot" "$compiler"
    [ -f "$compiler" ] || die "Err: compiler could not  generated in '$compiler'"

    baseline_test "$compiler"
    if [ $? -eq 0 ] ; then
        echo "Ok: baseline test successfull, lets move into build"
        move_into_build "$compiler"
    else
        die "Err: baseline test was not successful"
    fi

    [ -f "$compiler_built" ] || die "Err: compiler still not in build ('$compiler_built')"
fi


case "$target_file" in
   */*) die "Err: target file only in the basename form without folder";;
   *) : ;;
esac

echo generate_build_target "${compiler_built}" "$target_file"
generate_build_target "${compiler_built}" "$target_file"

move_into_build "$target_file"


```


