# solar-tracker
Tracking the performance of my photovoltaic installation

My inverter has a logger on it. The logger provides a "push service" that sends http POST requests to URLs I can choose.

There waits a Perl Mojo server saving information to an rrdtool. Also, it displays graphs on request.

As an example, the push service sends an HTTP POST ever 10 seconds to
192.168.1.100/infeed.
The server has two endpoints.
/infeed
    saves the data
/
    displays the graphs.

