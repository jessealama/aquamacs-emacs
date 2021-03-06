#!/usr/bin/perl

# Give version-queries.log as STDIN
#
#
use Time::ParseDate; 

use Geo::IP;

my $gi = Geo::IP->new(GEOIP_STANDARD);
 
$today = time;
$oneday = 60*60*24;

$firstday = 12936;  # manually set: day of introduction

$long_period_days = 7;
$current_long_period = 0;
@different_users_during_long_period = ();
%different_users_in_current_long_period = ();

%countries = ();

%users_startups = ();
%users_installtime = (); # first use time
%users_lastcheck = (); # a user's last version check
%new_users_in_period = ();

%checksperday = ();
%checkscurrentperiod = ();
%versions_timeline = ();
$versions_timeline_count = 0;
@allversions = ();

$lastperiod = -1;

$linecount = 0;
# the following assumes sequential reading - 
# earlier events must come earlier
while (<STDIN>)
  {
    # filter garbage at line start - is in there for some reason.. (???)

    s/ //g;



    if (/^[^A-Z]*\s*[^A-Z]*(.*?)\s\s\s+([\.0-9]+)\s*sess=(\-?[0-9]*)\&.*seq=([0-9]*)\&.*ver=([^\&\n]*)/ig) {
      
      $linecount += 1;
      
      $t = $1; 

      $ep = parsedate($t , FUZZY => 1, PREFER_PAST=>1); 
      if (int($ep) < 100) {
	warn "bad time: ", "x".$t."x". $ep;
      }

      if (int($ep) >= $prev_ep-1 && int($ep)<= $prev_ep+43200) # weed out garbage
	{
      $prev_ep = int($ep);

      $starts = $4;
      $ver = $5;

      $uid = $3;
      $origip = $2;
      $period = int($ep/($oneday));
      if ($period) {
	my $gap = ($period - $last_scanned_period);

	warn "gap $gap in data at $period" if ($gap > 1);
	$last_scanned_period = $period;
	
	my $pd = int(($period-$firstday)/$long_period_days);

	# sanity check in order to avoid corrupt data
	if (!$long_period || ($pd>$long_period-2 && $pd<$long_period+3))
	  {
	    $long_period = int(($period-$firstday)/$long_period_days);
	  }
      }

      

      if ($long_period > $current_long_period) {
	# has the next week started?
	# count number of different users encountered during last week
	$different_users_during_long_period[$current_long_period] 
	  = scalar keys %different_users_in_current_long_period;
	warn "week: $long_period";
	$current_long_period = $long_period;
	%different_users_in_current_long_period = ();
      } elsif ($long_period < $current_long_period)
	{
	  warn "time going backwards! weeks: $long_period < $current_long_period";
	  $current_long_period = $long_period;
	  %different_users_in_current_long_period = ();
	}
      $different_users_in_current_long_period{$uid} += 1;

      # exclude today (because incomplete)
      if ($period < int($today/$oneday)) {

	# we want to find out:
	# - new users per period, gone-away users per period

	if (exists($users_startups{$uid})) {
	  $users_startups{$uid} += $starts;
	} else {
	  $users_startups{$uid} = $starts;
	  # it's a new user!
	  $new_users_in_period{$period} += 1;
	  $users_installtime{$uid} = $ep;
	 
	}
	$users_lastcheck{$uid} = $ep;

	# user's country
	if ($ep > $today-4*$oneday) {
	  $users_country{$uid} = $gi->country_name_by_addr($origip);
	  
	}



	# conversion rate
	# how many of the new users per period keep using Aquamacs?
    

	# - numbers of users per version with more than 1 request in the last 10 days
	$ver =~ s/%20/ /gs;
	if ($users_version{$uid} eq $ver)
	  {
	    $user_has_updated = 0;
	  } else
	  {
	    $user_has_updated = 1;
	    $users_version{$uid} = $ver;
	  }
	
	$period_users_version{$uid} = $ver;


	# checks per day
	if ($period > $lastperiod) {
	    
	  # add the version distribution of the day

	  %td_versions = ();
	  for my $u (keys %period_users_version) {
	    $td_versions{$period_users_version{$u}} += 1;
	    if (! (exists ($allversions{$period_users_version{$u}}))) {
	      $allversions{$period_users_version{$u}} = 1; # add to the set
	    }
	    delete $period_users_version{$u};
	  }
	    
	  for my $v (keys %allversions) {
	    if (!( exists($versions_timeline{$v} ))) {
	      $versions_timeline{$v} = "\t NA" x $versions_timeline_count;
	      print $versions_timeline_count;
	    }
	    if (exists($td_versions{$v})) {
	      $versions_timeline{$v} .= "\t" . $td_versions{$v};
		    
	    } else {
	      $versions_timeline{$v} .= "\t 0";
	    }
	  }
	      

	  $versions_timeline_count += 1;

	  if ($lastperiod > 0) {	   
	    $checksperday{$lastperiod} = scalar(keys %checkscurrentperiod);
	  }
	  %checkscurrentperiod = ();
	  $lastperiod = $period;
	}
	
	$checkscurrentperiod{$uid} = 1;
      }
    }
    } else {
      # warn "parsing error: ".$_;
    }		

  }
