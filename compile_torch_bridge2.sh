gfortran -c -fPIC scaler_def.f90
gcc -fPIC -shared -o libonnx_c.so -I onnxruntime-osx-arm64-1.20.1/include/ onnx_gen_interface.c scaler_def.o onnxruntime-osx-arm64-1.20.1/lib/libonnxruntime.dylib -L/Users/mgrecu/miniforge3/lib -lgfortran

python -m numpy.f2py -c -I/Users/mgrecu/PMMCCST/ -L/Users/mgrecu/PMMCCST/  -m onnx_f90 onnx_interface.f90 test_onnx.f90 -lonnx_c

