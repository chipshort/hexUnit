package hex.unittest.notifier;
#if sys
import haxe.Json;
import hex.event.IEvent;
import hex.unittest.event.ITestRunnerListener;
import hex.unittest.event.TestRunnerEvent;
import sys.net.Host;
import sys.net.Socket;

/**
 * ...
 * @author Christoph Otter
 */
class SocketNotifier extends BaseSocketNotifier
{
	static inline var version = "0.1";
	
	var url : String;
	var port : Int;
	var socket : Socket;

	public function new (url : String, port : Int)
	{
		super ();
		this.url = url;
		this.port = port;
		
		socket = new Socket ();
		
		connect ();
	}
	
	function connect () : Void
	{
		socket.connect (new Host (url), port);
		_connected = true;
	}
	
	function close () : Void
	{
		socket.close ();
		_connected = false;
	}
	
	function flush():Void
	{
		var l:UInt = this._cache.length;
		for (i in 0 ... l ) 
		{
			this.socket.output.writeString( this._cache[i] );
		}
		
		this._cache = new Array<String>();
	}
	
	override function sendMessage (messageType : String, data : Dynamic) : Void
	{
		var message = {
			messageId: generateUUID (),
			clientType: "socketTestNotifier",
			clientVersion: SocketNotifier.version,
			clientId: _clientId,
			messageType: messageType,
			data: data
		};
		
		var stringified : String = Json.stringify (message);
		
		if (_connected)
		{
			socket.output.writeString (stringified + "\n");
		}
		else
		{
			_cache.push (stringified);
		}
	}
}
#end