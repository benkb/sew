% sew - a literate programming tool

This is tool in the tradition of Norman Ramsey `noweb` tool and also features
the `tangle` and `weave` command to compose source code and literate text.

## Development

sh ./bootstrap-boot.sh sew.md bootstrap.sh


sh ./build/bootstrap.sh sew.md sew.pl

perl build/sew.pl tangle lore.md



## sew.pl { #sew tangle=.pl }

### Head and Global Definitions
```perl
#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper 'Dumper';

#test

our $USAGE = '<cmd> <sourcefile> [tag] ...';

# sew - a literate programming tool
#  Commands:
#     tangle: get code
#     weave:  get text
#

```

### Some Helper Functions

```perl

sub error_non_ws{
   my ($ln, $lni, $errmsg) = @_;

   if($ln =~ /^\s/){
      die "Err: line on ln '$lni' cannot begin with a whitespace: $ln"
   }else{
      die $errmsg
   }
}


sub build_filename{
   my ($header_attrib, $ext) = @_;

   if($header_attrib->{file}){
      return  ($ext)
               ? $header_attrib->{file} . $ext
               : $header_attrib->{file}; 
   }else{
      die "Err: file key is missing"
   }
}
```

### cmd_tangle

```perl
sub cmd_tangle {
   my ($doc,$tag) = @_;

   my (@buffer, $filename, $docstart);

   my $tangle_header_line = sub{
      my ($header_attrib) = @_;
```

#### Check for endtangle

```perl

      if($header_attrib->{endtangle}){
         die "Err: There is no filename" unless ($filename);
         open (my $fh, '>', $filename) || die "Err: cannot write to '$filename'";
         print $fh map { $_ . "\n" } @buffer;
         close $fh;
         print "Success: File $filename written\n";
         exit
      }

      if($docstart){
         die "Err: unexpected docstart";
      }else{
         $docstart = 1;
         die "Err: (buffer) is not empty" if @buffer;
         $filename = build_filename($header_attrib );
         @buffer = map { '' } ( 0 .. $header_attrib->{lni});
         push @buffer, '';$header_attrib->{title};
      }
   };
   my $tangle_text_line = sub{
      die "Err: need to start text with a header" unless $docstart;
      push @buffer, '';
   };
   my $tangle_code_block = sub {
      die "Err: need to start text with a header" unless $docstart;
      
      my $block_type = shift @{ $_[0]};
      my $blk_attr = shift @{ $_[0]};

      my %blocktypes = (
         langblock => sub {
            push @buffer,  '';
            push @buffer, @_;
            push @buffer, '';
         },
         crownblock => sub {
            if($blk_attr->{notangle}){
               push @buffer, '';
               push @buffer, map { '' } @_;
               push @buffer, '';
            }else{
               push @buffer, '';
               push @buffer, @_;
               push @buffer, '';
            }
         },
      );

      my $bt = $blocktypes{$block_type};
      ($bt)
         ? $bt->(@{ $_[0] } )
         : die "Err: no blocktype found";

   };

   
   my %tangle_types = (
      HASH => $tangle_header_line ,
      ARRAY => $tangle_code_block,
      _ => $tangle_text_line,
   );

   foreach my $ln (@$doc){
      my $type = ref $ln;
      ($type) 
         ? $tangle_types{$type}->($ln) 
         : $tangle_types{_}->($ln);
   }
   
   if($filename){
      open (my $fh, '>', $filename) || die "Err: cannot write to '$filename'";
      print $fh map { $_ . "\n" } @buffer;
      close $fh;
      print "Success: File $filename written\n";
      exit
   }

}
```

### cmd_weave

