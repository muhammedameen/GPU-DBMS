cmake_minimum_required(VERSION 3.13)

project(dbase CUDA)

set(CMAKE_CUDA_STANDARD 14)

set(CMAKE_CXX_STANDARD 14)
#set(CMAKE_CXX_COMPILER /usr/bin/g++-8)

file(GLOB parser_src_parser_source
        "sql-parser/src/parser/*.h"
#        "sql-parser/src/parser/*.cpp"
        )
#
file(GLOB parser_src_sql_source
        "sql-parser/src/sql/*.h"
#        "sql-parser/src/sql/*.cpp"
        )

add_executable(dbase src/main.cu
        src/sql_create.cu src/sql_create.cuh
        src/CLI.cu src/CLI.cuh
        src/utils.cu src/utils.cuh
        src/Parser.cu src/Parser.cuh
        src/Metadata.cu src/Metadata.cuh
        src/sql_drop.cu src/sql_drop.cuh
        src/tokenizer.cu src/tokenizer.cuh
        src/sql_truncate.cu src/sql_truncate.cuh

#        sql-parser/src/sqlhelper.cpp
        sql-parser/src/sqlhelper.h
#        sql-parser/src/SQLParser.cpp
        sql-parser/src/SQLParser.h
#        sql-parser/src/SQLParserResult.cpp
        sql-parser/src/SQLParserResult.h
        ${parser_src_parser_source}
        ${parser_src_sql_source}

        src/sql_select.cu src/sql_select.cuh
        src/myExpr.cuh src/myExpr.cu
        src/deviceUtil.cu src/deviceUtil.cuh
        src/Data.cu src/Data.cuh
        src/sql_insert.cu src/sql_insert.cuh src/ColType.cu src/ColType.cuh src/errorHandler.cuh src/sql_update.cu src/sql_update.cuh src/sql_delete.cu src/sql_delete.cuh src/external_sort.cu src/external_sort.cuh)

target_link_libraries(dbase "${CMAKE_HOME_DIRECTORY}/sql-parser/libsqlparser.so")

set_target_properties(
        dbase
        PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON
)


#cmake_minimum_required(VERSION 3.13)
#
#project(dbase)
#
#set(CMAKE_CXX_STANDARD 14)
#
#file(GLOB parser_src_parser_source
#        "sql-parser/src/parser/*.h"
#        "sql-parser/src/parser/*.cpp"
#        )
#
#file(GLOB parser_src_sql_source
#        "sql-parser/src/sql/*.h"
#        "sql-parser/src/sql/*.cpp"
#        )
#
#add_executable(dbase src/main.cpp
#        src/sql_create.cpp src/sql_create.h
#        src/CLI.cpp src/CLI.h
#        src/utils.cpp src/utils.h
#        src/Parser.cpp src/Parser.h
#        src/Metadata.cpp src/Metadata.h
#        src/sql_drop.cpp src/sql_drop.h
#        src/tokenizer.cpp src/tokenizer.h
#        src/sql_truncate.cpp src/sql_truncate.h
#        sql-parser/src/sqlhelper.cpp sql-parser/src/sqlhelper.h
#        sql-parser/src/SQLParser.cpp sql-parser/src/SQLParser.h
#        sql-parser/src/SQLParserResult.cpp sql-parser/src/SQLParserResult.h
#        ${parser_src_parser_source}
#        ${parser_src_sql_source}
#        src/sql_select.cpp src/sql_select.h src/myExpr.h src/myExpr.cpp src/deviceUtil.cpp src/deviceUtil.h src/Data.cpp src/Data.h src/sql_insert.cpp src/sql_insert.h)
#
