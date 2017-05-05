/* Fann2MQL-threads.cpp
 *
 * Copyright (C) 2008-2009 Mariusz Woloszyn
 *
 *  This file is part of Fann2MQL package
 *
 *  Fann2MQL is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  Fann2MQL is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Fann2MQL; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include "stdafx.h"
#include "Fann2MQL.h"
#include "doublefann.h"
#include "fann_internal.h"
#include "windows.h"
#include <strsafe.h>

#include "tbb/task_scheduler_init.h"
#include "tbb/blocked_range.h"
#include "tbb/parallel_for.h"

/* number of threads */
DWORD _threads=0;

/* TBB initialization indicator */
int _TBB_Initialized=0;

/* data used by f2M_run_threaded function */
runThreadedData* _rtd[F2M_MAX_THREADS];

/* threads handlers */
HANDLE _threadH[F2M_MAX_THREADS];

void ErrorExit(LPTSTR lpszFunction);

using namespace tbb;

/* Intel TBB Task Scheduler */
task_scheduler_init TS(task_scheduler_init::deferred);

/* Intel TBB paralelized class used by f2M_run_parallel() */
class Apply_fann_run {
	int *anns;
	double *input_vector;
public:
	void operator()( const blocked_range<size_t>& r ) const {
		int* my_a=anns;
		double *my_iv=input_vector;
		for( size_t i=r.begin(); i!=r.end(); ++i )
			_outputs[my_a[i]]=fann_run(_fanns[my_a[i]], my_iv);
	}
	Apply_fann_run(int *a, double *iv) :
		anns(a), input_vector(iv)
	{}
};

/**
 * Run fann networks in parallel using Intel TBB
 *  anns_count - number of networks to run in paralel
 *  anns[] - network handlers returned by f2M_create*
 *  *input_vector - arrary of inputs
 * Returns:
 *  0 on success, <0 on error
 * Note:
 *  To obtain network output use f2M_get_output().
 *  Any existing output is overwritten
 */
FANN2MQL_API int __stdcall f2M_run_parallel(DWORD anns_count, int* anns, double *input_vector)
{
	DWORD i;
	int ret=0;

	if (!_TBB_Initialized) return -1;

	for (i=0; i<anns_count; i++)
	{
		/* this network is not allocated */
		if (anns[i]<0 || anns[i]>_ann || _fanns[anns[i]]==NULL) return -12;

		/* the input vector is empty */
		if (input_vector==NULL) return -30;
	}

	/* parallel the work */
	parallel_for(blocked_range<size_t>(0,anns_count),
	             Apply_fann_run(anns, input_vector),auto_partitioner());

	return 0;
}

/* Intel TBB paralelized class used by f2M_train_parallel() */
class Apply_fann_train {
	int *anns;
	double *input_vector;
	double *output_vector;
public:
	void operator()( const blocked_range<size_t>& r ) const {
		int* my_a=anns;
		double *my_iv=input_vector;
		double *my_ov=output_vector;
		for( size_t i=r.begin(); i!=r.end(); ++i )
			fann_train(_fanns[my_a[i]], my_iv, my_ov);
	}
	Apply_fann_train(int *a, double *iv, double *ov) :
		anns(a), input_vector(iv), output_vector(ov)
	{}
};

/**
 * Train fann networks in parallel using Intel TBB
 *  anns_count - number of networks to run in paralel
 *  anns[] - network handlers returned by f2M_create*
 *  *input_vector - arrary of inputs
 *	*output_vector - array of outputs
 * Returns:
 *  0 on success, <0 on error
 */
FANN2MQL_API int __stdcall f2M_train_parallel(DWORD anns_count, int* anns, double *input_vector, double *output_vector)
{
	DWORD i;
	int ret=0;

	if (!_TBB_Initialized) return -1;

	for (i=0; i<anns_count; i++)
	{
		/* this network is not allocated */
		if (anns[i]<0 || anns[i]>_ann || _fanns[anns[i]]==NULL) return -12;

		/* the input vector is empty */
		if (input_vector==NULL) return -30;

		/* the output vector is empty */
		if (output_vector==NULL) return -40;
	}

	/* parallel the work */
	parallel_for(blocked_range<size_t>(0,anns_count),
	             Apply_fann_train(anns, input_vector, output_vector),auto_partitioner());

	return 0;
}

