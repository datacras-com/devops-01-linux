# Sessiya 27 — Portlar (ss, nc, telnet əvəzi)
lab_init 27 "Portlar: kim dinləyir, açıqdırmı?"

objective \
  "port anlayışını və DevOps servislərinin standart portlarını bilməyi" \
  "ss -tlnp ilə serverdə hansı portların hansı proseslə dinləndiyini görməyi" \
  "nc -zv və /dev/tcp ilə portun açıq olub-olmadığını yoxlamağı" \
  "'Address already in use' xətasında portu tutan prosesi tapmağı"

concept "Port nədir?" \
  "IP serverin ünvanıdır (bina), port isə tətbiqin otaq nömrəsidir. Aralıq 0-65535; 0-1023 well-known (root tələb edir), 1024+ adi tətbiqlər." \
  "Bir portu eyni anda yalnız BİR proses dinləyə bilər; ikincisi 'Address already in use' alır." \
  "telnet host port köhnə yoxlama üsuludur və adətən quraşdırılmır; eyni işi nc -zv və ya bash /dev/tcp görür. netstat köhnədir, əvəzi ss-dir."

prep 'for c in ss nc python3 curl; do command -v $c >/dev/null || NEED=1; done; [ -z "$NEED" ] || { sudo apt-get update -qq && sudo apt-get install -y -qq iproute2 netcat-openbsd python3 curl; }'
cleanup "for f in $LAB_WORK/*.pid; do [ -f \"\$f\" ] && kill -9 \$(cat \"\$f\") 2>/dev/null; done; true"

step "DevOps portları cədvəli" \
  --why "'Qoşula bilmirəm' deyəndə hansı portu yoxlayacağınızı bilməlisiniz. Bu rəqəmlər gündəlik işdə təkrarlanır." \
  --cmd 'cat > ports.txt <<"EOP"
22     SSH               uzaqdan giriş
80     HTTP              veb
443    HTTPS             şifrəli veb
5432   PostgreSQL        verilənlər bazası
6443   Kubernetes API    kubectl buraya qoşulur
10250  kubelet           node agent
2379   etcd              K8s-in verilənlər bazası
3000   Grafana           dashboard UI
9100   node_exporter     Prometheus metrikaları
EOP
column -t -s"  " ports.txt 2>/dev/null || cat ports.txt' \
  --explain "6443 / 10250 / 2379|Kubernetes control-plane və node portları" \
  --explain "3000 / 9100|monitoring: Grafana və node_exporter" \
  --explain "<<\"EOP\"|here-document ilə cədvəli fayla yazır" \
  --expect "9 sətirlik port cədvəli" \
  --note "Bu cədvəl ports.txt-də qalır, sonra işlətməli olacaqsınız." \
  --assert 'grep -q "^6443" ports.txt && [ "$(wc -l < ports.txt)" -eq 9 ]'

step "Hansı portlar dinləyir? ss -tlnp" \
  --why "Servis qalxıb? Port açılıb? Başqası tutub? ss bütün bunlara cavab verir." \
  --cmd 'ss -tlnp; echo "---"; ss -tln | wc -l' \
  --explain "-t|TCP" \
  --explain "-l|yalnız dinləyən (listening) soketlər" \
  --explain "-n|port və IP-ləri rəqəmlə göstər (ad həll etmə, daha sürətli)" \
  --explain "-p|portu hansı proses tutub (root/sudo lazımdır)" \
  --expect "Başlıq (State, Local Address:Port, Process); təmiz konteynerdə sətir olmaya bilər" \
  --note "0.0.0.0:PORT = bütün interfeyslərdən, 127.0.0.1:PORT = yalnız lokal. Təhlükəsizlik üçün DB-ni 127.0.0.1-ə bağlamaq vacibdir." \
  --assert 'ss -tln | head -n1 | grep -q State'

step "Lokal server qaldır və portu gör" \
  --why "Real servis kimi bir şey lazımdır ki, portu görək. Python-un daxili HTTP serveri idealdır." \
  --cmd 'mkdir -p www; echo "grafana-mock" > www/index.html
cd www; python3 -m http.server 18080 --bind 127.0.0.1 >../web.log 2>&1 & echo $! > ../web.pid; cd ..
sleep 1; ss -tlnp | grep ":18080"' \
  --explain "python3 -m http.server 18080|18080 portunda statik HTTP server" \
  --explain "grep :18080|ss çıxışından yalnız bizim portu süz" \
  --expect "127.0.0.1:18080 LISTEN və users:((\"python3\",pid=...))" \
  --note "Sonuncu sütun portun sahibini göstərir: python3 və onun PID-i. Növbəti incident-də məhz bu lazım olacaq." \
  --assert 'ss -tln | grep -q ":18080"'

step "Port açıqdırmı? nc -zv" \
  --why "Firewall 443-ü bloklayır? DB-yə şəbəkədən çatılır? Port yoxlaması telnet-in işini görür." \
  --cmd 'nc -zv 127.0.0.1 18080; echo "rc=$?"; echo "---"; nc -zv -w 2 127.0.0.1 18999; echo "rc=$?"' \
  --explain "-z|data göndərmə, yalnız portu yoxla (zero-I/O)" \
  --explain "-v|nəticəni sözlə de (succeeded / refused)" \
  --explain "-w 2|2 saniyə gözlə" \
  --explain "rc=\$?|çıxış kodu: 0 = açıq, 1 = bağlı" \
  --expect "18080: succeeded (rc=0); 18999: Connection refused (rc=1)" \
  --predict "Port bağlıdır və firewall paketi atır (DROP). Bu halda nc nə göstərər: refused, yoxsa timeout?" \
  --note "Cavab: timeout. 'refused' = host var, port bağlı. Timeout = paket gedib çatmır (firewall/marşrut). Bu fərq diaqnostikanın açarıdır." \
  --assert 'nc -z 127.0.0.1 18080' \
  --allow-fail

