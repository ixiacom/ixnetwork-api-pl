################################################################################
#                                                                              #
#    Copyright 1997 - 2019 by IXIA  Keysight                                   #
#    All Rights Reserved.                                                      #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
#                                LEGAL  NOTICE:                                #
#                                ==============                                #
# The following code and documentation (hereinafter "the script") is an        #
# example script for demonstration purposes only.                              #
# The script is not a standard commercial product offered by Ixia and have     #
# been developed and is being provided for use only as indicated herein. The   #
# script [and all modifications enhancements and updates thereto (whether      #
# made by Ixia and/or by the user and/or by a third party)] shall at all times #
# remain the property of Ixia.                                                 #
#                                                                              #
# Ixia does not warrant (i) that the functions contained in the script will    #
# meet the users requirements or (ii) that the script will be without          #
# omissions or error-free.                                                     #
# THE SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND AND IXIA         #
# DISCLAIMS ALL WARRANTIES EXPRESS IMPLIED STATUTORY OR OTHERWISE              #
# INCLUDING BUT NOT LIMITED TO ANY WARRANTY OF MERCHANTABILITY AND FITNESS FOR #
# A PARTICULAR PURPOSE OR OF NON-INFRINGEMENT.                                 #
# THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SCRIPT  IS WITH THE #
# USER.                                                                        #
# IN NO EVENT SHALL IXIA BE LIABLE FOR ANY DAMAGES RESULTING FROM OR ARISING   #
# OUT OF THE USE OF OR THE INABILITY TO USE THE SCRIPT OR ANY PART THEREOF     #
# INCLUDING BUT NOT LIMITED TO ANY LOST PROFITS LOST BUSINESS LOST OR          #
# DAMAGED DATA OR SOFTWARE OR ANY INDIRECT INCIDENTAL PUNITIVE OR              #
# CONSEQUENTIAL DAMAGES EVEN IF IXIA HAS BEEN ADVISED OF THE POSSIBILITY OF    #
# SUCH DAMAGES IN ADVANCE.                                                     #
# Ixia will not be required to provide any software maintenance or support     #
# services of any kind (e.g. any error corrections) in connection with the     #
# script or any part thereof. The user acknowledges that although Ixia may     #
# from time to time and in its sole discretion provide maintenance or support  #
# services for the script any such services are subject to the warranty and    #
# damages limitations set forth herein and will not obligate Ixia to provide   #
# any additional maintenance or support services.                              #
#                                                                              #
################################################################################

################################################################################
#                                                                              #
# Description:                                                                 #
#    This script intends to demonstrate how to use NGPF PCEP API.              #
#      1. Configures a PCE on the topology1 and a PCC on topology2. SRv6 PCE   #
#         capability is enabled in PCC and PCE .The PCE has one SRv6           #
#         PCEinitiated LSP with two ERO in it. The PCC has one PreEstablished  #
#		  LSP with one ERO in it.                                              #
#      2. Start PCC and PCE.                                                   #
#      3. Verify statistics from "Protocols Summary" view                      #
#      4. Fetch PCC SRv6 Detailed learned information                          #
#      5. Fetch PCE SRv6 Detailed learned information                          #
#      6. Send PCupdate over PreEstablished LSP(Modify ERO).             	   #
#      7. Send PCupdate over PCEInitiated LSP(Modify ERO).                     #
#      8. Stop all protocols.                                                  # 
################################################################################

################################################################################
# Please ensure that PERL5LIB environment variable is set properly so that 
# IxNetwork.pm module is available. IxNetwork.pm is generally available in
# C:\<IxNetwork Install Path>\API\Perl
################################################################################
use IxNetwork;
use strict;

