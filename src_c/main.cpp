#include <iostream>
#include "cppflow/ops.h"
#include "cppflow/model.h"
#include <vector>
#include <tensorflow/c/tf_tensor.h>
using namespace std;
// g++ -std=c++17 -I /Users/mgrecu/libtensorflow2/include/ -I /Users/mgrecu/cppflow/include/ main.cpp  -L /Users/mgrecu/libtensorflow2/lib/ -ltensorflow
#include <stdio.h>
#include <time.h>
#include <ctime>

int main() {
  vector<vector<float>> vec;
  vector<float> vec1;
  vector<int64_t> ishape={9999,15,2};
  time_t time1,time2;
  double seconds=0;
  FILE *fout;

  fout=fopen("mlData.txt","r");
  
  cppflow::model model("my_model");
  for(int i=0;i<9999;i++)
    {
      float dum1, dum2, dum3, dum4, dum5, dum6;
      for(int j=0;j<15;j++)
	{
	  fscanf(fout,"%g %g %g %g %g %g",&dum1, &dum2, &dum3, &dum4, &dum5, &dum6);
	  vec1.push_back(dum1);
	  vec1.push_back(dum2);
	}
    }
      //time1 = time(NULL);
  auto start = chrono::steady_clock::now();
  
  cppflow::tensor input = cppflow::tensor(vec1,ishape);
  // do some stuff here
  
  auto end = chrono::steady_clock::now();
  //time2 = time(NULL);  /* get current time; same as: timer = time(NULL)  */
  seconds += chrono::duration_cast<chrono::microseconds>(end - start).count();
  
  vec1.clear();
  cppflow::tensor output = model(input);
  vector<float> vecout=output.get_data<float>();
  auto outshape=output.shape();
  //std::cout<<vecout[29]<<' ';
  //std::cout<<dum6<<std::endl;
  std::cout<<seconds/1000.0<<std::endl;
  for(int i=0;i<9999;i++)
    std::cout<<vecout[i*15]<<std::endl;
  return 0;
}
