#include "stdlib.h"
#include "math.h"

#include <npy_array_list.h>
#include <stdlib.h>
#include <assert.h>

#pragma GCC diagnostic ignored "-Wmissing-field-initializers"

void onnx_retrieval_ku_f90_(float *z_ku_meas, int *p_type, int *bin_nodes, int *n_scans,
			    float *onnx_precip_rate, float *onnx_dm, 
			    float *near_surf_onnx_precip_rate, float *xlon, float *xlat,
			    int *n_batch,
			    int *n_seq,int * n_input, int *n_output);
  
void get_dprdata_c_loc_(float *zku,float *zka,int *rain_type,
			int *node, int *bin_sfc, float *freez_h, float *xlon, float *xlat);

void onnx_bridge(int ichunk, int orbnumber)
{
  float *zku, *zka;
  int *rain_type,*node, *bin_sfc;
  float *freez_h;
  char *fname;
  float *onnx_precip_rate, *onnx_dm, *near_surf_onnx_precip_rate;
  float *xlon, *xlat;
  printf("ichunk=%i iorb=%i\n",ichunk,orbnumber);
  zku=(float *) malloc(sizeof(float)*300*49*88);
  zka=(float *) malloc(sizeof(float)*300*49*88);
  rain_type=(int *)malloc(sizeof(int)*300*49);
  node=(int *)malloc(sizeof(int)*300*49*5);
  bin_sfc=(int *)malloc(sizeof(int)*300*49);
  freez_h=(float *)malloc(sizeof(float)*300*49);
  onnx_dm=(float *)malloc(sizeof(float)*300*49*88);
  onnx_precip_rate=(float *)malloc(sizeof(float)*300*49*88);
  near_surf_onnx_precip_rate=(float *)malloc(sizeof(float)*300*49);
  xlon=(float *)malloc(sizeof(float)*300*49);
  xlat=(float *)malloc(sizeof(float)*300*49);
  get_dprdata_c_loc_(zku,zka,rain_type,node,bin_sfc,freez_h, xlon, xlat);
  fname=(char *)malloc(sizeof(char)*100);
  int n_scans=300,n_batch=1,n_seq=72,n_input=2,n_output=2;
  onnx_retrieval_ku_f90_(zku, rain_type, node, &n_scans,
			 onnx_precip_rate, onnx_dm, 
			 near_surf_onnx_precip_rate, xlon, xlat, &n_batch,
			 &n_seq,&n_input,&n_output);
  
  sprintf(fname, "npy_tmp_dir/cmb_npy.%2.2i.%6.6i.npz", ichunk, orbnumber);
  printf("Filename: %s\n", fname);

  npy_array_list_t* list_var=NULL;
  list_var= npy_array_list_append(list_var, 
				  NPY_ARRAY_BUILDER_COPY( rain_type, SHAPE( 300, 49 ), NPY_DTYPE_INT32 ), "rain_type" );
  list_var= npy_array_list_append(list_var,
				  NPY_ARRAY_BUILDER_DEEPCOPY( zku, SHAPE( 300, 49, 88 ), NPY_DTYPE_FLOAT32 ), "zku" );
  list_var= npy_array_list_append(list_var, 
				  NPY_ARRAY_BUILDER_COPY( near_surf_onnx_precip_rate,
							  SHAPE( 300, 49 ), NPY_DTYPE_FLOAT32 ), "near_surface_onnx_precip_rate" );
  list_var= npy_array_list_append(list_var,
				  NPY_ARRAY_BUILDER_DEEPCOPY( xlon, SHAPE( 49, 88 ), NPY_DTYPE_FLOAT32 ), "lon" );

  list_var= npy_array_list_append(list_var,
				  NPY_ARRAY_BUILDER_DEEPCOPY( xlat, SHAPE( 49, 88 ), NPY_DTYPE_FLOAT32 ), "lat" );

  npy_array_list_save_compressed( fname, list_var, ZIP_CM_DEFAULT, 0 );
  npy_array_list_free(list_var);
  
  free(zku);
  free(zka);
  free(rain_type);
  free(node);
  free(bin_sfc);
  free(freez_h);
  free(near_surf_onnx_precip_rate);
  free(onnx_precip_rate);
  free(onnx_dm);
  free(xlon);
  free(xlat);
}
