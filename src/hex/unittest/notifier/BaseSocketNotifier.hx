package hex.unittest.notifier;

import hex.error.VirtualMethodException;
import hex.event.IEvent;
import hex.log.Stringifier;
import hex.unittest.assertion.Assert;
import hex.unittest.description.TestMethodDescriptor;
import hex.unittest.event.ITestRunnerListener;
import hex.unittest.event.TestRunnerEvent;

/**
 * ...
 * @author ...
 */
class BaseSocketNotifier implements ITestRunnerListener
{
	
	var _clientId:String;
	
	var _cache = new Array<String>();
	var _connected:Bool = false;
	var netTimeElapsed	: Float;

	function new() 
	{
		_clientId = generateUUID();
	}
	
	public function onStartRun(event:TestRunnerEvent):Void 
	{
		
		this.netTimeElapsed = 0;
		
		this.sendMessage( "startRun", {} );
	}
	
	public function onEndRun(event:TestRunnerEvent):Void 
	{
		var data:Dynamic = { 
			successfulAssertionCount: Assert.getAssertionCount() - Assert.getAssertionFailedCount(),
			assertionFailedCount: Assert.getAssertionFailedCount(),
			assertionCount: Assert.getAssertionCount(),
			timeElapsed: this.netTimeElapsed
		}
		
		this.sendMessage( "endRun", data  );
	}
	
	public function onSuccess(event:TestRunnerEvent):Void 
	{
		var methodDescriptor : TestMethodDescriptor = event.getDescriptor().currentMethodDescriptor();
		
		var data:Dynamic = {
			className: event.getDescriptor().className,
			methodName: methodDescriptor.methodName,
			description: methodDescriptor.description,
			isAsync: methodDescriptor.isAsync,
			isIgnored: methodDescriptor.isIgnored,
			timeElapsed: event.getTimeElapsed(),


			fileName: "under_construction",
			lineNumber: 0
		};
		
		this.netTimeElapsed += event.getTimeElapsed();

		this.sendMessage( "testCaseRunSuccess", data );
	}
	
	public function onFail(event:TestRunnerEvent):Void 
	{
		var methodDescriptor : TestMethodDescriptor = event.getDescriptor().currentMethodDescriptor();
		
		var data:Dynamic = {
			className: event.getDescriptor().className,
			methodName: methodDescriptor.methodName,
			description: methodDescriptor.description,
			isAsync: methodDescriptor.isAsync,
			isIgnored: methodDescriptor.isIgnored,
			timeElasped: event.getTimeElapsed(),


			fileName: event.getError().posInfos != null ? event.getError().posInfos.fileName : "unknown",
			lineNumber: event.getError().posInfos != null ? event.getError().posInfos.lineNumber : 0,

			success: false,
			errorMsg: event.getError().message };
			
		this.netTimeElapsed += event.getTimeElapsed();

		this.sendMessage( "testCaseRunFailed", data );
	}
	
	public function onTimeout(event:TestRunnerEvent):Void 
	{
		this.onFail(event);
	}
	
	public function onIgnore(event:TestRunnerEvent):Void 
	{
		this.onSuccess(event);
	}
	
	public function onSuiteClassStartRun(event:TestRunnerEvent):Void 
	{
		var data:Dynamic = {
			className: event.getDescriptor().className,
			suiteName: event.getDescriptor().getName()
		};
		
		this.sendMessage( "testSuiteStartRun", data );
	}
	
	public function onSuiteClassEndRun(event:TestRunnerEvent):Void 
	{
		this.sendMessage( "testSuiteEndRun", {} );
	}
	
	public function onTestClassStartRun(event:TestRunnerEvent):Void 
	{
		var data:Dynamic = {
			className: event.getDescriptor().className
		};
		
		this.sendMessage( "testClassStartRun", data );
	}
	
	public function onTestClassEndRun(event:TestRunnerEvent):Void 
	{
		this.sendMessage( "testClassEndRun", {} );
	}
	
	public function handleEvent(e:IEvent):Void 
	{
		
	}
	
	function sendMessage(messageType:String, data:Dynamic):Void
	{
		throw new VirtualMethodException( Stringifier.stringify( this ) + ".sendMessage is not implemented" );
	}
	
	function generateUUID():String
	{
		var text:String = "";
		var possible:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

		for (i in 0...10) 
		{		
			text += possible.charAt(Math.floor(Math.random() * possible.length));
		}

		return text;
	}
}

typedef SocketMessage = {
	messageId:String,
	clientType:String,
	clientVersion:String,
	clientId:String,
	messageType:String,
	data:Dynamic
}