package SNMP::Simple;
use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

use SNMP;
$SNMP::use_enums = 1; # can be overridden with new(UseEnums=>0)

sub new {
    my ($class, @args) = @_;
    my $session = SNMP::Session->new(@args)
        or croak "Couldn't create session";
    bless \$session, $class;
}

sub get {
    my ($self, $name) = @_;
    my $result = $$self->get($name) || $$self->get("$name.0");
    my $enum = &SNMP::mapEnum($name,$result);
    return defined $enum ? $enum : $result;
}

sub get_table {
    my ($self, @oids) = @_;
    my @output = ();

    # build our varlist, the fun VarList way
    my $vars = new SNMP::VarList(map {[$_]} @oids);

    # get our initial results, assume that we should be able to get at least
    # *one* row back
    my @results = $$self->getnext($vars);
    croak $$self->{ErrorStr} if $$self->{ErrorStr};

    # dNb's recipe for iteration: make sure that there's no error and that the
    # OID name of the first cell is actually what we want
    while ( !$$self->{ErrorStr} and $$vars[0]->tag eq $oids[0] ) {
        push @output, [@results];
        @results = $$self->getnext($vars);
    }

    return wantarray ? @output : \@output;
}

sub get_list {
    my ($self, $oid) = @_;
    my @table = $self->get_table($oid);
    my @output = map { $_->[0] } @table;
    return wantarray ? @output : \@output;
}

sub get_named_table {
    my $self = shift;
    my %oid_to_name = reverse @_;
    my @oids = keys %oid_to_name;

    # remap table so it's a list of hashes instead of a list of lists
    my @table = $self->get_table(keys %oid_to_name);
    my @output = ();
    foreach my $row ( @table ) {
        my %data = ();
        for (my $i=0;$i<@oids;$i++) {
            $data{ $oid_to_name{$oids[$i]} } = $row->[$i];
        }
        push @output, \%data;
    }

    return wantarray ? @output : \@output;
}


1;
__END__

=head1 NAME

SNMP::Simple - shortcuts for when using SNMP

=head1 SYNOPSIS

    use SNMP::Simple;

    $name     = $s->get('sysName'); # same as sysName.0
    $location = $s->get('sysLocation');

    @array    = $s->get_list('hrPrinterStatus');
    $arrayref = $s->get_list('hrPrinterStatus');

    @list_of_lists = $s->get_table( qw(
        prtConsoleOnTime
        prtConsoleColor
        prtConsoleDescription
    ) );

    @list_of_hashes = $s->get_named_table(
        name   => 'prtInputDescription',
        media  => 'prtInputMediaName',
        status => 'prtInputStatus',
        level  => 'prtInputCurrentLevel',
        max    => 'prtInputMaxCapacity',
    );

=head1 DESCRIPTION

=head2 Goal

The goal of this module is to provide shortcuts and provide a cleaner interface for doing repetitive information-retrieval tasks with L<SNMP> version 1.

=head2 SNMP Beginners, read me first!

Please, please, B<please> do not use this module as a starting point for working with SNMP and Perl. Look elsewhere for starting resources:

=over 4

=item * The L<SNMP> module

=item * The Net-SNMP web site (L<http://www.net-snmp.org/>) and tutorial (L<http://www.net-snmp.org/tutorial-5/>)

=item * Appendix E of Perl for System Administration (L<http://www.amazon.com/exec/obidos/tg/detail/-/1565926099>) by David N. Blank-Edelman

=back

=head2 SNMP Advanced and Intermediate users, read me first!

I'll admit this is a complete slaughtering of SNMP, but my goals were precise. If you think SNMP::Simple could be refined in any way, feel free to send me suggestions/fixes/patches.

I'm trying to provide shortcuts, not abstract. My purpose in providing this is so one can write:

    $data{lights} = $s->get_named_table(
        status => 'prtConsoleOnTime',
        color  => 'prtConsoleColor',
        name   => 'prtConsoleDescription',
    );

Instead of the following, give or take a little refining:

    $vars = new SNMP::VarList(
        ['prtConsoleOnTime'],
        ['prtConsoleColor'],
        ['prtConsoleDescription'],
        );
    my ($light_status, $light_color, $light_desc) = $s->getnext($vars);
    die $s->{ErrorStr} if $s->{ErrorStr};
    while ( !$s->{ErrorStr} and $$vars[0]->tag eq "prtConsoleOnTime" ) {
        push @{ $data{lights} }, {
            status => ($light_status ? 0 : 1),
            color  => &SNMP::mapEnum($$vars[1]->tag, $light_color),
            description => $light_desc,
        };
        ($light_status, $light_color, $light_desc) = $s->getnext($vars);
    }

=head1 TODO

Among other things,

=over 4

=item * B<tests>

=item * make it smarter when using SNMPv2 and SNMPv3

=back

=head1 AUTHOR

Ian Langworth <langworth.com>

=head1 SEE ALSO

L<SNMP>

=cut
