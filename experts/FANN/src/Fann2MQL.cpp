/* Fann2MQL.cpp
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
#include "doublefann.h"
#include "fann_internal.h"
#include "windows.h"
#include "Fann2MQL.h"



#define F2M_MAX_THREADS	64

/* array of FANN network structures */
struct fann *_fanns[ANNMAX];
/* array of output values of networks */
double* _outputs[ANNMAX];
/* index to last allocated network */
int _ann=-1;

/* Creates a standard fully connected backpropagation neural network.
 *  num_layers - The total number of layers including the input and the output layer.
 *  l1num - number of neurons in 1st layer (inputs)
 *  l2num, l3num, l4num - number of neurons in hidden and output layers (depending on num_layers).
 * Returns:
 *	handler to ann, -1 on error
 */
FANN2MQL_API int __stdcall f2M_create_standard(unsigned int num_layers, int l1num, int l2num, int l3num, int l4num)
{
	/* to many networks allocated */
	if (_ann>=ANNMAX) return (-1);

	/* not accepting bogus arguments */
	if (l1num < 1 || l2num < 1 || l3num < 1 || l4num < 1 || num_layers < 2) return (-1);

	/* allocate the handler for ann */
	_ann++;		// XXX: rather simple allocation at the moment ;)

	_fanns[_ann]=fann_create_standard(num_layers, l1num, l2num, l3num, l4num);
	if (_fanns[_ann]==NULL) {
		/* fann_create_standard returned an error */
		_ann--;
		return (-1);
	} else {
		/* initialize _outputs[] just in case... */
		_outputs[_ann]=NULL;
		return (_ann);
	}
}

/* Destroy fann network
 *  ann - network handler returned by f2M_create*
 * Returns:
 *  0 on success -1 on error
 * WARNING: the ann handlers cannot be reused if ann!=(_ann-1)
 * Other handlers are reusable only after the last ann is destroyed.
 */
FANN2MQL_API int __stdcall f2M_destroy(int ann)
{
	int i, last_null=_ann-1;

	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	/* destroy */
	fann_destroy(_fanns[ann]);

	/* clear the pointers */
	_fanns[ann]=NULL;
	_outputs[ann]=NULL;

	/* let reuse the handlers if last */
	if (ann==_ann) {
		_ann--;

		/* look if we can recover any more handlers */
		for (i=_ann; i>-1; i--) {
			if (_fanns[i]==NULL) {
				_ann--;
			} else {
				break;
			}
		}
	}

	return 0;
}

/* Destroy all fann networks
 * Returns:
 *  0 on success -1 on error
 */
FANN2MQL_API int __stdcall f2M_destroy_all_anns()
{
	int i;

	for (i=0; i<_ann; i++) {
		/* destroy */
		if (_fanns[i]!=NULL) fann_destroy(_fanns[i]);
		/* clear the pointers */
		_fanns[i]=NULL;
		_outputs[i]=NULL;
	}
	/* initialize anns counter */
	_ann=-1;

	return 0;
}

/* Run fann network
 *  ann - network handler returned by f2M_create*
 *  *input_vector - arrary of inputs
 * Returns:
 *  0 on success, negative value on error
 * Note:
 *  To obtain network output use f2M_get_output().
 *  Any existing output is overwritten
 */
FANN2MQL_API int __stdcall f2M_run(int ann, double *input_vector)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return -2;

	/* the input vector is empty */
	if (input_vector==NULL) return -3;

	/* run and return */
	_outputs[ann]=fann_run(_fanns[ann], input_vector);
	if (_outputs[ann]==NULL) return -4;
	return 0;
}

/* Return an output vector from a given network
 *  ann - network handler returned by f2M_create*
 *  output - output vector number, 0 means first output and so on...
 * Returns:
 *  value calculated by network, on error DOUBLE_ERROR is returned
 */
FANN2MQL_API double __stdcall f2M_get_output(int ann, int output)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return DOUBLE_ERROR;
	
	/* this network has no output */
	if (_outputs[ann]==NULL) return DOUBLE_ERROR;

	/* this network has no such output vector */
	if (output>=f2M_get_num_output(ann)) return DOUBLE_ERROR;

	return _outputs[ann][output];

}

