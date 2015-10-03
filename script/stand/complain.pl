#!/usr/bin/perl

use strict;
use warnings;

use MongoDB;
use Data::Dumper;
use String::CRC::Cksum qw/cksum/;
use Text::Unaccent::PurePerl qw(unac_string);

my $state = 'SP';
my $city = 'SAO PAULO';

my $client = MongoDB::MongoClient->new(host => 'localhost', port => 27017);
my $db   = $client->get_database( 'BigData' );

my $comp_struct = {};
my $log_struct = {};

log_boot();
fetch_data_comp();

sub fetch_data_comp {
   my $comp = $db->get_collection('ComplaintsSP');
    my $addr = $comp->find({});
    $addr->immortal(1);
    my $count = 1;
    while (my $cursor = $addr->next) {
        next if $cursor->{solicitation_address} =~ /catalogado\s+no\s+sistema/i;
        my $res = clean_addr($cursor->{solicitation_address});
        next if !$res;
        my $cksum = cksum(@{$res});
        $comp->update( {'_id' => $cursor->{_id}}, {'$set' => {'addr_cksum' => $cksum}});
        print "$count\r";
        $count++;
    }
}

sub clean_addr {
	my $text = unac_string(uc shift);
    $text =~ s/[^\w\s,]//g;
    if ($text =~ /(\w+)\s+([\w\d\s]+),\s?(\d+)/i) {
       my ($log,$street,$number) = ($1,$2,$3);         
        $log =~ s/^\s+|\s+$//g;
        $street =~ s/^\s+|\s+$//g;
        $number =~ s/^\s+|\s+$//g;
        return [log_stand($log),$street,$number,$city,$state];
    }
}

sub log_boot {
    while(my $item = <DATA>) {
        my ($log,$ab) = split /\s+/,$item;
        $log_struct->{$ab} = $log;
    }
}

sub log_stand {
    my $log = shift;
    if ($log_struct->{$log}) { return $log_struct->{$log} }
    else { return $log }
}
__END__
ACESSO ACS
ADRO AD
AEROPORTO AER
ALAMEDA AL
ALTO AT
ATALHO ATL
ATERRO ATER
AUTODROMO ATD
AVENIDA AV
BAIA BAIA
BAIRRO B
BAIXA BX
BALNEARIO BAL
BECO BC
BELVEDERE BLV
BLOCO BL
BOSQUE BQ
BOULEVARD BV
CAIS C
CAMINHO CAM
CAMPO CPO
CANAL CAN
CARTODROMO CTD
CHACARA CH
CHAPADAO CHP
CIDADE CD
COLONIA COL
CONDOMINIO COND
CONJUNTO CJ
CORREDOR COR
CORREGO CRG
DESCIDA DSC
DESVIO DSV
DISTRITO DT
EDIFICIO ED
ENTREPOSTO ETP
ENTRONCAMENTO ENT
ESCADARIA ESD
ESCADINHA ESC
ESPLANADA ESP
ESTACAO ETC
ESTADIO ETD
ESTANCIA ETN
ESTRADA EST
FAVELA FAV
FAZENDA FAZ
FEIRA FRA
FERROVIA FER
FONTE FNT
FORTE FTE
FREGUESIA FRG
GALERIA GLR
GRANJA GR
HIPODROMO HPD
ILHA IA
JARDIM JD
LADEIRA LAD
LAGO LAG
LAGOA LGA
LARGO LGO
LIMITE LIM
LINHA DE TRANSMISSAO LINHA
LOTEAMENTO LOT
MANGUE MANG
MARGEM MGM
MONTE MT
MORRO MRO
PARADA PDA
PARQUE PQ
PASSAGEM PAS
PASSEIO PSO
PATIO PTO
PLANALTO PL
PLATAFORMA PLT
PONTE PTE
PORTO PRT
POSTO POS
PRACA PCA
PRAIA PR
PROLONGAMENTO PRL
RAMPA RMP
REDE ELETRICA REDE
RETA RTA
RIO RIO
RODOVIA RDV
RUA R
RUELA RE
SERRA SERRA
SERTAO SER
SERVIDAO SVD
SETOR ST
SITIO SIT
SUBIDA SUB
SUPERQUADRA SQD
TERMINAL TRM
TERRENO TER
TRANSVERSAL TSV
TRAVESSA TR
TREVIO TRV
VALE VAL
VARGEM VRG
VARIANTE VTE
VELODROMO VLD
VIA VIA
VIADUTO VD
VIELA VEL
VILA VL
