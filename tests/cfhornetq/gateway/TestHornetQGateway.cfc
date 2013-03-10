component name="TestHornetQGateway" extends="mxunit.framework.TestCase" {

	function setUp()  {
		//hqGateway = new cfhornetq.gateway.HornetQGateway();
	}

	function testHornetQ()  {
		hornetq = new cfhornetq.gateway.HornetQ();
		hornetq.start();
		try{

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
		} finally {
			hornetq.stop();
		}
	}

	function testGateway_Polling200ms()  {
		var consumer = new Consumer();
		server.hqGateway = new cfhornetq.gateway.HornetQGateway(id="wee",config={queue:"defaultQ"},listener=consumer);
		thread action="run" name="polling" hqG=server.hqGateway {
			hqG.start();
		}
		try{
			sleep(300);
			server.hqGateway.sendMessage({data:"wee1"});
			sleep(300);
			var messages = consumer.getMessages();
			assertEquals(1, arrayLen(messages));
			debug(messages);
			server.hqGateway.sendMessage({data:"wee2"});
			sleep(300);
			server.hqGateway.sendMessage({data:"wee3"});
			debug(consumer.getMessages());
			server.hqGateway.sendMessage({data:"wee4"});
			sleep(300);
			var messages = consumer.getMessages();
			assertEquals(4, arrayLen(messages));
			debug(messages);
		} finally {
			sleep(300);
			server.hqGateway.stop();
		}
	}

	function testGateway_blocking()  {
		var consumer = new Consumer();
		server.hqGateway = new cfhornetq.gateway.HornetQGateway(id="wee",config={queue:"defaultQ"},listener=consumer);
		thread action="run" name="blocking" hqG=server.hqGateway {
			hqG.start();
		}
		try{
			sleep(300);
			debug("Sending message 1");
			server.hqGateway.sendMessage({data:"wee1"});
			sleep(100); // wait a bit for message transport
			debug("Getting message 1");
			var messages = consumer.getMessages();
			debug(messages);
			debug(arrayLen(messages));
			debug("asserting message 1");
			assertEquals(1, arrayLen(messages));
			debug("Sending message 2 and 3");
			server.hqGateway.sendMessage({data:"wee2"});
			server.hqGateway.sendMessage({data:"wee3"});
			debug(consumer.getMessages());
			debug("Sending message 4");
			server.hqGateway.sendMessage({data:"wee4"});
			sleep(100); // still have to wait a tiny bit
			var messages = consumer.getMessages();
			assertEquals(4, arrayLen(messages));
			debug(messages);
		} finally {
			sleep(300);
			server.hqGateway.stop();
		}
	}

}