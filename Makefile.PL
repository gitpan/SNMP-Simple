use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'SNMP::Simple',
    'ABSTRACT_FROM' => 'lib/SNMP/Simple.pm',
    'AUTHOR'        => 'Ian Langworth <langworth.com>',
    'VERSION_FROM'  => 'lib/SNMP/Simple.pm',
    dist => {
        'PREOP'     => 'pod2text lib/SNMP/Simple.pm >README',
    },
    'PREREQ_PM'     => { 
        'SNMP' => 0,
    },
);
