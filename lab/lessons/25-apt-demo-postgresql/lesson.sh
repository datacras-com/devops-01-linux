# Sessiya 25 — apt demo: PostgreSQL ilə tam workflow
lab_init 25 "apt ilə real alət: PostgreSQL workflow"
export DEBIAN_FRONTEND=noninteractive

cleanup_pkgs postgresql-client
prep 'sudo apt-get update'

objective \
  "istənilən paket üçün 5 addımlı apt workflow-nu tətbiq etməyi" \
  "apt-cache search və grep ilə düzgün paket adını tapmağı" \
  "apt-cache depends ilə asılılıq ağacını oxumağı" \
  "tam server qurmadan apt-get install -s ilə nəyin qurulacağını görməyi və client qurub yoxlamağı"

concept "5 addımlı apt workflow" \
  "1) search: paket varmı, adı nədir  2) show: versiya, ölçü, asılılıq  3) update  4) install -y  5) yoxla (--version)." \
  "Bu yol nginx, Docker, Redis, PostgreSQL üçün eynidir. Bu dərsdə server əvəzinə yalnız simulyasiya və client qururuq."

step "Paketi axtar (apt-cache search)" \
  --why "'Serverə PostgreSQL qur' tapşırığında ilk sual: paketin dəqiq adı nədir?" \
  --cmd 'apt-cache search postgresql | wc -l; apt-cache search postgresql | grep "^postgresql "; apt-cache search postgresql | grep "^postgresql-client "' \
  --explain "wc -l|nəticələrin sayı (onlarla)" \
  --explain "grep \"^postgresql \"|adı tam 'postgresql' olan sətir (sonda boşluq)" \
  --explain "postgresql-client|yalnız client alətləri (psql)" \
  --expect "bir rəqəm, sonra postgresql - ... və postgresql-client - ..." \
  --note "Onlarca nəticə var, grep lazımlı olanı seçir." \
  --assert 'apt-cache search postgresql | grep -q "^postgresql-client "'

step "Metapaketə bax (apt show)" \
  --why "'postgresql' metapaketdir: özü kiçikdir, əsl server versiyalı paketdədir. Bunu show göstərir." \
  --cmd 'apt show postgresql 2>/dev/null | grep -E "^(Package|Version|Depends|Download-Size|Description)"' \
  --explain "Depends|asılı olduğu versiyalı paket (postgresql-NN)" \
  --explain "Download-Size|yalnız metapaketin ölçüsü, asıl yükləmə daha böyükdür" \
  --expect "Package: postgresql, Depends: postgresql-NN" \
  --predict "Download-Size kiçik olacaq, yoxsa yüzlərlə MB?" \
  --note "Cavab: kiçik (KB). Metapaket yalnız 'əsl paketi qur' deyir." \
  --assert 'apt show postgresql 2>/dev/null | grep -q "^Depends: postgresql-"'

step "Asılılıq ağacı (apt-cache depends)" \
  --why "Nə qurulacağını bilmək üçün: bu paket hansılara bağlıdır?" \
  --cmd 'apt-cache depends postgresql | head -n 6; echo ---; apt-cache depends postgresql-client | head -n 4' \
  --explain "depends|birbaşa asılılıqlar (Depends, Recommends, Suggests)" \
  --explain "head|çıxışı qısaldır" \
  --expect "postgresql -> Depends: postgresql-NN; postgresql-client -> Depends: postgresql-client-NN" \
  --note "Asılılıqlar rekursivdir: client-NN də libpq5 və s. istəyir. Aşağıdakı simulyasiya hamısını göstərəcək." \
  --assert 'apt-cache depends postgresql | grep -q "Depends: postgresql-"'

