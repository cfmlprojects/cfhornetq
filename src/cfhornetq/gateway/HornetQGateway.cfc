component {

    variables.state="stopped";

    public void function init(String id, Struct config, Component listener){
    	variables.id=id;
        variables.config=config;
        variables.listener=listener;
        if(!structKeyExists(server,"hornetq")) {
			server.hornetq = new HornetQ();
			server.queue = config.queue;
        }
		server.polltime = structKeyExists(config,"polltime") ? config.polltime : 0;
		variables.polltime = server.polltime;
		variables.queue = server.queue;
		variables.hornetq = server.hornetq;
        writelog(text="HornetQ Gateway [#arguments.id#] initialized", type="information", file="hornetq");
    }

	public void function start() {
		writelog(text = "Starting hornetq queue #variables.config.queue#", type = "information", file = "hornetq");
		sys = createObject("java","java.lang.System");
		try {
			variables.state = "starting";
			hornetq.start();
			writelog(text = "Started hornetq queue #variables.config.queue#", type = "information", file = "hornetq");
			state = "running";
			hornetq.createQueue(queue);
			while (state eq 'running') {
				//request.debug("waiting #variables.polltime#");
				// 0 timeout listens forever, prolly miss shutdown/etc?
				var message = variables.hornetq.receiveMessage(queue,variables.polltime);
				//request.debug("gotmessage:");
				//request.debug(message);
				if(isStruct(message)) {
					//request.debug("fired onmessage!");
					listener.onMessage(message);
				}
				sleep(variables.polltime);
			}
		}
		catch (Any e) {
			variables.state = "failed";
			writelog(text = "#e.message#", type = "fatal", file = "hornetq");
			rethrow;
		}
	}

	public void function stop() {
		writelog(text = "Stopping HornetQ queue #variables.config.queue#", type = "information", file = "hornetq");
		try {
			variables.state = "stopping";
			variables.hornetq.stop();
			structDelete(server,"hornetq");
			variables.state = "stopped";
			writelog(text = "Stopped HornetQ queue #variables.config.queue#", type = "information", file = "hornetq");
		}
		catch (Any e) {
			variables.state = "failed";
			writelog(text = "#e.message#", type = "fatal", file = "hornetq");
			rethrow;
		}
	}

	public void function restart() {
		writelog(text = "Restarting hornetq queue #variables.config.queue#", type = "information", file = "hornetq");
		if (variables.state EQ "running") {
			stop();
		}
		start();
	}

	public any function getHelper(){
	}

	public String function getState(){
	    return variables.state;
	}

	public any function getServer(){
	    return variables.server;
	}

	function sendMessage(message) {
		variables.hornetq.sendMessage(queue,message);
	}

}