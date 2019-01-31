package App::iperlmoddir;
use strict;
use warnings;
use Data::Dumper;
use Data::Dump qw(dd);
use Text::CSV qw( csv );
use Cwd qw(getcwd);
use App::iperlmoddir::Utils qw(:all);

=head1 NAME

App::iperlmoddir - quick print info about modules in directory at CSV file

=head1 SYNOPSIS
 
  $ iperlmoddir -g -d /foo/bar -s Foo.pm,Bar.pm
  
=head1 DESCRIPTION

By default, it prints CSV file meta.csv with info

1) about subroutines

2) about modules_used

3) about constants

=head1 OPTIONS

For more info please check iperlmoddir --help

=cut

sub run {
    my ( $self, $opts ) = @_;  # $opts is Getopt::Long::Descriptive::Opts
    
    my @exclude = ( $opts->skip ? split ( ',',  $opts->skip ) : () );
    my $dir = ( $opts->dir ? $opts->dir : '.' );
    
    my $modules = get_inspected_modules_list( $dir, \@exclude, $opts->verbose);
    
    my $cwd = getcwd();
    chdir $dir;
    my $res = parse_modules($modules);
    chdir $cwd;
    
    my $part_rows = {};
    my $csv_filename = "meta.csv";
    
    my $csv = Text::CSV->new ({ binary => 1, auto_diag => 1 });
    open my $fh, ">:encoding(utf8)", $csv_filename or die "new.csv: $!";
    
    for my $prm ( qw/subs used consts/ ) {
    
        my @cols = map { [ ( $_->{name}, @{$_->{$prm}} ) ] } @$res;
        _sort_cols_AoA_by_neighbour(\@cols, 1) if $opts->group;
        $part_rows->{$prm} = _cols2rows(\@cols);
        
        $csv->say ($fh, [ "### $prm" ]);
        $csv->say ($fh, $_) for @{ $part_rows->{$prm} };
    }
    
    close $fh or die "$csv_filename: $!";
    
}

1;