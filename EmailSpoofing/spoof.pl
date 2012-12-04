#!/usr/bin/perl
use Modern::Perl;
use Mail::Sendmail;
my $mailTo = '.'; my $mailfrom = '.';
my %email = (
                To=>$mailTo,
                From=>$mailfrom,
                Subject=>'You\'re awesome',
                Message=>'Team Ultra Awesome got 149 points, watch out for those guys.',
                'Content-type'=>'text/html; charset="utf-8"');
if (sendmail %email) { printf ("Sent the email from $mailfrom to $mailTo\n");}
else { printf ("Error $Mail::Sendmail::error\n");}
