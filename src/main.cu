#include "CLI.cuh"
#include "Parser.cuh"
#include "deviceUtil.cuh"

//__global__ void testkernal(){
//    char str[20];
//    int size = appendInt(str, threadIdx.x);
//    int size2 = appendInt(str + size, threadIdx.x + 10);
//    str[size+size2] = '\0';
//    printf("%s", str);
//}

int main() {
    CLI interface;
    utils::loadTables();
    Parser parser;
    std::string query = interface.readLine();
    while (!query.empty()) {
        parser.parse(query);
        query = interface.readLine();
    }
    utils::writeDatabase();
    return 0;
}