step "Qurulmadan simulyasiya (install -s)" \
  --why "Server paketi servis və istifadəçi yaradır, konteynerdə və ya test mühitində bunu istəmirik. -s yalnız plan göstərir." \
  --cmd 'apt-get install -s postgresql | grep -E "^Inst" | wc -l; apt-get install -s postgresql | grep -E "^Inst (postgresql|libpq)" | cut -d" " -f1-3; apt-get install -s postgresql | grep newly' \
  --explain "-s|simulate: heç nə qurulmur" \
  --explain "^Inst|qurulacaq paketləri göstərən sətirlər" \
  --expect "onlarla Inst sətri, aralarında postgresql-NN və libpq5" \
  --note "1 paket demisiniz, apt onlarla paket qurmaq istəyir. Bu, asılılıq həllidir. Biz serveri deyil, client-i qurmağa keçirik." \
  --assert 'apt-get install -s postgresql | grep -q "^Inst postgresql"'

step "Qurmazdan əvvəl policy" \
  --why "Hansı versiyanın və hansı repository-dən gələcəyini yoxlayın." \
  --cmd 'apt-cache policy postgresql-client | head -n 4' \
  --explain "Candidate|qurulacaq versiya" \
  --explain "Installed|hazırda qurulu (none = yox)" \
  --expect "Installed: (none), Candidate: NN+..." \
  --assert 'apt-cache policy postgresql-client | grep -q "Candidate: "'

step "Client-i qur (postgresql-client)" \
  --why "psql ilə uzaq DB-yə qoşulmaq üçün server lazım deyil, client yetərlidir (məs. RDS-ə qoşulma)." \
  --cmd 'sudo apt-get install -y postgresql-client 2>&1 | grep -E "newly installed|Setting up postgresql"' \
  --root \
  --explain "postgresql-client|psql, pg_dump və s., server yox" \
  --explain "-y|sual verilmir" \
  --expect "'newly installed' və 'Setting up postgresql-client'" \
  --note "Bu dərsin ən praktik nəticəsi: production DB-yə qoşulan jump-host-da yalnız client qurulur." \
  --assert 'dpkg -l postgresql-client | grep -q "^ii"'

step "Yoxla: psql --version" \
  --why "5-ci addım: qurulub və işləyir? Versiya cavabı bunu təsdiqləyir." \
  --cmd 'psql --version; command -v psql; dpkg -S "$(readlink -f "$(command -v psql)")" | head -n 1' \
  --explain "psql --version|client versiyası" \
  --explain "command -v|binarın yolu" \
  --explain "dpkg -S|binarın aid olduğu paket" \
  --expect "psql (PostgreSQL) NN.x, yol və paket adı" \
  --note "Server qurmadığımız üçün 'systemctl status postgresql' yoxdur: bu client-in işidir. Server qurulanda status da yoxlanılır." \
  --assert 'psql --version | grep -q "PostgreSQL"'

task "Versiya hesabatı" \
  "psql-version.txt faylına psql --version çıxışını yazın." \
  --check 'grep -q "PostgreSQL" psql-version.txt' \
  --hint "psql --version > psql-version.txt" \
  --solution 'psql --version > psql-version.txt'

task "Asılılıq sayı" \
  "client-deps.txt faylına postgresql-client-in birbaşa 'Depends:' sətirlərini yazın (apt-cache depends çıxışından)." \
  --check 'grep -q "Depends:" client-deps.txt' \
  --hint "apt-cache depends PAKET | grep Depends" \
  --solution 'apt-cache depends postgresql-client | grep Depends > client-deps.txt'

task "Server planı" \
  "server-plan.txt faylına 'apt-get install -s postgresql' çıxışından 'newly installed' xülasə sətrini yazın (qurmadan!)." \
  --check 'grep -q "newly installed" server-plan.txt && ! dpkg -s postgresql >/dev/null 2>&1' \
  --hint "-s simulyasiya, grep newly xülasə sətrini seçir" \
  --solution 'apt-get install -s postgresql | grep newly > server-plan.txt'

lab_summary "Sessiya 26 — Chapter 6 davamı" \
  "5 addım: search, show, update, install -y, yoxla" \
  "apt-cache depends və install -s: nəyin qurulacağını əvvəlcədən gör" \
  "client və server ayrı paketlərdir; jump-host-a yalnız client lazımdır" \
  "psql --version və dpkg -S: qurulmanı təsdiqlə"