sub assignPorts {
    my @my_resource = @_;
    my $ixNet    = $my_resource[0];
    my $chassis1 = $my_resource[1];
    my $card1    = $my_resource[2];
    my $port1    = $my_resource[3];
    my $chassis2 = $my_resource[4];
    my $card2    = $my_resource[5];
    my $port2    = $my_resource[6];
    my $vport1   = $my_resource[7];
    my $vport2   = $my_resource[8];
    
    my $root = $ixNet->getRoot();
    my $chassisObj1 = $ixNet->add($root.'/availableHardware', 'chassis');
    $ixNet->setAttribute($chassisObj1, '-hostname', $chassis1);
    $ixNet->commit();
    $chassisObj1 = ($ixNet->remapIds($chassisObj1))[0];
    
    my $chassisObj2 = '';
    if ($chassis1 ne $chassis2) {
        $chassisObj2 = $ixNet->add($root.'/availableHardware', 'chassis');
        $ixNet->setAttribute($chassisObj2, '-hostname', $chassis2);
        $ixNet->commit();
        $chassisObj2 = ($ixNet->remapIds($chassisObj2))[0];
    } else {
        $chassisObj2 = $chassisObj1;
    }
    
    my $cardPortRef1 = $chassisObj1.'/card:'.$card1.'/port:'.$port1;
    $ixNet->setMultiAttribute($vport1, '-connectedTo', $cardPortRef1,
        '-rxMode', 'captureAndMeasure', '-name', 'Ethernet - 001');
    $ixNet->commit();

    my $cardPortRef2 = $chassisObj2.'/card:'.$card2.'/port:'.$port2;
    $ixNet->setMultiAttribute($vport2, '-connectedTo', $cardPortRef2,
        '-rxMode', 'captureAndMeasure', '-name', 'Ethernet - 002');
        
    $ixNet->commit();
}

# Script Starts
print("!!! Test Script Starts !!!\n");

# Edit this variables values to match your setup
my $ixTclServer = '10.39.50.102';
my $ixTclPort   = '5556';
my @ports       = (('10.39.50.96', '10', '17'), ('10.39.50.96', '10', '19'));
# Spawn a new instance of IxNetwork object. 
my $ixNet = new IxNetwork();

print("Connect to IxNetwork Tcl server\n");
$ixNet->connect($ixTclServer, '-port', $ixTclPort, '-version', '8.00', '-setAttribute', 'strict');

print("Creating a new config\n");
$ixNet->execute('newConfig');

print("Adding 2 vports\n");
$ixNet->add($ixNet->getRoot(), 'vport');
$ixNet->add($ixNet->getRoot(), 'vport');
$ixNet->commit();

my @vPorts  = $ixNet->getList($ixNet->getRoot(), 'vport');
my $vportTx = $vPorts[0];
my $vportRx = $vPorts[1];
assignPorts($ixNet, @ports, $vportTx, $vportRx);
sleep(5);

print("Adding 2 topologies\n");
$ixNet->add($ixNet->getRoot(), 'topology', '-vports', $vportTx);
$ixNet->add($ixNet->getRoot(), 'topology', '-vports', $vportRx);
$ixNet->commit();

my @topologies = $ixNet->getList($ixNet->getRoot(), 'topology');
my $topo1 = $topologies[0];
my $topo2 = $topologies[1];

print("Adding 2 device groups\n");
$ixNet->add($topo1, 'deviceGroup');
$ixNet->add($topo2, 'deviceGroup');
$ixNet->commit();

my @t1devices = $ixNet->getList($topo1, 'deviceGroup');
my @t2devices = $ixNet->getList($topo2, 'deviceGroup');

my $t1dev1 = $t1devices[0];
my $t2dev1 = $t2devices[0];

print("Configuring the multipliers (number of sessions)\n");
$ixNet->setAttribute($t1dev1, '-multiplier', '1');
$ixNet->setAttribute($t2dev1, '-multiplier', '1');
$ixNet->commit();

print("Adding ethernet/mac endpoints\n");
$ixNet->add($t1dev1, 'ethernet');
$ixNet->add($t2dev1, 'ethernet');
$ixNet->commit();

my $mac1 = ($ixNet->getList($t1dev1, 'ethernet'))[0];
my $mac2 = ($ixNet->getList($t2dev1, 'ethernet'))[0];

print("Configuring the mac addresses\n");
$ixNet->setMultiAttribute($ixNet->getAttribute($mac1, '-mac').'/counter',
        '-direction', 'increment',
        '-start',     '18:03:73:C7:6C:B1',
        '-step',      '00:00:00:00:00:01');

$ixNet->setAttribute($ixNet->getAttribute($mac2, '-mac').'/singleValue',
        '-value', '18:03:73:C7:6C:01');
$ixNet->commit();

print("Add ipv4\n");
$ixNet->add($mac1, 'ipv4');
$ixNet->add($mac2, 'ipv4');
$ixNet->commit();

my $ip1 = ($ixNet->getList($mac1, 'ipv4'))[0];
my $ip2 = ($ixNet->getList($mac2, 'ipv4'))[0];