/**
 * Initializes Intel TBB parallel processing interface
 * Returns:
 *  0 on success
 */
FANN2MQL_API int __stdcall f2M_parallel_init()
{
	if (!_TBB_Initialized)
		TS.initialize();
	_TBB_Initialized++;

	//SetUnhandledExceptionFilter(NULL);
	return 0;
}

/**
 * Deinitiaizes Intel TBB parallel processing interface
 * Returns:
 *  0 on success, -1 on error
 */
FANN2MQL_API int __stdcall f2M_parallel_deinit()
{
	_TBB_Initialized--;
	if (_TBB_Initialized<=0)
		TS.terminate();

	return 0;
}

/* Puts thread into infnite loop, waiting for APC 
 */
DWORD WINAPI f2M_threads_loop(LPVOID lpParam)
{	
	runThreadedData* rtd=(runThreadedData*)lpParam;


	rtd->mutexH=CreateMutex(NULL, TRUE, NULL);
	if (rtd->mutexH==NULL) {
		ErrorExit(TEXT("f2M_threads_loop(): CreateMutex()"));
	}

	/* infinite loop, waiting for APC */
	while (1) {
		SleepEx(INFINITE, TRUE);
	}

	return 0;
}

/**
 * Initializes (starts) threads
 *  num_threads - number of threads to spawn
 * Returns:
 *  0 on success, -1 on error
 * Note:
 * This function starts threads and puts them in infinite loop waiting for
 * asynchronous procedure calls (APC)
 */
FANN2MQL_API int __stdcall f2M_threads_init(int num_threads)
{
	DWORD i;

	/* Seems threads already initialized! */
	if (_threads!=0) return -1;

	/* At least two threads */
	if (num_threads<2) return -2;
	
	/* limit number of threads */
	_threads=num_threads>F2M_MAX_THREADS?F2M_MAX_THREADS:num_threads;

	/* Start all threads */
	for (i=0; i<_threads; i++)
	{
		/* allocate data for runThreadedData structure */
		_rtd[i] = (runThreadedData*) HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sizeof(runThreadedData));
		if (_rtd[i]==NULL) ExitProcess(3);

		/* Initialize runThreadedData */
		_rtd[i]->ann_count=0;
		_rtd[i]->ann_start=0;
		_rtd[i]->anns=NULL;
		_rtd[i]->input_vector=NULL;
		_rtd[i]->mutexH=NULL;
		_rtd[i]->ret=0;
		_rtd[i]->threadId=NULL;

		_threadH[i] = CreateThread( 
			NULL,                   // default security attributes
			0,                      // use default stack size  
			f2M_threads_loop,		// thread function name
			(LPVOID)_rtd[i],        // argument to thread function 
			0,                      // use default creation flags 
			&_rtd[i]->threadId);			// returns the thread identifier 

		/* Thread initialization failed... exit! */
		if (_threadH[i] == NULL)
				ExitProcess(1);
		SetThreadPriority(_threadH[i],THREAD_PRIORITY_HIGHEST);
	}
	SwitchToThread();

	/* let there be rest ;) */
	Sleep(300);

	return 0;
}


/* Terminates thread */
VOID CALLBACK f2M_thread_terminate(ULONG_PTR dwParam)
{
	runThreadedData* data=_rtd[dwParam];
	
	/* clean up the stuff */
	CloseHandle(_threadH[dwParam]);
	CloseHandle(data->mutexH);
    HeapFree(GetProcessHeap(), 0, data);

	ExitThread(-1);
}

/**
 * Deinitiaizes (stops) threads
 * Returns:
 *  0 on success, -1 on error
 */
FANN2MQL_API int __stdcall f2M_threads_deinit()
{
	DWORD i;

	/* Seems no threads initialized! */
	if (_threads==0) return -1;

	/* schedule termination */
	for (i=0; i<_threads; i++)
	{
		QueueUserAPC(f2M_thread_terminate, _threadH[i], i);

	}
	/* wait for threads to terminate */
	WaitForMultipleObjects(_threads, _threadH, TRUE, INFINITE);

	/* set threads number to 0 indicating unitialized threads state */
	_threads=0;
	return 0;
}

/* obtain mutex */
VOID CALLBACK f2M_thread_get_mutex(ULONG_PTR dwParam)
{
	runThreadedData* data=_rtd[dwParam];

	WaitForSingleObject(data->mutexH,INFINITE);
}

