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
# Completed 10/21 - KD - Confirm OS via cli for now. We can probably use an OS tool to determine, will investigate.
#

use Modern::Perl;
use MD5;
use diagnostics;
use Data::Dumper;

my ($OSChecker, $ClientOS, $Argcounter);
$OSChecker=$ClientOS=$Argcounter=0; #Set initial variables to zero, just in case


 foreach (@ARGV){
	if ($_ eq '-OS'){ 
		if ($ARGV[$Argcounter+1] =~ m/xp/i) { $ClientOS=1; printf ("OS set to XP");}
		elsif ($ARGV[$Argcounter+1] =~ m/vista/i) { $ClientOS=2; printf ("OS set to Vista");}
		elsif ($ARGV[$Argcounter+1] =~ m/win7/i) { $ClientOS=3; printf ("OS set to Win7");}
		else { 
			printf ("That OS is not currently recognized, please refer to the help file for further assistance.\n"); 
			&help;
			}
	}
	elsif ($_ eq '-h'){ &help; }
	$Argcounter++;
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





