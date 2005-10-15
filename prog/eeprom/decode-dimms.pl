#!/usr/bin/perl -w
#
# Copyright 1998, 1999 Philip Edelbrock <phil@netroedge.com>
# modified by Christian Zuckschwerdt <zany@triq.net>
# modified by Burkart Lingner <burkart@bollchen.de>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# Version 0.4  1999  Philip Edelbrock <phil@netroedge.com>
# Version 0.5  2000-03-30  Christian Zuckschwerdt <zany@triq.net>
#  html output (selectable by commandline switches)
# Version 0.6  2000-09-16  Christian Zuckschwerdt <zany@triq.net>
#  updated according to SPD Spec Rev 1.2B
#  see http://developer.intel.com/technology/memory/pc133sdram/spec/Spdsd12b.htm
# Version 0.7  2002-11-08  Jean Delvare <khali@linux-fr.org>
#  pass -w and use strict
#  valid HTML 3.2 output (--format mode)
#  miscellaneous formatting enhancements and bug fixes
#  clearer HTML output (original patch by Nick Kurshev <nickols_k@mail.ru>)
#  stop decoding on checksum error by default (--checksum option forces)
# Version 0.8  2005-06-20  Burkart Lingner <burkart@bollchen.de>
#  adapted to Kernel 2.6's /sys filesystem
# Version 0.9  2005-07-15  Jean Delvare <khali@linux-fr.org>
#  fix perl warning
#  fix typo
#  refactor some code
# Version 1.0  2005-09-18  Jean Delvare <khali@linux-fr.org>
#  add large lookup tables for manufacturer names, based on data
#  provided by Rudolf Marek, taken from:
#  http://www.jedec.org/download/search/JEP106r.pdf
#
#
# EEPROM data decoding for SDRAM DIMM modules. 
#
# Two assumptions: lm_sensors-2.x installed,
# and Perl is at /usr/bin/perl
#
# use the following command line switches
#  -f, --format            print nice html output
#  -b, --bodyonly          don't print html header
#                          (useful for postprocessing the output)
#  -c, --checksum          decode completely even if checksum fails
#  -h, --help              display this usage summary
#
# References: 
# PC SDRAM Serial Presence 
# Detect (SPD) Specification, Intel, 
# 1997,1999, Rev 1.2B
#
# Jedec Standards 4.1.x & 4.5.x
# http://www.jedec.org
#

use strict;
use vars qw($opt_html $opt_body $opt_bodyonly $opt_igncheck $use_sysfs @vendors);

