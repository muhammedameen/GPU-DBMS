//
// Created by gautam on 08/05/20.
//

#ifndef DBASE_EXTERNAL_SORT_CUH
#define DBASE_EXTERNAL_SORT_CUH


#include "Data.cuh"
#include "deviceUtil.cuh"

class external_sort {
public:
    static void sort(Data &data, std::vector<std::string> &cols);
};


#endif //DBASE_EXTERNAL_SORT_CUH
