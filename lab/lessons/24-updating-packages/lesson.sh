# Sessiya 24 — Paket yeniləmə/silmə (update vs upgrade, remove vs purge, autoremove, hold)
lab_init 24 "Paketləri yeniləmək və silmək"
export DEBIAN_FRONTEND=noninteractive

cleanup_pkgs tree rsync htop
cleanup 'apt-mark unhold tree'     # tərs sıra ilə işləyir: əvvəl unhold, sonra purge
prep 'sudo apt-get update'

objective \
  "apt update və apt upgrade fərqini izah etməyi" \
  "yenilənə bilən paketləri görməyi və upgrade-i təhlükəsiz simulyasiya etməyi (-s)" \
  "remove və purge fərqini, autoremove-un nə etdiyini göstərməyi" \
  "apt-mark hold ilə paketi versiyada dondurmağı və geri açmağı"

concept "update vs upgrade" \
  "apt update: yalnız siyahını yeniləyir, heç nə qurmur ('nə var?' sualı)." \
  "apt upgrade: qurulu paketləri yeni versiyaya qaldırır ('götür, qur')." \
  "Production-da upgrade-dən əvvəl həmişə siyahıya baxın və ya -s ilə simulyasiya edin; gözlənilməz dəyişiklik olmasın."

step "Siyahını yenilə (apt update)" \
  --why "Upgrade köhnə siyahıdan işləməsin deyə ilk addım həmişə update-dir." \
  --cmd 'sudo apt-get update 2>&1 | tail -n 2' \
  --root \
  --explain "update|indeksi çəkir, paketlərə toxunmur" \
  --expect "'Reading package lists... Done'" \
  --assert 'ls /var/lib/apt/lists | grep -q Packages'

step "Nə yenilənə bilər? (apt list --upgradable)" \
  --why "Upgrade etmədən əvvəl dəyişikliyin siyahısını görmək lazımdır." \
  --cmd 'apt list --upgradable 2>/dev/null | head -n 5; echo "yenilənə bilən: $(apt list --upgradable 2>/dev/null | grep -c upgradable)"' \
  --explain "--upgradable|repo-da yeni versiyası olan qurulu paketlər" \
  --explain "head -n 5|ilk 5 sətir" \
  --explain "grep -c|saymaq" \
  --expect "'Listing...' sətri və sayı (təmiz imajda 0 ola bilər)" \
  --note "Boş siyahı xəta deyil: sistem artıq aktualdır." \
  --assert 'apt list --upgradable 2>/dev/null | head -n 1 | grep -q Listing'

step "Upgrade simulyasiyası (-s), real icra YOX" \
  --why "-s (simulate) nə baş verəcəyini göstərir, heç nə dəyişmir. Dəyişiklikdən əvvəl 'dry-run'." \
  --cmd 'apt-get -s upgrade | tail -n 3' \
  --explain "-s|simulyasiya: Inst/Remv sətirləri çıxır, disk toxunulmaz" \
  --explain "upgrade|yalnız mövcud paketləri yeniləyir, yeni paket qurmur/silmir" \
  --expect "'N upgraded, N newly installed, N to remove and N not upgraded.'" \
  --note "Dərs boyu apt-get upgrade-i real icra etmirik. Həqiqi serverdə -s nəticəsi xoşunuza gələndən sonra -y ilə işlədin. full-upgrade/dist-upgrade silə bilər, ehtiyatla." \
  --assert 'apt-get -s upgrade | grep -q "not upgraded"'

step "Paketi qur və dondur (apt-mark hold)" \
  --why "Məsələn, DB və ya kernel modulu versiyası dəyişməməlidir. hold paketi upgrade-dən çıxarır." \
  --cmd 'sudo apt-get install -y tree >/dev/null 2>&1; sudo apt-mark hold tree; apt-mark showhold' \
  --root \
  --explain "apt-mark hold|paketi donduraraq upgrade-dən qoruyur" \
  --explain "showhold|dondurulmuş paketlərin siyahısı" \
  --expect "'tree set on hold.' və siyahıda tree" \
  --note "Dondurmanı unutmayın: təhlükəsizlik yenilənmələri də həmin paketə getməyəcək." \
  --assert 'apt-mark showhold | grep -qx tree'

step "Dondurmanı aç (unhold)" \
  --why "Plan bitəndə paket yenə normal axına qayıtmalıdır." \
  --cmd 'sudo apt-mark unhold tree; echo "hold siyahısı: [$(apt-mark showhold)]"' \
  --root \
  --explain "unhold|dondurmanı götürür" \
  --expect "'Canceled hold on tree.' və boş hold siyahısı" \
  --assert '! apt-mark showhold | grep -qx tree'

