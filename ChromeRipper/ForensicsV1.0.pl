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

#http://computer-forensics.sans.org/blog/2010/01/21/google-chrome-forensics/
#http://search.cpan.org/~adamk/DBD-SQLite-1.37/lib/DBD/SQLite.pm
#http://www.perl.com/pub/1999/10/DBI.html
# --------------------------------

use Modern::Perl;
use Digest::MD5;
use Time::CTime;
use Win32::TieRegistry 0.20 (Delimiter=>"/");
use Win32;
use DBI;
use JSON -support_by_pp;
# Remove below before production
use diagnostics;
use Data::Dumper;
	
	# ---- Global declarations
	my ($OSChecker, $ClientOS, $isScriptAdmin, $ClientLogin, $isUserAdmin, $ChromeDB, $DefaultBrowser, $localgroups, $walltime );
	my ($printTo, $grabDeep, $fileOutName, $bookmarkCount);
	# ---- Initialize variables to null or zero
	$OSChecker=$ClientOS=$isScriptAdmin=$ClientLogin=$isUserAdmin=$ChromeDB=$DefaultBrowser=$walltime=0; 
	$printTo=$bookmarkCount=0;
	$grabDeep=$fileOutName=();
	# -----
	
	die if (!($^O =~ /MSWin32/i)); # If we're not on Windows, die
	
	foreach (@ARGV){
		if ($_ eq '-f'){ $printTo=2;} # User wants to print to a file
		if ($_ eq '-deep'){ $grabDeep=1;} # User wants more than the normal history
		if ($_ eq '-terminal'){ # User wants to print to the console
			if ($printTo == 2){ # Check in case user is a tard
				print "\nYou cannot chose both terminal and file.\n"; 
				&help; } 
			else { $printTo=1;}
		}
		if ($_ eq '-h'){ &help; } # Yay help messages
	}
	
	if (!$printTo){ &help(); } # If user did not pick terminal or file, call help and exit
	my $running = `tasklist | find "chrome"`;
	if ($running){ printf ("\n\nChrome is currently running. This will cause the script to pause until Chrome is exited.\n\n"); }
	if ($printTo==2){ # Get file name from user if -f is switched
		my $check = 0;
		printf ("By selecting a file, all script warnings will be disabled.\n");
		printf ("By continuing the user acknowledges that the script may crash and cause permanent damage to the system being investigated.\n\n");

			do{
				printf ("Please provide a name to save the output file as: ");
				chomp ($fileOutName = <STDIN>);
				if ($fileOutName =~ /\w+.txt/i){  # Ensure it's .txt and a legit name
						$check=1; print "\n\n";}
				else {printf ("That is an invalid name, but sure to include .txt in your file name\n"); }
			}while(!$check);
		
		&grabWall; 	
		open (FILE, ">", $fileOutName) or die "Couldn't open output file: $!\n";
		select FILE; # Since we're just using a file, don't print anything to the screen, print directly to file
		if ($running){ printf ("\nWhile grabbing wall-time, the Chrome process was running.\n");
			printf ("This may cause the script to fail to collect all information (such as the current browsing session information) or pause until Chrome is exited.\n"); }
		
	}
		printf ("\n\n");
		print '='x20;
	&Greet; # Say hello to the users
		print '='x20;
		
		printf ("\n\nDetermining OS information\n");
		print '-'x20;
	&DetermineOS; # Grab starter information and determine how to access chrome db
		print '-'x20;print "\n";
	
	
		printf ("\n\nGrabbing History [RECENT]\n");
		print '-'x20; print "\n";	
	&openChromeHistory ($ChromeDB); # Grab normal history
		print '-'x20;print "\n";
			
	if ($grabDeep){ 
			printf ("\n\nGrabbing History [DEEP]\n");
			print '-'x20; print "\n";
		&openChromeDeepHistory($ChromeDB); # Grab deep history
			print '-'x20;print "\n";
	}
		printf ("\n\nChecking login information\n");
		print '-'x20; print "\n";
	&openChromeLogins ($ChromeDB); # Login information
		print '-'x20;print "\n";
		
		printf ("\n\nGrabbing cookies\n");
		print '-'x20; print "\n";
	&openChromeCookies ($ChromeDB);	
		print '-'x20;print "\n";
		
		printf ("\n\nGrabbing bookmarks\n");
		print '-'x20; print "\n";
	&openChromeBookmarks ($ChromeDB); # The dredded bookmarks
	if ($bookmarkCount) {printf ("\nFound $bookmarkCount bookmark(s)\n");}
	else { printf ("No bookmarks were found in the database.\n"); }
		print '-'x20;print "\n";
	
		printf ("\n\nGrabbing downloads\n");
		print '-'x20; print"\n";
	&openChromeDownloads($ChromeDB); # Woo downloads
		print '-'x20;print "\n";
	
	&exitPhrase; # Clean exit
	
	if ($printTo == 2){ 
		close(FILE); # Close our file so we can hash it
			select STDOUT; # Select normal output to console so user can copy down the hash
			printf ("\n\nHashing file output (MD5)\n");
			print '-'x20;
		&GrabHash ($fileOutName); # Hash the txt
			print '-'x20;
			printf "\n\n";
	}