VOID CALLBACK f2M_thread_run_nowait(ULONG_PTR dwParam)
{
	int i;
	runThreadedData* data=_rtd[dwParam];


	data->ret=0;
	/* run all networks given fo this thread */
	for (i = data->ann_start;i < data->ann_start + data->ann_count; i++) {
		/* this network is not allocated */
		if (data->anns[i]<0 || data->anns[i]>_ann || _fanns[data->anns[i]]==NULL) {
			data->ret=-11;
			break;
		}
		/* the input vector is empty */
		if (data->input_vector==NULL) {
			data->ret=-22;
			break;
		}

		_outputs[data->anns[i]]=fann_run(_fanns[data->anns[i]], data->input_vector);
		if (_outputs[data->anns[i]]==NULL) {
			data->ret=-10;
			break;
		}
	}

	return;
}


VOID CALLBACK f2M_thread_run(ULONG_PTR dwParam)
{
	int i;
	runThreadedData* data=_rtd[dwParam];


	data->ret=0;
	/* run all networks given fo this thread */
	for (i = data->ann_start;i < data->ann_start + data->ann_count; i++) {
		/* this network is not allocated */
		if (data->anns[i]<0 || data->anns[i]>_ann || _fanns[data->anns[i]]==NULL) {
			data->ret=-11;
			break;
		}
		/* the input vector is empty */
		if (data->input_vector==NULL) {
			data->ret=-22;
			break;
		}

		_outputs[data->anns[i]]=fann_run(_fanns[data->anns[i]], data->input_vector);
		if (_outputs[data->anns[i]]==NULL) {
			data->ret=-10;
			break;
		}
	}

	/* release the mutex */
	ReleaseMutex(data->mutexH);
	return;
}

/**
 * Run fann networks in threads
 *  anns_count - number of networks to run in paralel
 *  anns[] - network handlers returned by f2M_create*
 *  *input_vector - arrary of inputs
 * Returns:
 *  0 on success, -1 on error
 * Note:
 *  To obtain network output use f2M_get_output().
 *  Any existing output is overwritten
 */
FANN2MQL_API int __stdcall f2M_run_threaded(DWORD anns_count, int* anns, double *input_vector)
{
	DWORD i;
	int ret=0;
	/* number of threads we need to run */
	DWORD threads=anns_count>_threads?_threads:anns_count;
	int anns_start=0;
	/* mutexes used for synchronisation */
	HANDLE _mutex[F2M_MAX_THREADS];

	for (i=0; i<anns_count; i++)
	{
		/* this network is not allocated */
		if (anns[i]<0 || anns[i]>_ann || _fanns[anns[i]]==NULL) return -12;

		/* the input vector is empty */
		if (input_vector==NULL) return -30;
	}

	for (i=0; i<threads; i++)
	{
		if (_rtd==NULL) {
			ErrorExit(TEXT("f2M_run_threaded(): _rtd==NULL"));
		}
		/* initialize values */
		_rtd[i]->ann_start=anns_start;
		_rtd[i]->ann_count=((anns_count%(threads-i))>0?1:0)+(anns_count/(threads-i));
		_rtd[i]->anns=anns;
		_rtd[i]->input_vector=input_vector;
		_rtd[i]->ret=-1;
		_mutex[i]=_rtd[i]->mutexH;


		/* exit on error */
		if (_mutex[i]==NULL) {
			ErrorExit(TEXT("f2M_run_threaded(): _mutex[%d]==NULL()"));
		}

		if (i<threads) {
			if (QueueUserAPC(f2M_thread_run, _threadH[i], i)==0)
				ErrorExit(TEXT("f2M_run_threaded(): QueueUserAPC(f2M_thread_run)"));
		} else {
			f2M_thread_run_nowait(i);
		}
		anns_start+=_rtd[i]->ann_count;
		anns_count-=_rtd[i]->ann_count;
	}

	/*
	Sleep(0);
	SwitchToThread();
	*/

	/* wait for all the threads to release release mutex */
	ret=WaitForMultipleObjects(threads, _mutex, TRUE, INFINITE);
	if (ret==WAIT_FAILED) {
		ErrorExit(TEXT("f2M_run_threaded(): WaitForMultipleObjects()"));
	}
	for(i=0; i<threads; i++)
	{
		ReleaseMutex(_rtd[i]->mutexH);
		if (QueueUserAPC(f2M_thread_get_mutex, _threadH[i], i)==0)
			ErrorExit(TEXT("f2M_run_threaded(): QueueUserAPC(f2M_thread_get_mutex)"));
		ret+=_rtd[i]->ret;
	}

	return ret;
}


