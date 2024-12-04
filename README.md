
### Find application output location
<pre>ls -l /proc/$pid/fd/0</pre>

### Find Pid
<pre>ps -aef | grep "$searchText" | awk '{print $2}')</pre>
<pre>pidof $process</pid>
