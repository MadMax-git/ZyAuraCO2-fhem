###############################################################################
# 
#  (c) 2017 Copyright: Joachim Scharnagl
#  All rights reserved
#
#  This script is based on the 74_XiaomiFlowerSens module done by Marko Oldenburg
#
#  The other necessary stuff is based on following works:
#
#  https://hackaday.io/project/5301-reverse-engineering-a-low-cost-usb-co-monitor
#
#  https://github.com/vshmoylov/libholtekco2
#
#  Many thanks to those guys!
#
#  This script is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  any later version.
#
#  The GNU General Public License can be found at
#  http://www.gnu.org/copyleft/gpl.html.
#  A copy is found in the textfile GPL.txt and important notices to the license
#  from the author is found in LICENSE.txt distributed with these scripts.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
###############################################################################

package main;

use strict;
use warnings;
use POSIX;

use Blocking;

my $version = "0.0.7";

sub ZyAuraCO2_Initialize($)
{
  my ($hash) = @_;
	
  $hash->{SetFn}    = "ZyAuraCO2_Set";
  $hash->{DefFn}    = "ZyAuraCO2_Define";
  $hash->{UndefFn}  = "ZyAuraCO2_Undef";
  $hash->{AttrFn}   = "ZyAuraCO2_Attr";
  $hash->{AttrList} = "interval ".
                      "CO2ReadData:both,temp,co2 ".
                      "CO2Path ".
                      "CO2sshHost ".
                      "timeout ".
                      "disable:1 ".
                      "disabledForIntervals ".
                      $readingFnAttributes;
}

sub ZyAuraCO2_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);
  my $name = $a[0];

  if(@a !=2)
  {
    return "too few parameters: define <name> ZyAuraCO2";
  }
      
  $hash->{INTERVAL}   = 300;

  readingsSingleUpdate($hash, "state", "initialized", 0);
    
  if(!defined($attr{$name}{room}))
  {
    $attr{$name}{room} = "ZyAuraCO2";
  }

  RemoveInternalTimer($hash);
      
  InternalTimer(gettimeofday()+$hash->{INTERVAL}, "ZyAuraCO2_stateRequestTimer", $hash, 0);
    
  Log3 $name, 3, "ZyAuraCO2 ($name) - defined";
    
  return undef;
}

sub ZyAuraCO2_Undef($$)
{
  my ($hash, $arg) = @_;
  my $name = $hash->{NAME};
    
  RemoveInternalTimer($hash);
    
  if(defined($hash->{helper}{RUNNING_PID}))
  {
    BlockingKill($hash->{helper}{RUNNING_PID});
  }
  
  Log3 $name, 3, "ZyAuraCO2 ($name) - undefined";

  return undef;
}

sub ZyAuraCO2_Attr(@)
{
  my ($cmd, $name, $attrName, $attrVal) = @_;
  my $hash = $defs{$name};
  my $orig = $attrVal;
    
  if($attrName eq "disable")
  {
    if($cmd eq "set" and $attrVal eq "1")
    {
      readingsSingleUpdate($hash, "state", "disabled", 1);
      Log3 $name, 3, "Sub ZyAuraCO2 ($name) - disabled";
    }
    elsif($cmd eq "del")
    {
      readingsSingleUpdate($hash, "state", "active", 1);
      Log3 $name, 3, "Sub ZyAuraCO2 ($name) - enabled";
    }
  }
    
  if($attrName eq "disabledForIntervals")
  {
    if($cmd eq "set")
    {
      Log3 $name, 3, "Sub ZyAuraCO2 ($name) - disabledForIntervals";
      readingsSingleUpdate($hash, "state", "Unknown", 1);
    }
    elsif($cmd eq "del")
    {
      readingsSingleUpdate($hash, "state", "active", 1);
      Log3 $name, 3, "Sub ZyAuraCO2 ($name) - enabled";
    }
  }
    
  if($attrName eq "interval")
  {
    if($cmd eq "set")
    {
      if($attrVal < 300)
      {
        Log3 $name, 3, "Sub ZyAuraCO2 ($name) - interval too small, please use something >= 300 (sec), default is 3600 (sec)";
        return "interval too small, please use something >= 300 (sec), default is 3600 (sec)";
      }
      else
      {
        $hash->{INTERVAL} = $attrVal;
        Log3 $name, 3, "Sub ZyAuraCO2 ($name) - set interval to $attrVal";
      }
    }
    elsif( $cmd eq "del" )
    {
      $hash->{INTERVAL} = 300;
      Log3 $name, 3, "Sub ZyAuraCO2 ($name) - set interval to default";
    }
  }
    
  return undef;
}

