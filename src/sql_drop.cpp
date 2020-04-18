


#include "sql_drop.h"
using namespace std;
#define invalidQuery(query) {utils::invalidQuery(query); return;}

void sql_drop::execute(std::string &query) {
    utils::toLower(query);
    tokenizer t(query);
	string word;
	t >> word;
	if(word != "drop")
		invalidQuery(query);
	t >> word;
	if(!utils::tableExists(word))
		invalidQuery(query);

	//drop table from Database
	utils::dropTable(word);
	//delete files
	string data_file;
	string mdata_file;
	data_file = utils::getDataFileName(word);
	mdata_file = utils::getMetadataFileName(word);
	remove(data_file.c_str());
	remove(mdata_file.c_str());
    return;
}

