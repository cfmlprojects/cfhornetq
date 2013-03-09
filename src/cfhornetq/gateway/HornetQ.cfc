component {

	TransportConfiguration = createObject("java","org.hornetq.api.core.TransportConfiguration");
	FileConfiguration = createObject("java","org.hornetq.core.config.impl.FileConfiguration");
	NettyAcceptorFactory = createObject("java","org.hornetq.core.remoting.impl.netty.NettyAcceptorFactory");
	TransportConstants = createObject("java","org.hornetq.core.remoting.impl.netty.TransportConstants");
	HornetQServer = createObject("java","org.hornetq.core.server.HornetQServer");
	JMSServerManager = createObject("java","org.hornetq.jms.server.JMSServerManager");
	JMSServerManagerImpl = createObject("java","org.hornetq.jms.server.impl.JMSServerManagerImpl");
	ConfigurationImpl = createObject("java","org.hornetq.core.config.impl.ConfigurationImpl");
	InVMAcceptorFactory = createObject("java","org.hornetq.core.remoting.impl.invm.InVMAcceptorFactory");
	InVMConnectorFactory = createObject("java","org.hornetq.core.remoting.impl.invm.InVMConnectorFactory");
	ServerLocator = createObject("java","org.hornetq.api.core.client.ServerLocator");
	HornetQClient = createObject("java","org.hornetq.api.core.client.HornetQClient");
	HornetQServers = createObject("java","org.hornetq.core.server.HornetQServers");
	System = createObject("java","java.lang.System");
	// temporary hack to simply store cf stuff
	CFOBJECT_PROP = "cf.object.property";

	function init() {
		return this;
	}

	function stop() {
	    variables.sf.close();
	    variables.hqserver.stop();
	}

	function start() {
		if(!structKeyExists(server,"__hornetq_server") || !server["__hornetq_server"].isStarted()) {
			var configuration = ConfigurationImpl.init();
			configuration.setPersistenceEnabled(false);
			configuration.setSecurityEnabled(false);
			configuration.getAcceptorConfigurations().add(TransportConfiguration.init(InVMAcceptorFactory.class.getName()));
			server["__hornetq_server"] = HornetQServers.newHornetQServer(configuration);
			server["__hornetq_server"].start();
		}
		variables.hqserver = server["__hornetq_server"];
		var serverLocator = HornetQClient.createServerLocatorWithoutHA([TransportConfiguration.init(InVMConnectorFactory.class.getName())]);
		variables.sf = serverLocator.createSessionFactory();
	}

	function createQueue(queueName="queue.exampleQueue") {
		var corehqsession = sf.createSession(false, false, false);
		corehqsession.createQueue(queueName, queueName, true);
		corehqsession.close();
	}

	function sendMessage(queueName = "queue.exampleQueue", message) {
		var hqsession = "";
		try {
			hqsession = sf.createSession();
			var producer = hqsession.createProducer(queueName);
			var hqmessage = hqsession.createMessage(false);
			hqmessage.putObjectProperty(CFOBJECT_PROP, serialize(message));
			producer.send(hqmessage);
			hqsession.close();
			return true;
		}
		catch (any e) {
			return false;
			e.printStackTrace();
		}
	}

	function receiveMessage(queueName = "queue.exampleQueue",timeout=1000) {
		var hqsession = "";
		try {
			var hqsession = sf.createSession();
			var messageConsumer = hqsession.createConsumer(queueName);
			var messageReceived = "";
			hqsession.start();
			if(timeout > 0) {
				messageReceived = messageConsumer.receive(timeout);
			} else {
				messageReceived = messageConsumer.receive();
			}
			if(!isNull(messageReceived)) {
				var cfObject = evaluate(messageReceived.getObjectProperty(CFOBJECT_PROP).toString());
				messageReceived.acknowledge();
				hqsession.close();
				return cfObject;
			} else {
				hqsession.close();
				return false;
			}
		}
		catch (any e) {
			try{ hqsession.close(); } catch(any e) {};
			e.printStackTrace();
		}
	}

	function startJMSServer() {

	    var configuration = FileConfiguration.init();

	    configuration.setConfigurationUrl("file:/" & expandPath(".") & "/hornetq-config.xml");
	    configuration.start();

	    // Change acceptor configuration
	    var acceptorParams = createObject("java","java.util.HashMap");
	    acceptorParams.put(TransportConstants.PORT_PROP_NAME, "5446");
	    acceptorParams.put(TransportConstants.HOST_PROP_NAME, "0.0.0.0");
	    configuration.getAcceptorConfigurations().clear();
	    configuration.getAcceptorConfigurations().add(TransportConfiguration.init(NettyAcceptorFactory.class.getName(), acceptorParams));


	    // Change connector configuration
	    var connectorParams = createObject("java","java.util.HashMap");
	    connectorParams.put(TransportConstants.PORT_PROP_NAME, "5446");
	    connectorParams.put(TransportConstants.HOST_PROP_NAME, "0.0.0.0");
	    configuration.getConnectorConfigurations().clear();
	    configuration.getConnectorConfigurations().put("netty", TransportConfiguration.init(NettyAcceptorFactory.class.getName(), connectorParams));

	    // Create HornetQ server
	    var hqserver = HornetQServers.newHornetQServer(configuration);
	    hqserver.getSecurityManager().addUser("guest", "guest");
	    hqserver.getSecurityManager().setDefaultUser("guest");
	    hqserver.getSecurityManager().addRole("guest", "guest");


	    // Load queues
	    jmsServerManager = JMSServerManagerImpl.init(hqserver, "hornetq-jms.xml");
	    jmsServerManager.setContext(javaCast("null",""));
	    // Start server
	    jmsServerManager.start();
	    jmsServerManager.stop();
	}

}