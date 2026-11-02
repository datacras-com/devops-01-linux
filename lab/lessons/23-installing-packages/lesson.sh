# Sessiya 23 — Paket quraşdırma (apt, dpkg, apt show/policy, apt install)
lab_init 23 "Paket quraşdırma: apt ilə alət qurmaq"
export DEBIAN_FRONTEND=noninteractive

cleanup_pkgs tree jq cowsay
prep 'sudo apt-get update'

objective \
  "apt update ilə repository indeksini yeniləməyi və niyə vacib olduğunu izah etməyi" \
  "paket qurmazdan əvvəl apt show və apt-cache policy ilə məlumat almağı" \
  "apt-get install -y ilə skriptdə təhlükəsiz paket qurmağı" \
  "dpkg ilə qurulmuş paketi və onun fayllarını yoxlamağı, 'Unable to locate package' xətasını həll etməyi"

concept "apt, dpkg və repository" \
  "Repository = paketlərin saxlandığı server. apt ona qoşulur, asılılıqları (dependency) özü həll edir və paketi qurur." \
  "dpkg isə aşağı səviyyəli alətdir: yalnız lokal .deb faylları ilə işləyir, internetə çıxmır." \
  "EC2 user-data və CI skriptlərində həmişə: apt-get update, sonra apt-get install -y PAKET."

step "Repository indeksini yenilə (apt update)" \
  --why "apt paketləri yerli indeksdən axtarır. Təmiz serverdə indeks boşdur, update olmadan heç nə tapılmaz." \
  --cmd 'sudo apt-get update 2>&1 | tail -n 4' \
  --root \
  --explain "apt-get update|repository serverlərindən paket siyahısını çəkir (heç nə qurmur)" \
  --explain "sudo|indeks /var/lib/apt/lists altında saxlanır, root icazəsi lazımdır" \
  --expect "Get:/Hit: sətirləri, sonda 'Reading package lists... Done'" \
  --note "Qayda: paket qurmazdan əvvəl update. Skriptlərdə apt-get (apt yox) işlədin: çıxışı sabitdir, interaktiv deyil." \
  --assert 'ls /var/lib/apt/lists | grep -q Packages'

step "Paket haqqında məlumat (apt show)" \
  --why "Qurmazdan əvvəl bilin: versiya nədir, ölçüsü nə qədərdir, nələrdən asılıdır?" \
  --cmd 'apt show tree 2>/dev/null | grep -E "^(Package|Version|Installed-Size|Depends|Description)"' \
  --explain "apt show PAKET|paketin metadata-sı" \
  --explain "2>/dev/null|apt-ın 'script-də CLI stabil deyil' xəbərdarlığını gizlədir" \
  --explain "grep -E|yalnız lazımlı sahələri saxlayır" \
  --expect "Package: tree, Version, Installed-Size, Depends, Description" \
  --note "Depends sahəsi: bu paketlər də avtomatik qurulacaq." \
  --assert 'apt show tree 2>/dev/null | grep -q "^Package: tree"'

step "Hansı versiya qurulacaq? (apt-cache policy)" \
  --why "Eyni paket bir neçə repository-də ola bilər. policy qurulmuş və namizəd (Candidate) versiyanı göstərir." \
  --cmd 'apt-cache policy tree | head -n 6' \
  --explain "policy|qurulu versiya, namizəd versiya və mənbə repository" \
  --explain "Installed|hazırda sistemdə olan versiya ((none) = qurulmayıb)" \
  --explain "Candidate|apt install etsəniz gələcək versiya" \
  --predict "Hələ qurmamışıq. Installed sətrində nə görünəcək?" \
  --expect "Candidate: bir versiya nömrəsi" \
  --note "Cavab: (none). Production-da 'hansı versiya gedir?' sualının cavabı policy-dir." \
  --assert 'apt-cache policy tree | grep -q "Candidate: [0-9]"'

step "Paketi qur (apt-get install -y)" \
  --why "-y olmadan əmr 'Do you want to continue? [Y/n]' sualında dayanır və CI pipeline asılı qalır." \
  --cmd 'sudo apt-get install -y tree 2>&1 | grep -E "newly installed|Setting up"' \
  --root \
  --explain "install|paketi və asılılıqlarını qurur" \
  --explain "-y|bütün suallara avtomatik 'yes'" \
  --explain "DEBIAN_FRONTEND=noninteractive|konfiqurasiya dialoqlarını söndürür (bu dərsdə ixrac olunub)" \
  --expect "'1 newly installed' və 'Setting up tree'" \
  --note "Sudo vacibdir: paket qurmaq sistem dəyişikliyidir." \
  --assert 'command -v tree'

