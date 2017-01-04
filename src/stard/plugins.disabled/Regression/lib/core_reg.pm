
package core_reg;
use strict;
use warnings;

use Starmade::Message;
use Stard::Base;
use Stard::Multiplexer;
use Stard::Plugin;
use Stard::Log;
use Starmade::Regression;

use lib("./lib");
use reg_lib;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(stard_core_reg);

my $stard_home = "../..";

## stard_core_reg
# Run tests against the functions in the stard_core library
# INPUT1: player name
sub stard_core_reg {
	my $player = shift(@_);

	my $test_cmd;
	my $logfile;
	my $argfile;
	my $result;

	if (!starmade_broadcast("###Running Core Tests###")) {
		print "failed to broadcast message :(\n";
		exit 1;
	}

	my @plugins = @{get_active_plugin_list()};
	test_result("stard_core - get_active_plugin_list", $#plugins);


	$result = get_exec_prefix("./files/execs/bash-script");
	test_result("stard_core - get_exec_prefix bash", $result =~/bash$/);
	test_result("stard_core - get_exec_prefix bash exec", -x $result);

	$result = get_exec_prefix("./files/execs/perl-script");
	test_result("stard_core - get_exec_prefix perl", $result =~/perl$/);
	test_result("stard_core - get_exec_prefix perl exec", -x $result);

	$result = get_exec_prefix("./files/execs/python-script");
	test_result("stard_core - get_exec_prefix perl", $result =~/python$/);
	test_result("stard_core - get_exec_prefix perl", -x $result);

	$result = get_exec_prefix("./files/execs/abs-path-script");
	test_result("stard_core - get_exec_prefix abs-path", !$result);


	### plugin_command tests
	$test_cmd = "test";
	$logfile = "$stard_home/log/plugins/Regression-log/cmd-$test_cmd.log";
	$argfile = "./tmp/commands/$test_cmd";
	unlink($argfile);
	unlink($logfile);
	plugin_command($test_cmd, 'arg1', 'arg2', 'arg3');
	sleep 2;
	test_result("stard_core - plugin_command args", ck_file_string($argfile, "$test_cmd 'arg1' 'arg2' 'arg3'\n"));
	test_result("stard_core - plugin_command logs", -e $logfile);


	### plugin_server_event tests
	$test_cmd = "test_event";
	$logfile = "$stard_home/log/plugins/Regression-log/event-$test_cmd.log";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	unlink($logfile);
	plugin_server_event($test_cmd, 'arg1', 'arg2', 'arg3');
	sleep 1;
	test_result("stard_core - plugin_server_event args", ck_file_string($argfile, "$test_cmd 'arg1' 'arg2' 'arg3'\n"));
	test_result("stard_core - plugin_server_event logs", -e $logfile);


	### server_messages tests
	# test overheating entity
	$test_cmd = "entityOverheat";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	ai_messages("[AI] Setting callback Server(0) Ship[TC Cruiser MKI_1470000327736](10) Executing send callback: true");
	server_messages("[SERVER] MAIN CORE STARTED DESTRUCTION: in 900 seconds - started 1470514620375\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'TC Cruiser MKI_1470000327736'\n"));
	
	# test overheating entity
	$test_cmd = "entityOverheat";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	ai_messages("[AI] Setting callback Server(0) Ship[SS Minow](1475) Executing Active (Boolean) [false, true]->[false]; Current: false send callback: true");
	server_messages("[SERVER] MAIN CORE STARTED DESTRUCTION: in 900 seconds - started 1470514620375\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'SS Minow'\n"));
	
	# test player spawning for authenticated player
	$test_cmd = "playerSpawn";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][SPAWN] SPAWNING NEW CHARACTER FOR PlS[Jeryia [Jeryia]*; id(3)(2)f(0)]\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd 1", ck_file_string($argfile, "$test_cmd 'Jeryia' 'Jeryia'\n"));
	
	# test player spawning for non authenticated player
	$test_cmd = "playerSpawn";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][SPAWN] SPAWNING NEW CHARACTER FOR PlS[Jeryia; id(3)(2)f(0)]\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd 2", ck_file_string($argfile, "$test_cmd 'Jeryia'\n"));

	# test player login
	$test_cmd = "playerLogin";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][LOGIN] new client connected. given id: 2: description: Jeryia\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'Jeryia'\n"));

	# test player logout
	$test_cmd = "playerLogout";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][DISCONNECT] Client 'RegisteredClient: Jeryia (5) connected: true' HAS BEEN DISCONNECTED\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'Jeryia'\n"));

	# test player logout alt format
	$test_cmd = "playerLogout";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER] onLoggedOut starting for RegisteredClient: Jeryia (2) [Jeryia]connected: true\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'Jeryia' 'Jeryia'\n"));

	# test player death
	$test_cmd = "playerDeath";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER] character PlayerCharacter[(ENTITY_PLAYERCHARACTER_Jeryia)(486)] has been deleted by Sector[487](8, 8, 8)\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'Jeryia' 'Sector[487](8, 8, 8)'\n"));

	# test player joining a faction
	$test_cmd = "playerFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][ChannelRouter] Faction Changed by PlS[Jeryia ; id(3)(2)f(10041)] to 10041\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'Jeryia' '10041'\n"));

	# test player joining a faction alt format
	$test_cmd = "playerFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][ChannelRouter] Faction Changed by PlS[Jeryia [Jeryia]*; id(3)(2)f(10041)] to 10041\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd 2", ck_file_string($argfile, "$test_cmd 'Jeryia' '10041'\n"));

	# test player joinging a faction that is a negative id
	$test_cmd = "playerFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][ChannelRouter] Faction Changed by PlS[Jeryia2 ; id(2)(1)f(-1)] to -1\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd 3", ck_file_string($argfile, "$test_cmd 'Jeryia2' '-1'\n"));

	# test player leaving a faction
	$test_cmd = "playerUnFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][Faction] Sending removal of member Jeryia from Faction [id=10041, name=Test Faction, description=description goes here, size: 1; FP: 100]\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'Jeryia' '10041'\n"));

	# test player leaving a faction of negative id
	$test_cmd = "playerUnFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][Faction] Sending removal of member Jeryia from Faction [id=-1, name=Test Faction, description=description goes here, size: 1; FP: 100]\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'Jeryia' '-1'\n"));

	# test entity losing faction
	$test_cmd = "entityUnFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER] FACTION BLOCK REMOVED FROM SpaceStation[ENTITY_SPACESTATION_Ares Mining Outpost_1443893697034(310)]; resetting faction !!!!!!!!!!!!!!\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'ENTITY_SPACESTATION_Ares Mining Outpost_1443893697034'\n"));

	# test entity joining faction
	$test_cmd = "entityFaction";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER] received object faction change request 10038 for object SpaceStation[ENTITY_SPACESTATION_Ares Mining Outpost_1443893697034(310)]\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'ENTITY_SPACESTATION_Ares Mining Outpost_1443893697034' '10038'\n"));

	# test deleting an entity
	$test_cmd = "entityDestroyed";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER][SEGMENTCONTROLLER] PERMANENTLY DELETING ENTITY: ENTITY_SPACESTATION_Beta_base_1443297379.ent\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'SPACESTATION_Beta_base_1443297379'\n"));

	# test sector change
	$test_cmd = "sectorChange";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER] PlayerCharacter[(ENTITY_PLAYERCHARACTER_Jeryia)(139)] has players attached. Doing Sector Change for PlS[Jeryia ; id(3)(1)f(10073)]: Sector[5](3, 8, 7) -> Sector[23](3, 8, 6)\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd", ck_file_string($argfile, "$test_cmd 'ENTITY_PLAYERCHARACTER_Jeryia' 'Jeryia' '3 8 7' '3 8 6'\n"));

	# test sector change to negative sectors
	$test_cmd = "sectorChange";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER] PlayerCharacter[(ENTITY_PLAYERCHARACTER_Jeryia)(139)] has players attached. Doing Sector Change for PlS[Jeryia ; id(3)(1)f(10073)]: Sector[5](-3, -8, -7) -> Sector[23](-3, -2, -6)\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd 2", ck_file_string($argfile, "$test_cmd 'ENTITY_PLAYERCHARACTER_Jeryia' 'Jeryia' '-3 -8 -7' '-3 -2 -6'\n"));

	# test sector change for character (instead of ship)
	$test_cmd = "sectorChange";
	$test_cmd = "sectorChange";
	$argfile = "./tmp/serverEvents/$test_cmd";
	unlink($argfile);
	server_messages("[SERVER] Ship[UE Patrol Ship MKIV_1443985052059](299) has CHARACTER. Doing Sector Change for PlayerCharacter[(ENTITY_PLAYERCHARACTER_Jeryia)(272)]: Sector[330](5, 8, 4) -> Sector[344](5, 8, 5) ID 344\n");
	sleep 1;
	test_result("stard_core - server_messages $test_cmd 3", ck_file_string($argfile, "$test_cmd 'UE Patrol Ship MKIV_1443985052059' 'Jeryia' '5 8 4' '5 8 5'\n"));


	### chat_messages tests
	$test_cmd = "test";
	$argfile = "./tmp/commands/$test_cmd";
	unlink($argfile);
	chat_messages("[CHANNELROUTER] RECEIVED MESSAGE ON Server(0): [CHAT][sender=$player][receiverType=CHANNEL][receiver=all][message=!test a1 a2 a3 ' sd']");
	sleep 1;
	test_result("stard_core - chat_messages $test_cmd", ck_file_string($argfile, "$test_cmd '$player' 'a1' 'a2' 'a3' ' sd'\n"));
}