```perl
sub cmd_weave {
   my ($doc,$tag) = @_;

   my (@buffer, $filename, $docstart);

   my $weave_header_line = sub{
      my ($header_attrib) = @_;


      if($header_attrib->{endweave}){
         die "Err: There is no filename" unless ($filename);
         open (my $fh, '>', $filename) || die "Err: cannot write to '$filename'";
         print $fh map { $_ . "\n" } @buffer;
         close $fh;
         print "Success: File $filename written\n";
         exit
      }

      if($docstart){
         die fff => @_;

      }else{
         $docstart = 1;
         $filename = build_filename($header_attrib, '.md');
         push @buffer, $header_attrib->{title};
      }
   };
   my $weave_text_line = sub{
      die "Err: need to start text with a header" unless $docstart;
      push @buffer, $_[0]
   };
   my $weave_code_block = sub {
      die "Err: need to start text with a header" unless $docstart;
      
      my $block_type = shift @{ $_[0]};
      my $blk_attr = shift @{ $_[0]};

      

      my %blocktypes = (
         langblock => sub {
            push @buffer,  '```' . $blk_attr->{lang} ;
            push @buffer, @_;
            push @buffer, '```';

         },
         crownblock => sub {
            unless($blk_attr->{noweave}){
               push @buffer, (exists $blk_attr->{tag})
                  ? '```' . $blk_attr->{lang} . ' { #' . $blk_attr->{tag} . ' }'
                  : '```' . $blk_attr->{lang} ;
               push @buffer, @_;
               push @buffer, '```';
               }
         },
      );

      my $bt = $blocktypes{$block_type};
      ($bt)
         ? $bt->(@{ $_[0] } )
         : die "Err: no blocktype found";

   };

   
   my %weave_types = (
      HASH => $weave_header_line ,
      ARRAY => $weave_code_block,
      _ => $weave_text_line,
   );

   foreach my $ln (@$doc){
      my $type = ref $ln;
      ($type) 
         ? $weave_types{$type}->($ln) 
         : $weave_types{_}->($ln);
   }
      if($filename){
         open (my $fh, '>', $filename) || die "Err: cannot write to '$filename'";
         print $fh map { $_ . "\n" } @buffer;
         close $fh;
         print "Success: File $filename written\n";
         exit
      }

}

our %dispatcher = (
   weave => \&cmd_weave,
   tangle => \&cmd_tangle,
);
```

### main

```perl

