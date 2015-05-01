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

use XML::Compile::SOAP::Daemon::PSGI;
use XML::Compile::WSDL11;
use XML::Compile::SOAP11;

use Log::Report syntax => 'LONG';

dispatcher PERL => 'default', mode => 'VERBOSE';

my $wsdl_filename = 'mo-sms-service-ws.wsdl';

my $wsdl = XML::Compile::WSDL11->new($wsdl_filename);
$wsdl->importDefinitions(['mo-sms-service-ws.xsd']);

my $daemon = XML::Compile::SOAP::Daemon::PSGI->new;

$daemon->operationsFromWSDL(
    $wsdl,
    callbacks => {
        DeliverShortMessage => sub {
            my ($soap, $data) = @_;
            # your code here
            return +{
                DeliverShortMessageReturn => 1,
            };
        },
        DeliverNotification => sub {
            my ($soap, $data) = @_;
            # your code here
            return +{
                DeliverNotificationResponse => 1,
            };
        },
    },
);

$daemon->setWsdlResponse($wsdl_filename);

my $sms_receiver_ws_app = $daemon->to_app;


# Full debugging of requests and responses

use Plack::Builder;

my $app = builder {
    enable 'TrafficLog';
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