my $mvAdd1 = $ixNet->getAttribute($ip1, '-address');
my $mvAdd2 = $ixNet->getAttribute($ip2, '-address');
my $mvGw1  = $ixNet->getAttribute($ip1, '-gatewayIp');
my $mvGw2  = $ixNet->getAttribute($ip2, '-gatewayIp');

print("configuring ipv4 addresses\n");
$ixNet->setAttribute($mvAdd1.'/singleValue', '-value', '20.20.20.2');
$ixNet->setAttribute($mvAdd2.'/singleValue', '-value', '20.20.20.1');
$ixNet->setAttribute($mvGw1.'/singleValue', '-value', '20.20.20.1');
$ixNet->setAttribute($mvGw2.'/singleValue', '-value', "20.20.20.2");

$ixNet->setAttribute($ixNet->getAttribute($ip1, '-prefix').'/singleValue', '-value', '24');
$ixNet->setAttribute($ixNet->getAttribute($ip2, '-prefix').'/singleValue', '-value', '24');

$ixNet->setMultiAttribute($ixNet->getAttribute($ip1, '-resolveGateway').'/singleValue', '-value', 'true');
$ixNet->setMultiAttribute($ixNet->getAttribute($ip2, '-resolveGateway').'/singleValue', '-value', 'true');
$ixNet->commit();

print("Adding a PCE on Topology 1\n");
$ixNet->add($ip1, 'pce');
$ixNet->commit();
my $pce = ($ixNet->getList($ip1, 'pce'))[0];

print("Adding a PCC group on the top of PCE\n");
$ixNet->add($pce, 'pccGroup');
$ixNet->commit();
my $pccGroup = ($ixNet->getList($pce, 'pccGroup'))[0];

# Adding PCC with preEstablishedSrLspsPerPcc 1
print("Adding a PCC object on the Topology 2\n");
$ixNet->add($ip2, 'pcc');
$ixNet->commit();
my $pcc = ($ixNet->getList($ip2, 'pcc'))[0];

# Set preEstablishedSrLspsPerPcc in pcc
$ixNet->setMultiAttribute($pcc, '-preEstablishedSrLspsPerPcc',  '1');
$ixNet->commit();

# Set pcc group multiplier to 1
$ixNet->setAttribute($pccGroup, '-multiplier',  '1');
$ixNet->commit();

# Set pcc multiplier to 1
$ixNet->setAttribute($pcc, '-multiplier',  '1');
$ixNet->commit();

# Set PCC group's  "PCC IPv4 Address" field  to 20.20.20.1
my $pccIpv4AddressMv = $ixNet->getAttribute($pccGroup, '-pccIpv4Address');
$ixNet->setAttribute($pccIpv4AddressMv.'/singleValue', '-value',  '20.20.20.1');
$ixNet->commit();

################################################################################
#Set SRv6 PCE capability in PCC and PCE                                        # 
# 1. SRv6 PCE capability                                                       #
# 2. Max Segments Left                                                         #
################################################################################
# set SRv6 capability in PCC
my $srv6pcccapabilityMv = $ixNet->getAttribute($pcc, '-srv6PceCapability');
$ixNet->setAttribute($srv6pcccapabilityMv.'/singleValue', '-value',  'True');
$ixNet->commit();

#set max segment left
my $srv6maxslMv = $ixNet->getAttribute($pcc, '-srv6MaxSL');
$ixNet->setAttribute($srv6maxslMv.'/singleValue', '-value',  '5');
$ixNet->commit();

#Set SRv6 capability in PCE
my $srv6pcecapabilityMv = $ixNet->getAttribute($pccGroup, '-srv6PceCapability');
$ixNet->setAttribute($srv6pcecapabilityMv.'/singleValue', '-value',  'True');
$ixNet->commit();

################################################################################
# Adding Pre-Established SR LSPs                                               #
# Configured parameters :                                                      #
#    -initialDelegation                                                        #
#    -includeBandwidth                                                         #
#	 -includeLspa                                                              #
#    -includeMetric                                                            #
################################################################################
my $preEstablishedSRLsps = $pcc.'/preEstablishedSrLsps:1';
my $initialDelegation = $ixNet->getAttribute($preEstablishedSRLsps, '-initialDelegation');
$ixNet->add($initialDelegation, 'singleValue');
$ixNet->setMultiAttribute($initialDelegation.'/singleValue',
            '-value', 'true');
$ixNet->commit();
my $includeBandwidth = $ixNet->getAttribute($preEstablishedSRLsps, '-includeBandwidth');
$ixNet->add($includeBandwidth, 'singleValue');
$ixNet->setMultiAttribute($includeBandwidth.'/singleValue',
            '-value', 'true');