sub ZyAuraCO2_stateRequest($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $state = ReadingsVal($name, "state", 0); 
  
  Log3 $name, 5, "Sub ZyAuraCO2_stateRequest ($name) state: $state";
      
  if((ReadingsVal($name, "state", 0) eq "initialized" or ReadingsVal($name, "state", 0) eq "unreachable" or ReadingsVal($name, "state", 0) eq "disabled" or ReadingsVal($name, "state", 0) eq "Unknown") and !IsDisabled($name))
  {
    readingsSingleUpdate($hash, "state", "active", 1);
  }
  
  if(IsDisabled($name))
  {
    readingsSingleUpdate($hash, "state", "disabled", 1);
  }
  
  if(!IsDisabled($name))
  {
    ZyAuraCO2($hash)
  }
}

sub ZyAuraCO2_stateRequestTimer($)
{
  my ($hash)      = @_;
  my $name        = $hash->{NAME};
  
  RemoveInternalTimer($hash);
  
  if((ReadingsVal($name, "state", 0) eq "initialized" or ReadingsVal($name, "state", 0) eq "unreachable" or ReadingsVal($name, "state", 0) eq "disabled" or ReadingsVal($name, "state", 0) eq "Unknown") and !IsDisabled($name))
  {
    readingsSingleUpdate($hash, "state", "active", 1);
  }
  
  if(IsDisabled($name))
  {
    readingsSingleUpdate($hash, "state", "disabled", 1);
  }
  
  Log3 $name, 5, "Sub ZyAuraCO2 ($name) - Request Timer wird aufgerufen";
  
  if(!IsDisabled($name))
  {
    ZyAuraCO2($hash)
  }
  
  InternalTimer(gettimeofday() + $hash->{INTERVAL}, "ZyAuraCO2_stateRequestTimer", $hash, 1);
}

sub ZyAuraCO2_Set($$@)
{
  my ($hash, $name, @aa) = @_;
  my ($cmd, $arg) = @aa;
  my $action;

  if($cmd eq 'statusRequest')
  {
    ZyAuraCO2_stateRequest($hash);
  }
  else
  {
    my $list = "statusRequest:noArg";
    return "Unknown argument $cmd, choose one of $list";
  }

  return undef;
}

sub ZyAuraCO2($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};
  my $timeout = AttrNum($name, "timeout", 120);

  if(defined($hash->{helper}{RUNNING_PID}))
  {
    BlockingKill($hash->{helper}{RUNNING_PID});
  }
      
  $hash->{helper}{RUNNING_PID} = BlockingCall("ZyAuraCO2_Run", $name, "ZyAuraCO2_Done", $timeout, "ZyAuraCO2_Aborted", $hash) unless(exists($hash->{helper}{RUNNING_PID}));
  Log3 $name, 5, "Sub ZyAuraCO2 ($name) - Blocking Call started with timeout of $timeout s.";
  
  if(ReadingsVal($name, "state", 0) eq "active")
  {
    readingsSingleUpdate($hash, "state", "call data", 1);
  }
}

sub ZyAuraCO2_Run($)
{
  my ($name) = @_;

  Log3 $name, 5, "Sub ZyAuraCO2_Run ($name) - Running nonBlocking";

  ##### Abruf des CO2-Wertes
  my $co2 = ZyAuraCO2_ReadCO2($name);
  
  ##### Abruf des Temperatur-Wertes
  # TODO

  if(defined $co2)
  {
    Log3 $name, 5, "Sub ZyAuraCO2_Run ($name) - Rückgabe an Auswertungsprogramm beginnt / co2: $co2";
  }
  else
  {
    Log3 $name, 3, "Sub ZyAuraCO2_Run ($name) - Rückgabe an Auswertungsprogramm. Fehler beim Lesen von co2.";
  }

  return "$name|err"
  unless(defined($co2));
  
  Log3 $name, 5, "Sub ZyAuraCO2_Run ($name) - co2 definded: $co2";

  return "$name|$co2";
}

