package cfhornetq;

import java.util.HashMap;
import java.util.Map;

import org.hornetq.api.core.TransportConfiguration;
import org.hornetq.core.config.impl.FileConfiguration;
import org.hornetq.core.remoting.impl.netty.NettyAcceptorFactory;
import org.hornetq.core.remoting.impl.netty.TransportConstants;
import org.hornetq.core.server.HornetQServer;
import org.hornetq.core.server.HornetQServers;
import org.hornetq.jms.server.JMSServerManager;
import org.hornetq.jms.server.impl.JMSServerManagerImpl;

public class HornetQEmbedded  {

    private JMSServerManager jmsServerManager;

    public HornetQEmbedded() {
    }


    public void start() {
        try {
            System.out.println("Starting Embedded HornetQ instance...");

            // Retrieve configuration from xml file
            FileConfiguration configuration = new FileConfiguration();
            configuration.setConfigurationUrl("hornetq-config.xml");
            configuration.start();

            // Change acceptor configuration
            Map<String, Object> acceptorParams = new HashMap<String, Object>();
            acceptorParams.put(TransportConstants.PORT_PROP_NAME, "5446");
            acceptorParams.put(TransportConstants.HOST_PROP_NAME, "0.0.0.0");
            configuration.getAcceptorConfigurations().clear();
            configuration.getAcceptorConfigurations().add(new   TransportConfiguration(NettyAcceptorFactory.class.getName(), acceptorParams));


            // Change connector configuration
            Map<String, Object> connectorParams = new HashMap<String, Object>();
            connectorParams.put(TransportConstants.PORT_PROP_NAME, "5446");
            connectorParams.put(TransportConstants.HOST_PROP_NAME, "0.0.0.0");
            configuration.getConnectorConfigurations().clear();
            configuration.getConnectorConfigurations().put("netty", new TransportConfiguration(NettyAcceptorFactory.class.getName(), connectorParams));

            // Create HornetQ server
            HornetQServer server = HornetQServers.newHornetQServer(configuration);
            server.getSecurityManager().addUser("guest", "guest");
            server.getSecurityManager().setDefaultUser("guest");
            server.getSecurityManager().addRole("guest", "guest");


            // Load queues
            jmsServerManager = new JMSServerManagerImpl(server, "hornetq-jms.xml");
            jmsServerManager.setContext(null);               

            // Start server
            jmsServerManager.start();

            System.out.println("Waiting 5 second for embedded hornetq server to start...");
            Thread.sleep(5000);           

        } catch (Exception e) {
            System.out.println("Error starting Embedded HornetQ server: " + e.toString());           
            throw new RuntimeException(e);
        }
    }       
}