print "done1: $linecount lines.";

$checksperday{$lastperiod} = scalar(keys %checkscurrentperiod);

# now check conversion rates

# filter out users that did not stick with Aquamacs
# track versions
$num_users = 0;
%version_dist = (0,0);
%converted_per_period = {};
foreach my $uid (keys %users_installtime)
  {
    if ($users_lastcheck{$uid} - $users_installtime{$uid}>7*$oneday and $users_installtime{$uid}<$today-12*$oneday and $users_startups{$uid}>5)  
      {
	# user has been sticking with it for at least 7 days
	# and more than 5 startups

	$p = int($users_installtime{$uid}/$oneday);
	$converted_per_period{$p} += 1;
	$num_users += 1;
      }
    # check version and country distribution
    if ($users_lastcheck{$uid} > $today-4*$oneday)
      {
	if ($version_dist{$users_version{$uid}}) {
	  $version_dist{$users_version{$uid}} += 1; }
	else {
	  $version_dist{$users_version{$uid}} = 1;
	}
	$countries{$users_country{$uid}} += 1;
      }
  }

 

# print user community stats

print "done2\n";

open F, ">conversionrate.txt";
print F "day  no.users  no.new    no.converted \n";

foreach my $p (sort(map(int, keys(%new_users_in_period))))
  {
    # multiplyu checks per day by 3 --> estimate of user base
    print F $p-$firstday, "\t", 3* $checksperday{$p}, "\t", $new_users_in_period{$p}, "\t";
    if ($converted_per_period{$p})
      {
	print F $converted_per_period{$p}
      } else {
	print F 0
      }
     
    print F "\n";
  }
close F;

print "done3\n";

open F, ">versions.txt";
print F "version   no.users \n" ;
print "Keys: ", scalar(%version_dist), "\n";

foreach my $v (sort keys %version_dist)
  {
    print F "\"$v\"", "\t", $version_dist{$v}, "\n";
  }
close F;

open F, ">version-timeline.txt";
for my $v (keys %allversions)
  {
    $v2 = $v;
    $v2 =~ s/\s//g;
    print F $v2, "\t", $versions_timeline{$v}, "\n";
  }
close F;

print "done4\n";
open F, ">countries.txt";
print F "country   no.users \n" ;

foreach my $c (sort keys %countries)
  {
    print F "\"$c\"", "\t", $countries{$c}, "\n";
  }
close F;


# - average startups per user and day (and distribution)

$perday_sum = 0;
$perday_num = 0;
@perday_dist = ();
@usage_duration = ();

foreach my $uid (keys %users_startups)
  {
    # how long has this guy been a user?
    $days = int(($users_lastcheck{$uid} - $users_installtime{$uid}) / $oneday);
    if($days>0)
      {
	$perday = $users_startups{$uid}/$days;
	$perday_sum += $perday;
	$perday_num += 1;
	$perday_dist[int($perday)] += 1;
	$usage_duration[$days] += 1;
      }
  }


open F, ">startups.txt";
print F "no.startups   no.users \n";
$perday_num = 1 if ($perday_num <1);
print F "# Mean # startups per day: ", ($perday_sum / $perday_num), "\n";
$i=0;
while($i< scalar( @perday_dist))
  {
    print F $i, "\t", $perday_dist[$i], "\n";
    $i++;
  }
close F;

open F, ">usage-duration.txt";
print F "duration   no.users \n"; 

$i=0;
while($i< scalar( @usage_duration))
  {
    print F $i, "\t", $usage_duration[$i], "\n";
    $i++;
  }
close F;

#


open F, ">user-exposure.txt";
print F "week   no.users \n"; 

$i=0;
while($i< scalar( @different_users_during_long_period))
  {
    if ( $different_users_during_long_period[$i]) 
      { print F  $i, "\t", $different_users_during_long_period[$i], "\n";}
    else
      { print F  $i, "\t", "NA\n"; }
    $i++;
  }
close F;

print "Number of users (last 10 days): ", $num_users, "\n";
