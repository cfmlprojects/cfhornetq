component name="TestHornetQGateway" extends="mxunit.framework.TestCase" {

	function setUp()  {
		//hqGateway = new cfhornetq.gateway.HornetQGateway();
	}

	function testHornetQ()  {
		hornetq = new cfhornetq.gateway.HornetQ();
		hornetq.start();
		hornetq.createQueue("testQueue");
		hornetq.sendMessage("testQueue",{funk:"weoooho",bort:"yerp"});
		debug(hornetq.receiveMessage("testQueue",1));
		debug(hornetq.receiveMessage("testQueue",1));
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