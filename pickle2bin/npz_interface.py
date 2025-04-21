

import cffi
ffibuilder = cffi.FFI()

header = """
extern void npz_interface_qv_(float *cqv_mean,float *cqv_std,int *n1, char *fname);

"""
module = """
import sys
sys.path.append("/Users/mgrecu/PMMCCST/")
from my_plugin import ffi
import numpy as np


@ffi.def_extern()
def npz_interface_qv_(cqv_mean,cqv_std,n1,fname):
    print(n1[0])
    n1_py=n1[0]
    py_fname = ffi.string(fname).decode('utf-8')
    npz=np.load(py_fname)
    print(npz['mean'].shape)
    print(npz['std'].shape)
    qv_mean = np.frombuffer(ffi.buffer(cqv_mean,n1_py*4),np.dtype('f4')).reshape(n1_py)
    qv_std = np.frombuffer(ffi.buffer(cqv_std,n1_py*4),np.dtype('f4')).reshape(n1_py)
    qv_mean[:] = npz['mean']
    qv_std[:] = npz['std']
    #print(py_fname)
    
    


"""
with open("plugin.h", "w") as f:
    f.write(header)

ffibuilder.embedding_api(header)
ffibuilder.set_source("my_plugin", r'''
    #include "plugin.h"
''')

ffibuilder.embedding_init_code(module)
ffibuilder.compile(target="libmy_plugin.so", verbose=True)
