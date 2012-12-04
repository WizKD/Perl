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
# Completed 10/24 13:13 - Determin OS without user interaction, determine if script is running as admin, display current time and date
#
# To do: determine if user [not script] is an admin

use Modern::Perl;
use MD5;
use Win32;
use diagnostics;
use Data::Dumper;

my ($OSChecker, $ClientOS, $Argcounter, $isUserAdmin, $ClientLogin, $usingDB );
$OSChecker=$ClientOS=$Argcounter=$isUserAdmin=0; #Set initial variables to zero, just in case

die if (!($^O =~ /MSWin32/i)); # If we're not on Windows, die
foreach (@ARGV){
	if ($_ eq '-h'){ &help; }
	$Argcounter++;
}

&Greet; # Say hello to the users
&DetermineOS; # Grab starter information and determine how to access chrome db
&GrabDBHash;

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
$isUserAdmin = Win32::IsAdminUser();

if ($ClientOS =~ /win7/i){ $usingDB = 'C:\Users\\'.$ClientLogin.'\AppData\Local\Google\Chrome\User Data\Default'; }
elsif ($ClientOS =~ /winvista/i || $ClientOS =~ /winxp/i) { 
$usingDB = 'C:\Documents and Settings\\'.$ClientLogin.'\Local Settings\Application Data\Google\Chrome\User Data\Default'; 
}


printf ("\nOS is $ClientOS\nIs script running as admin %s\n", ($isUserAdmin? "true" : "false"));
printf ("Running under login name of $ClientLogin\n");
printf ("Using DBI path of $usingDB\n");
print '-'x20;
}

sub GrabDBHash{
printf ("\nUsing this DB: $usingDB\n");

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