/* Give each connection a random weight between min_weight and max_weight
 *  ann - network handler returned by f2M_create*
 *  min_weight - minimum weight
 *  max_weight - maximum weight
 * Returns:
 *  0 on success, -1 on error
 */
FANN2MQL_API int __stdcall f2M_randomize_weights(int ann, double min_weight, double max_weight)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	fann_randomize_weights(_fanns[ann], min_weight, max_weight);

	return 0;
}

/* Returns the number of ann inputs
 *  ann - network handler returned by f2M_create*
 */
FANN2MQL_API int __stdcall f2M_get_num_input(int ann)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);
	
	return fann_get_num_input(_fanns[ann]);
}

/* Returns the number of ann outputs
 *  ann - network handler returned by f2M_create*
 */
FANN2MQL_API int __stdcall f2M_get_num_output(int ann)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);
	
	return fann_get_num_output(_fanns[ann]);
}

/* Train one iteration with a set of inputs, and a set of desired outputs.
 * This training is always incremental training, since only one pattern is presented.
 *  ann - network handler returned by f2M_create*
 *  *input_vector - arrary of inputs
 *  *output_vector - arrary of outputs
 * Returns:
 *  0 on success and -1 on error
 */
FANN2MQL_API int __stdcall f2M_train(int ann, double *input_vector, double *output_vector)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	/* the input or output vector is empty */
	if (input_vector==NULL || output_vector==NULL) return -1;

	fann_train(_fanns[ann], input_vector, output_vector);
	return (0);
}

/* Train one iteration with a set of inputs, and a set of desired outputs.
 * The trick is to call internal fann functions and avoid the call to fann_run() inside fann_train().
 *  ann - network handler returned by f2M_create*
 *  *input_vector - arrary of inputs // Not used; You need to make sure that fann_run() was called on this input before.
 *  *output_vector - arrary of outputs
 * Returns:
 *  0 on success and -1 on error
 */
FANN2MQL_API int __stdcall f2M_train_fast(int ann, double *input_vector, double *output_vector)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	/* the input or output vector is empty */
	if (input_vector==NULL || output_vector==NULL) return -1;

	//fann_train(_fanns[ann], input_vector, output_vector);
	fann_compute_MSE(_fanns[ann], output_vector);
	fann_backpropagate_MSE(_fanns[ann]);
	fann_update_weights(_fanns[ann]);

	return (0);
}

/* Test with a set of inputs, and a set of desired outputs.
 * This operation updates the mean square error, but does not change the network in any way.
 *  ann - network handler returned by f2M_create*
 *  *input_vector - arrary of inputs
 *  *output_vector - arrary of outputs
 * Returns:
 *  0 on success, -1 on error
 * Note:
 *  To obtain network output use f2M_get_output()
 */
FANN2MQL_API int __stdcall f2M_test(int ann, double *input_vector, double *output_vector)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return -1;

	/* the input or output vector is empty */
	if (input_vector==NULL || output_vector==NULL) return -1;

	/* run and return */
	_outputs[ann]=fann_test(_fanns[ann], input_vector,output_vector);
	if (_outputs[ann]==NULL) return -1;
	return 0;
}

/* Return mean square error of the network
 *  ann - network handler returned by f2M_create*
 * Returns:
 *  MSE or -1 on error
 */
FANN2MQL_API double __stdcall f2M_get_MSE(int ann)
{
	double mse;

	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	mse=(double) fann_get_MSE(_fanns[ann]);

	return mse;
}

/* Returns number of fail bits; means the number of output neurons which differ more than the bit fail limit
 * (see f2M_get_bit_fail_limit, f2M_set_bit_fail_limit).  The bits are counted in all of the training data,
 * so this number can be higher than the number of training data.
 * This value is reset by fann_reset_MSE and updated by all the same functions which also updates
 * the MSE value (e.g.  f2M_test_data, f2M_train_epoch)
 *
 */
FANN2MQL_API int __stdcall f2M_get_bit_fail(int ann)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	return (fann_get_bit_fail(_fanns[ann]));
}

/* Reset mean square error of the network
 *  ann - network handler returned by f2M_create*
 * Returns:
 *  0 or <0 on error
 */
FANN2MQL_API int __stdcall f2M_reset_MSE(int ann)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	fann_reset_MSE(_fanns[ann]);

	return 0;
}

