implement Thread_L;

# javal v1.3 generated file: edit with care

include "jni.m";
    jni : JNI;
        ClassModule,
        JString,
        JArray,
        JArrayI,
        JArrayC,
        JArrayB,
        JArrayS,
        JArrayJ,
        JArrayF,
        JArrayD,
        JArrayZ,
        JArrayJObject,
        JArrayJClass,
        JArrayJString,
        JClass,
        JThread,
        JObject : import jni;

#>> extra pre includes here

#<<

include "Thread_L.m";

#>> extra post includes here

sys  : Sys;
jldr : JavaClassLoader;
cast : Cast;

# following used for calling Thread.run()
threadclass      : JNI->ClassData;  #class data for java.lang.Thread
thread_run_idx   : int;             #method index for Thread.run()
thread_exit_idx  : int;             #method index for Thread.exit()

# some imports
ThreadData : import jldr;

#<<

init( jni_p : JNI )
{
    # save java native inteface mod instance
    jni = jni_p;
    #>>extra initialization here

	sys  = jni->sys;
	jldr = jni->jldr;
	cast = jni->CastMod();

	threadclass = jni->FindClass( "java.lang.Thread" );
	if ( threadclass == nil )
		jni->InitError( "Thread_L.init(): could not get thread class" );

	Class : import jldr;
	thread_run_idx     = threadclass.findvmethod( "run", "()V" );
	if ( thread_run_idx == -1 )
		jni->InitError( "Thread_L.init(): could not locate Thread.run()" );

	#thread_exit_idx     = threadclass.findvmethod( "exit", "()V" );
	#if ( exit_idx == -1 )
	#	jni->InitError( "Thread_L.init(): could not locate Thread.exit()" );
    #<<
}

currentThread_rThread( ) : JThread
{#>>
	e := ref Sys->Exception;
	if ( sys->rescue("*",e) == Sys->HANDLER )
	{
		# get the java thread object assocciated 
		# with this thread. it is stored in the
		# class loader's thread structure.
		thd_obj := jldr->getthreaddata().this;
		if ( thd_obj != nil )
			return( cast->JObjToJThd(thd_obj) );
		sys->unrescue();
	}
	else
		sys->rescued(Sys->ONCE, nil);

	
	# either we could not find the thread data
	# or no "Thread" object was stored in it
	# either way we are in bad shape
	jni->FatalError( "could not get thread object" );

	return(nil);
}#<<

yield_V( )
{#>>
	jni->sys->sleep(0);
}#<<

sleep_J_V( p0 : big)
{#>>
	millis := int p0;

	if ( millis < 1 )
	{
		if ( millis == 0 ) 
		{
			# just yield thread
			jni->sys->sleep(0);
			return;
		}

		# bad sleep value
		jni->ThrowException( "java.lang.IllegalArgumentException", "timeout value is negative" );
	}
	jldr->sleep( millis );
}#<<

start_V( this : JThread)
{#>>
	thdobj := cast->JThdToJObj(this);

	# grab the lock on the thread object to ensure
	# no state is changed while we are starting the
	# thread.
#	jni->MonitorEnter( thdobj );

	if ( (this.stillborn == byte 0) && (this.PrivateInfo == nil) )
	{
		# spawn a limbo fct as the java
		# thread's starting point.
		ok := chan of int;
		spawn javathreadinit( this, ok );

		# wait for thread to init then we can
		# continue. Note we hold a lock and
		# the thread will change some state
		# and notify us before the java run()
		# method is invoked. The purpose is to
		# allow for state information to be updated
		# while we have the lock.
		status := <- ok;

		#status == 0 is an err
		#       == 1 is ok

		if ( status == 0 )
		{
			this.stillborn = byte 1;
			this.PrivateInfo = nil;
		}

	}
#	jni->MonitorExit( thdobj );
}#<<

isInterrupted_Z_Z( this : JThread, p0 : int) : int
{#>>
	old_flag := int this.was_interrupted;

	if ( old_flag )
		this.was_interrupted = byte p0;
	return( old_flag );
}#<<