@vendors = (
["AMD", "AMI", "Fairchild", "Fujitsu",
 "GTE", "Harris", "Hitachi", "Inmos",
 "Intel", "I.T.T.", "Intersil", "Monolithic Memories",
 "Mostek", "Freescale (formerly Motorola)", "National", "NEC",
 "RCA", "Raytheon", "Conexant (Rockwell)", "Seeq",
 "Philips Semi. (Signetics)", "Synertek", "Texas Instruments", "Toshiba",
 "Xicor", "Zilog", "Eurotechnique", "Mitsubishi",
 "Lucent (AT&T)", "Exel", "Atmel", "SGS/Thomson",
 "Lattice Semi.", "NCR", "Wafer Scale Integration", "IBM",
 "Tristar", "Visic", "Intl. CMOS Technology", "SSSI",
 "MicrochipTechnology", "Ricoh Ltd.", "VLSI", "Micron Technology",
 "Hyundai Electronics", "OKI Semiconductor", "ACTEL", "Sharp",
 "Catalyst", "Panasonic", "IDT", "Cypress",
 "DEC", "LSI Logic", "Zarlink (formerly Plessey)", "UTMC",
 "Thinking Machine", "Thomson CSF", "Integrated CMOS (Vertex)", "Honeywell",
 "Tektronix", "Sun Microsystems", "SST", "ProMos/Mosel Vitelic",
 "Infineon (formerly Siemens)", "Macronix", "Xerox", "Plus Logic",
 "SunDisk", "Elan Circuit Tech.", "European Silicon Str.", "Apple Computer",
 "Xilinx", "Compaq", "Protocol Engines", "SCI",
 "Seiko Instruments", "Samsung", "I3 Design System", "Klic",
 "Crosspoint Solutions", "Alliance Semiconductor", "Tandem", "Hewlett-Packard",
 "Intg. Silicon Solutions", "Brooktree", "New Media", "MHS Electronic",
 "Performance Semi.", "Winbond Electronic", "Kawasaki Steel", "Bright Micro",
 "TECMAR", "Exar", "PCMCIA", "LG Semi (formerly Goldstar)",
 "Northern Telecom", "Sanyo", "Array Microsystems", "Crystal Semiconductor",
 "Analog Devices", "PMC-Sierra", "Asparix", "Convex Computer",
 "Quality Semiconductor", "Nimbus Technology", "Transwitch", "Micronas (ITT Intermetall)",
 "Cannon", "Altera", "NEXCOM", "QUALCOMM",
 "Sony", "Cray Research", "AMS(Austria Micro)", "Vitesse",
 "Aster Electronics", "Bay Networks (Synoptic)", "Zentrum or ZMD", "TRW",
 "Thesys", "Solbourne Computer", "Allied-Signal", "Dialog",
 "Media Vision", "Level One Communication"],
["Cirrus Logic", "National Instruments", "ILC Data Device", "Alcatel Mietec",
 "Micro Linear", "Univ. of NC", "JTAG Technologies", "Loral",
 "Nchip", "Galileo Tech", "Bestlink Systems", "Graychip",
 "GENNUM", "VideoLogic", "Robert Bosch", "Chip Express",
 "DATARAM", "United Microelec Corp.", "TCSI", "Smart Modular",
 "Hughes Aircraft", "Lanstar Semiconductor", "Qlogic", "Kingston",
 "Music Semi", "Ericsson Components", "SpaSE", "Eon Silicon Devices",
 "Programmable Micro Corp", "DoD", "Integ. Memories Tech.", "Corollary Inc.",
 "Dallas Semiconductor", "Omnivision", "EIV(Switzerland)", "Novatel Wireless",
 "Zarlink (formerly Mitel)", "Clearpoint", "Cabletron", "Silicon Technology",
 "Vanguard", "Hagiwara Sys-Com", "Vantis", "Celestica",
 "Century", "Hal Computers", "Rohm Company Ltd.", "Juniper Networks",
 "Libit Signal Processing", "Ramtron", "Tundra Semiconductor", "Adaptec Inc.",
 "LightSpeed Semi.", "ZSP Corp.", "AMIC Technology", "Adobe Systems",
 "Dynachip", "PNY Electronics", "Newport Digital", "MMC Networks",
 "T Square", "Seiko Epson", "Broadcom", "Viking Components",
 "V3 Semiconductor", "Flextronics (formerly Orbit)", "Suwa Electronics", "Transmeta",
 "Micron CMS", "American Computer & Digital Components Inc", "Enhance 3000 Inc", "Tower Semiconductor",
 "CPU Design", "Price Point", "Maxim Integrated Product", "Tellabs",
 "Centaur Technology", "Unigen Corporation", "Transcend Information", "Memory Card Technology",
 "CKD Corporation Ltd.", "Capital Instruments, Inc.", "Aica Kogyo, Ltd.", "Linvex Technology",
 "MSC Vertriebs GmbH", "AKM Company, Ltd.", "Dynamem, Inc.", "NERA ASA",
 "GSI Technology", "Dane-Elec (C Memory)", "Acorn Computers", "Lara Technology",
 "Oak Technology, Inc.", "Itec Memory", "Tanisys Technology", "Truevision",
 "Wintec Industries", "Super PC Memory", "MGV Memory", "Galvantech",
 "Gadzoox Nteworks", "Multi Dimensional Cons.", "GateField", "Integrated Memory System",
 "Triscend", "XaQti", "Goldenram", "Clear Logic",
 "Cimaron Communications", "Nippon Steel Semi. Corp.", "Advantage Memory", "AMCC",
 "LeCroy", "Yamaha Corporation", "Digital Microwave", "NetLogic Microsystems",
 "MIMOS Semiconductor", "Advanced Fibre", "BF Goodrich Data.", "Epigram",
 "Acbel Polytech Inc.", "Apacer Technology", "Admor Memory", "FOXCONN",
 "Quadratics Superconductor", "3COM"],
["Camintonn Corporation", "ISOA Incorporated", "Agate Semiconductor", "ADMtek Incorporated",
 "HYPERTEC", "Adhoc Technologies", "MOSAID Technologies", "Ardent Technologies",
 "Switchcore", "Cisco Systems, Inc.", "Allayer Technologies", "WorkX AG",
 "Oasis Semiconductor", "Novanet Semiconductor", "E-M Solutions", "Power General",
 "Advanced Hardware Arch.", "Inova Semiconductors GmbH", "Telocity", "Delkin Devices",
 "Symagery Microsystems", "C-Port Corporation", "SiberCore Technologies", "Southland Microsystems",
 "Malleable Technologies", "Kendin Communications", "Great Technology Microcomputer", "Sanmina Corporation",
 "HADCO Corporation", "Corsair", "Actrans System Inc.", "ALPHA Technologies",
 "Silicon Laboratories, Inc. (Cygnal)", "Artesyn Technologies", "Align Manufacturing", "Peregrine Semiconductor",
 "Chameleon Systems", "Aplus Flash Technology", "MIPS Technologies", "Chrysalis ITS",
 "ADTEC Corporation", "Kentron Technologies", "Win Technologies", "Tachyon Semiconductor (formerly ASIC Designs Inc.)",
 "Extreme Packet Devices", "RF Micro Devices", "Siemens AG", "Sarnoff Corporation",
 "Itautec Philco SA", "Radiata Inc.", "Benchmark Elect. (AVEX)", "Legend",
 "SpecTek Incorporated", "Hi/fn", "Enikia Incorporated", "SwitchOn Networks",
 "AANetcom Incorporated", "Micro Memory Bank", "ESS Technology", "Virata Corporation",
 "Excess Bandwidth", "West Bay Semiconductor", "DSP Group", "Newport Communications",
 "Chip2Chip Incorporated", "Phobos Corporation", "Intellitech Corporation", "Nordic VLSI ASA",
 "Ishoni Networks", "Silicon Spice", "Alchemy Semiconductor", "Agilent Technologies",
 "Centillium Communications", "W.L. Gore", "HanBit Electronics", "GlobeSpan",
 "Element 14", "Pycon", "Saifun Semiconductors", "Sibyte, Incorporated",
 "MetaLink Technologies", "Feiya Technology", "I & C Technology", "Shikatronics",
 "Elektrobit", "Megic", "Com-Tier", "Malaysia Micro Solutions",
 "Hyperchip", "Gemstone Communications", "Anadigm (formerly Anadyne)", "3ParData",
 "Mellanox Technologies", "Tenx Technologies", "Helix AG", "Domosys",
 "Skyup Technology", "HiNT Corporation", "Chiaro", "MCI Computer GMBH",
 "Exbit Technology A/S", "Integrated Technology Express", "AVED Memory", "Legerity",
 "Jasmine Networks", "Caspian Networks", "nCUBE", "Silicon Access Networks",
 "FDK Corporation", "High Bandwidth Access", "MultiLink Technology", "BRECIS",
 "World Wide Packets", "APW", "Chicory Systems", "Xstream Logic",
 "Fast-Chip", "Zucotto Wireless", "Realchip", "Galaxy Power",
 "eSilicon", "Morphics Technology", "Accelerant Networks", "Silicon Wave",
 "SandCraft", "Elpida"],
["Solectron", "Optosys Technologies", "Buffalo (Formerly Melco)", "TriMedia Technologies",
 "Cyan Technologies", "Global Locate", "Optillion", "Terago Communications",
 "Ikanos Communications", "Princeton Technology", "Nanya Technology", "Elite Flash Storage",
 "Mysticom", "LightSand Communications", "ATI Technologies", "Agere Systems",
 "NeoMagic", "AuroraNetics", "Golden Empire", "Mushkin",
 "Tioga Technologies", "Netlist", "TeraLogic", "Cicada Semiconductor",
 "Centon Electronics", "Tyco Electronics", "Magis Works", "Zettacom",
 "Cogency Semiconductor", "Chipcon AS", "Aspex Technology", "F5 Networks",
 "Programmable Silicon Solutions", "ChipWrights", "Acorn Networks", "Quicklogic",
 "Kingmax Semiconductor", "BOPS", "Flasys", "BitBlitz Communications",
 "eMemory Technology", "Procket Networks", "Purple Ray", "Trebia Networks",
 "Delta Electronics", "Onex Communications", "Ample Communications", "Memory Experts Intl",
 "Astute Networks", "Azanda Network Devices", "Dibcom", "Tekmos",
 "API NetWorks", "Bay Microsystems", "Firecron Ltd", "Resonext Communications",
 "Tachys Technologies", "Equator Technology", "Concept Computer", "SILCOM",
 "3Dlabs", "c't Magazine", "Sanera Systems", "Silicon Packets",
 "Viasystems Group", "Simtek", "Semicon Devices Singapore", "Satron Handelsges",
 "Improv Systems", "INDUSYS GmbH", "Corrent", "Infrant Technologies",
 "Ritek Corp", "empowerTel Networks", "Hypertec", "Cavium Networks",
 "PLX Technology", "Massana Design", "Intrinsity", "Valence Semiconductor",
 "Terawave Communications", "IceFyre Semiconductor", "Primarion", "Picochip Designs Ltd",
 "Silverback Systems", "Jade Star Technologies", "Pijnenburg Securealink", "MemorySolutioN",
 "Cambridge Silicon Radio", "Swissbit", "Nazomi Communications", "eWave System",
 "Rockwell Collins", "PAION", "Alphamosaic Ltd", "Sandburst",
 "SiCon Video", "NanoAmp Solutions", "Ericsson Technology", "PrairieComm",
 "Mitac International", "Layer N Networks", "Atsana Semiconductor", "Allegro Networks",
 "Marvell Semiconductors", "Netergy Microelectronic", "NVIDIA", "Internet Machines",
 "Peak Electronics", "Litchfield Communication", "Accton Technology", "Teradiant Networks",
 "Europe Technologies", "Cortina Systems", "RAM Components", "Raqia Networks",
 "ClearSpeed", "Matsushita Battery", "Xelerated", "SimpleTech",
 "Utron Technology", "Astec International", "AVM gmbH", "Redux Communications",
 "Dot Hill Systems", "TeraChip"],
["T-RAM Incorporated", "Innovics Wireless", "Teknovus", "KeyEye Communications",
 "Runcom Technologies", "RedSwitch", "Dotcast", "Silicon Mountain Memory",
 "Signia Technologies", "Pixim", "Galazar Networks", "White Electronic Designs",
 "Patriot Scientific", "Neoaxiom Corporation", "3Y Power Technology", "Europe Technologies",
 "Potentia Power Systems", "C-guys Incorporated", "Digital Communications Technology Incorporated", "Silicon-Based Technology",
 "Fulcrum Microsystems", "Positivo Informatica Ltd", "XIOtech Corporation", "PortalPlayer",
 "Zhiying Software", "Direct2Data", "Phonex Broadband", "Skyworks Solutions",
 "Entropic Communications", "Pacific Force Technology", "Zensys A/S", "Legend Silicon Corp.",
 "sci-worx GmbH", "Oasis Silicon Systems", "Renesas Technology", "Raza Microelectronics",
 "Phyworks", "MediaTek", "Non-cents Productions", "US Modular",
 "Wintegra Ltd", "Mathstar", "StarCore", "Oplus Technologies",
 "Mindspeed", "Just Young Computer", "Radia Communications", "OCZ",
 "Emuzed", "LOGIC Devices", "Inphi Corporation", "Quake Technologies",
 "Vixel", "SolusTek", "Kongsberg Maritime", "Faraday Technology",
 "Altium Ltd.", "Insyte", "ARM Ltd.", "DigiVision",
 "Vativ Technologies", "Endicott Interconnect Technologies", "Pericom", "Bandspeed",
 "LeWiz Communications", "CPU Technology", "Ramaxel Technology", "DSP Group",
 "Axis Communications", "Legacy Electronics", "Chrontel", "Powerchip Semiconductor",
 "MobilEye Technologies", "Excel Semiconductor", "A-DATA Technology", "VirtualDigm",
 "G Skill Intl", "Quanta Computer", "Yield Microelectronics", "Afa Technologies",
 "WEI-HEH Electronics", "Ceva", "iStor Networks", "Advance Modules",
 "Microsoft", "Open-Silicon", "Goal Semiconductor", "ARC International",
 "Simmtec", "Metanoia", "Key Stream", "Lowrance Electronics",
 "Adimos", "SiGe Semiconductor", "Fodus Communications", "Credence Systems Corp.",
 "Genesis Microchip Inc.", "Vihana, Inc.", "WIS Technologies", "GateChange Technologies",
 "High Density Devices AS", "Synopsys", "Gigaram", "Enigma Semiconductor Inc.",
 "Century Micro Inc.", "Icera Semiconductor", "Mediaworks Integrated Systems", "O'Neil Product Development",
 "Supreme Top Technology Ltd.", "MicroDisplay Corporation", "Team Group Inc.", "Sinett Corporation",
 "Toshiba Corporation", "Tensilica", "SiRF Technology", "Bacoc Inc.",
 "SMaL Camera Technologies", "Thomson SC", "Airgo Networks", "Wisair Ltd.",
 "SigmaTel", "Arkados", "Compete IT gmbH Co. KG", "Eudar Technology Inc.",
 "Focus Enhancements", "Xyratex"],
["Specular Networks", "PDP Systems", "U-Chip Technology Corp.", "Silicon Optix",
 "Greenfield Networks", "CompuRAM GmbH", "Stargen, Inc.", "NetCell Corporation",
 "Excalibrus Technologies Ltd", "SCM Microsystems", "Xsigo Systems, Inc.", "CHIPS & Systems Inc",
 "Tier 1 Multichip Solutions", "CWRL Labs", "Teradici", "Gigaram, Inc.",
 "g2 Microsystems", "PowerFlash Semiconductor", "P.A. Semi, Inc.", "NovaTech Solutions, S.A.",
 "c2 Microsystems, Inc.", "Level5 Networks", "COS Memory AG", "Innovasic Semiconductor",
 "02IC Co. Ltd", "Tabula, Inc.", "Crucial Technology", "Chelsio Communications",
 "Solarflare Communications", "Xambala Inc.", "EADS Astrium", "ATO Semicon Co. Ltd.",
 "Imaging Works, Inc.", "Astute Networks, Inc.", "Tzero", "Emulex",
 "Power-One", "Pulse~LINK Inc.", "Hon Hai Precision Industry", "White Rock Networks Inc.",
 "Telegent Systems USA, Inc."]);

