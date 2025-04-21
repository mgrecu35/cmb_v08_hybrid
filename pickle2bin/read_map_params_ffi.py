import cffi
ffibuilder = cffi.FFI()
#call get_norm_param(scaler%tc,scaler%sfc_type,scaler%sk_temp,scaler%oe_wvp,&
#     scaler%near_sfc_precip,scaler%xenc,scaler%xenc_prec,scaler%xenv_enc,fname)

header = """
extern void get_norm_param_(float *tc,float *sfc_type,float *sk_temp,float *oe_wvp,float *near_sfc_precip,float *xenc,float *xenc_prec,float *xenv_enc,char *fname);

"""
module = """
import sys
sys.path.append("/Users/mgrecu/PMMCCST/")
from my_plugin import ffi
import numpy as np
import matplotlib.pyplot as plt

@ffi.def_extern()
def get_norm_param_(ctc,csfc_type,csk_temp,coe_wvp,cnear_sfc_precip,cxenc,cxenc_prec,cxenv_enc,fname):
    py_fname = ffi.string(fname).decode('utf-8')
    print(py_fname[:40])
    npz=np.load(py_fname[:40])
    tc= np.frombuffer(ffi.buffer(ctc,191100*4),np.dtype('f4')).reshape(13,49,150,2) #reshape(2,150,49,13)
    print(tc.shape)
    tc_py=npz['tc'].astype(np.dtype('f4'))
    tc[:]=tc_py.T
    print(npz['tc'].shape)
    sfc_type= np.frombuffer(ffi.buffer(csfc_type,14700*4),np.dtype('f4')).reshape(49,150,2)
    sfc_type_py=npz['sfc_type'].astype(np.dtype('f4'))
    sfc_type[:]=sfc_type_py.T
    sk_temp= np.frombuffer(ffi.buffer(csk_temp,14700*4),np.dtype('f4')).reshape(49,150,2)
    sk_temp_py=npz['sk_temp'].astype(np.dtype('f4'))
    sk_temp[:]=sk_temp_py.T
    oe_wvp= np.frombuffer(ffi.buffer(coe_wvp,14700*4),np.dtype('f4')).reshape(49,150,2)
    oe_wvp_py=npz['oe_wvp'].astype(np.dtype('f4'))
    plt.pcolormesh(oe_wvp_py[0,:,:].T)
    plt.show()
    oe_wvp[:]=oe_wvp_py.T
    near_sfc_precip= np.frombuffer(ffi.buffer(cnear_sfc_precip,14700*4),np.dtype('f4')).reshape(49,150,2)
    near_sfc_precip_py=npz['near_sfc_precip'].astype(np.dtype('f4'))
    near_sfc_precip[:]=near_sfc_precip_py.T
    xenc= np.frombuffer(ffi.buffer(cxenc,58800*4),np.dtype('f4')).reshape(4,49,150,2)
    xenc_py=npz['xenc'].astype(np.dtype('f4'))
    xenc[:]=xenc_py.T
    xenc_prec= np.frombuffer(ffi.buffer(cxenc_prec,88200*4),np.dtype('f4')).reshape(6,49,150,2)
    xenc_prec_py=npz['xenc_prec'].astype(np.dtype('f4'))
    xenc_prec[:]=xenc_prec_py.T
    xenv_enc= np.frombuffer(ffi.buffer(cxenv_enc,58800*4),np.dtype('f4')).reshape(4,49,150,2)
    xenv_enc_py=npz['xenv_enc'].astype(np.dtype('f4'))
    #boo
    xenv_enc[:]=xenv_enc_py.T


"""
with open("plugin.h", "w") as f:
    f.write(header)

ffibuilder.embedding_api(header)
ffibuilder.set_source("my_plugin", r'''
    #include "plugin.h"
''')

ffibuilder.embedding_init_code(module)
ffibuilder.compile(target="libmy_plugin_2d.so", verbose=True)