isAlive_Z( this : JThread) : int
{#>>
	thd := this.PrivateInfo;
	if ( (this.stillborn == byte 0) && (thd != nil) )
	{
		# JLS does not require that we actually determine
		# the "os" thread is alive, just that the object
		# state indicates it is
		return( JNI->TRUE );
	}

	# looks like thread is not alive
	return( jni->FALSE );
}#<<

countStackFrames_I( this : JThread) : int
{#>>
	junk := this;
	# need to do some /prog work
	return( 0 );
}#<<

setPriority0_I_V( this : JThread, p0 : int)
{#>>
	# just save the priority, a dis thread
	# has no priority
	this.priority = p0;
}#<<

stop0_rObject_V( this : JThread, p0 : JObject)
{#>>
	# the calling thread is attempting to throw an
	# exception at "this" thread (i.e. the one represented
	# by this thread object.  make sure that thread at least 
	# appears to be running and throw the exceptio at it

	thd := this.PrivateInfo;
	stillborn := this.stillborn;
	
	# prevent a start or re-start
	this.stillborn = byte 1;

	if ( (stillborn == byte 0) && (thd != nil) )
	{
		# throw the exception (p0) at the thread
		jldr->stop( thd, p0 );
	}

}#<<

suspend0_V( this : JThread)
{#>>
	# the calling thread wants to suspend
	# the "this" thread.
	thd := this.PrivateInfo;
	if ( (this.stillborn == byte 0) && (thd != nil) )
		jldr->suspend( thd );

}#<<

resume0_V( this : JThread)
{#>>
	# the calling thread wants to resume
	# the "this" thread.
	thd := this.PrivateInfo;
	if ( (this.stillborn == byte 0) && (thd != nil) )
		jldr->resume( thd );
}#<<

interrupt0_V( this : JThread)
{#>>
	# the calling thread wants to interrupt
	# the "this" thread.
	thd := this.PrivateInfo;
	if ( (this.stillborn == byte 0) && (thd != nil) )
		jldr->interrupt( thd );
}#<<

lowinit_rThread_V( p0 : JThread)
{#>>
	# this fct is called once during the static init of the
	# java.lang.Thread object. 'p0' is the "root thread" object
	# which must be associated witht the Dis thread which is
	# calling this fuction -- i.e. associate the 'p0' java thread
	# object with the current Dis thread. 'p1' is the same thread
	# object, just with the type JObject which allows us to store
	# it off in the JavaClassLoader->ThreadData structure associated
	# with the calling Dis thread.

	# since this is the root thread make a root thread group by
	# creating an instance of ThreadGroup and calling its private
	# default constructor.
	thd_grp_cl := jni->FindClass( "java.lang.ThreadGroup" );
	if ( thd_grp_cl == nil )
		jni->FatalError( "could not obtain ThreadGroup class" );

	thd_grp := jni->NewObject( thd_grp_cl );
	if ( thd_grp == nil )
		jni->FatalError( "could not created root threadgroup" );
	p0.group = thd_grp;

	# get the ThreadData structure for the calling thread
	thd := jldr->getthreaddata();
	thd.this       = cast->JThdToJObj(p0);     # save java object in thread data
	p0.PrivateInfo = thd;    # save thread data in java object

}#<<





##### private functions used by the Thread_L module