$ixNet->commit();
my $includeLspa = $ixNet->getAttribute($preEstablishedSRLsps, '-includeLspa');
$ixNet->add($includeLspa, 'singleValue');
$ixNet->setMultiAttribute($includeLspa.'/singleValue',
            '-value', 'true');
$ixNet->commit();
my $includeMetricMv = $ixNet->getAttribute($preEstablishedSRLsps, '-includeMetric');
$ixNet->add($includeMetricMv, 'singleValue');
$ixNet->setMultiAttribute($includeMetricMv.'/singleValue',
            '-value', 'true');
$ixNet->commit();

################################################################################
# Set the properties SRv6 ERO in PreEstablished LSP                            #
# a. Active                                                                    # 
# b. SRv6 NAI Type                                                             #
# c. F bit                                                                     #
# d. SRv6 Identifier                                                           #
# e. SRv6 Function Code                                                        #
# f. Local IPv6 Address                                                        #
# g. Remote IPv6 Address                                                       #
################################################################################
my $ero1ActiveMv = $ixNet->getAttribute($pcc.'/preEstablishedSrLsps/pcepEroSubObjectsList:1', '-active');
$ixNet->setAttribute($ero1ActiveMv.'/singleValue', '-value', 'True');

my $ero1NaiTypeMv = $ixNet->getAttribute($pcc.'/preEstablishedSrLsps/pcepEroSubObjectsList:1', '-srv6NaiType');
$ixNet->setAttribute($ero1NaiTypeMv.'/singleValue', '-value', 'ipv6adjacency');

my $ero1FbitMv = $ixNet->getAttribute($pcc.'/preEstablishedSrLsps/pcepEroSubObjectsList:1', '-fBit');
$ixNet->setAttribute($ero1FbitMv.'/singleValue', '-value', 'False');

my $ero1SRv6IdentifierMv = $ixNet->getAttribute($pcc.'/preEstablishedSrLsps/pcepEroSubObjectsList:1', '-srv6Identifier');
$ixNet->setAttribute($ero1SRv6IdentifierMv.'/singleValue', '-value', '2122::1');

my $ero1SRv6FunCodeMv = $ixNet->getAttribute($pcc.'/preEstablishedSrLsps/pcepEroSubObjectsList:1', '-srv6FunctionCode');
$ixNet->setAttribute($ero1SRv6FunCodeMv.'/singleValue', '-value', 'endfunction');

my $localIPv6AddressMv = $ixNet->getAttribute($pcc.'/preEstablishedSrLsps/pcepEroSubObjectsList:1', '-localIpv6Address');
$ixNet->setAttribute($localIPv6AddressMv.'/singleValue', '-value', '2122::2');

my $remoteIPv6AddressMv = $ixNet->getAttribute($pcc.'/preEstablishedSrLsps/pcepEroSubObjectsList:1', '-remoteIpv6Address');
$ixNet->setAttribute($remoteIPv6AddressMv.'/singleValue', '-value', '2122::3');

$ixNet->commit();

################################################################################
#Set  pceInitiateLSPParameters                                                 # 
#Path Setup Type -- SRv6                                                       #
################################################################################
my $pathsetuptype = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-pathSetupType');
$ixNet->setAttribute($pathsetuptype.'/singleValue', '-value', 'srv6');

$ixNet->commit();

################################################################################
# Set  pceInitiateLSPParameters                                                #
# 1. IP version                -- ipv6                                         #
# 2. IPv6 source endpoint      -- 2244::101                                    #
# 3. IPv6 destination endpoint -- 2344::101                                    #
################################################################################
#Configuring PCE Initiated LSP parameters
my $ipVerisionMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-ipVersion');
$ixNet->setAttribute($ipVerisionMv.'/singleValue', '-value', 'ipv6');
$ixNet->commit();

my $Ipv4SrcEndpointsMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-srcEndPointIpv6');
$ixNet->setAttribute($Ipv4SrcEndpointsMv.'/singleValue', '-value', '2244::101');

my $Ipv4DestEndpointsMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-destEndPointIpv6');
$ixNet->setAttribute($Ipv4DestEndpointsMv.'/singleValue', '-value', '2344::101');
$ixNet->commit();

