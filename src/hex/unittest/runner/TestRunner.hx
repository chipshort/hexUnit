package hex.unittest.runner;

import haxe.Timer;
import hex.event.BasicEvent;
import hex.event.IEvent;
import hex.event.LightweightListenerDispatcher;
import hex.unittest.description.TestMethodDescriptor;
import haxe.ds.GenericStack;
import hex.unittest.event.MethodRunnerEvent;
import hex.unittest.event.IMethodRunnerListener;
import hex.unittest.event.TestRunnerEvent;
import hex.unittest.description.TestClassDescriptor;

import hex.unittest.event.ITestRunnerListener;

/**
 * ...
 * @author Francis Bourre
 */
class TestRunner implements ITestRunner implements IMethodRunnerListener
{
    var _dispatcher                 : LightweightListenerDispatcher<ITestRunnerListener, TestRunnerEvent>;
    var _classDescriptors           : GenericStack<TestClassDescriptor>;
    var _executedDescriptors        : Map<TestClassDescriptor, Bool>;
	var _lastRender					: Float = 0;
	
	#if flash
	static public var RENDER_DELAY 			: Int = 150;
	#else
	static public var RENDER_DELAY			: Int = 0;
	#end

    public function new( classDescriptor : TestClassDescriptor )
    {
        this._classDescriptors          = new GenericStack<TestClassDescriptor>();
        this._dispatcher                = new LightweightListenerDispatcher<ITestRunnerListener, TestRunnerEvent>();
        this._executedDescriptors       = new Map<TestClassDescriptor, Bool>();

        this._classDescriptors.add( classDescriptor );
    }

    public function run() : Void
    {
        var classDescriptor : TestClassDescriptor = this._classDescriptors.first();
        this._dispatcher.dispatchEvent( new TestRunnerEvent( TestRunnerEvent.START_RUN, this, classDescriptor ) );
        this._runClassDescriptor( this._classDescriptors.first() );
    }

    function _runClassDescriptor( classDescriptor : TestClassDescriptor ) : Void
    {
        if ( classDescriptor != null )
        {
            if ( classDescriptor.isSuiteClass )
            {
                if ( !this._executedDescriptors.exists( classDescriptor ) )
                {
                    this._dispatcher.dispatchEvent( new TestRunnerEvent( TestRunnerEvent.SUITE_CLASS_START_RUN, this, classDescriptor ) );
                    this._executedDescriptors.set( classDescriptor, true );
                }

                this._runSuiteClass( classDescriptor );
            }
            else
            {
                if ( !this._executedDescriptors.exists( classDescriptor ) )
                {
                    this._dispatcher.dispatchEvent( new TestRunnerEvent( TestRunnerEvent.TEST_CLASS_START_RUN, this, classDescriptor ) );
                    classDescriptor.instance = Type.createEmptyInstance( classDescriptor.type );
                    this._executedDescriptors.set( classDescriptor, true );
                }

                this._tryToRunBeforeClass( classDescriptor );
                this._runTestClass( classDescriptor );
            }
        }
        else
        {
            this._dispatcher.dispatchEvent( new TestRunnerEvent( TestRunnerEvent.END_RUN, this, classDescriptor ) );
        }
    }

    function _runSuiteClass( classDescriptor : TestClassDescriptor ) : Void
    {
        if ( classDescriptor.hasNextClass() )
        {
            classDescriptor = classDescriptor.nextClass();
            this._classDescriptors.add( classDescriptor );
            this._runClassDescriptor( classDescriptor );
        }
        else
        {
            this._dispatcher.dispatchEvent( new TestRunnerEvent( TestRunnerEvent.SUITE_CLASS_END_RUN, this, classDescriptor ) );
            this._classDescriptors.pop();
            this._runClassDescriptor( this._classDescriptors.first() );
        }
    }

