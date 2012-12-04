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


# Remember to check the README

# To do: determine if user [not script] is an admin - Emailed Bob


use Modern::Perl;
use Digest::MD5;
use Time::CTime;
use Win32::TieRegistry 0.20 (Delimiter=>"/");
use Win32;
use DBI;
# Remove below before production
use diagnostics;
use Data::Dumper;

	my ($OSChecker, $ClientOS, $Argcounter, $isScriptAdmin, $ClientLogin, $isUserAdmin, $ChromeDB, $DefaultBrowser );
	my (@ChromeRecentHistoryRecords, @ChromeRecentLoginRecords);
	$OSChecker=$ClientOS=$Argcounter=$isScriptAdmin=$ClientLogin=$isUserAdmin=$ChromeDB=$DefaultBrowser=0; #Set initial variables to zero, just in case

	die if (!($^O =~ /MSWin32/i)); # If we're not on Windows, die
	foreach (@ARGV){
		if ($_ eq '-h'){ &help; }
		$Argcounter++;
	}

	&Greet; # Say hello to the users
	print '='x20;
	&DetermineOS; # Grab starter information and determine how to access chrome db
	&openChromeHistory ($ChromeDB);
	&openChromeLogins ($ChromeDB);
	&openChromeBookmarks ($ChromeDB);
	#&GrabHash (filenamehere); # Hash DB before playing with it <- This is broken. I'll use this once we get info from the DB

sub Greet{
	my @time = localtime(time);
	my @monthAbbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @dayOfWeekAbbr = qw (Sun Mon Tue Wed Thurs Fri Sat);
	my ($seconds, $minutes, $hour, $dayMonth, $month, $year, $dayOfWeek, $isdst, $walltime, $timegood);
	$walltime=""; $timegood=0;
	$seconds = $time[0]; $minutes = $time[1]; $hour = $time[2];
	$dayMonth = $time[3]; $month = $time[4]+1; $year = $time[5]+1900;
	$dayOfWeek = $time[6]; $isdst = $time[8];
	printf ("\n\n");
	print '='x20;
	printf ("\nWelcome to $0\n");
	printf ("This script assumes a Windows environment.\n");
	printf ("Please review the disclaimer packaged in the source or within the download file.\n");
	printf ("\nScripting by Kevin Dolphin, Jeris Rue\n");
	print '-'x20;
	printf ("\nSystem date and time are as follows: ");
	printf ("%s %s %s %02d %02d:%02d.%02d\n", $dayOfWeekAbbr[$dayOfWeek],$monthAbbr[$month], $dayMonth, $year, $hour, $minutes, $seconds);
	do{
		printf ("Please provide your wall-time in any two by two digit format (i.e. 01:30 or 13:30).\nThe script will record this time for the investigators convenience.\n\n");
		printf ("Wall-time: ");
		chomp ($walltime = <STDIN>);
		if($walltime =~ /\d{2}\:\d{2}/){ $timegood=1;}
	}while ($timegood==0);
	printf ("\n\nInvestigators wall-time: $walltime\n");
	print '='x20;

}

