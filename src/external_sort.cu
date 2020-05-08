//
// Created by gautam on 08/05/20.
//

#include "external_sort.cuh"

void external_sort::sort(Data &data, std::vector<std::string> &colNames) {

    std::vector<int> cols(colNames.size());
    for (int i = 0; i < colNames.size(); ++i) {
        cols[i] = data.mdata.colMap[colNames[i]];
    }

    int *cols_d;
    cudaMalloc(&cols_d, sizeof(int) * cols.size());
    cudaMemcpy(cols_d, &cols[0], sizeof(int) * cols.size(), cudaMemcpyHostToDevice);

    void *chunk = malloc(data.mdata.rowSize * data.chunkSize);

    cudaFree(cols_d);
}
