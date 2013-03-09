component name="TestHornetQGateway" extends="mxunit.framework.TestCase" {

	function setUp()  {
		//hqGateway = new cfhornetq.gateway.HornetQGateway();
	}

	function testHornetQ()  {
		hornetq = new cfhornetq.gateway.HornetQ();
		hornetq.start();
		hornetq.createQueue("testQueue");

		hornetq.sendMessage("testQueue",{funk:"weoooho",bort:"yerp"});
		var gotMessage = hornetq.receiveMessage("testQueue",1);
		debug(gotMessage);
		assertTrue(structKeyExists(gotMessage,"bort"));
		assertEquals(gotMessage.bort,"yerp");
		assertEquals(gotMessage.funk,"weoooho");

		// this message should be false, as the first was consumed
		gotMessage = hornetq.receiveMessage("testQueue",1);
		debug(gotMessage);
		assertFalse(gotMessage);

		hornetq.sendMessage("testQueue",{woohoo:"yaydoggy!",status:"awesome"});
		var gotMessage = hornetq.receiveMessage("testQueue",1);
		debug(gotMessage);
		assertTrue(structKeyExists(gotMessage,"woohoo"));
		assertEquals(gotMessage.woohoo,"yaydoggy!");
		assertEquals(gotMessage.status,"awesome");

		hornetq.stop();
	}

	function testGateway()  {
		server.hqGateway = new cfhornetq.gateway.HornetQGateway(id="wee",config={queue:"defaultQ"},listener=this);
		thread action="run" name="wee" hqG=server.hqGateway {
			hqG.start();
		}
		server.hqGateway.sendMessage({data:"wee"});
		sleep(2000);
		server.hqGateway.sendMessage({data:"wee"});
		sleep(2000);
		server.hqGateway.sendMessage({data:"wee"});
		sleep(2000);
		server.hqGateway.sendMessage({data:"wee"});
		sleep(2000);
		server.hqGateway.stop();
	}

	function onMessage(message)  {
		createObject("java","java.lang.System").out.println("WHOLY SHIT!:" & serializeJSON(message));
	}

}