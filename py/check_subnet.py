import ipaddress
import sys

def same_subnet(ip_cidr, ip):
    ip_cidr_network = ipaddress.ip_network(ip_cidr, strict=False)
    return ipaddress.ip_address(ip) in ip_cidr_network

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("用法: python subnet_check.py <ip_cidr> <ip>")
        sys.exit(1)

    ip_cidr = sys.argv[1]
    ip = sys.argv[2]
    result = same_subnet(ip_cidr, ip)
    if result:
        print("检查通过, 不需要加 gwroute 选项")
    else:
        print("检查不通过，请注意在 dev_ip 中需要加上 'gwroute' => 'true' !")
