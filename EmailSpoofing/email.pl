#!/usr/bin/perl
use diagnostics;
use Modern::Perl;
use Mail::Sendmail;

my ($toCheck, $fromCheck, $subjectCheck, $messageCheck, $tempCount, $mailto, $mailfrom, $subject, $message);
$tempCount=$toCheck=$fromCheck=$subjectCheck=0;$message="";
$subject="No Subject";

foreach (@ARGV){
        if ($_ eq "-t"){$toCheck=1; $mailto=$ARGV[$tempCount+1];}
        elsif ($_ eq "-f"){$fromCheck=1; $mailfrom=$ARGV[$tempCount+1];}
        elsif ($_ eq "-s"){$subjectCheck=1; $subject=$ARGV[$tempCount+1];}
        elsif ($_ eq "-m") {$messageCheck=1; &populateMessage($ARGV[$tempCount+1]);}
        elsif ($_ eq "-h"){ &help; }
        $tempCount++;
}

if ($toCheck == 0 || $fromCheck == 0 || $messageCheck== 0) {&usage;}
if ($subjectCheck == 0){printf ("You did not provide a subject. Default subject is \"No Subject\".\n");}

my %email = (
        To=>$mailto,
        From=>$mailfrom,
        Subject=>$subject,
        Message=>$message,
        'Content-type'=>'text/html; charset="utf-8"');

if (sendmail %email) { printf ("Sent the email from $mailfrom\n");}
else { printf ("Error $Mail::Sendmail::error\n");}

# --------------- Subs -------------------------- #

sub usage{
        printf ("\n$0 -t to\@email.com -f from\@email.com -s \"Subject for email\" -m File containing message\n");
        printf ("\nAdditionally you can use the -h switch (\"$0 -h\") for more info.\n\n");
        exit(1);
}
sub populateMessage{
        my $file = shift;
        open (IN, "<", $file) or die "Could not open file. Application will quit. $!\n";
        while(<IN>){$message.=$_;}
        close IN;
}
sub help{
        say"";
        printf ("\t-t\tThe to address of your email.--REQUIRED\n");
        printf ("\t-f\tThe from address of your email.--REQUIRED\n");
        printf ("\t-m\tThe message of your email.--REQUIRED\n");
        printf ("\t-s\tThe subject of your email.--optional\n");
        printf ("\t-h\tThis help message.\n");
        printf ("----------\n\n\n");
        printf ("For example:\n-t toemail\@nsd.com -f fromemail\@nsd.com -m filemessage.txt -s \"Subject here\"\n\n");
        say"";
        exit(0);
}