sub DetermineOS{
	printf ("\n\nDetermining OS information\n");
	print '-'x20;
	my $Browser_HKEY_LOCALE = 'HKEY_CURRENT_USER/Software/Microsoft/Windows/Shell/Associations/UrlAssociations/http/UserChoice/Progid';
	my $ClientDefaultBrowser = ();
	# Grab information about OS, login, etc
	$ClientOS = Win32::GetOSName();
	$ClientLogin = Win32::LoginName();
	$isScriptAdmin = Win32::IsAdminUser();
	
	# Determine what OS the user has as default for http connections
	$ClientDefaultBrowser = $Registry->{$Browser_HKEY_LOCALE} or die "Error: $!\n";
	# By using these ifs instead of a simple ELSE, we can just come back and waste less time if we expand functionality to another popular browser.
	if ($ClientDefaultBrowser =~ /FirefoxURL/gi){ 
		printf ("\n\nDefault browser is Firefox.\n");
		$DefaultBrowser=1;  # By collecting this information now, it'll be less painful in expansions. Since we already look for 
							# what browser is the default, we might as well store that information. This way, later, we can simply just have an if
							# which will allow us to switch to whatever sub call we need to. For example, if we expand to include firefox, we can just
							# have an if that says if $defaultbrowser==1, call firefox db connection. 
	}
	elsif ($ClientDefaultBrowser =~ /IE\.HTTP/gi){ 
		printf ("\nDefault browser is Internet Explorer.\n");
		$DefaultBrowser=2;
	}
	elsif ($ClientDefaultBrowser =~ /ChromeHTML/gi){ 
		printf ("\nDefault browser is Chrome\n"); 
		$DefaultBrowser=0; # Zero since it's the first one we actually scripted for
	}
	else { 
		printf ("\nBrowser not recognized.\n"); 
		$DefaultBrowser=3;
	}
	if ($DefaultBrowser != 0){
		my $quitResp = ();
		printf ("The default browser is not supported at this time\n");
		printf ("Would you like to continue your investigation anyway? [y/n]: ");
		chomp ($quitResp = <STDIN>);
		
		if ($quitResp =~ /no?/i){ printf ("Terminating script\n"); exit(0); }
		elsif ($quitResp =~ /ye?s?/i){ 
			printf ("\n\nUser has acknowledged that Chrome is not the default browser but still wishes to search for the database files.\n");
			printf ("By continuing the user acknowledges that the script may crash and cause permanent damage to the system being investigated.\n");
		#	system(`timeout 5`);
		}
		else { 
			printf ("Command not recognized. Please try again.\n");	
			while ($quitResp ne 'y'){ # Just look for 'y', because if we get no, then we die anyway
				printf ("The default browser is not supported at this time.\n");
				printf ("Would you like to continue your investigation anyway? [y/n]: ");
				chomp ($quitResp = <STDIN>);
				if ($quitResp =~ /no?/i){ printf ("Terminating script\n"); exit(0); }
				elsif ($quitResp =~ /ye?s?/i){ 
					printf ("\n\nUser has acknowledged that Chrome is not the default browser but still wishes to search for the database files.\n");
					printf ("By continuing the user acknowledges that the script may crash and cause permanent damage to the system being investigated.\n");
					$quitResp = 'y';
		#			system(`timeout 5`);
				}
			}
		}
	}
	if ($ClientOS =~ /win7/i || $ClientOS =~ /winvista/i){ $ChromeDB = 'C:\Users\\'.$ClientLogin.'\AppData\Local\Google\Chrome\User Data\Default\\'; }
	elsif ($ClientOS =~ /winxp/i) { 
	$ChromeDB = 'C:\Documents and Settings\\'.$ClientLogin.'\Local Settings\Application Data\Google\Chrome\User Data\Default\\'; 
	}
	printf ("\nChecking local account information.\n\n");
## Determine groups here
	printf ("\nClient Operating System: $ClientOS\nIs script running as admin? %s\n", ($isScriptAdmin? "true" : "false"));
	printf ("Script is running under login name of \"$ClientLogin\"\n");
	print '-'x20;
	print "\n";
}

sub GrabHash{
	printf ("\n\nHashing file output (MD5)\n");
	print '-'x20;
	my $file = shift; # Set file to hash
	my ($md5, $FileHash);

	open(FILE, $file) or die "Couldn't open file: $!\n"; # Check permissions prior to this - KD
	binmode(FILE); # Switch file to binmode

	$md5 = Digest::MD5->new; # Reset Digest

	while(<FILE>){$md5->add($_);} # Drop everything into the digest
	close (FILE); # Close file

	$FileHash = $md5->hexdigest; # Create MD5

	printf ("\nThe MD5 of the file ($file) is \n");
	print '-'x20;
	printf "\n\n";
	# Reminder for kevin: http://perldoc.perl.org/functions/-X.html
}
 