# ---- OS specific modules
sub DetermineOS{
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
		printf ("\nDefault browser is Firefox.\n");
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
	if ($DefaultBrowser != 0 && $printTo != 2){
		my $quitResp = ();
		printf ("The default browser is not supported at this time\n");
		printf ("Would you like to continue your investigation anyway? [y/n]: ");
		chomp ($quitResp = <STDIN>);
		
		if ($quitResp =~ /no?/i){ printf ("Terminating script\n"); exit(0); }
		elsif ($quitResp =~ /ye?s?/i){ 
			printf ("\n\nUser has acknowledged that Chrome is not the default browser but still wishes to search for the database files.\n");
			printf ("By continuing the user acknowledges that the script may crash and cause permanent damage to the system being investigated.\n");
		#	`timeout 5`;
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
		#			`timeout 5`;
				}
			}
		}
	}
	if ($ClientOS =~ /win7/i || $ClientOS =~ /winvista/i){ $ChromeDB = 'C:\Users\\'.$ClientLogin.'\AppData\Local\Google\Chrome\User Data\Default\\'; }
	elsif ($ClientOS =~ /winxp/i) { 
	$ChromeDB = 'C:\Documents and Settings\\'.$ClientLogin.'\Local Settings\Application Data\Google\Chrome\User Data\Default\\'; 
	}
	printf ("\nChecking local account information.\n\n");
	$localgroups = `net user %username% |findstr "*"`;
	printf ("User groups for $ClientLogin:\n$localgroups");
	printf ("\nClient Operating System: $ClientOS\nIs script running as admin? %s\n", ($isScriptAdmin? "true" : "false"));
	printf ("Script is running under login name of \"$ClientLogin\"\n");
}

 
# ---- Chrome based modules
sub openChromeHistory{
	my $dbPath = shift;
	my $dbHandle = ();
	my $ensureGrab = 0;
	my @rows = ();
	
	if (-d $dbPath){
		$dbHandle = DBI->connect("dbi:SQLite:$dbPath/History","","") or die ("\n\nSomething went wrong during the scrape [History-RECENT] " . DBI->errstr);

		my $sth = $dbHandle->prepare("SELECT urls.url, urls.title, urls.visit_count, urls.typed_count, urls.last_visit_time, urls.hidden, 
		visits.visit_time, visits.from_visit, visits.transition FROM urls, visits WHERE urls.id=visits.url GROUP BY urls.last_visit_time") or die ("\n\nCouldn't prepare the SQL statement for history: $!\n\n");
		$sth->execute() or die ("\n\nCouldn't execute query: $!\n\n");
		
		while(@rows = $sth->fetchrow_array()){
			my $url=$rows[0]; my $urltitle=$rows[1]; my $visitcount=$rows[2];
			my $urltyped=$rows[3]; my $last_visit_time=&convertTime($rows[4]); my $hidden=$rows[5];
			my $visit_time=&convertTime($rows[6]); my $fromvisit=$rows[7]; my $transition=($rows[8]%10);
			
			printf ("%s - %s - Was this typed: %d\n", $url, $urltitle, $urltyped);
			printf ("Visit count: %d - Last visited: %s - Visit time: %s\n", $visitcount, $last_visit_time, $visit_time);
			printf ("From where: %s - Transition code: %s - Was hidden: %d\n\n", $fromvisit, $transition, $hidden);
			$ensureGrab++;
		}
		if ($ensureGrab == 0){ printf ("No history [RECENT] was found in the database.\n"); }
		else{ printf ("Found $ensureGrab history artifact(s).\n"); }
		$sth->finish; # Tell DB that we're done
		$dbHandle->disconnect; # Be nice to the DB
	}
	else{ printf ("\n\nThe database for History does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
}

sub openChromeDeepHistory{
	my $dbPath = shift;
	my $dbHandle = ();
	my $ensureGrab = 0;
	my @rows = ();
	
	if (-d $dbPath){
		$dbHandle = DBI->connect("dbi:SQLite:$dbPath/Archived History","","") or die ("\n\nSomething went wrong during the scrape [History-Deep] " . DBI->errstr);

		my $sth = $dbHandle->prepare("SELECT urls.url, urls.title, urls.visit_count, urls.typed_count, urls.last_visit_time, urls.hidden, 
		visits.visit_time, visits.from_visit, visits.transition FROM urls, visits WHERE urls.id=visits.url GROUP BY urls.last_visit_time") or die ("\n\nCouldn't prepare the SQL statement for history: $!\n\n");
		$sth->execute() or die ("\n\nCouldn't execute query: $!\n\n");
		
		while(@rows = $sth->fetchrow_array()){
			my $url=$rows[0]; my $urltitle=$rows[1]; my $visitcount=$rows[2];
			my $urltyped=$rows[3]; my $last_visit_time=&convertTime($rows[4]); my $hidden=$rows[5];
			my $visit_time=&convertTime($rows[6]); my $fromvisit=$rows[7]; my $transition=$rows[8];
			$ensureGrab++;
		}
		if ($ensureGrab == 0){ printf ("No history [DEEP] was found in the database.\n"); }
		else{ printf ("Found $ensureGrab history [DEEP] artifact(s).\n"); }
		$sth->finish; # Tell DB that we're done
		$dbHandle->disconnect; # Be nice to the DB
	}
	else{ printf ("\n\nThe database for History [DEEP] does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
}

sub openChromeLogins{
	my $dbPath = shift;
	my $dbHandle = ();
	my $ensureGrab = 0;
	my @rows = ();

	if (-d $dbPath){
		$dbHandle = DBI->connect("dbi:SQLite:$dbPath/Login Data","","") or die ("\n\nSomething went wrong during the scrape [Logins] " . DBI->errstr);
		my $sth = $dbHandle->prepare("SELECT logins.origin_url, logins.username_value, logins.date_created FROM logins") or die ("\n\nCouldn't prepare the SQL statement for logins: $!\n\n");
		$sth->execute() or die ("\n\nCouldn't execute query: $!\n\n");
		printf ("Note that passwords with creation value of '0' may have been imported from a different browser.\nPasswords will NOT be shown.\n\n");
		while(@rows = $sth->fetchrow_array()){
			my $originURL=$rows[0]; my $usernameVal=$rows[1]; my $dateCreated=$rows[2];
			if ($dateCreated){$dateCreated=&convertTime($rows[5]);}
			printf ("Username: %s - Created: %d - URL: %s\n", $usernameVal, $dateCreated, $originURL);
			$ensureGrab++;
		}
		if ($ensureGrab == 0 ){ printf ("No login history was found in the database.\n");}
		else{ printf ("\nFound $ensureGrab login artifact(s).\n"); }
		$sth->finish; # Tell DB that we're done
		$dbHandle->disconnect; # Be nice to the DB
	}
	else{ printf ("\n\nThe database for Logins does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
}
 
sub openChromeBookmarks{
	my $dbPath = shift;
		
	if (-d $dbPath){
		#Get contents of bookmark file (JSON string)
		undef $/;
		open (BOOKS, $dbPath.'Bookmarks') or die "Couldn't open bookmarks: $!\n";
		my $JSON = do { local $/; <BOOKS> };
  
		#Call parser, passing JSON string
		&custom_parse_json($JSON);
	}
	else{ printf ("\n\nThe database for Bookmarks does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
}

sub openChromeDownloads{
	my $dbPath = shift;
	my $dbHandle = ();
	my $ensureGrab = 0;
	my @rows = ();
	
	if (-d $dbPath){
		$dbHandle = DBI->connect("dbi:SQLite:$dbPath/History","","") or die ("\n\nSomething went wrong during the scrape [Downloads] " . DBI->errstr);

		my $sth = $dbHandle->prepare("SELECT downloads.url, downloads.opened, downloads.full_path, downloads.received_bytes, downloads.total_bytes, downloads.start_time, downloads.end_time FROM downloads") or die ("\n\nCouldn't prepare the SQL statement for downloads: $!\n\n");
		$sth->execute() or die ("\n\nCouldn't execute query: $!\n\n");
		
		while(@rows = $sth->fetchrow_array()){
			my $url = $rows[0]; my $opened = $rows[1]; my $path = $rows[2];
			my $rec = $rows[3]; my $total = $rows[4]; my $start = &convertUnix($rows[5]);
			my $end = &convertUnix($rows[6]);
			printf ("URL: %s - Path: %s\n", $url, $path);
			printf ("Bytes received: %d - Bytes total: %d - Opened from browser: %s\n", $rec, $total, $opened==1?'Yes':'No');
			printf ("Begin download: %s - End download: %s\n\n", $start, $rec==$total?$end:'Did not finish');
			$ensureGrab++;
		}
		if ($ensureGrab == 0){ printf ("No downloads were found in the database.\n"); }
		else{ printf ("Found $ensureGrab download artifact(s).\n"); }
		$sth->finish; # Tell DB that we're done
		$dbHandle->disconnect; # Be nice to the DB
	}
	else{ printf ("\n\nThe database for downloads does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
}

sub openChromeCookies{
	my $dbPath = shift;
	my $dbHandle = ();
	my $ensureGrab = 0;
	my @rows = ();
	
	if (-d $dbPath){
		$dbHandle = DBI->connect("dbi:SQLite:$dbPath/Cookies","","") or die ("\n\nSomething went wrong during the scrape [Cookies] " . DBI->errstr);

		my $sth = $dbHandle->prepare("SELECT cookies.creation_utc, cookies.name, cookies.value, cookies.expires_utc, cookies.secure, cookies.last_access_utc, cookies.persistent, cookies.host_key FROM cookies") or die ("\n\nCouldn't prepare the SQL statement for cookies: $!\n\n");
		$sth->execute() or die ("\n\nCouldn't execute query: $!\n\n");
		
		while(@rows = $sth->fetchrow_array()){
			my $creation = &convertTime($rows[0]); my $name = $rows[1]; my $value = $rows[2];
			my $expires = $rows[3]!=0?&convertTime($rows[3]):'Does not expire'; my $secure = $rows[4]; my $last = &convertTime($rows[5]);
			my $pers = $rows[6]; my $host = $rows[7];
			printf ("Host: %s - Name: %s - Created: %s\n", $host, $name, $creation);
			printf ("Value of cookie: %s - Secure: %s - Persistent: %s\n", $value, $secure==0?'No':'Yes', $pers==0?'No':'Yes');
			printf ("Last accessed: %s - Expires on: %s\n\n", $last, $expires);
			$ensureGrab++;
		}
		if ($ensureGrab == 0){ printf ("No cookies were found in the database.\n"); }
		else{ printf ("Found $ensureGrab cookie artifact(s).\n"); }
		$sth->finish; # Tell DB that we're done
		$dbHandle->disconnect; # Be nice to the DB
	}
	else{ printf ("\n\nThe database for cookies does not exist in the default path.\nAre you sure the system has chrome on it?\n\n"); exit(); }
}


# ---- JSON based modules
sub custom_parse_json{
	my ($passed_json) = @_;
	my $perl_scalar = from_json($passed_json);	
	
	my @hashArray = sort {$a cmp $b} keys %$perl_scalar;
   for my $e ( @hashArray ) {
	  if ( $$perl_scalar{$e} =~ /HASH/ ) {
		&print_json_hash($$perl_scalar{$e});
	  }
	  elsif ( $$perl_scalar{$e} =~ /ARRAY/ ) {
		&print_json_array($$perl_scalar{$e});	
	  }
   }	
}
	
sub print_json_hash{
	my $isFolder = "No";
	my $hashref = shift;
	
	my @hashArray = sort {$a cmp $b} keys $hashref; #%passed_json;
	for my $e ( @hashArray ) {
	  
	  if ( $hashref->{$e} =~ /HASH/ ) {
		$isFolder = "Yes";
		&print_json_hash($hashref->{$e});
	  }
	  elsif ( $hashref->{$e} =~ /ARRAY/ ) {
		$isFolder = "Yes";
		&print_json_array($hashref->{$e});
	  }
   }	
   if ( $isFolder ~~ "No" ) {
		$bookmarkCount++;
		for my $e ( @hashArray ) {
			if ( $hashref->{$e} =~ /\d{17}/ ) {
				print ("$e - ".&convertTime($hashref->{$e})."\n");
			}
			else {
				print ("$e - $hashref->{$e}\n");
			}
		}
		print "\n\n";
   }
}
 
sub print_json_array{
	my $arrayref = shift;
	
	for my $e ( @{$arrayref} ) {
	  if ( $e =~ /HASH/ ) {
		&print_json_hash($e);
	  }
	  elsif ( $e =~ /ARRAY/ ) {
		&print_json_array($e);
	  }
   }	
}



# ---- Time based modules
sub grabWall {
	my $timegood = 0; 
	if ($walltime==0){
		do{
			printf ("Please provide your wall-time in any two by two digit format (i.e. 01:30 or 13:30).\nThe script will record this time for the investigators convenience.\n\n");
			printf ("Wall-time: ");
			chomp ($walltime = <STDIN>);
			if($walltime =~ /\d{2}\:\d{2}/){ $timegood=1;}
		}while ($timegood==0);
	}
}
 
sub convertTime {
	# converts WINDOWS epoch time to human readable time
	my $epochSeconds = ((shift)/1000000)-11644473600;
	my $theDateTime= strftime( '%Y-%m-%d %H:%M:%S', localtime($epochSeconds) );

	return $theDateTime;
}

sub convertUnix{
	# Since chrome likes to fuck with us, we store downloads as UNIX epoch, but everything else as host based. Go figure.
	my $epochSeconds = shift;
	my $realtime = localtime($epochSeconds);

	return $realtime;
}

sub sysTime{
	my @time = localtime(time);
	my @monthAbbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @dayOfWeekAbbr = qw (Sun Mon Tue Wed Thurs Fri Sat);
	my ($seconds, $minutes, $hour, $dayMonth, $month, $year, $dayOfWeek, $isdst);
	$seconds = $time[0]; $minutes = $time[1]; $hour = $time[2];
	$dayMonth = $time[3]; $month = $time[4]+1; $year = $time[5]+1900;
	$dayOfWeek = $time[6]; $isdst = $time[8];
	printf ("%s %s %s %02d %02d:%02d.%02d\n", $dayOfWeekAbbr[$dayOfWeek],$monthAbbr[$month], $dayMonth, $year, $hour, $minutes, $seconds);
}



# ---- Aux. modules 
sub Greet{
	printf ("\nWelcome to $0\n");
	printf ("This script assumes a Windows environment.\n");
	printf ("Please review the disclaimer packaged in the source or within the download file.\n");
	printf ("\nScripting by Kevin Dolphin, Jeris Rue\n");
	print '-'x20; print"\n\n";
	printf ("\nSystem date and time: ");
	&sysTime();
	if ($printTo != 2){&grabWall();}
	printf ("\n\nInvestigators wall-time: $walltime\n");
}

sub exitPhrase{
	print "\n\n";
	print '='x20;
	printf ("\nScript has finished, system time is: "); &sysTime;
}

sub GrabHash{
	my $file = shift; # Set file to hash
	my ($md5, $FileHash);
	printf "\nUsing file: $file to hash\n";
	open(HASH, $file) or die "Couldn't open file: $!\n"; # Check permissions prior to this - KD
	binmode(HASH); # Switch file to binmode

	$md5 = Digest::MD5->new; # Reset Digest

	while(<HASH>){$md5->add($_);} # Drop everything into the digest
	close (HASH); # Close file

	$FileHash = $md5->hexdigest; # Create MD5

	printf ("\nThe MD5 of the file ($file) is $FileHash\n");
	# Reminder for kevin: http://perldoc.perl.org/functions/-X.html
}
 
sub help{
	printf ("\nWelcome to $0.\nThe available switches are available for your usage throughout this program.\n");
	print '-'x20; say"";
	printf ("\nOne of the following are required:\n");
	printf ("%10s : Run the program, but display all results to the terminal. This requires interaction by the user.\n", '-terminal');
	printf ("%10s : Run the program, save to a file. The user will be asked to specify a filename after the program begins.\n", '-f');
	printf ("\t\t\tAll errors or warnings will be ignored. The file will be hashed following the completion of the program.\n");
	printf ("\nOther switches for misc. activities are as follows:\n");
	printf ("%10s : Display all stored history for Chrome.\n", '-deep');
	printf ("%10s : Display this message.\n", '-h');
	printf ("\n");
	exit(0);
}

 
 
 



