# solar-tracker
Tracking the performance of my photovoltaic installation

My inverter has a logger on it. The logger provides a "push service" that sends http POST requests to URLs I can choose.

There waits a Perl Mojo server saving information to an rrdtool. Also, it displays graphs on request.

As an example, the push service sends an HTTP POST ever 10 seconds to
192.168.1.100/infeed.
The server has two endpoints. "/infeed" saves the data and "/" displays the graphs.

Note: In "raw_data" there is output from the logger written directly to files. This is done for development / debugging reasons. Everything could be done in rrdtool. The data you find in "raw_data" is sample data to give an idea.
