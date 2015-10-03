#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use LWP::ConnCache;
use HTML::TreeBuilder::XPath;
use Data::Dumper;
use Encode;
use MongoDB;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';


die unless $ARGV[0] =~ /^\d+$/;

my $ua = LWP::UserAgent->new;
$ua->conn_cache( LWP::ConnCache->new );
$ua->agent(
"Mozilla/4.0 (compatible; MSIE 7.0b; Windows NT 5.1; .NET CLR 1.1.4322; Alexa Toolbar)"
);

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

my $client = MongoDB::MongoClient->new( host => 'localhost', port => 27017 );
my $database = $client->get_database('BigData');
my $collection = $database->get_collection('ComplaintsSP');

my $c            = $ARGV[0];
#my $c           = 12905615;
my $error_stack = 0;
while ( $error_stack <= 10000 ) {
    print STDERR "$c\n";
    my $res = $ua->get(
"http://sac.prefeitura.sp.gov.br/SolicitacaoConsultaSolNum.asp?botao=Continuar&txtSolNum=$c"
    );
    unless ( $res->is_success ) {
        $error_stack++;
        next;
    }
    my $tree  = HTML::TreeBuilder::XPath->new_from_content( $res->content );
    my @itens = $tree->findnodes('//div[@id="conteudo2"]//table/tr');
    splice @itens, 0, 2;
    if ( @itens > 2 ) {
        my %itens =
          map { $_->findvalue('.//th'), $_->findvalue('.//td') } @itens;
        if ( $itens{''} ) {
            $itens{'Providências:'} = $itens{''};
        }
        delete $itens{''};
      KEY: foreach my $key ( keys %itens ) {
            foreach my $clean_key ( keys %{$replace} ) {
                if ( $key =~ /$clean_key/i ) {
                    $itens{ $replace->{$clean_key} } = $itens{$key};
                    delete $itens{$key};
                    next KEY;
                }
            }
        }
        $collection->insert( \%itens );
    }
    else {
        $error_stack++;
    }
    $tree->delete;
    $c--;
}