/* Returns the training algorithm. This training algorithm is used by f2m_Train_on_file.
 * The default training algorithm is FANN_TRAIN_RPROP.
 * Returns:
 *  0 or <0 on error
 */
FANN2MQL_API int __stdcall f2M_get_training_algorithm(int ann)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);
	
	return (fann_get_training_algorithm(_fanns[ann]));
}

/* Set the training algorithm.
 * Returns:
 *  0 or <0 on error
 */
FANN2MQL_API int __stdcall f2M_set_training_algorithm(int ann, int training_alorithm)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);
	
	fann_set_training_algorithm(_fanns[ann], (fann_train_enum) training_alorithm);

	return (0);
}


/* Set the activation function for all the neurons in the layer number layer, counting the input layer as layer 0.
 * It is not possible to set activation functions for the neurons in the input layer.
 *  ann - network handler returned by f2M_create*
 *  activation_function - activation function
 *  layer - layer number
 * Returns:
 *  0 on success, -1 on error
 */
FANN2MQL_API int __stdcall f2M_set_act_function_layer(int ann, int activation_function, int layer)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return -1;

	fann_set_activation_function_layer(_fanns[ann],(fann_activationfunc_enum)activation_function, layer);

	return 0;
}

/* Set the activation function for all of the hidden layers.
 *  ann - network handler returned by f2M_create*
 *  activation_function - activation function
 * Returns:
 *  0 on success, -1 on error
 */
FANN2MQL_API int __stdcall f2M_set_act_function_hidden(int ann, int activation_function)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return -1;

	fann_set_activation_function_hidden(_fanns[ann],(fann_activationfunc_enum)activation_function);

	return 0;
}

/* Set the activation function for the output layer.
 *  ann - network handler returned by f2M_create*
 *  activation_function - activation function
 * Returns:
 *  0 on success, -1 on error
 */
FANN2MQL_API int __stdcall f2M_set_act_function_output(int ann, int activation_function)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return -1;

	fann_set_activation_function_output(_fanns[ann],(fann_activationfunc_enum)activation_function);

	return 0;
}

/* Trains on a data from file, for a period of time.
 * This training uses the training algorithm chosen by 
 * f2M_set_training_algorithm, and the parameters set for these training algorithms.
 *  ann - network handler returned by f2M_create*
 *  filename - filename of data file
 *  max_epochs - The maximum number of epochs the training should continue
 *  desired_error - The desired f2M_get_MSE or f2M_get_bit_fail, depending on which stop function
 *  is chosen by fann_set_train_stop_function.
 * Returns:
 *  0 on success and <0 on error
 */

FANN2MQL_API int __stdcall f2M_train_on_file(int ann, char *filename, unsigned int max_epoch, float desired_error)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	fann_train_on_file(_fanns[ann], filename, max_epoch, 0, desired_error);
	return (0);
}

/* Load fann ann from file
 *	path - path to .net file
 * Returns:
 *	handler to ann, -1 on error
 */
FANN2MQL_API int __stdcall f2M_create_from_file(char *path)
{	
	/* too many networks allocated */
	if (_ann>=ANNMAX) return (-1);
	
	/* allocate the handler for ann */
	_ann++;		// XXX: rather simple allocation at the moment ;)

	_fanns[_ann]=fann_create_from_file(path);
	if (_fanns[_ann]==NULL) {
		/* fann_create_from_file returned an error */
		_ann--;
		return (-1);
	} else {
		/* initialize _outputs[] just in case... */
		_outputs[_ann]=NULL;
		return (_ann);
	}
}

/* Save the entire network to a configuration file.
 *  ann - network handler returned by f2M_create*
 * Returns:
 *  0 on success and -1 on failure
 */
FANN2MQL_API int __stdcall f2M_save(int ann, char *path)
{
	/* this network is not allocated */
	if (ann<0 || ann>_ann || _fanns[ann]==NULL) return (-1);

	return fann_save(_fanns[ann], path);
}

#if 0
// This is an example of an exported variable
FANN2MQL_API int nFann2MQL=0;

// This is an example of an exported function.
FANN2MQL_API int fnFann2MQL(void)
{
	return 42;
}

// This is the constructor of a class that has been exported.
// see Fann2MQL.h for the class definition
CFann2MQL::CFann2MQL()
{
	return;
}
#endif