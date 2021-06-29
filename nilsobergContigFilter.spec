/*
A KBase module: nilsobergContigFilter
This sample module contains one small method that filters contigs.
*/

module nilsobergContigFilter {
    typedef structure {
        string report_name;
        string report_ref;
    } ReportResults;

    /*
        This example function accepts any number of parameters and returns results in a KBaseReport
    */
    funcdef run_nilsobergContigFilter(mapping<string,UnspecifiedObject> params) returns (ReportResults output) authentication required;

    funcdef run_nilsobergContigFilter_max(mapping<string,UnspecifiedObject> params) returns (ReportResults output) authentication required;

};