step "Telnet əvəzi: bash /dev/tcp və curl" \
  --why "Minimal serverdə nc və telnet olmaya bilər. Bash özü TCP bağlantısı aça bilər; heç nə quraşdırmaq lazım deyil." \
  --cmd 'for p in 18080 18999; do timeout 2 bash -c "</dev/tcp/127.0.0.1/$p" 2>/dev/null && echo "port $p: ACIQ" || echo "port $p: BAGLI"; done; echo "---"; curl -s http://127.0.0.1:18080/' \
  --explain "</dev/tcp/HOST/PORT|bash-ın xüsusi yolu: bağlantı açılırsa uğurlu" \
  --explain "timeout 2|2 saniyədən çox gözləmə" \
  --explain "&& ... ||| əmr uğurlu isə birinci, deyilsə ikinci mesaj" \
  --expect "port 18080: ACIQ, port 18999: BAGLI; sonra grafana-mock" \
  --note "Eyni üsul K8s API üçün: timeout 2 bash -c '</dev/tcp/10.40.1.10/6443' && echo açıq. Port açıqdırsa, növbəti addım curl/uygulama səviyyəsidir." \
  --assert 'timeout 2 bash -c "</dev/tcp/127.0.0.1/18080"'

step "Portu kim tutub? Prosesi tap və dayandır" \
  --why "Servis 'port busy' deyə qalxmırsa, əvvəlcə portun sahibini PID ilə tapıb dayandırmaq lazımdır." \
  --cmd 'PID=$(ss -tlnp "sport = :18080" | grep -o "pid=[0-9]*" | head -n1 | cut -d= -f2); echo "18080-i tutan PID=$PID"; ps -o pid,cmd -p $PID; kill $PID; sleep 1; ss -tln | grep -q ":18080" && echo "hələ açıq" || echo "port azad oldu"' \
  --explain 'ss ... "sport = :18080"|ss-in öz filtri: yalnız bu mənbə port' \
  --explain "grep -o pid=[0-9]*|çıxışdan yalnız pid=NNN hissəsini götür" \
  --explain "kill \$PID|adla yox, tapılmış dəqiq PID ilə" \
  --expect "PID, python3 http.server sətri və 'port azad oldu'" \
  --note "Bu, 'ss → PID → kill' axınıdır. Adla pkill python3 etsəydik, başqa python servisləri də ölə bilərdi." \
  --assert '! ss -tln | grep -q ":18080"'

inject "Port artıq tutulub" \
  "Başqa proses 18081 portunu tutub. Yeni server qaldırmaq istəyəndə 'Address already in use' alırsınız. Portun sahibini ss ilə tapıb dayandırın." \
  --cmd 'python3 -m http.server 18081 --bind 127.0.0.1 >/dev/null 2>&1 & echo $! > squat.pid; sleep 1' \
  --symptom 'python3 -m http.server 18081 --bind 127.0.0.1 2>&1 | tail -n 2; echo "---"; ss -tlnp | grep 18081' \
  --fix 'kill $(ss -tlnp "sport = :18081" | grep -o "pid=[0-9]*" | head -n1 | cut -d= -f2); sleep 1' \
  --check '! ss -tln | grep -q ":18081"' \
  --hint "ss -tlnp | grep 18081 → users:((\"python3\",pid=N)) → kill N"

task "Dinləyən portların hesabatı" \
  "ss -tln çıxışını listen.txt faylına yazın (başlıq sətri daxil)." \
  --check 'test -s listen.txt && head -n1 listen.txt | grep -q State' \
  --hint "ss -tln > listen.txt" \
  --solution 'ss -tln > listen.txt'

task "Port yoxlama nəticəsi" \
  "Lokal 18082 portunda python3 -m http.server qaldırın (PID p82.pid-ə yazılsın), sonra nc -z ilə yoxlayıb açıqdırsa 'open' sözünü port82.txt-yə yazın." \
  --check 'test -s p82.pid && kill -0 $(cat p82.pid) && grep -qx open port82.txt' \
  --hint "python3 -m http.server 18082 --bind 127.0.0.1 & echo \$! > p82.pid ; sleep 1 ; nc -z 127.0.0.1 18082 && echo open > port82.txt" \
  --solution 'python3 -m http.server 18082 --bind 127.0.0.1 >/dev/null 2>&1 & echo $! > p82.pid; sleep 1; nc -z 127.0.0.1 18082 && echo open > port82.txt'

task "Servis → port xəritəsi" \
  "ports.txt-dən Kubernetes API sətrini (6443) k8s-port.txt faylına yazın." \
  --check 'grep -q "^6443" k8s-port.txt && [ "$(wc -l < k8s-port.txt)" -eq 1 ]' \
  --hint "grep \"^6443\" ports.txt > k8s-port.txt" \
  --solution 'grep "^6443" ports.txt > k8s-port.txt'

lab_summary "Sessiya 28 — Servislər (systemctl)" \
  "ss -tlnp — kim hansı portu dinləyir (proses ilə)" \
  "nc -zv və /dev/tcp — telnet-siz port yoxlaması; refused vs timeout" \
  "Address already in use → ss ilə sahibini tap → dəqiq PID ilə dayandır" \
  "DevOps portları: 6443 K8s API, 10250 kubelet, 2379 etcd, 3000 Grafana, 9100 node_exporter"