#
# this function is the first function of all java
# threads, except for the first thread which is
# controlled by the JavaClassLoader module.
#
# jthd   : the Java thread object associated with this 
#          Dis thread.
#
# ok     : use this channel to notify "spawner" that
#          we are under-way. send 0==fail; 1==ok
#
javathreadinit( jthd : JNI->JThread, ok : chan of int )
{
	# create a JavaClassLoader->ThreadData structure
	# and "register" it with the class loader.

	thd := jldr->getthreaddata();

	if ( thd.this != nil )
	{
		# this should be nil, else the java thread
		# already is set for this Dis thread and we
		# are in some screwed-up state.
		ok <-= 0;
		return;
	}

	# now fill in the java thread obj (after
	# the putthreaddata so any init is not affected
	thdobj   := cast->JThdToJObj( jthd );
	thd.this  = thdobj;

	# now save the ThreadData in the java object in order
	# to allow a lookup from the other diretion
	jthd.PrivateInfo = thd;

	# set our daemon thread status
	if ( jthd.daemon == JNI->BTRUE )
		jldr->daemonize();

	# notify spawner we are under-way
	ok <- = 1;

	# we need to catch any exceptions in order
	# to clean up the thread object's state
	ee := ref Sys->Exception;
	if ( sys->rescue( "*", ee ) == Sys->HANDLER )
	{
		
		# call Thread.run() or Runnable.run()
		Run( jthd, thdobj );
		
		# call Thread.exit()
		(mod,idx) := jni->FindMethod( threadclass, "exit", "()V", JNI->METH_PRIVATE );
		jni->jassist->mcall1( mod, idx, thdobj );
		sys->unrescue();
	}
	else
	{
		# clear exception
		sys->rescued( Sys->ONCE, nil );

		# thread threw an unhandled exception so
		# call the ThreadGroup.uncaughtException()
		# method.
		UncaughtException( jthd, thdobj, ee );
	}

	# java thread clean up

	jni->jldr->monitorenter( thdobj );   ##LOCK thread object
	{

		jthd.stillborn   = byte 1;    # prevent re-run

		# notify ALL "waiters" (which includes any Thread.join()'s)
		jni->jldr->monitornotify( thdobj, 1 );
	}
	jni->jldr->monitorexit( thdobj ); ##UNLOCK thread object

	# clean up thread structures
	jldr->delthreaddata();
	thd.this         = nil;  
	jthd.PrivateInfo = nil;  
}


#
# if the thread object contains a "registered" Runnable
# object then execute that Runnable's run() method, else
# execute the Thread's run() method (which should be 
# overridden.
#
Run( jthd : JNI->JThread, thdobj : JObject )
{
	Class : import jldr;
	class      : JNI->ClassData;
	run_idx    := thread_run_idx;  #default to Thread.run()
	obj        := thdobj;          #this obj for run() call

	if ( jthd.target != nil )
	{
		# the thread has a registered Runnable
		# object, find its run() method
		class   = jni->GetObjectClassData( jthd.target );
		run_idx = class.findvmethod( "run", "()V" );
		if ( run_idx == -1 )
			return;
		obj = jthd.target;  #set 'this' to the runnable obj
	}
	else
	{
		# use the thread object's run() 
		class = jni->GetObjectClassData(thdobj);
	}

	run_method := class.virtualmethods[run_idx];

	# do the run()
	jni->jassist->mcall1( run_method.class.mod, run_method.field.value, obj );
}

#
# If the thread's ThreadGroup is a subclass of java.lang.ThreadGroup
# then invoke that class'es "uncaughtException" method.  This
# method is called whenever a thread does not handle an exception.
# The method is passed an instance of the Thread along with the
# "throwable" (i.e. exception).
#
UncaughtException( jthd : JThread, thdobj : JObject, ee : ref Sys->Exception )
{
	tgrp_cl := jni->GetObjectClassData( jthd.group );

	#
	# if the thread group is the default thread group
	# class, then we will handle the excepition here
	# which is to simply do nothing.
	#
	if ( tgrp_cl.name != "java/lang/ThreadGroup" )
	{
		# call method, protected against exceptions
		# since we must still clean-up the thread
		eee := ref Sys->Exception;
		if ( sys->rescue( "*", eee ) == Sys->HANDLER )
		{
			# find the uncaughtException method for the thd-grp
			(mod,idx) := jni->FindMethod( tgrp_cl, "uncaughtException", 
				                          "(Ljava.lang.Thread;Ljava.lang.Throwable;)V", 
										  JNI->METH_VIRTUAL );
			if ( mod != nil )
			{
				# call the uncaughException handler
				Value : import jni;
				args := array[] of 
					{ 
						ref Value.TObject(thdobj),           #the thread
						ref Value.TObject(jldr->culprit(ee)) #the exception
					};

				# do the call
				##LATER nil := jni->LowCall( mod, idx, jthd.group, args ); 
			}
			sys->unrescue();
		}
		else
		{
			# if we get an exception here just return
			# and let the thread finish cleanup.
			sys->rescued( Sys->ONCE, nil );
		}
	}
	
}

