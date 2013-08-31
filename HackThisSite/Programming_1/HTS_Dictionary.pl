#! C:\strawberry\perl\bin\perl.exe
# Kevin Dolphin
# Hack This Site
# Programming 1

# Note: For some reason, unknown to me, this doesn't work every time. I failed the mission the first time with the script, completed it the second time.
# If you don't get it the first time, cycle through a few times, you'll get it.


my (@list, @scrambled, @unscrambled); # For your dictionary, scrambled, and unscrambled words
my @scrambled = qw/ 	
ietrbm
	
suactc
	
coeiko
	
rced1ti
	
esegal
	
rapaciti
	
icstru
	
cooclaca
	
sig1nt
	
hvewraet
/;

# Copy and paste the words, given on the website, above. The words should be placed on the lines after "qw/", with the line after your last word being "/;"


&readlist();
&compare();

print "\n";
foreach (@unscrambled){ # Print the end result!
	print "$_," unless $_ eq $unscrambled[$#unscrambled];
	if ($_ eq $unscrambled[$#unscrambled]){ print "$_\n"; }
} 

sub readlist{ # Open the wordlist they provide. You may need to edit this depending on where you're running the script from and where you placed the wordlist
	open (LIST, "<", "wordlist.txt");
	while(<LIST>){s/\R//g; push(@list,$_); } # s/\R//g replaces any type of newline or carriage return
	close LIST;
}

sub compare{ # MAGIC GOES HERE
	foreach my $scramble (@scrambled){ # For every scrambled word in our list, perform the following . . .
		my @matches; # Each word will have several initial valid matches, based on length
		
		# print "Starting with word: $scramble\n"; # Remove the '#' if you want a more verbose output
		
			foreach my $dict (@list){ # Find matches that could exist based on length of the dictionary word and the scrambled word
				if (length($scramble) == length($dict)){
					push (@matches, $dict);
				}
			}
			
			foreach my $match (@matches){ # Now that we have initial matches, lets do some magic
				my $usable = $scramble; # Perserve the scrambled word
				my $matchCount = 0; # To ensure we match 100%
				my $count = 0; # To increment through our word
				
				my @splitUse = split('', $usable); # Split the temp word into lettters
								
				while ($count < length($match)){ # While our count is less than the length of the dictionary word
					my $search = quotemeta($match); # Quotemeta incase we have special chars
					$_ = $splitUse[$count]; # Reset for easy regex
					
				# print "$search -> $_\n"; # More verbose output if required
				
					if ($search =~ m/$_/gi){ # If our dict word contains the current letter, we match
						$matchCount++; # This will hopefully equal the length of the word
					}
					$count++;
				}
				if ($matchCount == length($match)){ 
					push (@unscrambled, $match); # Add our found, unscrambled, word to a list
					last; # End since we found our word
				}
			}
	}
}