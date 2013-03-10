component output="false" persistent="false" {

	messages = [];

	function init() {
		return this;
	}

	function onMessage(message)  {
		arrayAppend(messages,message);
		createObject("java","java.lang.System").out.println("Message:" & serializeJSON(message));
	}

	function getMessages()  {
		return messages;
	}

}