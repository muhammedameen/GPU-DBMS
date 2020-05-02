


#include "sql_truncate.cuh"

using namespace std;

#define invalidQuery(query) {utils::invalidQuery(query); return;}

void sql_truncate::execute(std::string &query) {
    utils::toLower(query);
    tokenizer t(query);
	string word;
	t >> word;
	if(word != "truncate")
		invalidQuery(query);
	t >> word;
	if(!utils::tableExists(word))
		invalidQuery(query);

	//delete files
	string dataFileName;
	dataFileName = utils::getDataFileName(word);
	remove(dataFileName.c_str());
	std::ofstream fout = ofstream(dataFileName);
    fout.close();
    return;
}

