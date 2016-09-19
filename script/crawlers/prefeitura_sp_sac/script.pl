#!/usr/bin/perl

# - Daniel Mantovani, Just Another Perl Hacker.

use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use LWP::ConnCache;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use Encode;
use MongoDB;
use Socket;
use IO::Handle;

use feature 'say';

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use constant 'BUFFER'      => 10000;
use constant 'START_ID'    => 4900000;
use constant 'MAX_PROCESS' => 40;
use constant 'ERROR_LIMIT' => 10;
use constant 'BASE_URL' =>
'http://sac.prefeitura.sp.gov.br/SolicitacaoConsultaSolNum.asp?botao=Continuar&txtSolNum=';

my $replace = {
    '^N.\s+Solicita..o:'            => 'solicitation',
    '^Especifica..o:'               => 'specification',
    '^Endere.o\s+da\s+Solicita..o:' => 'solicitation_address',
    '^Data\s+da\s+Conclus.o:'       => 'conclusion_date',
    '^Assunto:'                     => 'subject',
    '^Provid.ncias:'                => 'actions',
    'Situa..o da Solicita..o:'      => 'solicitation_status',
    'Supervis.o:'                   => 'supervision',
    'Data\s+da\s+Solicita..o:'      => 'solicitation_date',
    'Org.o\s+Respons.vel:'          => 'organization_responsible',
};

SCHEDULER: {
    my $c           = START_ID;
    my $process_num = 1;
    socketpair( CHILD, PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC )
      || die "socketpair: $!";
    CHILD->autoflush(1);
    PARENT->autoflush(1);
    while (1) {
        while ( MAX_PROCESS >= $process_num ) {
            $process_num++;
            my $pid = fork();
            say "NEW_CHILD_CREATED: $pid" if $pid;
            if ( $pid == 0 ) {
                close CHILD;
                eval { crawler($c) };
                warn "$c => {$@}" if $@;
                say PARENT $$;
                exit(0);
            }
            $c += BUFFER;
        }
        my $pid_child = <CHILD>;
        chomp $pid_child;
        waitpid $pid_child, 0;
        $process_num--;
    }
}

sub crawler {
    my $c  = shift;
    my $db = storage();
    my $ua = agent();
    for ( my $i = $c ; $i <= ( $c + BUFFER ) ; $i++ ) {
        my $error_stack = 1;
        my $res         = $ua->get( BASE_URL . $i );
      CHECK_SUCCESS: until ( $res->is_success ) {
            say "Error, at request number: {$i} $error_stack of " . ERROR_LIMIT;
            $error_stack++;
            if ( ERROR_LIMIT >= $error_stack ) {
                $res = $ua->get( BASE_URL . $i );
                next CHECK_SUCCESS;
            }
            else {
                die "Request number: $i because: $res->status_line";
            }
        }
        my $items = parser( $res->content );
		say "Inserting $items";
        ref $items eq 'HASH'
          ? $db->insert($items)
          : die "Request number: $i not a fucking hash";
    }
}

sub agent {
    my $ua = LWP::UserAgent->new;
    $ua->conn_cache( LWP::ConnCache->new );
    $ua->timeout(10);
    $ua->agent(
"Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322; Alexa Toolbar)"
    );
    return $ua;
}

sub storage {
    my $client =
      MongoDB::MongoClient->new( host => 'localhost', port => 27017 );
    my $database   = $client->get_database('PrefeituraSP');
    my $collection = $database->get_collection('ComplaintsSP');
    return $collection;
}

sub parser {
    my $content = shift;
    my $tree    = HTML::TreeBuilder::XPath->new_from_content($content);
    my @trs     = $tree->findnodes('//div[@id="conteudo2"]//table/tr');
    splice @trs, 0, 2;
    if ( @trs > 2 ) {
        my %items =
          map { $_->findvalue('.//th'), $_->findvalue('.//td') } @trs;
        if ( $items{''} ) {
            $items{'Providências:'} = $items{''};
        }
        delete $items{''};
      KEY: foreach my $key ( keys %items ) {
            foreach my $clean_key ( keys %{$replace} ) {
                if ( $key =~ /$clean_key/i ) {
                    $items{ $replace->{$clean_key} } = $items{$key};
                    delete $items{$key};
                    next KEY;
                }
            }
        }
        $tree->delete;
        return \%items;
    }
}

sub _scheduler_test {
    my $c = shift;
    sleep rand 100;
    for ( my $i = $c ; $i <= ( $c + BUFFER ) ; $i++ ) { say "\t$i" }
    return;
}

