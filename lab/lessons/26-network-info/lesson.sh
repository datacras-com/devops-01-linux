# Sessiya 26 — Şəbəkə məlumatı (hostname, ip a, ip r, ping, curl, wget)
lab_init 26 "Şəbəkə məlumatı: IP, route, ping, curl"

objective \
  "serverin host adını və IP ünvanlarını (ip a, hostname -I) tapmağı" \
  "routing cədvəlindən default gateway-i oxumağı (ip r)" \
  "ping -c ilə əlçatanlığı yoxlamağı və nəticəni oxumağı" \
  "curl və wget ilə HTTP servisin cavab verdiyini yoxlamağı"

concept "Şəbəkə problemini necə daraltmaq olar?" \
  "Qayda: yuxarıdan aşağı gedin. 1) Mənim IP-m var? (ip a)  2) Gateway var? (ip r)  3) Hədəf əlçatandır? (ping)  4) Servis cavab verir? (curl)." \
  "ifconfig köhnədir (net-tools); müasir Linux-da ip a / ip r istifadə olunur." \
  "ping ICMP istifadə edir; bəzi firewall-lar onu bağlayır, ona görə ping yoxdursa servis də yoxdur demək olmaz, curl ilə yoxlayın."

prep 'for c in ip ping curl wget python3; do command -v $c >/dev/null || NEED=1; done; [ -z "$NEED" ] || { sudo apt-get update -qq && sudo apt-get install -y -qq iproute2 iputils-ping curl wget python3; }'
cleanup "[ -f $LAB_WORK/srv.pid ] && kill \$(cat $LAB_WORK/srv.pid); true"

step "Host adı" \
  --why "Log, monitoring və Ansible/K8s serveri adı ilə tanıyır. Düzgün serverdə olduğunuzu təsdiqləyin." \
  --cmd 'hostname; cat /etc/hostname 2>/dev/null || true; hostname -f 2>/dev/null || true' \
  --explain "hostname|serverin adı" \
  --explain "/etc/hostname|adın daimi saxlandığı fayl" \
  --explain "hostname -f|tam (FQDN) ad, əgər həll olunursa" \
  --expect "Server adı (konteynerdə qısa hex ID)" \
  --note "Production-da hostname dəyişməyin: DNS və monitoring qeydləri pozula bilər. Daimi dəyişmə: hostnamectl set-hostname (systemd lazımdır)." \
  --assert '[ -n "$(hostname)" ]'

step "IP ünvanları: ip a və hostname -I" \
  --why "'Serverin IP-si nədir?' — bağlantı, firewall qaydası və DNS qeydi üçün ilk məlumat." \
  --cmd 'ip a | grep -E "^[0-9]+:|inet "; echo "---"; ip -br a; echo "---"; hostname -I' \
  --explain "ip a|bütün interfeyslər və ünvanlar (address)" \
  --explain "inet|IPv4 ünvanı (inet6 = IPv6)" \
  --explain "ip -br a|qısa (brief) cədvəl: interfeys, vəziyyət, ünvan" \
  --explain "hostname -I|yalnız IP-lər, skript üçün rahat" \
  --expect "lo (127.0.0.1) və əsas interfeys (eth0) IP ilə" \
  --note "lo loopback-dir (127.0.0.1, yalnız bu maşın). eth0/ens5 isə real şəbəkə IP-sidir. UP vəziyyəti interfeysin aktiv olduğunu göstərir." \
  --assert 'ip a | grep -q "127.0.0.1"'

step "Routing cədvəli: ip r" \
  --why "Paket hara gedir? Default gateway yoxdursa server internetə çıxa bilməz." \
  --cmd 'ip r; echo "---"; ip r | grep default || echo "default route yoxdur"; echo "---"; ip r get 127.0.0.1' \
  --explain "ip r|routing cədvəli" \
  --explain "default via X|hədəf cədvəldə yoxdursa paket gateway X-ə göndərilir" \
  --explain "ip r get IP|konkret IP üçün hansı yol seçilir" \
  --expect "default via <gateway> dev eth0 və lokal şəbəkə sətri" \
  --predict "10.40.5.9 ünvanı cədvəldəki lokal şəbəkədə deyilsə paket hara gedəcək?" \
  --note "Cavab: default gateway-ə. Bulud mühitində (VPC) gateway adətən subnetin .1 ünvanıdır." \
  --assert 'ip r | grep -q .'

step "Ping: əlçatanlıq" \
  --why "Database/API serveri əlçatandırmı? Ən sürətli ilk yoxlama." \
  --cmd 'ping -c 3 127.0.0.1; echo "---"; ping -c 2 -W 2 8.8.8.8 || echo "8.8.8.8 əlçatan deyil (firewall və ya internet yoxdur)"' \
  --explain "-c 3|3 paket göndər və dayan (olmasa ping sonsuza qədər davam edir)" \
  --explain "-W 2|cavabı 2 saniyə gözlə" \
  --explain "packet loss, rtt|itirilən paket faizi və orta gecikmə (ms)" \
  --expect "127.0.0.1: 0% packet loss; 8.8.8.8 internet varsa cavab verir" \
  --note "0% loss yaxşıdır, 100% loss — hədəf yoxdur, marşrut/firewall problemi var. rtt avg gecikmənin göstəricisidir." \
  --assert 'ping -c 1 127.0.0.1 | grep -q "1 received"' \
  --allow-fail

