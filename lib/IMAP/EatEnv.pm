package IMAP::EatEnv;
use base Exporter;
# eat an imap envelope (RFC 3501) from doveadm
# turn it into a perl hash
our $VERSION="0.1";
our @EXPORT = qw/parse_env/;
my @hdr = qw/date subject from sender reply-to to cc bcc
	     in-reply-to message-id/;
my @adr = qw/from sender reply-to to cc bcc/;
my @adrh = qw/personal at-domain-list mailbox host/;

=head1 NAME

IMAP::EatEnv - eat IMAP envelope, poop Perl structure

=head1 SYNOPSIS

 use IMAP::EatEnv;

 while (<>) {
   chomp;
   $h = parse_env();
   print "Another one from Mom\n" if ($h->{from}[0]{personal} =~ /Mom/);
 }

=head2 parse_env()

Exported automatically.
Parses an IMAP envelope string in $_ into a Perl hash structure.
Destroys $_.

Top level hash keys are:

 date
 subject
 from *
 sender *
 reply-to *
 to *
 cc *
 bcc *
 in-reply-to 
 message-id

Starred keys are address arrays. Each array member is a hash with keys

 personal
 at-domain-list
 mailbox
 host

=cut

sub parse_env {
  my (@a,%h);
  s/^\s*(?:imap\.envelope: *)//;
  s/\s*$//;
  while (length($_)) {
    my $l = next_tok();
    return unless defined $l;
    push @a, $l;
  }
  @h{@hdr} = @a;
  for my $k (@adr) {
    $_ = $h{$k};
    if ($_ eq 'NIL') {
      $h{$k} = undef;
    }
    else {
      my @b;
      while (length) {
	my $l;
	$l = next_tok();
	return unless defined $l;
	my %g;
	@g{@adrh} = @$l;
	push @b, \%g;
      }
      $h{$k} = \@b;
      1;
    }
  }
  return \%h;
}

1;

sub next_tok {
  return unless length;
  my $ret;
  if (/^["]/) {
    /^("[^"]*")/g;
    $ret = $1;
    $ret =~ s/^"//;
    $ret =~ s/"$//;
  }
  elsif (/^\({2}/) {
    /^(\({2}.*?\){2})/g;
    $ret = $1;
    $ret =~ s/^\(//;
    $ret =~ s/\)$//;
  }
  elsif (/^\(/) {
    my @a;
    $_ = substr($_,1);
    while (length && !/^\(/) {
      my $l =  next_tok();
      return unless defined $l;
      push @a,$l;
    }
    $ret = \@a;
    return $ret;
  }
  elsif (/^NIL/) {
    /^(NIL)/g;
    $ret = $1;
  }
  elsif (/^(\{([0-9]+)\})/) {
    my $p = $1;
    my $q = quotemeta($p);
    /$q..(.$p)/sg;
    $ret = $1;
    $ret =~ s/^\s*//;
    $ret =~ s/\s*$//;
  }
  else {
    warn "Can't parse event ".substr($_,0,1);
    return;
  }
  $_ = substr($_, pos()+1); # skip space
  $ret;
}

1;
