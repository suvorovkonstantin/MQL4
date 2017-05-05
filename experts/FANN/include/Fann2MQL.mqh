/* Fann2MQL.mqh
 *
 * Copyright (C) 2008-2016 Mariusz Woloszyn
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

#property copyright "Mariusz Woloszyn"
#property link      "https://fann2mql.wordpress.com/"

#import "Fann2MQL.dll"

/* Creation/Execution */
int f2M_create_standard(int num_layers, int l1num, int l2num, int l3num, int l4num);
int f2M_destroy(int ann);
int f2M_destroy_all_anns();
int f2M_run(int ann, double& input_vector[]);
double f2M_get_output(int ann, int output);
int f2M_randomize_weights(int ann, double min_weight, double max_weight);
/* Creation/Execution Parameters */
int  f2M_get_num_input(int ann);
int  f2M_get_num_output(int ann);

/* Training */
int f2M_train(int ann, double& input_vector[], double& output_vector[]);
int f2M_train_fast(int ann, double& input_vector[], double& output_vector[]);
int f2M_test(int ann, double& input_vector[], double& output_vector[]);
double f2M_get_MSE(int ann);
int f2M_get_bit_fail(int ann);
int f2M_reset_MSE(int ann);
/* Training Parameters */
int f2m_get_training_algorithm(int ann);
int f2m_set_training_algorithm(int ann, int training_algorithm);
int f2M_set_act_function_layer(int ann, int activation_function, int layer);
int f2M_set_act_function_hidden(int ann, int activation_function);
int f2M_set_act_function_output(int ann, int activation_function);

/* Data training */
int f2M_train_on_file(int ann, char &filename[], int max_epoch, double desired_error);


/* File Input/Output */
int f2M_create_from_file(char &path[]);
int f2M_save(int ann, char &path[]);


/* Parallel processing functions */
int f2M_parallel_init();
int f2M_parallel_deinit();
int f2M_run_parallel(int anns_count, int& anns[], double& input_vector[]);
int f2M_train_parallel(int anns_count, int& anns[], double& input_vector[], double& output_vector[]);
#import

#define F2M_MAX_THREADS	64

#define FANN_DOUBLE_ERROR	-1000000000

#define FANN_LINEAR                     0
#define FANN_THRESHOLD	                1
#define FANN_THRESHOLD_SYMMETRIC        2
#define FANN_SIGMOID                    3
#define FANN_SIGMOID_STEPWISE           4
#define FANN_SIGMOID_SYMMETRIC          5
#define FANN_SIGMOID_SYMMETRIC_STEPWISE 6
#define FANN_GAUSSIAN                   7
#define FANN_GAUSSIAN_SYMMETRIC         8
#define FANN_GAUSSIAN_STEPWISE          9
#define FANN_ELLIOT                     10
#define FANN_ELLIOT_SYMMETRIC           11
#define FANN_LINEAR_PIECE               12
#define FANN_LINEAR_PIECE_SYMMETRIC     13
#define FANN_SIN_SYMMETRIC              14
#define FANN_COS_SYMMETRIC              15
#define FANN_SIN                        16
#define FANN_COS                        17

#define FANN_TRAIN_INCREMENTAL			0
#define FANN_TRAIN_BATCH				1
#define FANN_TRAIN_RPROP				2
#define FANN_TRAIN_QUICKPROP			3

/* Inline string versions of functions that were redefined due to unicode strings */
int f2M_create_from_file_string(string path) {
   uchar p[];
   StringToCharArray(path,p,0,-1,CP_ACP);
   int ret=f2M_create_from_file(p);
   return ret;
}
int f2M_save_string(int ann,string path) {
   uchar p[];
   StringToCharArray(path,p,0,-1,CP_ACP);
   int ret=f2M_save(ann,p);
   return ret;
}

int f2M_train_on_file_string(int ann, string filename, int max_epoch, double desired_error){
   uchar f[];
   StringToCharArray(filename,f,0,-1,CP_ACP);
   int ret=f2M_train_on_file(ann, f, max_epoch, desired_error);
   return ret;
}
