



















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





sub cmd_tangle {
   my ($doc,$tag) = @_;

   my (@buffer, $filename, $docstart);

   my $tangle_header_line = sub{
      my ($header_attrib) = @_;






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






sub main {
   my ($cmdinput, $sourcefile, $taginput) = @_;
   die "usage: $USAGE" unless ($cmdinput && $sourcefile && $taginput);

   my $cmd = $dispatcher{$cmdinput};
   die "Err: could not find cmd for '$cmdinput'" unless ($cmd);

   my $searchtag = ($taginput =~ /^\#([a-zA-Z0-9]+)/) ? $1 : undef;
   die "Err: tag input is invalid. '#tag' with a leading hash and an alphanumeric value" unless $searchtag;







   my ($listing) = parse($sourcefile);


   my ($document) = (exists $listing->{$searchtag})
      ? $listing->{$searchtag}
      : die "Err: could not find taginput in '$searchtag'";


   $cmd->($document, $taginput);
}







sub parse{
   my ($sourcefile) = @_;







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