step "Lokal HTTP servis qaldır (yoxlama üçün)" \
  --why "curl və wget-i təhlükəsiz sınamaq üçün öz maşınımızda kiçik veb server qaldırırıq (python3 -m http.server)." \
  --cmd 'mkdir -p site; echo "<h1>deploy ok</h1>" > site/index.html; echo "v1.0.3" > site/version.txt
cd site; python3 -m http.server 18080 --bind 127.0.0.1 >../srv.log 2>&1 & echo $! > ../srv.pid; cd ..
sleep 1; ls site; echo "server PID=$(cat srv.pid)"' \
  --explain "python3 -m http.server 18080|cari qovluğu 18080 portunda HTTP ilə paylaşır" \
  --explain "--bind 127.0.0.1|yalnız lokal maşından əlçatan (təhlükəsiz)" \
  --explain "& echo \$! > srv.pid|PID-i saxlayırıq ki, sonda dəqiq dayandıraq" \
  --expect "index.html, version.txt və server PID" \
  --note "Bu, 'deploy etdim' simulyasiyasıdır. İndi curl ilə API cavab verirmi yoxlayacağıq." \
  --assert 'kill -0 $(cat srv.pid)'

step "curl: HTTP sorğusu" \
  --why "Deploy-dan sonra 'servis cavab verirmi?' sualının standart cavabı: HTTP status kodu." \
  --cmd 'curl -s http://127.0.0.1:18080/version.txt; echo "---"; curl -sI http://127.0.0.1:18080/ | head -n 3; echo "---"; curl -s -o /dev/null -w "status=%{http_code}\n" http://127.0.0.1:18080/index.html; curl -s -o /dev/null -w "status=%{http_code}\n" http://127.0.0.1:18080/yoxdur' \
  --explain "-s|silent: irəliləmə zolağı olmadan" \
  --explain "-I|yalnız başlıqlar (HEAD sorğusu)" \
  --explain "-o /dev/null|cavab gövdəsini at" \
  --explain "-w %{http_code}|yalnız status kodunu çap et" \
  --expect "v1.0.3; HTTP/1.0 200 OK başlıqları; status=200 və status=404" \
  --note "200 = uğurlu, 404 = tapılmadı, 5xx = server xətası. Health check-lər və CI məhz status koduna baxır." \
  --assert '[ "$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18080/index.html)" = "200" ]'

step "wget: faylı yüklə" \
  --why "Binary, arxiv və ya konfiqurasiya faylını serverə terminaldan yükləmək (artifact, installer)." \
  --cmd 'mkdir -p dl; wget -q -O dl/version.txt http://127.0.0.1:18080/version.txt; ls -l dl; cat dl/version.txt; echo "---"; curl -s -o dl/index2.html http://127.0.0.1:18080/index.html; ls dl' \
  --explain "wget -q|sakit rejim" \
  --explain "-O dl/version.txt|yüklənən faylı bu adla saxla" \
  --explain "curl -o|curl ilə eyni iş (fayla yaz)" \
  --expect "dl/version.txt (v1.0.3) və index2.html" \
  --note "Qısa fərq: wget fayl yükləmək üçün rahatdır, curl isə API sorğuları (başlıq, POST, status) üçün daha güclüdür." \
  --assert 'grep -q v1.0.3 dl/version.txt'

task "Server məlumat kartı" \
  "netinfo.txt faylı yaradın: 1-ci sətir hostname, 2-ci sətir hostname -I çıxışı (ilk IP kifayətdir). Cəmi 2 sətir." \
  --check '[ "$(wc -l < netinfo.txt)" -eq 2 ] && [ "$(head -n1 netinfo.txt)" = "$(hostname)" ] && sed -n 2p netinfo.txt | grep -Eq "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+"' \
  --hint "hostname > netinfo.txt; hostname -I >> netinfo.txt  (konteynerdə IP görünmürsə ip -4 -br a istifadə edin)" \
  --solution 'hostname > netinfo.txt; (hostname -I | tr " " "\n" | grep . | head -n1; ) >> netinfo.txt; [ "$(wc -l < netinfo.txt)" -eq 2 ] || { hostname > netinfo.txt; echo 127.0.0.1 >> netinfo.txt; }'

task "Health check" \
  "curl ilə lokal serverin /version.txt cavabının HTTP status kodunu (yalnız rəqəm) status.txt faylına yazın." \
  --check 'test -s status.txt && [ "$(tr -d "[:space:]" < status.txt)" = "200" ]' \
  --hint "curl -s -o /dev/null -w \"%{http_code}\" URL > status.txt" \
  --solution 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18080/version.txt > status.txt'

task "Default gateway" \
  "ip r çıxışından default route sətrini gw.txt faylına yazın (default route yoxdursa 'none' yazın)." \
  --check 'test -s gw.txt && { grep -q "^default" gw.txt || [ "$(tr -d "[:space:]" < gw.txt)" = none ]; }' \
  --hint "ip r | grep default > gw.txt  (boş olarsa echo none)" \
  --solution 'ip r | grep "^default" > gw.txt; [ -s gw.txt ] || echo none > gw.txt'

lab_summary "Sessiya 27 — Portlar (ss, nc, telnet)" \
  "ip a / ip r / hostname -I — IP və gateway" \
  "ping -c — əlçatanlıq, packet loss və rtt" \
  "curl -s -o /dev/null -w %{http_code} — servis health check" \
  "wget -O / curl -o — fayl yükləmək"
