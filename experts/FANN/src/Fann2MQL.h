/* Fann2MQL.h
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

// The following ifdef block is the standard way of creating macros which make exporting 
// from a DLL simpler. All files within this DLL are compiled with the FANN2MQL_EXPORTS
// symbol defined on the command line. this symbol should not be defined on any project
// that uses this DLL. This way any other project whose source files include this file see 
// FANN2MQL_API functions as being imported from a DLL, whereas this DLL sees symbols
// defined with this macro as being exported.
#ifdef FANN2MQL_EXPORTS
#define FANN2MQL_API __declspec(dllexport)
#else
#define FANN2MQL_API __declspec(dllimport)
#endif

/* maximum number of concurrently handled networks */
#define ANNMAX	1024

/* indicates an error if returned by a function returning double */
#define DOUBLE_ERROR	-100000000

/* maximum number of concurrent threads */
#define F2M_MAX_THREADS	64

typedef struct rTD {
	int ann_start;
	int ann_count;
	int* anns;
	double * input_vector;
	int ret;
	HANDLE mutexH;
	DWORD threadId;
} runThreadedData;


/* array of FANN network structures */
extern struct fann *_fanns[ANNMAX];
/* array of output values of networks */
extern double* _outputs[ANNMAX];
/* index to last allocated network */
extern int _ann;

/* Creation/Execution */
FANN2MQL_API int __stdcall f2M_create_standard(unsigned int num_layers, int l1num, int l2num, int l3num, int l4num);
FANN2MQL_API int __stdcall f2M_destroy(int ann);
FANN2MQL_API int __stdcall f2M_destroy_all_anns();
FANN2MQL_API int __stdcall f2M_run(int ann, double *input_vector);
FANN2MQL_API double __stdcall f2M_get_output(int ann, int output);
FANN2MQL_API int __stdcall f2M_randomize_weights(int ann, double min_weight, double max_weight);
/* Parameters */
FANN2MQL_API int __stdcall f2M_get_num_input(int ann);
FANN2MQL_API int __stdcall f2M_get_num_output(int ann);


/* Training */
FANN2MQL_API int __stdcall f2M_train(int ann, double *input_vector, double *output_vector);
FANN2MQL_API int __stdcall f2M_train_fast(int ann, double *input_vector, double *output_vector);
FANN2MQL_API int __stdcall f2M_test(int ann, double *input_vector, double *output_vector);
FANN2MQL_API double __stdcall f2M_get_MSE(int ann);
FANN2MQL_API int __stdcall f2M_get_bit_fail(int ann);
FANN2MQL_API int __stdcall f2M_reset_MSE(int ann);
/* Parameters */
FANN2MQL_API int __stdcall f2m_get_training_algorithm(int ann);
FANN2MQL_API int __stdcall f2m_set_training_algorithm(int ann, int training_algorithm);

FANN2MQL_API int __stdcall f2M_set_act_function_layer(int ann, int activation_function, int layer);
FANN2MQL_API int __stdcall f2M_set_act_function_hidden(int ann, int activation_function);
FANN2MQL_API int __stdcall f2M_set_act_function_output(int ann, int activation_function);


/* Data training */
FANN2MQL_API int __stdcall f2M_train_on_file(int ann, char *filename, unsigned int max_epoch, float desired_error);
/* Data manipulation */
/* ... */

/* File Input/Output */
FANN2MQL_API int __stdcall f2M_create_from_file(char *path);
FANN2MQL_API int __stdcall f2M_save(int ann, char *path);





#if 0
/* Threaded functions */
FANN2MQL_API int __stdcall f2M_threads_init(int num_threads);
FANN2MQL_API int __stdcall f2M_threads_deinit();
FANN2MQL_API int __stdcall f2m_run_threaded(int anns_count, int anns[], double *input_vector);
#endif 

#if 0
// This class is exported from the Fann2MQL.dll
class FANN2MQL_API CFann2MQL {
public:
	CFann2MQL(void);
	// TODO: add your methods here.
};

extern FANN2MQL_API int nFann2MQL;

FANN2MQL_API int fnFann2MQL(void);
#endif