#!/usr/bin/perl --
use Modern::Perl;
use Mail::Sendmail;
use Getopt::Long;

my ($mailto, $mailfrom, $subject, $message, $help); # Create to, from, subject, message
$subject = 'I have a proposition';

GetOptions ( 'to=s' => \$mailto, 'from=s' => \$mailfrom, 'subj=s' => \$subject, 'msg=s' => \$message, 'h|help|?' => \$help );

if ($help) { help(); }
if ( $subject eq 'I have a proposition' ){ printf "[-] You did not provide a subject. Default subject is \"$subject\".\n"; }
if ( !(defined $message) ) { 
    while ( !(defined $message) ) { 
        printf "[-] You did not provide a file for a message. Please provide some text now.\n\$ ";
        chomp ($message = <STDIN>);
    }
} else { populatemsg($message); }
if (!(defined $mailto || (defined $mailfrom))){ help(); } else { sendmsg(); }

# ---------------------------------------

sub sendmsg {
    my %email = ( To=>$mailto, From=>$mailfrom, Subject=>$subject, Message=>$message, 'Content-type'=>'text/html; charset="utf-8"' );
    if (sendmail %email) { printf "[+] Sent $mailfrom => $mailto\n"; }
    else { printf "[-] Configure issue: $Mail::Sendmail::error\n"; printf "[-] Could not send the message\n";  }
    return 0;
}
sub usage {
    printf "\n[!] $0 -t to\@email.com -f from\@email.com -s \"Subject for email\" -m File containing message\n\n";
    exit 0;
}
sub populatemsg {
    my $file = shift;
    $message = "";
    printf "[+] Opening:  $file...\n";
    open my $IN, '<', $file or die "[-] Could not open file. Application will quit. $!\n";
    while(<$IN>){ $message.=$_; }
    printf "[+] Message is done populating\n";
    close $IN or warn "[-] File did not close properly. $!\n";;
    return 0;
}
sub help {
    printf "\n";
    printf "-"x20;
    printf "\n%-8s-The \'to\' address of your email. (Required)\n", '-to';
    printf "%-8s-The \'from\' address of your email. (Required)\n", '-from';
    printf "%-8s-The HTML encoded message of your email. (Required)\n", '-msg';
    printf "%-8s-The \'subject\' of your email. (Optional)\n", '-subj';
    printf "-"x20;
    usage();
}