    function _runTestClass( classDescriptor : TestClassDescriptor ) : Void
    {
        if ( classDescriptor.hasNextMethod() )
        {
            this._tryToRunSetUp( classDescriptor );
            var methodRunner = new MethodRunner( classDescriptor.instance, classDescriptor.nextMethod() );
            methodRunner.addListener( this );
            methodRunner.run();
        }
        else
        {
            this._dispatcher.dispatchEvent( new TestRunnerEvent( TestRunnerEvent.TEST_CLASS_END_RUN, this, classDescriptor ) );
            this._tryToRunAfterClass( classDescriptor );
            this._classDescriptors.pop();
            this._runClassDescriptor( this._classDescriptors.first() );
        }
    }

    function _tryToRunSetUp( classDescriptor : TestClassDescriptor ) : Void
    {
        if ( classDescriptor.setUpFieldName != null )
        {
            Reflect.callMethod( classDescriptor.instance, Reflect.field( classDescriptor.instance, classDescriptor.setUpFieldName ), [] );
        }
    }

    function _tryToRunTearDown( classDescriptor : TestClassDescriptor ) : Void
    {
        if ( classDescriptor.tearDownFieldName != null )
        {
            Reflect.callMethod( classDescriptor.instance, Reflect.field( classDescriptor.instance, classDescriptor.tearDownFieldName ), [] );
        }
    }

    function _tryToRunBeforeClass( classDescriptor : TestClassDescriptor ) : Void
    {
        if ( classDescriptor.beforeClassFieldName != null )
        {
           Reflect.callMethod( classDescriptor.type, Reflect.field( classDescriptor.type, classDescriptor.beforeClassFieldName ), [] );
        }
    }

    function _tryToRunAfterClass( classDescriptor : TestClassDescriptor ) : Void
    {
        if ( classDescriptor.afterClassFieldName != null )
        {
            Reflect.callMethod( classDescriptor.type, Reflect.field( classDescriptor.type, classDescriptor.afterClassFieldName ), [] );
        }
    }

    public function addListener( listener : ITestRunnerListener ) : Bool
    {
        return this._dispatcher.addListener( listener );
    }

    public function removeListener( listener : ITestRunnerListener ) : Bool
    {
        return this._dispatcher.removeListener( listener );
    }

    /**
     *
     **/
	public function handleEvent( e : IEvent ) : Void
	{
		
	}
	
    public function onSuccess( e : MethodRunnerEvent ) : Void
    {
        this._endTestMethodCall( e, TestRunnerEvent.SUCCESS );
    }

    public function onFail( e : MethodRunnerEvent ) : Void
    {
        this._endTestMethodCall( e, TestRunnerEvent.FAIL );
    }

    public function onTimeout( e : MethodRunnerEvent ) : Void
    {
        this._endTestMethodCall( e, TestRunnerEvent.TIMEOUT );
    }
	
	public function onIgnore( e : MethodRunnerEvent ):Void 
	{
		this._endTestMethodCall( e, TestRunnerEvent.IGNORE );
	}

    function _endTestMethodCall( e : MethodRunnerEvent, eventType : String ) : Void
    {
        var classDescriptor : TestClassDescriptor = this._classDescriptors.first();
        this._dispatcher.dispatchEvent( new TestRunnerEvent( eventType, this, classDescriptor, e.getTimeElapsed(), e.getError() ) );
        this._tryToRunTearDown( classDescriptor );
		
		#if (!neko || haxe_ver >= "3.3")
		if ( TestRunner.RENDER_DELAY > 0 && Date.now().getTime() - this._lastRender > TestRunner.RENDER_DELAY )
		{
			this._lastRender = Date.now().getTime() + 1;
			Timer.delay( function( ) { _runTestClass( classDescriptor ); }, 1 );
		}
		else
		{
			this._lastRender = Date.now().getTime() + TestRunner.RENDER_DELAY;
			Timer.delay( function( ) { _runTestClass( classDescriptor ); }, TestRunner.RENDER_DELAY );
		}
		#else
		_runTestClass( classDescriptor );
		#end
    }
}
