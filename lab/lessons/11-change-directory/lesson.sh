# Sessiya 11 — Qovluq dəyişmək (cd, pwd, mütləq/nisbi yol)
lab_init 11 "Naviqasiya: cd, pwd və yollar"

objective \
  "pwd ilə harada olduğunuzu həmişə yoxlamağı" \
  "mütləq (absolute) və nisbi (relative) yolu fərqləndirməyi" \
  "cd .., cd, cd ~ və cd - qısayollarından istifadə etməyi" \
  "rm -rf-dən əvvəl pwd yoxlamağın niyə vacib olduğunu izah etməyi"

concept "Mütləq və nisbi yol" \
  "Mütləq yol / ilə başlayır (/var/log/nginx) — harada olmağınızdan asılı deyil. Nisbi yol isə cari qovluqdan hesablanır (logs/app.log)." \
  "cd shell-in öz əmridir: dərsdə cd-nin təsiri sonrakı addımlara keçir. Qısayollar: .. (üst), . (cari), ~ (ev), - (əvvəlki)."

step "Hazırlıq və pwd" \
  --why "Yanlış qovluqda əmr işlətmək ən çox rast gəlinən səhvdir. pwd hər an cavab verir." \
  --cmd 'mkdir -p proj/app/logs proj/app/conf; echo "ERROR x" > proj/app/logs/app.log; pwd' \
  --explain "mkdir -p|iç-içə qovluqları bir əmrlə yaradır" \
  --explain "pwd|Print Working Directory — cari tam yol" \
  --expect "Sandbox yolu (.../s11)" \
  --assert 'pwd | grep -q "/s11$"'

step "Nisbi yol ilə içəri girmək" \
  --why "Layihə içində qısa nisbi yollarla işləmək sürətlidir." \
  --cmd 'cd proj/app/logs; pwd; ls' \
  --explain "cd proj/app/logs|cari qovluqdan başlayaraq üç səviyyə aşağı" \
  --expect "Yol .../s11/proj/app/logs, siyahıda app.log" \
  --assert 'pwd | grep -q "/proj/app/logs$"'

step "Üst qovluğa çıxmaq: cd .." \
  --why "Layihə ağacında yuxarı-aşağı hərəkət gündəlik əməliyyatdır." \
  --cmd 'cd ..; pwd; cd ../..; pwd' \
  --explain ".. |parent (üst) qovluq" \
  --explain "../..|iki səviyyə yuxarı" \
  --predict "İkinci cd ../.. sonrası harada olacağıq?" \
  --expect "Əvvəl .../proj/app, sonra .../s11" \
  --assert 'pwd | grep -q "/s11$"'

step "Mütləq yol: cd /var/log" \
  --why "Sistem qovluqlarına (log, konfiq) harada olduğunuzdan asılı olmayaraq mütləq yolla gedilir." \
  --cmd 'cd /var/log; pwd; cd /etc; pwd; ls | head -n 3' \
  --explain "/var/log|/ ilə başlayır → mütləq yol, kökdən hesablanır" \
  --explain "/etc|konfiqurasiya faylları burada saxlanır" \
  --expect "/var/log, sonra /etc və bir neçə fayl adı" \
  --note "/var/log — log-lar, /etc — konfiqlər. Hər şey buradan başlayır, kökdən yuxarı yoxdur." \
  --assert '[ "$(pwd)" = /etc ]'

step "cd - : əvvəlki qovluğa qayıt" \
  --why "İki qovluq arasında (məs. /etc/nginx və /var/log/nginx) tez gediş-gəliş üçün." \
  --cmd 'cd /var/log; cd /etc; cd -; cd -; pwd' \
  --explain "cd -|əvvəlki qovluğa keçir və onun yolunu çap edir" \
  --predict "Son pwd hansı yolu göstərəcək?" \
  --expect "cd - hər dəfə yol çap edir; son pwd /etc" \
  --assert '[ "$(pwd)" = /etc ]'

step "Ev qovluğu: cd və cd ~" \
  --why "Hər istifadəçinin ev qovluğu var (root üçün /root). Tək cd ora qaytarır." \
  --cmd 'cd ~; pwd; cd /tmp; cd; pwd; echo "HOME=$HOME"' \
  --explain "cd ~|ev qovluğuna (~ = $HOME)" \
  --explain "cd (tək)|eyni nəticə" \
  --expect "Hər iki pwd ev qovluğunu göstərir" \
  --assert '[ "$(pwd)" = "$HOME" ]'

step "Sandbox-a qayıt və pwd qaydası" \
  --why "Qızıl qayda: rm -rf, mv, cp * əmrlərindən əvvəl pwd ilə yoxla. Kökdə rm -rf * bütün sistemi silir." \
  --cmd 'cd "$LAB_WORK"; pwd; cd proj/app && pwd && ls' \
  --explain "cd $LAB_WORK|dərsin iş qovluğuna mütləq yolla qayıt" \
  --explain "&&|əvvəlki uğurlu olsa növbətini işlət — yanlış yerdə əmr işləməsin" \
  --expect "Əvvəl .../s11, sonra .../s11/proj/app və logs, conf" \
  --note "cd uğursuz olsa && səbəbilə sonrakı əmr icra olunmur. Skriptlərdə bu təhlükəsizlik mexanizmidir." \
  --assert 'pwd | grep -q "/proj/app$"'

task "Mütləq yolla get" \
  "Mütləq yol istifadə edib /var/log qovluğuna keçin." \
  --check '[ "$(pwd)" = /var/log ]' \
  --hint "cd /var/log" \
  --solution 'cd /var/log'

task "Nisbi yolla get" \
  "Sandbox qovluğundan başlayaraq nisbi yolla proj/app/conf-a keçin." \
  --check 'pwd | grep -q "/s11/proj/app/conf$"' \
  --hint "Əvvəl cd \"\$LAB_WORK\", sonra cd proj/app/conf" \
  --solution 'cd "$LAB_WORK"; cd proj/app/conf'

task "Yolu faylda saxla" \
  "Hazırkı qovluqdan asılı olmayaraq proj/app/conf-a keçin və pwd çıxışını sandbox-dakı yol.txt faylına yazın." \
  --check 'grep -q "/proj/app/conf$" "$LAB_WORK/yol.txt"' \
  --hint "pwd > \"\$LAB_WORK/yol.txt\" (mütləq yolla yazın ki, harada olsanız da işləsin)" \
  --solution 'cd "$LAB_WORK/proj/app/conf"; pwd > "$LAB_WORK/yol.txt"'

lab_summary "Sessiya 12 — Fayl axtarmaq (find, diff, file)" \
  "pwd — harada olduğunu göstərir; ondan əvvəl heç bir silmə əmri" \
  "/ ilə başlayan yol mütləqdir, qalanı nisbi" \
  "cd .., cd, cd ~, cd - — dörd qısayol" \
  "uğurlu cd-dən sonra && ilə davam et"