sub main {
   my ($cmdinput, $sourcefile, $taginput) = @_;
   die "usage: $USAGE" unless ($cmdinput && $sourcefile && $taginput);

   my $cmd = $dispatcher{$cmdinput};
   die "Err: could not find cmd for '$cmdinput'" unless ($cmd);

   my $searchtag = ($taginput =~ /^\#([a-zA-Z0-9]+)/) ? $1 : undef;
   die "Err: tag input is invalid. '#tag' with a leading hash and an alphanumeric value" unless $searchtag;

```

#### call parser 

```perl

   my ($listing) = parse($sourcefile);


   my ($document) = (exists $listing->{$searchtag})
      ? $listing->{$searchtag}
      : die "Err: could not find taginput in '$searchtag'";


   $cmd->($document, $taginput);
}

```

### Parser

```perl

sub parse{
   my ($sourcefile) = @_;

```

### Regular Expressions

```perl

   my $rxs_fence = '^\`\`\`';
   my $rxs_crown_capt = '\s*\{\s*([^\}]*)\s*\}\s*$';
   my $rxs_alphanum_capt = '\s*([a-zA-Z0-9]*)\s*';
   my $rxs_fname_capt = '\s*([a-zA-Z0-9\.\-\_]*)\s*';

   my $rx_fence_probe = qr|^\s*\`\`|;
   my $rx_fence_fault = qr|^\s+\`\`|;
   my $rx_fence_lang_crown_capt = qr|${rxs_fence}${rxs_alphanum_capt}${rxs_crown_capt}|;
   my $rx_fence_lang_capt = qr|${rxs_fence}${rxs_alphanum_capt}$|;
   my $rx_fence_end = qr|${rxs_fence}\s*$|;

   my $rx_header_probe = qr|^\s*\#.*\{|;
   my $rx_header_fault = qr|^\s+\#.*\{|;
   my $rx_header_crown_capt = qr|^(#+\s*[^\{]+)$rxs_crown_capt|;
   my $rx_maintitle_capt = qr|^(\%\s+.*)\s*$|;

   my $rx_tag_capt = qr|^#$rxs_alphanum_capt$|;
   my $rx_option_capt = qr|^\.$rxs_alphanum_capt$|;
   my $rx_tangle_file_capt = qr,(tangle|weave)=$rxs_fname_capt$,;

   my $lni = 0;
   
   my $check_lang = sub {
      die "Err: language is missing" unless($_[0]);
   };

   my @buffer;
   my %listing;
   my $last_tag ;
   my $last_crown ;

   my $handle_crown = sub {
      my ( $marker, $crw_str, $str) = @_;

      my %crw  = ( lni => $lni, marker => $marker  ); 


      if($marker eq 'header'){
         die "Err: no title in crown '$str'" unless $str;
         $crw{title} = $str;
      }else{
         die "Err: no lang in crown '$str'" unless $str;
         $crw{lang} = $str;
      }
         
      my ($linetag);
      foreach my $a (split(' ', $crw_str)){

         if($a =~ /$rx_tag_capt/){ 
            die "Err: there can only be one tag " if $linetag;
            $linetag = (exists $listing{$1})
               ? die "Err: there is already a tag '$1'" 
               : $1; 
         }

         if($a =~ /$rx_option_capt/){ $crw{$1} = 1; }

         if($a =~ /$rx_tangle_file_capt/){
            die "Err: there is already a file defined" if $crw{file};
            my $tangle_file = $2;
            $crw{type} = $1;
            if($tangle_file =~ /^\./){
               die "Err: need a tag on line '$crw_str'" unless ( $linetag);
               $crw{file} = $linetag . $tangle_file;
            }else{
               $crw{file} = $tangle_file;
            }
         }
      }
      if($linetag && (exists $crw{file})){
         if($last_tag){
            if($marker eq 'header'){
               $listing{$last_tag} = [ @buffer ];
               $last_tag = $linetag;
               undef @buffer;
            }
         }else{
            die "Err there is a buffer, but no tag" if (@buffer > 0);
         }
      }
      return \%crw  ;
   };

   open (my $fh, '<', $sourcefile) || die "Err: cannot open sourcefile '$sourcefile'";
   my $firstline = <$fh>;
   my $maintitle = ($firstline =~ /$rx_maintitle_capt/)
      ? $1
      : die "Err: could not fetch mainitle";
   $last_tag = 'readme';
   push @buffer, { lni => 0, title => $maintitle, weave => '.md', file=> $last_tag . '.md' } ;
   my @code_buffer;
   my ($infence, $fence_crw, @doc)  ;
   foreach my $ln (<$fh>){
      chomp $ln;
      my $crw_line;
      if($infence){
         if($ln =~ /$rx_fence_probe/){
            if ($ln =~ /$rx_fence_end/){
               push @buffer, [@code_buffer];
               undef @code_buffer;
               $infence = undef;
            }else{
               die "Err: invalid end fence"
            }
         }else{
            push @code_buffer, $ln;
         }
      }else{
         if($ln =~ /$rx_fence_probe/){
            if($ln =~ /$rx_fence_lang_crown_capt/){
               die "Err: language is missing" unless($1);
               @code_buffer = (crownblock => $handle_crown->(fence => $2, $1));
               $infence = 1;
            }elsif($ln =~ /$rx_fence_lang_capt/){
               $check_lang->($1);
               @code_buffer = ( langblock => { lni => $lni, lang => $1 }) ; 
               $infence = 1;
            }else{
               error_non_ws($ln, $lni, "Err: fence has the wrong form on line '$lni': $ln");
            }
         }elsif($ln =~ /$rx_header_probe/){
            if($ln =~ /$rx_header_crown_capt/){
               push @buffer, $handle_crown->(header => $2, $1);
            }else{
               error_non_ws($ln, $lni, "Err: head is invalid in ($lni): " . $ln);
            }
         }else{
            push @buffer, $ln
         }
      }
      $lni++;
   }
   if($last_tag){
      if(@buffer){
         $listing{$last_tag} = [ @buffer ];
         undef @buffer;
      }
   }else{
      die "Err there is a buffer, but no tag" if (@buffer > 0);
   }

   close $fh;
   return \%listing
}


main @ARGV;

```

## bootstrap.sh { #bootstrap tangle=.sh }


```bash
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

```


## roundtrip.sh { #roundtrip tangle=.sh }

```bash
tempfile="$(mktemp)"

sh ./build/bootstrap.sh sew.md sew.pl > $tempfile 2>&1

if [ $? -eq 0 ] ; then
    perl ./build/sew.pl $@
else
    cat "$tempfile"
    echo fail
    exit 1
fi
```

## basetest.md { #basetest weave=.md }

### Lorem Ipsum

is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.

## It has survived { #loremtest tangle=.pl }

not only five centuries


```perl
my $perl = "is shiny";
```

but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of

## Letraset sheets containing Lorem Ipsum passages

and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.