step "Qurulmanı yoxla (dpkg və tree)" \
  --why "'Qurdum' demək kifayət deyil, yoxlayın: paket bazada varmı, fayllar hardadır, əmr işləyirmi?" \
  --cmd 'dpkg -l tree | tail -n 1; dpkg -L tree | head -n 4; dpkg -S "$(command -v tree)"; mkdir -p demo/app/logs; tree demo' \
  --explain "dpkg -l|qurulmuş paket siyahısı; sətir 'ii' = düzgün qurulub" \
  --explain "dpkg -L|paketin qurduğu faylların siyahısı" \
  --explain "dpkg -S FAYL|bu fayl hansı paketə aiddir?" \
  --expect "ii tree ..., fayl yolları, 'tree: /usr/bin/tree' və qovluq ağacı" \
  --note "dpkg -S həll yolu: 'bu binar haradan gəlib?' sualı incident-lərdə tez-tez çıxır." \
  --assert 'dpkg -l tree | grep -q "^ii"'

step "Asılılığı olan paket: jq" \
  --why "jq JSON-u komanda sətrində emal edir (API cavabları, terraform output). O, kitabxanalarla gəlir." \
  --cmd 'sudo apt-get install -y jq 2>&1 | grep -E "NEW packages|newly installed" -A1; echo "{\"service\":\"nginx\",\"port\":80}" | jq .port' \
  --root \
  --explain "NEW packages|bir əmrlə qurulan paket siyahısı (jq + libjq1 + libonig5)" \
  --explain "jq .port|JSON-dan 'port' sahəsini çıxarır" \
  --expect "asılılıq siyahısı, sonra 80" \
  --note "Asılılıq həlli apt-ın əsas üstünlüyüdür: əl ilə .deb yükləsəydiniz libjq1-i özünüz tapmalıydınız." \
  --assert 'command -v jq && [ "$(echo "{\"a\":7}" | jq .a)" = 7 ]'

step "Qurulu paketləri filtrlə" \
  --why "'Bu server üzərində nginx qurulubmu?' sualını dəqiqliklə cavablandırmaq lazımdır." \
  --cmd 'apt list --installed 2>/dev/null | grep -E "^(tree|jq)/"; dpkg -l | grep -c "^ii"' \
  --explain "apt list --installed|qurulmuş paketlər" \
  --explain "grep -E \"^(tree|jq)/\"|yalnız adı tree və ya jq ilə başlayanlar" \
  --explain "grep -c|uyğun sətirlərin sayı" \
  --expect "tree/... [installed] və jq/... [installed,automatic deyil], sonra ümumi sayı" \
  --note "Boş çıxış = paket qurulu deyil." \
  --assert 'apt list --installed 2>/dev/null | grep -q "^jq/"'

task "Quraşdırma hesabatı" \
  "tree-version.txt faylına tree paketinin qurulu versiyasını yazın: dpkg -s tree çıxışından 'Version:' sətri." \
  --check 'grep -q "^Version: " tree-version.txt' \
  --hint "dpkg -s PAKET statusu göstərir; grep ilə '^Version' sətrini seçin və > ilə fayla yönləndirin." \
  --solution 'dpkg -s tree | grep "^Version" > tree-version.txt'

task "Namizəd versiyanı saxla" \
  "apt-cache policy jq çıxışından Candidate sətrini candidate.txt faylına yazın." \
  --check 'grep -q "Candidate: [0-9]" candidate.txt' \
  --hint "apt-cache policy jq | grep Candidate" \
  --solution 'apt-cache policy jq | grep Candidate > candidate.txt'

inject "Unable to locate package" \
  "Kimsə apt indeksini silib (məs. şəkil təmizliyi). cowsay qurmaq istəyirsiniz, amma apt paketi tanımır." \
  --cmd 'sudo rm -rf /var/lib/apt/lists/*' \
  --symptom 'sudo apt-get install -y cowsay' \
  --fix 'sudo apt-get update; sudo apt-get install -y cowsay' \
  --check 'dpkg -s cowsay 2>/dev/null | grep -q "Status: install ok installed"' \
  --hint "Xəta mesajı: 'Unable to locate package'. Paketin adı düzgündür, indeks isə boşdur. Əvvəlcə apt-get update."

lab_summary "Sessiya 24 — Paketləri yeniləmək və silmək" \
  "apt update indeksi yeniləyir, install qurur; -y skriptlər üçün məcburidir" \
  "apt show / apt-cache policy: qurmazdan əvvəl məlumat" \
  "dpkg -l / -L / -S: qurulmuş paket, onun faylları, faylın sahibi" \
  "'Unable to locate package' = əvvəlcə apt-get update, sonra paket adını yoxla"