################################################################################
# Set  pceInitiateLSPParameters                                                #
# a. Include srp,lsp                                                           #
# b. Include symbolic pathname TLV                                             #
# c. Symbolic path name                                                        #
# d. Include Association                                                       #
################################################################################

# Include srp
my $includeSrpMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-includeSrp');
$ixNet->setAttribute($includeSrpMv.'/singleValue',  '-value',  'True');
$ixNet->commit();

# Include lsp
my $includeLspMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-includeLsp');
$ixNet->setAttribute($includeLspMv.'/singleValue',  '-value',  'True');
$ixNet->commit();

my $includeSymbolicPathMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-includeSymbolicPathNameTlv');
$ixNet->setAttribute($includeSymbolicPathMv.'/singleValue',  '-value',  'True');
$ixNet->commit();    
    
my $symbolicPathNameMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-symbolicPathName');
$ixNet->setAttribute($symbolicPathNameMv.'/singleValue',  '-value', 'IXIA_SAMPLE_LSP_1');
$ixNet->commit();

my $includeAssociationMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters', '-includeAssociation');
$ixNet->setAttribute($includeAssociationMv.'/singleValue',  '-value', 'True');
$ixNet->commit();

# Add 2 EROs
$ixNet->setMultiAttribute($pccGroup.'/pceInitiateLSPParameters', '-numberOfEroSubObjects', '2');
$ixNet->commit();

################################################################################
# Set the properties of ERO1                                                   #
# a. Active                                                                    # 
# b. SRv6 NAI Type                                                             #
# c. SRv6 Node ID                                                              #
# d. F bit                                                                     #
# e. SRv6 Identifier                                                           #
# f. SRv6 Function Code                                                        #
################################################################################
my $ero1ActiveMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:1', '-active');
$ixNet->setAttribute($ero1ActiveMv.'/singleValue', '-value', 'True');

my $ero1NaiTypeMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:1', '-srv6NaiType');
$ixNet->setAttribute($ero1NaiTypeMv.'/singleValue', '-value',  'ipv6nodeid');

my $ero1IPv6NodeidMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:1', '-ipv6NodeId');
$ixNet->setAttribute($ero1IPv6NodeidMv.'/singleValue', '-value', '5556::1');

my $ero1FbitMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:1', '-fBit');
$ixNet->setAttribute($ero1FbitMv.'/singleValue', '-value',  'False'); 

my $ero1SRv6IdentifierMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:1', '-srv6Identifier');
$ixNet->setAttribute($ero1SRv6IdentifierMv.'/singleValue', '-value', '4445::1');

my $ero1SRv6FunCodeMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:1', '-srv6FunctionCode');
$ixNet->setAttribute($ero1SRv6FunCodeMv.'/singleValue', '-value', 'endfunction');
$ixNet->commit();

################################################################################
# Set the properties of ERO2                                                   #
# a. Active                                                                    # 
# b. SRv6 NAI Type                                                             #
# c. F bit                                                                     #
# d. SRv6 Identifier                                                           #
# e. SRv6 Function Code                                                        #
################################################################################
my $ero2ActiveMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:2', '-active');
$ixNet->setAttribute($ero2ActiveMv.'/singleValue', '-value', 'True');

my $ero2NaiTypeMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:2', '-srv6NaiType');
$ixNet->setAttribute($ero2NaiTypeMv.'/singleValue', '-value',  'notapplicable');

my $ero2FbitMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:2', '-fBit');
$ixNet->setAttribute($ero2FbitMv.'/singleValue', '-value',  'False'); 

my $ero2SRv6IdentifierMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:2', '-srv6Identifier');
$ixNet->setAttribute($ero2SRv6IdentifierMv.'/singleValue', '-value', '4446::1');

my $ero2SRv6FunCodeMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:2', '-srv6FunctionCode');
$ixNet->setAttribute($ero2SRv6FunCodeMv.'/singleValue', '-value', 'enddx6function');
$ixNet->commit();

# Set PCC's  "PCE IPv4 Address" field  to 20.20.20.2
my $pceIpv4AddressMv = $ixNet->getAttribute($pcc, '-pceIpv4Address');
$ixNet->setAttribute($pceIpv4AddressMv.'/singleValue', '-value', '20.20.20.2');
$ixNet->commit();

################################################################################
# 2.Start PCEP protocol and wait for 60 seconds                                #
################################################################################
print("Starting protocols and waiting for 60 seconds for protocols to come up\n");
$ixNet->execute('startAllProtocols');
sleep(60);