$use_sysfs = -d '/sys/bus';

sub manufacturer(@)
{
	my @bytes = @_;
	my $ai = 0;
	my $first;
	
	while (defined($first = shift(@bytes)) && $first == 0x7F) {
		$ai++;
	}

	if (defined $first && defined $vendors[$ai][($first & 0x7F) - 1]) {
		return ($vendors[$ai][($first & 0x7F) - 1], \@bytes);
	}

	return ("Unknown", \@bytes);
}

sub manufacturer_data(@)
{
	my $hex = "";
	my $asc = "";
	my $all_0 = 1;

	foreach my $byte (@_) {
		$hex .= sprintf("\%02X ", $byte);
		$asc .= ($byte >= 32 && $byte < 127) ? chr($byte) : '?';
		$all_0 = 0 if $byte != 0 && $byte != 0xff;
	}

	return if $all_0;
	return "$hex(\"$asc\")";
}

sub printl ($$) # print a line w/ label and value
{
   my ($label, $value) = @_;
   if ($opt_html) {
       $label =~ s/</\&lt;/sg;
       $label =~ s/>/\&gt;/sg;
       $label =~ s/\n/<br>\n/sg;
       $value =~ s/</\&lt;/sg;
       $value =~ s/>/\&gt;/sg;
       $value =~ s/\n/<br>\n/sg;
       print "<tr><td valign=top>$label</td><td>$value</td></tr>\n";
   } else {
       $value =~ s%\n%\n\t\t%sg;
       print "$label\t$value\n";
   }
}

