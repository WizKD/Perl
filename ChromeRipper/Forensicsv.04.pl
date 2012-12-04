#!C:\strawberry\perl\bin\perl.exe
#--------------------------------
# Authors: Kevin Dolphin, Jeris Rue
# For CSCI-4380, Fall 2012, Computer and Network Forensics
# Class instruction by Stephen Nugen, NUCIA

# ------ Disclaimer -------------
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# --------------------------------

# Dev Notes
# Chrome history setting locations
# XP: C:\Documents and Settings\[USER]\Local Settings\Application Data\Google\Chrome\User Data\Default\
# Vista: C:\Documents and Settings\[USER]\Local Settings\Application Data\Google\Chrome\User Data\Default\
# Win7: C:\Users\[username]\AppData\Local\Google\Chrome\User Data\Default
# --------------------------------
# Notes to devs:
# Completed 10/24 13:13 - Determine OS without user interaction, determine if script is running as admin, display current time and date
# Completed 10/24 18:10 - Drop in a MD5 function, this is forensics after all

# To do: determine if user [not script] is an admin - Emailed Bob
# Actually use a computer with Chrome on it to scrape the DB (LOL)

use Modern::Perl;
use Digest::MD5;
use Win32;
use DBI;
# Remove below before production
use diagnostics;
use Data::Dumper;

my ($OSChecker, $ClientOS, $Argcounter, $isScriptAdmin, $ClientLogin, $isUserAdmin, $usingDB );
$OSChecker=$ClientOS=$Argcounter=$isScriptAdmin=$isUserAdmin=0; #Set initial variables to zero, just in case

die if (!($^O =~ /MSWin32/i)); # If we're not on Windows, die
foreach (@ARGV){
	if ($_ eq '-h'){ &help; }
	$Argcounter++;
}

&Greet; # Say hello to the users
&DetermineOS; # Grab starter information and determine how to access chrome db
&openDB ($usingDB);
#&GrabHash ($usingDB); # Hash DB before playing with it <- This is broken. I'll use this once we get info from the DB

sub Greet{
my @time = localtime(time);
my @monthAbbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @dayOfWeekAbbr = qw (Sun Mon Tue Wed Thurs Fri Sat);
my ($seconds, $minutes, $hour, $dayMonth, $month, $year, $dayOfWeek, $isdst);
$seconds = $time[0]; $minutes = $time[1]; $hour = $time[2];
$dayMonth = $time[3]; $month = $time[4]+1; $year = $time[5]+1900;
$dayOfWeek = $time[6]; $isdst = $time[8];
printf ("\n\n");
print '='x20;
printf ("\nWelcome to $0\n");
printf ("This script assumes a Windows environment.\n");
printf ("Current date and time are as follows: ");
printf ("%s %s %s %02d %02d:%02d.%02d\n", $dayOfWeekAbbr[$dayOfWeek],$monthAbbr[$month], $dayMonth, $year, $hour, $minutes, $seconds);
printf ("Please review the disclaimer packaged in the source or within the download file.\n");
printf ("\nScripting by Kevin Dolphin, Jeris Rue\n");
print '='x20;

}

sub DetermineOS{
print '='x20;
printf ("\n\nDetermining OS information\n");
print '-'x20;

$ClientOS = Win32::GetOSName();
$ClientLogin = Win32::LoginName();
$isScriptAdmin = Win32::IsAdminUser();

if ($ClientOS =~ /win7/i || $ClientOS =~ /winvista/i){ $usingDB = 'C:\Users\\'.$ClientLogin.'\AppData\Local\Google\Chrome\User Data\Default\History'; }
elsif ($ClientOS =~ /winxp/i) { 
$usingDB = 'C:\Documents and Settings\\'.$ClientLogin.'\Local Settings\Application Data\Google\Chrome\User Data\Default\History'; 
}
printf ("\nChecking local account information.\n\n");

printf ("\nClient Operating System: $ClientOS\nIs script running as admin? %s\n", ($isScriptAdmin? "true" : "false"));
printf ("Script is running under login name of \"$ClientLogin\"\n");
print '-'x20;
print "\n\n";
}

sub GrabHash{
printf ("\n\nHashing Chrome Database (MD5)\n");
print '-'x20;
my $file = shift; # Set file to hash as chrome DB
my $md5;
my $ChromeHash;

open(FILE, $file) or die "Couldn't open file: $!\n"; # This breaks if you attempt to open the DB
binmode(FILE); # Switch file to binmode

$md5 = Digest::MD5->new; # Reset Digest

while(<FILE>){$md5->add($_);} # Drop everything into the digest
close (FILE); # Close file

my $temp = $md5->hexdigest; # Create MD5

printf ("\nThe MD5 of the file ($file) is \n");
print '-'x20;
printf "\n\n";
}
 
sub openDB{
	my $dbPath = shift;
	my @grabURLs = ();
	my $dbHandle = DBI->connect("dbi:SQLite:$dbPath","","") or die "Something went wrong during the scrape: " . DBI->errstr;
	#http://computer-forensics.sans.org/blog/2010/01/21/google-chrome-forensics/
	#http://search.cpan.org/~adamk/DBD-SQLite-1.37/lib/DBD/SQLite.pm
	#http://www.perl.com/pub/1999/10/DBI.html
#SELECT urls.url, urls.title, urls.visit_count, urls.typed_count, urls.last_visit_time, urls.hidden, visits.visit_time, visits.from_visit, visits.transition
#FROM urls, visits
#WHERE
# urls.id = visits.url

my $sth = $dbHandle->prepare("SELECT * FROM urls");
$sth->execute();
my $row = $sth->fetch;
print Dumper (\$row);
	
	$dbHandle->disconnect();

	

}

 
 
 
sub help{
printf ("\nWelcome to $0.\nThe available switches are available for your usage throughout this program.\n");
printf ("Operating System (OS) switches are as follows:\n\nWindows XP: XP\nWindows Vista: Vista\nWindows 7: Win7\n");
printf ("OS example as follows:\n $0 -OS XP\n $0 -OS Vista\n $0 -OS Win7\n");
print '-'x20; say"";
printf ("Other switches for misc. activities are as follows:\nHelp: -h.");
printf ("\n");
exit(0);
}