################################################################################
# 3. Retrieve protocol statistics.                                             #
################################################################################
print("Fetching all Protocol Summary Stats\n");
my $viewPage = '::ixNet::OBJ-/statistics/view:"Protocols Summary"/page';
my @statcap  = $ixNet->getAttribute($viewPage, '-columnCaptions');
my @rowvals  = $ixNet->getAttribute($viewPage, '-rowValues');
my $index    = 0;
my $statValueList= '';
foreach $statValueList (@rowvals) {
    print("***************************************************\n");
    my $statVal = '';
    foreach $statVal (@$statValueList) {
        my $statIndiv = ''; 
        $index = 0;
        foreach $statIndiv (@$statVal) {
            printf(" %-30s:%s\n", $statcap[$index], $statIndiv);
            $index++;
        }
    }    
}
print("***************************************************\n");

################################################################################
# 4. Retrieve PCC SRv6 detailed learned info                                   #
################################################################################
print("Fetching PCC SRv6 detailed Learned Info\n");
$ixNet->execute('getPccSrv6LearnedInfo', $pcc, '1');
sleep(5);
my $linfo  = ($ixNet->getList($pcc, 'learnedInfo'))[0];
my @values = $ixNet->getAttribute($linfo, '-values');
my $v      = '';
print("********PCC SRv6 detailed Learned Info****************\n");
foreach $v (@values) {
    my $w = '0';
    foreach $w (@$v) {
        printf("%10s", $w);
    }
    print("\n");
}
print("***************************************************\n");

################################################################################
# 5. Retrieve PCE SRv6 detailed learned info                                   #
################################################################################
print("Fetching PCE SRv6 detailed Learned Info\n");
$ixNet->execute('getPceDetailedAllSrv6LspLearnedInfo', $pccGroup, '1');
sleep(5);
my $linfo  = ($ixNet->getList($pccGroup, 'learnedInfo'))[0];
my @values = $ixNet->getAttribute($linfo, '-values');
my $v      = '';
print("******PCE SRv6 detailed Learned Info***********\n");
foreach $v (@values) {
    my $w = '0';
    foreach $w (@$v) {
        printf("%10s", $w);
    }
    print("\n");
}
print("***************************************************\n");

################################################################################
# 6. Change SRv6 Identifier ERO1 of PCinitiated LSP                            #
################################################################################
my $ero1SRv6IdentifierMv = $ixNet->getAttribute($pccGroup.'/pceInitiateLSPParameters/pcepEroSubObjectsList:1', '-srv6Identifier');
$ixNet->setAttribute($ero1SRv6IdentifierMv.'/singleValue', '-value', 'abcd::1');
$ixNet->commit();

my $globals   = ($ixNet->getRoot()).'/globals';
my $topology  = $globals.'/topology';
print("Applying changes on the fly\n");
$ixNet->execute('applyOnTheFly', $topology);
sleep(5);
#---------------------------------------------------------------------------
# Setting the TCL APIs for getting PCUpdate Triggers
#---------------------------------------------------------------------------  
my @learnedInfoUpdate = $ixNet->getList($pccGroup, 'learnedInfoUpdate');
my $learnedInfoUpdate1 = $learnedInfoUpdate[0];

my $trigger1 = $learnedInfoUpdate1.'/pceDetailedSrv6SyncLspUpdateParams:1';
#################################################################################
# 7. Change ERO1 srv6Identifier over Pre - Established SR LSPs.                 #
#################################################################################
my $ero = $ixNet->getAttribute($trigger1, '-configureEro');
$ixNet->add($ero, 'singleValue');
$ixNet->setMultiAttribute($ero.'/singleValue', '-value', 'modify');
$ixNet->commit();
time.sleep(2);

my $ero1  = ($ixNet->getList($trigger1, 'pceUpdateSrv6EroSubObjectList'))[0];
my $ero1SRv6IdentifierMv = $ixNet->getAttribute($ero1, '-srv6Identifier');
$ixNet->setMultiAttribute($ero1SRv6IdentifierMv.'/singleValue', '-value', 'abcd::2');
$ixNet->commit();
time.sleep(2);

#print("Send PCUpdate from Learned Info from PCE side");
$ixNet->execute('sendPcUpdate', $trigger1, '2');
time.sleep(2);
################################################################################
# 8. Stop all protocols                                                        #
################################################################################
print("Stopping All Protocols\n");
$ixNet->execute('stopAllProtocols');
print("!!! Test Script Ends !!!");
