package hex.unittest.notifier;

#if flash
import flash.display.LoaderInfo;
import flash.errors.Error;
import flash.events.ErrorEvent;
import flash.events.UncaughtErrorEvent;
#end
import hex.error.Exception;
import hex.event.IEvent;
import hex.unittest.assertion.Assert;
import hex.unittest.description.TestMethodDescriptor;
import hex.unittest.error.AssertException;
import hex.unittest.event.ITestRunnerListener;
import hex.unittest.event.TestRunnerEvent;

/**
 * ...
 * @author Francis Bourre
 */
class TraceNotifier implements ITestRunnerListener
{
	public static var TAB_CHARACTER:String = "  ";
	
    var _tabs   			: String;
    var _errorBubbling   	: Bool;

	#if flash
    public function new( loaderInfo : LoaderInfo, errorBubbling : Bool = false )
    {
		this._errorBubbling = errorBubbling;
		loaderInfo.uncaughtErrorEvents.addEventListener( UncaughtErrorEvent.UNCAUGHT_ERROR, this._uncaughtErrorHandler );
    }
	
	function _uncaughtErrorHandler( event : UncaughtErrorEvent ) : Void
	{
		event.preventDefault();
		if ( Std.is( event.error, Error ) )
		{
			var error : Error = cast event.error;
			// do something with the error
			trace( "UNCAUGHT ERROR: " + error.message + ":" + error.getStackTrace() );
		}
		else if ( Std.is( event.error, ErrorEvent ) )
		{
			var errorEvent : ErrorEvent = cast event.error;
			// do something with the error
			trace( "UNCAUGHT ERROR: " + errorEvent.text );
		}
		else
		{
			// a non-Error, non-ErrorEvent type was thrown and uncaught
			trace( "UNCAUGHT ERROR: " + event.text );
		}
		
	}
	#else
	public function new( errorBubbling : Bool = false )
    {
		this._errorBubbling = errorBubbling;
    }
	#end

    function _log( message : String ) : Void
    {
		#if neko
        Sys.println( this._tabs + message );
		#else
		trace( this._tabs + message );
		#end
    }

    function _addTab() : Void
    {
        this._tabs += TAB_CHARACTER;
    }

    function _removeTab() : Void
    {
        this._tabs = this._tabs.substr( 0, this._tabs.length - (TAB_CHARACTER.length) );
    }

    public function onStartRun( e : TestRunnerEvent ) : Void
    {
        this._tabs = "";
        this._log( "<<< Start " + e.getDescriptor().className + " tests run >>>" );
        this._addTab();
    }

    public function onEndRun( e : TestRunnerEvent ) : Void
    {
        this._removeTab();
        this._log( "<<< End tests run >>>" );
        this._log( "Assertions passed: " + Assert.getAssertionCount() );
		
		if ( Assert.getAssertionFailedCount() > 0 )
		{
			this._log( "Assertions failed: " + Assert.getAssertionFailedCount() + "\n" );
			#if flash
			flash.system.System.exit( 1 );
			#elseif ( php || neko )
			Sys.exit(1);
			#end
		}
		
		#if flash
		flash.system.System.exit( 0 );
		#end
    }

    public function onSuiteClassStartRun( e : TestRunnerEvent ) : Void
    {
        this._log( "Suite class '" + e.getDescriptor().getName() + "'" );
        this._addTab();
    }

    public function onSuiteClassEndRun( e : TestRunnerEvent ) : Void
    {
        this._removeTab();
    }

    public function onTestClassStartRun( e : TestRunnerEvent ) : Void
    {
        this._log( "Test class '" + e.getDescriptor().className + "'" );
        this._addTab();
    }

    public function onTestClassEndRun( e : TestRunnerEvent ) : Void
    {
        this._removeTab();
    }

    public function onSuccess( e : TestRunnerEvent ) : Void
    {
        var methodDescriptor : TestMethodDescriptor = e.getDescriptor().currentMethodDescriptor();
        var description : String = methodDescriptor.description;
        var timeElapsed : String = " " + e.getTimeElapsed() + "ms";
        var message : String = "* [" + methodDescriptor.methodName + "] " + ( description.length > 0 ? description : "" ) + timeElapsed;
        this._log( message );
    }

    public function onFail( e : TestRunnerEvent ) : Void
    {
		if ( e != null && e.getDescriptor() != null )
		{
			var methodDescriptor : TestMethodDescriptor = e.getDescriptor().currentMethodDescriptor();
			var description : String = methodDescriptor.description;
			var message : String = "FAILURE!!!	* [" + methodDescriptor.methodName + "] " + ( description.length > 0 ? description : "." );
			this._log( message );
			this._addTab();
			#if php
			this._log( "" + e.getError() + ": " + ( Std.is( e.getError(), AssertException ) ? ": " + Assert.getLastAssertionLog() : "" ) );
			#else
			this._log( e.getError().toString() );
			this._log( e.getError().message + ": " + ( Std.is( e.getError(), AssertException ) ? ": " + Assert.getLastAssertionLog() : "" ) );
			#end
			
			this._removeTab();
			
			if ( this._errorBubbling )
			{
				throw( e.getError() );
			}
		}
		
    }

    public function onTimeout( e : TestRunnerEvent ) : Void
    {
        var methodDescriptor : TestMethodDescriptor = e.getDescriptor().currentMethodDescriptor();
        var description : String = methodDescriptor.description;
        var message : String = "* [" + methodDescriptor.methodName + "] " + ( description.length > 0 ? description : "." );
        this._log( message );
        this._addTab();
        this._log( e.getError().message );
        this._removeTab();
    }
	
	public function onIgnore( e : TestRunnerEvent):Void 
	{
		var methodDescriptor : TestMethodDescriptor = e.getDescriptor().currentMethodDescriptor();
        var description : String = methodDescriptor.description;
        var timeElapsed : String = " " + e.getTimeElapsed() + "ms";
        var message : String = "IGNORE	* [" + methodDescriptor.methodName + "] " + ( description.length > 0 ? description : "" ) + timeElapsed;
        this._log( message );
	}
	
	public function handleEvent( e : IEvent ) : Void
	{
		
	}
}
