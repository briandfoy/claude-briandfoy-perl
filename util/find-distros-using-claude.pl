#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

use HTTP::Tiny;
use JSON::PP;
use List::Util qw(max);

my $http = HTTP::Tiny->new( agent => 'find-claude-md/1.0' );
my $api  = 'https://fastapi.metacpan.org/v1';

# 1. Find files named exactly "CLAUDE.md" (case sensitive) in latest releases.
my $file_body = encode_json({
    query => {
        bool => {
            must => [
                { term => { name   => 'CLAUDE.md' } },
                { term => { status => 'latest'    } },
            ],
        },
    },
    _source => [qw(author release distribution path)],
    size    => 1000,
});

my $res = $http->post(
    "$api/file/_search",
    {
        headers => { 'Content-Type' => 'application/json' },
        content => $file_body,
    },
);

unless ( $res->{success} ) {
    warn "File search failed ($res->{status} $res->{reason}); nothing to do.\n";
    exit 0;
}

my @files = map { $_->{_source} }
            @{ decode_json( $res->{content} )->{hits}{hits} };

# 2. Look up the source repository for each distribution's latest release.
my %seen;
my @dists = grep { !$seen{$_}++ } map { $_->{distribution} } @files;

my %repo;
if ( @dists ) {
    my $rel_body = encode_json({
        query => {
            bool => {
                must => [
                    { terms => { distribution => \@dists  } },
                    { term  => { status       => 'latest' } },
                ],
            },
        },
        _source => [qw(distribution resources)],
        size    => scalar @dists,
    });

    my $r = $http->post(
        "$api/release/_search",
        {
            headers => { 'Content-Type' => 'application/json' },
            content => $rel_body,
        },
    );

    if ( $r->{success} ) {
        for my $hit ( @{ decode_json( $r->{content} )->{hits}{hits} } ) {
            my $s    = $hit->{_source};
            my $repo = $s->{resources}{repository} // {};
            $repo{ $s->{distribution} } = $repo->{web} // $repo->{url};
        }
    }
    else {
        warn "Release search failed ($r->{status} $r->{reason}); no repo URLs available.\n";
    }
}

# 3. Collect rows (release, author, repo), skipping any without a repo URL.
my @rows;
for my $f ( sort { $a->{release} cmp $b->{release} } @files ) {
    my $repo = $repo{ $f->{distribution} };
    unless ( defined $repo ) {
        warn "skipping $f->{release} ($f->{author}): no repository URL\n";
        next;
    }
    push @rows, [ $f->{release}, $f->{author}, $repo ];
}

# 4. Print in aligned columns using the actual maximum width of each column.
my @width;
if ( @rows ) {
    @width = map {
        my $col = $_;
        max map { length $_->[$col] } @rows;
    } 0 .. $#{ $rows[0] };
}

# Don't bother padding the final column.
for my $row ( @rows ) {
    printf "%-*s  %-*s  %s\n",
        $width[0], $row->[0],
        $width[1], $row->[1],
                   $row->[2];
}

say '';
say sprintf 'Total: %d CLAUDE.md file(s)', scalar @rows;

__END__

=pod

=head1 NAME

find-distros-using-claude.pl - find CLAUDE.md files in the latest CPAN releases

=head1 SYNOPSIS

    perl find-distros-using-claude.pl

=head1 DESCRIPTION

Queries the MetaCPAN API for every file named F<CLAUDE.md> that appears
in the latest release of all distributions in CPAN, then looks up the source
repository URL for each of those distributions. Results are printed as
aligned columns of release, author, and repository, followed by a total
count.

=head1 AUTHOR

Claude Code, Anthropic's agentic coding CLI (L<https://claude.com/claude-code>),
running model Claude Opus 4.7 (C<claude-opus-4-7>).

=head1 REVIEWER

brian d foy <briandfoy@pobox.com>

=head1 BUGS

Report issues at L<https://github.com/YOUR-USER/YOUR-REPO/issues>.

=cut