sub printl2 ($$) # print a line w/ label and value (outside a table)
{
   my ($label, $value) = @_;
   if ($opt_html) {
       $label =~ s/</\&lt;/sg;
       $label =~ s/>/\&gt;/sg;
       $label =~ s/\n/<br>\n/sg;
       $value =~ s/</\&lt;/sg;
       $value =~ s/>/\&gt;/sg;
       $value =~ s/\n/<br>\n/sg;
       print "$label: $value\n";
   } else {
       $value =~ s%\n%\n\t\t%sg;
       print "$label\t$value\n";
   }
}

sub prints ($) # print seperator w/ given text
{
   my ($label) = @_;
   if ($opt_html) {
       $label =~ s/</\&lt;/sg;
       $label =~ s/>/\&gt;/sg;
       $label =~ s/\n/<br>\n/sg;
       print "<tr><td align=center colspan=2><b>$label</b></td></tr>\n";
   } else {
       print "\n---=== $label ===---\n";
   }
}

sub printh ($) # print header w/ given text
{
   my ($label) = @_;
   if ($opt_html) {
       $label =~ s/</\&lt;/sg;
       $label =~ s/>/\&gt;/sg;
       $label =~ s/\n/<br>\n/sg;
       print "<h1>$label</h1>\n";
   } else {
	print "\n$label\n";
   }
}

sub readspd16 ($$) { # reads 16 bytes from SPD-EEPROM
	my ($offset, $dimm_i) = @_;
	if ($use_sysfs) {
		# Kernel 2.6 with sysfs
		open (HANDLE, "/sys/bus/i2c/drivers/eeprom/$dimm_i/eeprom")
			or die "Cannot open /sys/bus/i2c/drivers/eeprom/$dimm_i/eeprom";
		binmode HANDLE;
		seek (HANDLE, $offset, 0);
		read (HANDLE, my $eeprom, 16);
		close HANDLE;
		my @bytes = ();
		for my $i ( 0 .. 15 ) {
			$_ = ord substr($eeprom, $i, 1);
			push(@bytes, $_);
		}
		return @bytes;
	} else {
		# Kernel 2.4 with procfs
		$offset = sprintf('%02x', $offset);
		$_ = `cat /proc/sys/dev/sensors/$dimm_i/$offset`;
		return split(" ");
	}
}

for (@ARGV) {
    if (/-h/) {
		print "Usage: $0 [-f|-b|-h]\n\n",
			"  -f, --format            print nice html output\n",
			"  -b, --bodyonly          don't print html header\n",
			"                          (useful for postprocessing the output)\n",
			"  -c, --checksum          decode completely even if checksum fails\n",
			"  -h, --help              display this usage summary\n";
		exit;
    }
    $opt_html = 1 if (/-f/);
    $opt_bodyonly = 1 if (/-b/);
    $opt_igncheck = 1 if (/-c/);
}
$opt_body = $opt_html && ! $opt_bodyonly;