step "remove vs purge" \
  --why "remove binarı silir, konfiqurasiya fayllarını saxlayır. purge hər şeyi silir. Təmiz yenidən quraşdırma üçün purge lazımdır." \
  --cmd 'sudo apt-get install -y rsync >/dev/null 2>&1; sudo apt-get remove -y rsync >/dev/null 2>&1; echo "remove-dan sonra:"; dpkg -l rsync | tail -n 1 | cut -c1-30; sudo apt-get purge -y rsync >/dev/null 2>&1; echo "purge-dan sonra:"; dpkg -l rsync 2>&1 | tail -n 1 | cut -c1-60' \
  --root \
  --explain "remove|paketi silir, /etc konfiqurasiyası qalır" \
  --explain "dpkg -l 'rc'|removed, config qalıb" \
  --explain "purge|paketi və konfiqurasiyanı silir" \
  --predict "remove-dan sonra dpkg -l hansı iki hərfi göstərəcək: ii, rc, yoxsa un?" \
  --expect "remove: 'rc rsync', purge: paket tapılmır" \
  --note "Cavab: rc (removed, config-files). purge-dan sonra paket bazadan çıxır." \
  --assert '! dpkg -s rsync >/dev/null 2>&1'

step "Yetim asılılıqlar: autoremove" \
  --why "Paketi silsəniz, onunla gələn asılılıqlar diskdə qalır. Dolu diskdə bu, ilk təmizlik yeridir." \
  --cmd 'sudo apt-get install -y htop >/dev/null 2>&1; sudo apt-get remove -y htop >/dev/null 2>&1; apt-get -s autoremove | grep -E "^Remv"; sudo apt-get autoremove -y 2>&1 | tail -n 2' \
  --root \
  --explain "autoremove|başqa heç bir paketin lazım olmadığı asılılıqları silir" \
  --explain "-s autoremove|əvvəl nələrin silinəcəyini göstərir (Remv sətirləri)" \
  --expect "Remv libnl-... sətirləri, sonra silinmə" \
  --note "Qayda: autoremove-dan əvvəl -s ilə siyahıya baxın, gözlənilməz silinmə olmasın." \
  --assert '! dpkg -s htop >/dev/null 2>&1'

step "Paket axtarışı (apt-cache search)" \
  --why "Paketin dəqiq adını bilmirsinizsə, təsvirə görə axtarın." \
  --cmd 'apt-cache search "json processor" | head -n 5; echo ---; apt-cache search --names-only "^jq$"' \
  --explain "apt-cache search|ad və təsvirdə axtarır" \
  --explain "--names-only|yalnız paket adında axtarır" \
  --explain "^jq\$|adı tam jq olan" \
  --expect "bir neçə nəticə, sonra 'jq - lightweight and flexible command-line JSON processor'" \
  --assert 'apt-cache search --names-only "^jq$" | grep -q "^jq "'

task "Yenilənə bilən paketlərin sayı" \
  "upgradable.txt faylına yenilənə bilən paketlərin sayını yazın (yalnız rəqəm; 0 ola bilər)." \
  --check 'grep -Eq "^[0-9]+$" upgradable.txt' \
  --hint "apt list --upgradable | grep -c upgradable (başlıq sətrində 'upgradable' yoxdur, deməli düzgün sayır)." \
  --solution 'apt list --upgradable 2>/dev/null | grep -c upgradable > upgradable.txt || true'

task "Upgrade planı" \
  "plan.txt faylına upgrade-in simulyasiya xülasə sətrini yazın (apt-get -s upgrade | tail -n 1)." \
  --check 'grep -q "not upgraded" plan.txt' \
  --hint "-s ilə simulyasiya edin, son sətri fayla yönləndirin." \
  --solution 'apt-get -s upgrade | tail -n 1 > plan.txt'

inject "Dondurulmuş paket" \
  "Köhnə bir iş zamanı kimsə tree paketini apt-mark hold ilə dondurub və unudub. Siz bunu tapıb açmalısınız." \
  --cmd 'sudo apt-get install -y tree; sudo apt-mark hold tree' \
  --symptom 'apt-mark showhold' \
  --fix 'sudo apt-mark unhold tree' \
  --check '! apt-mark showhold | grep -qx tree' \
  --hint "apt-mark showhold dondurulmuşları göstərir, apt-mark unhold PAKET açır."

lab_summary "Sessiya 25 — apt demo: PostgreSQL" \
  "update siyahını yeniləyir, upgrade paketləri yeniləyir; -s ilə əvvəl simulyasiya et" \
  "apt list --upgradable: dəyişikliyin siyahısı" \
  "remove konfiqurasiyanı saxlayır (rc), purge silir; autoremove yetimləri təmizləyir" \
  "apt-mark hold/unhold: kritik paketin versiyasını nəzarətdə saxla"
