#!/usr/bin/env perl

# PSGI application
#
# Install libraries:
# $ cpanm XML::Compile::SOAP::Daemon Plack::Middleware::TrafficLog
#
# Run server:
# $ plackup sms-receiver-ws-server.pl

use warnings;
use strict;

use FindBin;

use XML::Compile::SOAP::Daemon::PSGI;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;
use XML::LibXML;

use Log::Report syntax => 'LONG';

dispatcher PERL => 'default', mode => 'VERBOSE';

my $wsdl_filename = "$FindBin::Bin/mo-sms-service-ws.wsdl";

my $wsdl_dom = XML::LibXML->load_xml(location => $wsdl_filename);
my $imports = $wsdl_dom->find('/wsdl:definitions/wsdl:types/xsd:schema/xsd:import');
my @schemas = map { $_->getAttribute('schemaLocation') } $imports->get_nodelist;

my $wsdl = XML::Compile::WSDL11->new($wsdl_filename);
$wsdl->importDefinitions(@schemas);

my $daemon = XML::Compile::SOAP::Daemon::PSGI->new;

$daemon->operationsFromWSDL(
    $wsdl,
    callbacks => {
        DeliverShortMessage => sub {
            my ($soap, $data) = @_;
            # your code here
            return +{
                DeliverShortMessageReturn => 'true',
            };
        },
        DeliverNotification => sub {
            my ($soap, $data) = @_;
            # your code here
            return +{
                DeliverNotificationResponse => 'true',
            };
        },
    },
);

$daemon->setWsdlResponse($wsdl_filename);

my $sms_receiver_ws_app = $daemon->to_app;


# Full debugging of requests and responses

use Plack::Builder;

my $app = builder {
    enable 'TrafficLog', with_body => 1;
    $sms_receiver_ws_app;
};

# Run as standalone script or as a PSGI app

unless (caller) {
    require Plack::Runner;
    my $runner = Plack::Runner->new;
    $runner->parse_options(@ARGV);
    return $runner->run($app);
}

return $app;