sub openChromeHistory{
	printf ("\n\nGrabbing History\n");
	print '-'x20; print "\n";
	my $dbPath = shift;
	my $dbHandle = ();
	my @grabURLs = ();
	my @rows = ();
	if (-d $dbPath){
		$dbHandle = DBI->connect("dbi:SQLite:$dbPath/History","","") or die ("\n\nSomething went wrong during the scrape [History] " . DBI->errstr);
		#http://computer-forensics.sans.org/blog/2010/01/21/google-chrome-forensics/
		#http://search.cpan.org/~adamk/DBD-SQLite-1.37/lib/DBD/SQLite.pm
		#http://www.perl.com/pub/1999/10/DBI.html

		my $sth = $dbHandle->prepare("SELECT urls.url, urls.title, urls.visit_count, urls.typed_count, urls.last_visit_time, urls.hidden, 
		visits.visit_time, visits.from_visit, visits.transition FROM urls, visits WHERE urls.id=visits.url GROUP BY urls.last_visit_time") or die ("\n\nCouldn't prepare the SQL statement for history: $!\n\n");
		$sth->execute() or die ("\n\nCouldn't execute query: $!\n\n");
		
		while(@rows = $sth->fetchrow_array()){
			my $url=$rows[0]; my $urltitle=$rows[1]; my $visitcount=$rows[2];
			my $urltyped=$rows[3]; my $last_visit_time=&convertTime($rows[4]); my $hidden=$rows[5];
			my $visit_time=&convertTime($rows[6]); my $fromvisit=$rows[7]; my $transition=$rows[8];
			push(@ChromeRecentHistoryRecords, [ $url, $urltitle, $visitcount, $urltyped, $last_visit_time, $hidden, $visit_time, $fromvisit, $transition ]);
			# Array is structured as: url, title, visit_count, typed_count, last_visit_time, hidden?, visit_time, from_visit, tranisition
		}
		foreach (@ChromeRecentHistoryRecords){ printf ("@$_\n\n"); }
		
		$sth->finish; # Tell DB that we're done
		$dbHandle->disconnect; # Be nice to the DB
	}
	else{ printf ("\n\nThe database for History does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
	print '-'x20;
	print "\n\n";
}

sub openChromeLogins{
	printf ("\n\nChecking login information\n");
	print '-'x20; print "\n";
	my $dbPath = shift;
	my $dbHandle = ();
	my @grabURLs = ();
	my @rows = ();

	if (-d $dbPath){
		$dbHandle = DBI->connect("dbi:SQLite:$dbPath/Login Data","","") or die ("\n\nSomething went wrong during the scrape [Logins] " . DBI->errstr);
		my $sth = $dbHandle->prepare("SELECT logins.origin_url, logins.username_element, logins.username_value, logins.password_element, 
		logins.password_value, logins.date_created FROM logins") or die ("\n\nCouldn't prepare the SQL statement for logins: $!\n\n");
		$sth->execute() or die ("\n\nCouldn't execute query: $!\n\n");
		
		while(@rows = $sth->fetchrow_array()){
			my $originURL=$rows[0]; my $usernameElem=$rows[1]; my $usernameVal=$rows[2]; my $passwordElem=$rows[3];
			my $passwordVal=$rows[4]; my $dateCreated=$rows[5];
			print Dumper (\@rows);

			push(@ChromeRecentLoginRecords, [ $originURL, $usernameElem, $usernameVal, $passwordElem, $passwordVal, $dateCreated]);
		# Array is structured as: origin, usernamelement, usernamevalue, passwordelement, passwordvalue, datecreated
		}
		print "@$_\n" for @ChromeRecentLoginRecords;
		
		$sth->finish; # Tell DB that we're done
		$dbHandle->disconnect; # Be nice to the DB
	}
	else{ printf ("\n\nThe database for Logins does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
	print '-'x20;
	print "\n\n";
}
 
sub openChromeBookmarks{
	printf ("\n\nGrabbing bookmarks\n");
	print '-'x20; print "\n";
	my $dbPath = shift;
		
	if (-d $dbPath){
		my $bookmarkFile = ();
		my @bookmarkInfo = ();

		
		open (FILE, "$dbPath/Bookmarks") or die "Couldn't open bookmarks: $!\n";
		while (<FILE>){ push(@bookmarkInfo,$_);}
		close FILE;
		
		print (@bookmarkInfo);
	
	
	}
	else{ printf ("\n\nThe database for Bookmarks does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
	print '-'x20;
	print "\n\n";
}
 
 
 
 
sub help{
	printf ("\nWelcome to $0.\nThe available switches are available for your usage throughout this program.\n");
	print '-'x20; say"";
	printf ("Other switches for misc. activities are as follows:\nHelp: -h.");
	printf ("\n");
	exit(0);
}

sub convertTime {
# converts google time to human readable time
my $epochSeconds = ((shift)/1000000)-11644473600;
#print "$epochSeconds\n";
my $theDateTime= strftime( '%Y-%m-%d %H:%M:%S', localtime($epochSeconds) );

#print "The Epoch Seconds are\: $epochSeconds\n";
#print "The Converted Date is\: $theDate\n";

return $theDateTime;
}




