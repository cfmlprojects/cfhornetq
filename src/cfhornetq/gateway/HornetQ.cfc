component {

	thisDir = getDirectoryFromPath(getMetaData(this).path);
  	cl = new LibraryLoader(thisDir & "/../lib/").init();
	jThread = cl.create("java.lang.Thread");
	TransportConfiguration = cl.create("org.hornetq.api.core.TransportConfiguration");
	FileConfiguration = cl.create("org.hornetq.core.config.impl.FileConfiguration");
	NettyAcceptorFactory = cl.create("org.hornetq.core.remoting.impl.netty.NettyAcceptorFactory");
	TransportConstants = cl.create("org.hornetq.core.remoting.impl.netty.TransportConstants");
	HornetQServer = cl.create("org.hornetq.core.server.HornetQServer");
	JMSServerManager = cl.create("org.hornetq.jms.server.JMSServerManager");
	JMSServerManagerImpl = cl.create("org.hornetq.jms.server.impl.JMSServerManagerImpl");
	ConfigurationImpl = cl.create("org.hornetq.core.config.impl.ConfigurationImpl");
	InVMAcceptorFactory = cl.create("org.hornetq.core.remoting.impl.invm.InVMAcceptorFactory");
	InVMConnectorFactory = cl.create("org.hornetq.core.remoting.impl.invm.InVMConnectorFactory");
	ServerLocator = cl.create("org.hornetq.api.core.client.ServerLocator");
	HornetQClient = cl.create("org.hornetq.api.core.client.HornetQClient");
	HornetQServers = cl.create("org.hornetq.core.server.HornetQServers");
	System = cl.create("java.lang.System");
	// temporary hack to simply store cf stuff
	CFOBJECT_PROP = "cf.object.property";

	function init() {
		return this;
	}

	function _stop() {
	    variables.sf.close();
	    variables.hqserver.stop();
	}

	function _start() {
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

	function _createQueue(queueName="queue.exampleQueue") {
		var corehqsession = sf.createSession(false, false, false);
		corehqsession.createQueue(queueName, queueName, true);
		corehqsession.close();
	}

	function _sendMessage(queueName = "queue.exampleQueue", message) {
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

	function _receiveMessage(queueName = "queue.exampleQueue",timeout=1000) {
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

	function _startJMSServer() {

	    var configuration = FileConfiguration.init();

	    configuration.setConfigurationUrl("file:/" & expandPath(".") & "/hornetq-config.xml");
	    configuration.start();

	    // Change acceptor configuration
	    var acceptorParams = cl.create("java.util.HashMap");
	    acceptorParams.put(TransportConstants.PORT_PROP_NAME, "5446");
	    acceptorParams.put(TransportConstants.HOST_PROP_NAME, "0.0.0.0");
	    configuration.getAcceptorConfigurations().clear();
	    configuration.getAcceptorConfigurations().add(TransportConfiguration.init(NettyAcceptorFactory.class.getName(), acceptorParams));


	    // Change connector configuration
	    var connectorParams = cl.create("java.util.HashMap");
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


	/**
	 * Access point for this component.  Used for thread context loader wrapping.
	 **/

	function onMissingMethod(missingMethodName,missingMethodArguments){
		return callMethod("_"&missingMethodName,missingMethodArguments);
	}

	function callMethod(methodName, args) {
		jThread = cl.create("java.lang.Thread");
		cTL = jThread.currentThread().getContextClassLoader();
		//system.out.println(server.coldfusion.productname);
		if(findNoCase("railo",server.coldfusion.productname)) {
			jThread.currentThread().setContextClassLoader(cl.GETLOADER().getURLClassLoader());
		}
//		var tl = cl.create("com.googlecode.transloader.Transloader").DEFAULT;
//		var er = cl.create("org.jivesoftware.util.log.util.CommonsLogFactory");
//		var wee = tl.wrap(er.getClass());

		variables.switchThreadContextClassLoader = cl.getLoader().switchThreadContextClassLoader;
		return switchThreadContextClassLoader(this.runInThreadContext,arguments,cl.getLoader().getURLClassLoader());
    }
	function runInThreadContext(methodName,  args) {
		try{
			var theMethod = this[methodName];
			return theMethod(argumentCollection=args);
		} catch (any e) {
			try{
				stopServer();
			} catch(any err) {}
			jThread.currentThread().setContextClassLoader(cTL);
			throw(e);
		}
		jThread.currentThread().setContextClassLoader(cTL);
	}


}