#if 0
DWORD WINAPI f2M_threaded_run(LPVOID lpParam) 
{
	int i;
	runThreadedData* data=(runThreadedData*)lpParam;

	for (i = data->ann_start;i < data->ann_start + data->ann_count; i++) {
		_outputs[data->anns[i]]=fann_run(_fanns[data->anns[i]], data->input_vector);
		if (_outputs[data->anns[i]]==NULL) return -1;
	}

	return 0;
}

/* Run fann networks in threads
 *  threads_count - number of threads to spawn
 *  anns_count - number of networks to run in paralel
 *  anns[] - network handlers returned by f2M_Init
 *  *input_vector - arrary of inputs
 * Returns:
 *  0 on success, -1 on error
 * Note:
 *  To obtain network output use f2M_get_output().
 *  Any existing output is overwritten
 */
FANN2MQL_API int __stdcall f2M_run_threaded(int threads_count, int anns_count, int anns[], double *input_vector)
{
	runThreadedData* data[F2M_MAX_THREADS];
    DWORD threadId[F2M_MAX_THREADS];
	HANDLE threadHandle[F2M_MAX_THREADS]; 
	int anns_start=0;

	int threads=threads_count>F2M_MAX_THREADS?F2M_MAX_THREADS:threads_count;
	int i;

	for (i=0; i<anns_count; i++)
	{
		/* this network is not allocated */
		if (anns[i]<0 || anns[i]>_ann || _fanns[anns[i]]==NULL) return _ann;

		/* the input vector is empty */
		if (input_vector==NULL) return -2;

	}

	for (i=0; i<threads; i++)
	{
		data[i] = (runThreadedData*) HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, sizeof(runThreadedData));
		if (data[i]==NULL) ExitProcess(2);
		data[i]->anns=anns;
		data[i]->ann_start=anns_start;
		data[i]->ann_count=((anns_count%(threads-i))>0?1:0)+(anns_count/(threads-i));
		data[i]->input_vector=input_vector;
		
		if (i<threads-1) {
			threadHandle[i] = CreateThread( 
	            NULL,                   // default security attributes
				0,                      // use default stack size  
				f2M_threaded_run,       // thread function name
				data[i],	            // argument to thread function 
				0,                      // use default creation flags 
				&threadId[i]);   // returns the thread identifier 

			if (threadHandle[i] == NULL) 
			{
				ExitProcess(3);
			}
		} else {
			f2M_threaded_run((LPVOID)data[i]);
		}

		anns_start+=data[i]->ann_count;
		anns_count-=data[i]->ann_count;
		
	}

	WaitForMultipleObjects(threads-1, threadHandle, TRUE, INFINITE);

	for(int i=0; i<threads; i++)
    {
        CloseHandle(threadHandle[i]);
        if(data[i] != NULL)
        {
            HeapFree(GetProcessHeap(), 0, data[i]);
            data[i] = NULL;    // Ensure address is not reused.
        }
    }

	return(0);
}
#endif
void ErrorExit(LPTSTR lpszFunction) 
{ 
    // Retrieve the system error message for the last-error code

    LPVOID lpMsgBuf;
    LPVOID lpDisplayBuf;
    DWORD dw = GetLastError(); 

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );

    // Display the error message and exit the process

    lpDisplayBuf = (LPVOID)LocalAlloc(LMEM_ZEROINIT, 
        (lstrlen((LPCTSTR)lpMsgBuf) + lstrlen((LPCTSTR)lpszFunction) + 40) * sizeof(TCHAR)); 
    StringCchPrintf((LPTSTR)lpDisplayBuf, 
        LocalSize(lpDisplayBuf) / sizeof(TCHAR),
        TEXT("%s failed with error %d: %s"), 
        lpszFunction, dw, lpMsgBuf); 
    MessageBox(NULL, (LPCTSTR)lpDisplayBuf, TEXT("Error"), MB_OK); 

    LocalFree(lpMsgBuf);
    LocalFree(lpDisplayBuf);
    ExitProcess(dw); 
}
