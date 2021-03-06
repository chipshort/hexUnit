package hex.unittest.runner;

import hex.event.IEvent;
import hex.event.LightweightListenerDispatcher;
import hex.log.Stringifier;
import hex.unittest.assertion.Assert;
import hex.unittest.description.TestClassDescriptor;
import hex.unittest.event.ITestRunnerListener;
import hex.unittest.event.TestRunnerEvent;
import hex.unittest.metadata.MetadataParser;

/**
 * ...
 * @author Francis Bourre
 */
class ExMachinaUnitCore implements ITestRunner implements ITestRunnerListener
{
    var _dispatcher                 : LightweightListenerDispatcher<ITestRunnerListener, TestRunnerEvent>;
    var _parser                     : MetadataParser;
    var _classDescriptors           : Array<TestClassDescriptor>;
    var _runner                     : TestRunner;
    var _currentClassDescriptor     : Int;

    public function new()
    {
        this._dispatcher        = new LightweightListenerDispatcher<ITestRunnerListener, TestRunnerEvent>();
        this._parser            = new MetadataParser();
        this._classDescriptors  = [];
    }

    public function run() : Void
    {
        this._currentClassDescriptor = 0;
        Assert.resetAssertionLog();
        this._runNext();
    }
	
	public function getTestLength() : UInt
	{
		var length : UInt = 0;
		for ( classDescriptor in this._classDescriptors )
		{
			length += classDescriptor.getTestLength();
		}
		return length;
	}

    public function addTest( testableClass : Class<Dynamic> ) : Void
    {
        this._classDescriptors.push( this._parser.parse( testableClass ) );
    }
	
	public function addTestCollection( collection : Array<Class<Dynamic>> ) : Void
    {
		for ( testableClass in collection )
		{
			this.addTest( testableClass );
		}
    }
	
	public function addTestMethod( testableClass : Class<Dynamic>, methodName : String ) : Void
    {
		this._classDescriptors.push( this._parser.parseMethod( testableClass, methodName ) );
	}

    public function toString() : String
    {
        return Stringifier.stringify( this );
    }

    /**
     * Event handling
     **/
	public function handleEvent( e : IEvent ) : Void
	{
		
	}
	
    public function addListener( listener : ITestRunnerListener ) : Bool
    {
        return this._dispatcher.addListener( listener );
    }

    public function removeListener( listener : ITestRunnerListener ) : Bool
    {
        return this._dispatcher.removeListener( listener );
    }

    public function onStartRun( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

    public function onEndRun( event : TestRunnerEvent ) : Void
    {
        if ( this._hasNextClassDescriptor() )
        {
			this._dispatcher.dispatchEvent( event );
            Assert.resetAssertionLog();
			
            this._runner.removeListener( this );
            this._runNext();
        }
        else
        {
            this._dispatcher.dispatchEvent( event );
            Assert.resetAssertionLog();
        }
    }

    public function onSuiteClassStartRun( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

    public function onSuiteClassEndRun( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

    public function onTestClassStartRun( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

    public function onTestClassEndRun( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

    public function onSuccess( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

    public function onFail( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

    public function onTimeout( event : TestRunnerEvent ) : Void
    {
        this._dispatcher.dispatchEvent( event );
    }

	public function onIgnore(event:TestRunnerEvent):Void 
	{
		this._dispatcher.dispatchEvent( event );
	}

    /**
     *
     **/
    function _runNext() : Void
    {
        this._runner = new TestRunner( this._nextClassDescriptor() );
        this._runner.addListener( this );
        this._runner.run();
    }

    function _nextClassDescriptor() : TestClassDescriptor
    {
        return this._classDescriptors[ this._currentClassDescriptor++ ];
    }

    function _hasNextClassDescriptor() : Bool
    {
        return this._currentClassDescriptor < this._classDescriptors.length;
    }
}
