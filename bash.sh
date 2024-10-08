# #!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 <numClients> <loopNum> <sleepTimeSeconds>"
    exit 1
fi

numClients=$1
loopNum=$2
sleepTime=$3

# Create an array to store individual throughputs
throughputs=()

# Start multiple clients in the background
for ((i = 1; i <= $numClients; i++)); do
    ./client 127.0.0.1:5500 source_code1.cpp $loopNum $sleepTime > client_$i.txt &
    #pids+=("$!")
done
wait

totalRequests=0
totalTime=0

# Calculate total requests and total time
for ((i = 1; i <= $numClients; i++)); do
    # Parse client log file to extract total requests and total time
    requests_i=$(grep "Number of Successful Responses" client_$i.txt | awk '{print $5}')
    time_i=$(grep "Average Response Time" client_$i.txt | awk '{print $4}')
    #echo $time_i
    # Accumulate values for all clients
    totalRequests=`expr $totalRequests + $requests_i`
    totalTime=$(echo "scale=3; $totalTime + $time_i" | bc)
    
    # Calculate throughput for client i
    throughput_i=$(echo "scale=3; $requests_i / $time_i" | bc)
    throughput_i=$(echo "scale=3; $throughput_i / $requests_i" | bc)
    throughputs+=($throughput_i)
done

#Calculate overall throughput as the sum of individual throughputs
overallThroughput=0
for throughput in "${throughputs[@]}"; do
    overallThroughput=$(echo "$overallThroughput + $throughput" | bc)
done

overallThroughput=$(echo "scale=3; $overallThroughput / $numClients" | bc)

#Calculate average response time
totalResponseTime=0
totalResponses=0

for ((i = 1; i <= $numClients; i++)); do
    responseTime_i=$(grep "Average Response Time" client_$i.txt | awk '{print $4}')
    responses_i=$(grep "Number of Successful Responses" client_$i.txt | awk '{print $5}')

    totalResponseTime=$(echo "$totalResponseTime + ($responseTime_i * $responses_i)" | bc)
    totalResponses=$(($totalResponses + $responses_i))
done
    
averageResponseTime=$(echo "scale=3; $totalResponseTime / $totalResponses" | bc)

echo "Overall Throughput: $overallThroughput requests/second" >> output.txt
echo "Average Response Time: $averageResponseTime seconds" >> output.txt