if ($opt_body)
{
	print "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n",
	      "<html><head>\n",
		  "\t<meta HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html; charset=iso-8859-1\">\n",
		  "\t<title>PC DIMM Serial Presence Detect Tester/Decoder Output</title>\n",
		  "</head><body>\n";
}

printh '
PC DIMM Serial Presence Detect Tester/Decoder
By Philip Edelbrock, Christian Zuckschwerdt, Burkart Lingner and others
Version 2.9.3
';


my $dimm_count=0;
if ($use_sysfs) { $_=`ls /sys/bus/i2c/drivers/eeprom`; }
else { $_=`ls /proc/sys/dev/sensors/`; }
my @dimm_list=split();

for my $i ( 0 .. $#dimm_list ) {
	$_=$dimm_list[$i];
	if (($use_sysfs && /^\d+-\d+$/)
	 || (!$use_sysfs && /^eeprom-/)) {
		my $dimm_checksum=0;
		$dimm_count += 1;
		
		print "<b><u><br><br>" if $opt_html;
		printl2 "Decoding EEPROM", ($use_sysfs ?
			"/sys/bus/i2c/drivers/eeprom/$dimm_list[$i]" :
			"/proc/sys/dev/sensors/$dimm_list[$i]");
		print "</u></b>" if $opt_html;
		print "<table border=1>\n" if $opt_html;
		if (($use_sysfs && /^[^-]+-([^-]+)$/)
		 || (!$use_sysfs && /^[^-]+-[^-]+-[^-]+-([^-]+)$/)) {
			my $dimm_num=$1 - 49;
			printl "Guessing DIMM is in", "bank $dimm_num";
		}
# Decode first 16 bytes
		prints "The Following is Required Data and is Applicable to all DIMM Types";

		my @bytes = readspd16(0, $dimm_list[$i]);
		for my $j ( 0 .. 15 ) { $dimm_checksum = $dimm_checksum + $bytes[$j];  }
		
		printl "# of bytes written to SDRAM EEPROM",$bytes[0];

		my $l = "Total number of bytes in EEPROM";
		if ($bytes[1] <= 13) {
			printl $l, 2**$bytes[1];
		} elsif ($bytes[1] == 0) {
			printl $l, "RFU"; 
		} else { printl $l, "ERROR!"; }

		$l = "Fundamental Memory type";
		if ($bytes[2] == 2) { printl $l, "EDO"; }
		elsif ($bytes[2] == 4) { printl $l, "SDR SDRAM"; }
		elsif ($bytes[2] == 7) { printl $l, "DDR SDRAM"; }
		elsif ($bytes[2] == 8) { printl $l, "DDR2 SDRAM"; }
		elsif ($bytes[2] == 17) { printl $l, "Rambus [UNSUPPORTED]"; }
		elsif ($bytes[2] == 1) { printl $l, "Direct Rambus [UNSUPPORTED]"; }
		else { printl $l, "???"; }

		$l = "Number of Row Address Bits (SDRAM only)";
		if ($bytes[3] == 0) { printl $l, "Undefined!" } 		
		elsif ($bytes[3] == 1) { printl $l, "1/16" } 		
		elsif ($bytes[3] == 2) { printl $l, "2/17" } 		
		elsif ($bytes[3] == 3) { printl $l, "3/18" }
		else { printl $l, $bytes[3]; }

		$l = "Number of Col Address Bits (SDRAM only)";
		if ($bytes[4] == 0) { printl $l, "Undefined!" } 		
		elsif ($bytes[4] == 1) { printl $l, "1/16" } 		
		elsif ($bytes[4] == 2) { printl $l, "2/17" } 		
		elsif ($bytes[4] == 3) { printl $l, "3/18" }
		else { printl $l, $bytes[4]; }

		$l = "Number of Module Rows";
		if ($bytes[5] == 0 ) { printl $l, "Undefined!"; }
		else { printl $l, $bytes[5]; }

		$l = "Data Width (SDRAM only)";
		if ($bytes[7] > 1) { printl $l, "Undefined!" } else {
			my $temp=($bytes[7]*256) + $bytes[6];
			printl $l, $temp; }

		$l = "Module Interface Signal Levels";
		if ($bytes[8] == 0) { printl $l, "5.0 Volt/TTL";}
		elsif ($bytes[8] == 1) { printl $l, "LVTTL";}
		elsif ($bytes[8] == 2) { printl $l, "HSTL 1.5";}
		elsif ($bytes[8] == 3) { printl $l, "SSTL 3.3";}
		elsif ($bytes[8] == 4) { printl $l, "SSTL 2.5";}
		elsif ($bytes[8] == 255) { printl $l, "New Table";}
		else { printl $l, "Undefined!";}
		
		$l = "Cycle Time (SDRAM) highest CAS latency";
		my $temp=($bytes[9] >> 4) + ($bytes[9] & 0xf) * 0.1;
		printl $l, "${temp}ns";
		
		if (($bytes[2] == 7) || ($bytes[2] == 8)) {
			my $mul = 2;
			my $ddr = "DDR";
			if ($bytes[2] == 8) {
				$mul = 4;
				$ddr = "DDR2";
			} 
			my $ddrclk = $mul * (1000/$temp);
			my $tbits = ($bytes[7]*256) + $bytes[6];
			if (($bytes[11] == 2) ||  ($bytes[11] == 1)) { $tbits = $tbits - 8;}
			my $pcclk = int ($ddrclk * $tbits / 8);
			$pcclk += 100 if ($pcclk % 100) >= 50; # Round properly
			$pcclk = $pcclk - ($pcclk % 100);
			$ddrclk = int ($ddrclk);
			printl "Maximum module speed", "$ddr ${ddrclk}MHz (PC${pcclk})";
		}
	
		$l = "Access Time (SDRAM)";
		$temp=($bytes[10] >> 4) + ($bytes[10] & 0xf) * 0.1;
		printl $l, "${temp}ns";
		
		$l = "Module Configuration Type";
		if ($bytes[11] == 0) { printl $l, "No Parity"; }
		elsif ($bytes[11] == 1) { printl $l, "Parity"; }
		elsif ($bytes[11] == 2) { printl $l, "ECC"; }
		else { printl $l, "Undefined!"; }
			
		$l = "Refresh Type";
		if ($bytes[12] > 126) { printl $l, "Self Refreshing"; }
		else { printl $l, "Not Self Refreshing"; }
		
		$l = "Refresh Rate";
		$temp=$bytes[12] & 0x7f;
		if ($temp == 0) { printl $l, "Normal (15.625uS)"; }
		elsif ($temp == 1) { printl $l, "Reduced (3.9uS)"; }
		elsif ($temp == 2) { printl $l, "Reduced (7.8uS)"; }
		elsif ($temp == 3) { printl $l, "Extended (31.3uS)"; }
		elsif ($temp == 4) { printl $l, "Extended (62.5uS)"; }
		elsif ($temp == 5) { printl $l, "Extended (125uS)"; }
		else { printl $l, "Undefined!";}
		
		$l = "Primary SDRAM Component Bank Config";
		if ($bytes[13]>126) { printl $l, "Bank2 = 2 x Bank1";}
		else { printl $l, "No Bank2 OR Bank2 = Bank1 width";}
		
		$l = "Primary SDRAM Component Widths";
		$temp=$bytes[13] & 0x7f;
		if ($temp == 0) { printl $l, "Undefined!\n"; }
		else { printl $l, $temp; }
		
		$l = "Error Checking SDRAM Component Bank Config";
		if ($bytes[14]>126) { printl $l, "Bank2 = 2 x Bank1";}
		else { printl $l, "No Bank2 OR Bank2 = Bank1 width";}
		
		$l = "Error Checking SDRAM Component Widths";
		$temp=$bytes[14] & 0x7f;
		if ($temp == 0) { printl $l, "Undefined!"; }
		else { printl $l, $temp; }
		
		$l = "Min Clock Delay for Back to Back Random Access";
		if ($bytes[15] == 0) { printl $l, "Undefined!"; }
		else { printl $l, $bytes[15]; }
		
		prints "The Following Apply to SDRAM DIMMs ONLY";
		
# Decode next 16 bytes
		@bytes = readspd16(16, $dimm_list[$i]);
		for my $j ( 0 .. 15 ) { $dimm_checksum = $dimm_checksum + $bytes[$j]; }
		
		$l = "Burst lengths supported";
		$temp="";
		if (($bytes[0] & 1) > 0) { $temp .= "Burst Length = 1\n"; }
		if (($bytes[0] & 2) > 0) { $temp .= "Burst Length = 2\n"; }
		if (($bytes[0] & 4) > 0) { $temp .= "Burst Length = 4\n"; }
		if (($bytes[0] & 8) > 0) { $temp .= "Burst Length = 8\n"; }
		if (($bytes[0] & 16) > 0) { $temp .= "Undefined! (bit 4)\n"; }
		if (($bytes[0] & 32) > 0) { $temp .= "Undefined! (bit 5)\n"; }
		if (($bytes[0] & 64) > 0) { $temp .= "Undefined! (bit 6)\n"; }
		if (($bytes[0] & 128) > 0) { $temp .= "Burst Length = Page\n"; }
		if ($bytes[0] == 0) { $temp .= "(None Supported)\n";}
		printl $l, $temp;
		
		$l = "Number of Device Banks";
		if ($bytes[1] == 0) { printl $l, "Undefined/Reserved!"; }
		else { printl $l, $bytes[1]; }
		
		$l = "Supported CAS Latencies";
		$temp="";
		if (($bytes[2] & 1) > 0) { $temp .= "CAS Latency = 1\n";}
		if (($bytes[2] & 2) > 0) { $temp .= "CAS Latency = 2\n"; }
		if (($bytes[2] & 4) > 0) { $temp .= "CAS Latency = 3\n"; }
		if (($bytes[2] & 8) > 0) { $temp .= "CAS Latency = 4\n"; }
		if (($bytes[2] & 16) > 0) { $temp .= "CAS Latency = 5\n"; }
		if (($bytes[2] & 32) > 0) { $temp .= "CAS Latency = 6\n"; }
		if (($bytes[2] & 64) > 0) { $temp .= "CAS Latency = 7\n"; }
		if (($bytes[2] & 128) > 0) { $temp .= "Undefined (bit 7)\n"; }
		if ($bytes[2] == 0) { $temp .= "(None Supported)\n";}
		printl $l, $temp;
		
		$l = "Supported CS Latencies";
		$temp="";
		if (($bytes[3] & 1) > 0) { $temp .= "CS Latency = 0\n";}
		if (($bytes[3] & 2) > 0) { $temp .= "CS Latency = 1\n"; }
		if (($bytes[3] & 4) > 0) { $temp .= "CS Latency = 2\n"; }
		if (($bytes[3] & 8) > 0) { $temp .= "CS Latency = 3\n"; }
		if (($bytes[3] & 16) > 0) { $temp .= "CS Latency = 4\n"; }
		if (($bytes[3] & 32) > 0) { $temp .= "CS Latency = 5\n"; }
		if (($bytes[3] & 64) > 0) { $temp .= "CS Latency = 6\n"; }
		if (($bytes[3] & 128) > 0) { $temp .= "Undefined (bit 7)\n"; }
		if ($bytes[3] == 0) { $temp .= "(None Supported)\n";}
		printl $l, $temp;
		
		$l = "Supported WE Latencies";
		$temp="";
		if (($bytes[4] & 1) > 0) { $temp .= "WE Latency = 0\n";}
		if (($bytes[4] & 2) > 0) { $temp .= "WE Latency = 1\n"; }
		if (($bytes[4] & 4) > 0) { $temp .= "WE Latency = 2\n"; }
		if (($bytes[4] & 8) > 0) { $temp .= "WE Latency = 3\n"; }
		if (($bytes[4] & 16) > 0) { $temp .= "WE Latency = 4\n"; }
		if (($bytes[4] & 32) > 0) { $temp .= "WE Latency = 5\n"; }
		if (($bytes[4] & 64) > 0) { $temp .= "WE Latency = 6\n"; }
		if (($bytes[4] & 128) > 0) { $temp .= "Undefined (bit 7)\n"; }
		if ($bytes[4] == 0) { $temp .= "(None Supported)\n";}
		printl $l, $temp;
		
		$l = "SDRAM Module Attributes";
		$temp="";
		if (($bytes[5] & 1) > 0) { $temp .= "Buffered Address/Control Inputs\n";}
		if (($bytes[5] & 2) > 0) { $temp .= "Registered Address/Control Inputs\n"; }
		if (($bytes[5] & 4) > 0) { $temp .= "On card PLL (clock)\n"; }
		if (($bytes[5] & 8) > 0) { $temp .= "Buffered DQMB Inputs\n"; }
		if (($bytes[5] & 16) > 0) { $temp .= "Registered DQMB Inputs\n"; }
		if (($bytes[5] & 32) > 0) { $temp .= "Differential Clock Input\n"; }
		if (($bytes[5] & 64) > 0) { $temp .= "Redundant Row Address\n"; }
		if (($bytes[5] & 128) > 0) { $temp .= "Undefined (bit 7)\n"; }
		if ($bytes[5] == 0) { $temp .= "(None Reported)\n";}
		printl $l, $temp;
		
		$l = "SDRAM Device Attributes (General)";
		$temp="";
		if (($bytes[6] & 1) > 0) { $temp .= "Supports Early RAS# Recharge\n";}
		if (($bytes[6] & 2) > 0) { $temp .= "Supports Auto-Precharge\n"; }
		if (($bytes[6] & 4) > 0) { $temp .= "Supports Precharge All\n"; }
		if (($bytes[6] & 8) > 0) { $temp .= "Supports Write1/Read Burst\n"; }
		if (($bytes[6] & 16) > 0) { $temp .= "Lower VCC Tolerance:5%\n"; }
		if (($bytes[6] & 16) == 0) { $temp .= "Lower VCC Tolerance:10%\n"; }
		if (($bytes[6] & 32) > 0) { $temp .= "Upper VCC Tolerance:5%\n"; }
		if (($bytes[6] & 32) == 0) { $temp .= "Upper VCC Tolerance:10%\n"; }
		if (($bytes[6] & 64) > 0) { $temp .= "Undefined (bit 6)\n"; }
		if (($bytes[6] & 128) > 0) { $temp .= "Undefined (bit 7)\n"; }
		printl $l, $temp;
		
		$l = "SDRAM Cycle Time (2nd highest CAS)";
		$temp = $bytes[7] >> 4;
		if ($temp == 0) { printl $l, "Undefined!"; }
		else {
			if ($temp < 4 ) {$temp=$temp + 15;}
			printl $l, $temp + (($bytes[7] & 0xf) * 0.1) . "nS";
		}
		
		$l = "SDRAM Access from Clock Time (2nd highest CAS)";
		$temp = $bytes[8] >> 4;
		if ($temp == 0) { printl $l, "Undefined!"; }
		else {
			if ($temp < 4 ) {$temp=$temp + 15;}
			printl $l, $temp + (($bytes[8] & 0xf) * 0.1) . "nS";
		}
		
		prints "The Following are Optional (may be Bogus)";
		
		$l = "SDRAM Cycle Time (3rd highest CAS)";
		$temp = $bytes[9] >> 2;
		if ($temp == 0) { printl $l, "Undefined!"; }
		else { printl $l, $temp + ($bytes[9] & 0x3) * 0.25 . "nS"; }
		
		$l = "SDRAM Access from Clock Time (3rd highest CAS)";
		$temp = $bytes[10] >> 2;
		if ($temp == 0) { printl $l, "Undefined!"; }
		else { printl $l, $temp + ($bytes[10] & 0x3) * 0.25 . "nS"; }
		
		prints "The Following are Required (for SDRAMs)";
		
		$l = "Minimum Row Precharge Time";
		if ($bytes[11] == 0) { printl $l, "Undefined!"; }
		else { printl $l, "$bytes[11]nS"; }
		
		$l = "Row Active to Row Active Min";
		if ($bytes[12] == 0) { printl $l, "Undefined!"; }
		else { printl $l, "$bytes[12]nS"; }
		
		$l = "RAS to CAS Delay";
		if ($bytes[13] == 0) { printl $l, "Undefined!"; }
		else { printl $l, "$bytes[13]nS"; }
		
		$l = "Min RAS Pulse Width";
		if ($bytes[14] == 0) { printl $l, "Undefined!"; }
		else { printl $l, "$bytes[14]nS"; }
		
		
		prints "The Following are Required and Apply to ALL DIMMs";
		
		$l = "Row Densities";
		$temp="";
		if (($bytes[15] & 1) > 0) { $temp .= "4 MByte\n";}
		if (($bytes[15] & 2) > 0) { $temp .= "8 MByte\n"; }
		if (($bytes[15] & 4) > 0) { $temp .= "16 MByte\n"; }
		if (($bytes[15] & 8) > 0) { $temp .= "32 MByte\n"; }
		if (($bytes[15] & 16) > 0) { $temp .= "64 MByte\n"; }
		if (($bytes[15] & 32) > 0) { $temp .= "128 MByte\n"; }
		if (($bytes[15] & 64) > 0) { $temp .= "256 MByte\n"; }
		if (($bytes[15] & 128) > 0) { $temp .= "512 MByte\n"; }
		if ($bytes[15] == 0) { $temp .= "(Undefined! -- None Reported!)\n";}
		printl $l, $temp;
		
		
# Decode next 16 bytes (32-47)
		@bytes = readspd16(32, $dimm_list[$i]);
		for my $j ( 0 .. 15 ) { $dimm_checksum = $dimm_checksum + $bytes[$j];  }
		
		prints "The Following are Proposed and Apply to SDRAM DIMMs";
		
		$l = "Command and Address Signal Setup Time";
		$temp = (($bytes[0] & 0x7f) >> 4) + ($bytes[0] & 0xf) * 0.1;
		printl $l, ( ($bytes[0] >> 7) ? -$temp : $temp ) . "nS";
		
		$l = "Command and Address Signal Hold Time";
		$temp = (($bytes[1] & 0x7f) >> 4) + ($bytes[1] & 0xf) * 0.1;
		printl $l, ( ($bytes[1] >> 7) ? -$temp : $temp ) . "nS";
		
		$l = "Data Signal Setup Time";
		$temp =(($bytes[2] & 0x7f) >> 4) + ($bytes[2] & 0xf) * 0.1;
		printl $l, ( ($bytes[2] >> 7) ? -$temp : $temp ) . "nS";
		
		$l = "Data Signal Hold Time";
		$temp = (($bytes[3] & 0x7f) >> 4) + ($bytes[3] & 0xf) * 0.1;
		printl $l, ( ($bytes[3] >> 7) ? -$temp : $temp ) . "nS";

# That's it for the lower part of an SDRAM EEPROM's memory!
# Decode next 16 bytes (48-63)
		@bytes = readspd16(48, $dimm_list[$i]);
		for my $j ( 0 .. 14 ) { $dimm_checksum = $dimm_checksum + $bytes[$j];  }

		printl "SPD Revision code ", sprintf("%x", $bytes[14]);
		$l = "EEPROM Checksum of bytes 0-62";
		$dimm_checksum &= 0xff;
		printl $l, ($bytes[15]==$dimm_checksum?
			sprintf("OK (0x%.2X)",$bytes[15]):
			sprintf("Bad (found 0x%.2X, calculated 0x%.2X)\n",$bytes[15],$dimm_checksum));

		if($bytes[15]==$dimm_checksum || $opt_igncheck) {
# Decode next 16 bytes (64-79)
		@bytes = readspd16(64, $dimm_list[$i]);
		
		$l = "Manufacturer";
		# $extra is a reference to an array containing up to
		# 7 extra bytes from the Manufacturer field. Sometimes
		# these bytes are filled with interesting data.
		($temp, my $extra) = manufacturer(@bytes[0..7]);
		printl $l, $temp;
		$l = "Custom Manufacturer Data";
		$temp = manufacturer_data(@{$extra});
		printl $l, $temp if defined $temp;
		
		$l = "Manufacturing Location Code";
		$temp = sprintf("0x%.2X\n",$bytes[8]);
		printl $l, $temp;
		
		$l = "Manufacurer's Part Number";
# Decode next 16 bytes (80-95)
		my @bytes2= readspd16(80, $dimm_list[$i]);

		$temp = pack("C18",$bytes[9],$bytes[10],$bytes[11],$bytes[12],$bytes[13],$bytes[14],$bytes[15],
			$bytes2[0],$bytes2[1],$bytes2[2],$bytes2[3],$bytes2[4],$bytes2[5],$bytes2[6],$bytes2[7],$bytes2[8],$bytes2[9],$bytes2[10]);
		printl $l, $temp;
		
		$l = "Revision Code";
		$temp = sprintf("0x%.2X%.2X\n",$bytes2[11],$bytes2[12]);
		printl $l, $temp;
		
		$l = "Manufacturing Date";
		$temp = sprintf("0x%.2X%.2X\n",$bytes2[13],$bytes2[14]);
		printl $l, $temp;
		
		$l = "Assembly Serial Number";
# Decode next 16 bytes (96-111)
		@bytes = readspd16(96, $dimm_list[$i]);
		
		$temp = sprintf("0x%.2X%.2X%.2X%.2X\n",$bytes2[15],$bytes[0],$bytes[1],$bytes[2]);
# Decode next 16 bytes (112-127)
		@bytes = readspd16(112, $dimm_list[$i]);
		
		$l = "Intel Specification for Frequency";
		if ($bytes[14] == 102) { printl $l, "66MHz\n"; }
		elsif ($bytes[14] == 100) { printl $l, "100MHz\n"; }
		else { printl $l, "Undefined!\n"; }
		
		$l = "Intel Spec Details for 100MHz Support";
		$temp="";
		if (($bytes[15] & 1) > 0) { $temp .= "Intel Concurrent AutoPrecharge\n";}
		if (($bytes[15] & 2) > 0) { $temp .= "CAS Latency = 2\n";}
		if (($bytes[15] & 4) > 0) { $temp .= "CAS Latency = 3\n";}
		if (($bytes[15] & 8) > 0) { $temp .= "Junction Temp A (90 degrees C)\n";}
		if (($bytes[15] & 8) == 0) { $temp .= "Junction Temp B (100 degrees C)\n";}
		if (($bytes[15] & 16) > 0) { $temp .= "CLK 3 Connected\n";}
		if (($bytes[15] & 32) > 0) { $temp .= "CLK 2 Connected\n";}
		if (($bytes[15] & 64) > 0) { $temp .= "CLK 1 Connected\n";}
		if (($bytes[15] & 128) > 0) { $temp .= "CLK 0 Connected\n";}
		if ($bytes[15] > 175) { $temp .= "Double Sided DIMM\n"; }
		else { $temp .= "Single Sided DIMM\n";}
		printl $l, $temp;
		}
		
		print "</table>\n" if $opt_html;
	}
}
print '<br><br>' if $opt_html;
printl2 "Number of SDRAM DIMMs detected and decoded", $dimm_count;

print "</body></html>\n" if $opt_body;
print "\nTry '$0 --format' for html output.\n" unless $opt_html;
