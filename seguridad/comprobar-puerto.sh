echo "Netcat"
nc -zv 192.168.1.107 8001
echo "Telnet"
telnet 192.168.1.107 8001
echo "Curl"
curl -I http://192.168.1.107:8001
echo "Nmap"
nmap -p 8001 192.168.1.100
echo "Nmap sin ping"
nmap -p 8001 -Pn 192.168.0.107
