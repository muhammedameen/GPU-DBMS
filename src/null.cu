//
// Created by ameen on 09/05/20.
//

#include "null.cuh"

__device__ bool isNull(int *i){
    return *i == INT_MIN;
}

__device__ bool isNull(char *data){
    int i = 0;
    while (data[i] == 127) ++i;
    return data[i] == 0;
}

__device__ bool isNull(float *f){
    return isnan(*f);
}

__device__ int getNullInt(){
    return INT_MIN;
}

__device__ float getNullFlt(){
    return NAN;
}

__device__ void getNullStr(char *data, int size){
    int i=0;
    while(i < size-1){
        data[i] = 127;
        i++;
    }
    data[size-1] = 0;
}
