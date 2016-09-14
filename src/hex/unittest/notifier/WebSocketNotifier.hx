package hex.unittest.notifier;
#if js
import haxe.Json;
import hex.event.IEvent;
import hex.event.LightweightClosureDispatcher;
import hex.unittest.assertion.Assert;
import hex.unittest.description.TestMethodDescriptor;
import hex.unittest.event.ITestRunnerListener;
import hex.unittest.event.TestRunnerEvent;
import js.html.CloseEvent;
import js.html.Event;
import js.html.WebSocket;

/**
 * ...
 * @author ...
 */
class WebSocketNotifier extends BaseSocketNotifier
{
	static public inline var version:String = "0.1.1";
	
	var _url:String;
	var _webSocket:WebSocket;
	
	var _dispatcher:LightweightClosureDispatcher<WebSocketNotifierEvent>;

	public function new(url:String) 
	{
		super();
		this._url = url;
		
		this._dispatcher = new LightweightClosureDispatcher<WebSocketNotifierEvent>();
		this._connect( );
	}
	
	public function addEventListener( eventType:String, callback:WebSocketNotifierEvent->Void ):Void
	{
		this._dispatcher.addEventListener( eventType, callback );
	}
	
	function _connect():Void
	{
		trace("WebSocketServiceJS._connect", this._url);
		this._webSocket = new WebSocket(this._url);
		this._addWebSocketListeners( this._webSocket );
	}
	
	function _close():Void
	{
		this._webSocket.close(0,"testOver");
		this._removeWebSocketListeners(this._webSocket);
	}
	
	function _addWebSocketListeners( webSocket:WebSocket ):Void
	{
		webSocket.addEventListener( "open", this.onOpen );
		webSocket.addEventListener( "close", this.onClose );
		webSocket.addEventListener( "error", this.onError );
		webSocket.addEventListener( "message", this.onMessage );
	}
	
	function _removeWebSocketListeners( webSocket:WebSocket ):Void
	{
		webSocket.removeEventListener( "open", this.onOpen );
		webSocket.removeEventListener( "close", this.onClose );
		webSocket.removeEventListener( "error", this.onError );
		webSocket.removeEventListener( "message", this.onMessage );
	}
	
	function onOpen(e:Event):Void 
	{
		trace("WebSocketServiceJS.onOpen");
		
		this._dispatcher.dispatchEvent(new WebSocketNotifierEvent(WebSocketNotifierEvent.CONNECTED, this));
		this._connected = true;
		
		this.flush( );
	}
	
	function flush():Void
	{
		var l:UInt = this._cache.length;
		for (i in 0 ... l ) 
		{
			this._webSocket.send( this._cache[i] );
		}
		
		this._cache = new Array<String>();
	}
	
	function onClose(e:CloseEvent):Void 
	{
		trace("WebSocketNotifier.onClose", e.reason, e.code);
		this._connected = false;
	}
	
	function onError(e:Event):Void 
	{
		trace("WebSocketNotifier.onError", e);
	}
	
	function onMessage(e:Event):Void 
	{
		trace("WebSocketNotifier.onMessage");
	}
	
	override function sendMessage( messageType:String, data:Dynamic ):Void
	{
		var message:Dynamic = {
			messageId: this.generateUUID(),
			clientType: "webSocketTestNotifier",
			clientVersion: WebSocketNotifier.version,
			clientId: this._clientId,
			messageType: messageType,
			data: data
		};
		
		var stringified:String = Json.stringify(message);
		
		if ( this._connected )
		{
			this._webSocket.send( stringified );
		}
		else
		{
			this._cache.push( stringified );
		}
	}
}
#end