sub ZyAuraCO2_ReadCO2($)
{
  my ($name) = @_;
  my $path = AttrVal($name, "CO2Path", "/usr/bin/ZyAuraCO2");
  my $sshHost = AttrVal($name, "CO2sshHost", "n.a.");
  my @pathparts = split(/\//, $path);
  my $execname = $pathparts[(scalar @pathparts) - 1];
  my $cmdExec = "";
  my $cmdGrep = "";
  my $loop = 0;

  Log3 $name, 5, "Sub ZyAuraCO2_ReadCO2 ($name) path: $path  execname: $execname";
  
  if($sshHost ne "n.a.")
  {
    $sshHost =~ s/@/\\@/g;

#    $cmdExec = "ssh $sshHost \"sudo $path\"";
    $cmdExec = "ssh $sshHost \"sudo $path\" 2>/dev/null";

#    $cmdGrep = "ssh $sshHost \"ps ax | grep -v grep | grep \"$execname\"\"";
    $cmdGrep = "ssh $sshHost \"ps ax | grep -v grep | grep \"$execname\"\" 2>/dev/null";
  }
  else
  {
#    $cmdExec = "sudo $path";
    $cmdExec = "sudo $path  2>/dev/null";
  }

  while((qx($cmdGrep) and $loop = 0) or (qx($cmdGrep) and $loop < 20))
  {
    Log3 $name, 5, "Sub ZyAuraCO2_ReadCO2 ($name) already running...";
    sleep 0.5;
    $loop++;
  }

  Log3 $name, 5, "Sub ZyAuraCO2_ReadCO2 ($name) starting $cmdExec";

#TODO: error handling etc.  
  my $readData = qx($cmdExec);
  
  my @readDataParts = split(/\n/, $readData);
  $readData = $readDataParts[1];

  if(defined $readData)
  {
    Log3 $name, 5, "Sub ZyAuraCO2_ReadCO2 ($name) readData: $readData";
  }
  else
  {
    Log3 $name, 5, "Sub ZyAuraCO2_ReadCO2 ($name) readData failed.";
  }

  return $readData;
}

sub ZyAuraCO2_Done($)
{
  my ($string) = @_;
  my ($name,$response) = split("\\|",$string);
  my $hash = $defs{$name};

  Log3 $name, 5, "Sub ZyAuraCO2_Done ($name) - 1";
  
  delete($hash->{helper}{RUNNING_PID});
  
  Log3 $name, 5, "Sub ZyAuraCO2_Done ($name) - 2";
  
  Log3 $name, 5, "Sub ZyAuraCO2_Done ($name) - Der Helper ist disabled. Daher wird hier abgebrochen" if($hash->{helper}{DISABLED});

  return if($hash->{helper}{DISABLED});

  if($response eq "err")
  {
#    readingsSingleUpdate($hash,"state","unreachable", 1);
    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash, "state", "unreachable");
    readingsBulkUpdate($hash, "CO2", "error");
    readingsEndUpdate($hash,1);
    return undef;
  }

  Log3 $name, 5, "Sub ZyAuraCO2_Done ($name) - 3";
  
  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "CO2", $response);
  if(ReadingsVal($name,"state", 0) eq "call data" or ReadingsVal($name,"state", 0) eq "unreachable")
  {
    readingsBulkUpdate($hash, "state", "active");
  }  
  readingsEndUpdate($hash,1);
  
  Log3 $name, 5, "Sub ZyAuraCO2_Done ($name) - Abschluss!";
}

sub ZyAuraCO2_Aborted($)
{
  my ($hash) = @_;
  my $name = $hash->{NAME};
  
  delete($hash->{helper}{RUNNING_PID});

  readingsSingleUpdate($hash,"state","unreachable", 1);

  Log3 $name, 3, "($name) - The BlockingCall Process terminated unexpectedly. Timedout";
}



1;




=pod
=item device
=item summary    
=item summary_DE 

=begin html

=end html

=begin html_DE

=end html_DE

=cut
