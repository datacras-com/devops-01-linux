---
marp: true
theme: default
paginate: true
backgroundColor: "#F7F9F8"
color: "#0F172A"
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    padding: 24px 44px;
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    box-sizing: border-box;
    overflow: hidden;
    background-color: #F7F9F8;
    color: #0F172A;
  }
  h1 { color: #00A859; font-size: 1.65em; margin: 0 0 6px 0; }
  h2 { color: #00A859; font-size: 1.2em; border-bottom: 2px solid #00A859; padding-bottom: 5px; margin: 0 0 8px 0; }
  h3 { color: #0F172A; font-size: 0.95em; margin: 5px 0; }
  strong { color: #00A859; }
  em { color: #848688; font-style: normal; }
  code { background: #E8F5EE; color: #00703A; padding: 2px 5px; border-radius: 4px; font-size: 0.78em; border: 1px solid #C3E4D0; }
  pre { background: #0F172A; color: #E2E8F0; padding: 8px 12px; border-radius: 8px; border-left: 4px solid #00A859; font-size: 0.50em; line-height: 1.4; margin: 5px 0; overflow: hidden; }
  pre code { font-size: 1em; padding: 0; background: transparent; color: #A7F3D0; border: none; }
  table { width: 100%; border-collapse: collapse; font-size: 0.8em; }
  th { background: #00A859; color: #ffffff; padding: 6px 10px; text-align: left; }
  td { background: #ffffff; padding: 6px 10px; border-bottom: 1px solid #D1E8DC; color: #0F172A; }
  tr:nth-child(even) td { background: #F0FAF4; }
  .columns { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
  .columns pre { font-size: 0.48em; }
  blockquote { border-left: 4px solid #00A859; background: #E8F5EE; padding: 8px 14px; margin: 6px 0; border-radius: 0 8px 8px 0; color: #0F172A; font-style: normal; font-size: 0.84em; }
  ul { line-height: 1.55; margin: 5px 0; }
  li { margin-bottom: 2px; font-size: 0.86em; }
  br { display: block; margin: 4px 0; content: ''; }
  section::after { color: #848688; font-size: 0.75em; }
  .ai-box { background: #FFF8E1; border: 2px solid #F59E0B; border-radius: 10px; padding: 12px 16px; margin: 10px 0; font-size: 0.85em; }
  .ai-box h3 { color: #B45309; margin: 0 0 6px 0; font-size: 0.95em; }
  .ai-tip { background: #FFF8E1; border-left: 4px solid #F59E0B; padding: 8px 14px; margin: 8px 0; border-radius: 0 6px 6px 0; font-size: 0.82em; color: #78350F; }
  section img { display: block; margin: 6px auto; background: transparent; }
  section img.emoji, section img[data-marp-twemoji] { display: inline; margin: 0 2px; height: 1em; width: 1em; vertical-align: -0.12em; }
  pre code .hljs-attr, pre code .hljs-attribute, pre code .hljs-section, pre code .hljs-keyword, pre code .hljs-name, pre code .hljs-selector-tag { color: #7DD3FC; }
  pre code .hljs-string, pre code .hljs-bullet, pre code .hljs-symbol { color: #FCD34D; }
  pre code .hljs-comment, pre code .hljs-quote { color: #94A3B8; }
  pre code .hljs-number, pre code .hljs-literal, pre code .hljs-regexp { color: #F9A8D4; }
  pre code .hljs-variable, pre code .hljs-template-variable, pre code .hljs-meta, pre code .hljs-built_in, pre code .hljs-params { color: #A7F3D0; }
  pre code .hljs-title, pre code .hljs-type, pre code .hljs-class, pre code .hljs-function { color: #C4B5FD; }
  pre code .hljs-operator, pre code .hljs-punctuation, pre code .hljs-subst { color: #E2E8F0; }
---

# 🌐 Nginx Challenge — ortaq serverdə öz saytın

## Chapter 2–7 yekun layihəsi · addım-addım tələbə tapşırığı

```bash
$ nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf   # Ch5
$ curl http://localhost:808N                            # Ch7
<h1>Salam, <ad>!</h1>
```

---

## Bu gün nə quracaqsan?

**Nəticə:** `curl localhost:808N` yazanda **öz adın** olan səhifə görünür. Sən onu sıfırdan, əmrlərlə qurursan.

```
curl ──▶ nginx (sənin portun 808N) ──▶ /      ──▶ ~/nginx-lab/site/index.html   (sənin səhifən)
                                      ├──▶ /health ──▶ "ok-KOD"
                                      └──▶ /api/   ──▶ 127.0.0.1:908N               (kiçik backend)
```

- **16 faza (F0–F16).** Hər faza: nə edirik → əmr → nə görməlisən → `journal.txt`-ə bir sətir
- Əvvəl keçdiyimiz hər şey burada tətbiq olunur (Chapter 2–7) — yeni heç nə öyrənmirsən, **birləşdirirsən**
- Təxmini vaxt: **2–3 saat**. Tələsmə, hər fazanın "Gözlənilən" hissəsini yoxla

> Kod yazmaq üçün yox, **anlamaq** üçün: hər əmri icra etməzdən əvvəl "nə edəcək?" sualını özünə ver.

---

## 1-ci addım: serverə qoşul

<style scoped>td, th { padding: 3px 9px; font-size: 0.74em; } li { font-size: 0.8em; margin-bottom: 0; } p { margin: 4px 0; }</style>

**Hər şey serverdə edilir, öz kompüterində yox.** Terminal aç və yaz:

```bash
ssh <server-ünvanı> -l <ad> -p <ssh-port>   # <ad> = sənin istifadəçi adın (məs. nazrin)
cat ~/nginx-lab/TASKS.md             # SƏNİN fərdi dəyərlərin burdadır!
```

| `TASKS.md`-dəki | Nə üçün |
|---|---|
| `N` | sənin nömrən (1–8) |
| `P` = 8080 + N | **sənin** sayt portun |
| `B` = 9080 + N | **sənin** backend portun |
| `/health` kodu | yalnız sənə məxsus kod |

- `<server-ünvanı>`, `<ssh-port>` və parolu **müəllim verir** (Plane-dəki tapşırıqda). `-l` = istifadəçi adı, `-p` = SSH portu (22 yox!)
- **Hər kəsin portu fərqlidir.** Başqasının portunu yazsan, `Address already in use` alarsan
- Yalnız `~/nginx-lab/` daxilində yaz. `sudo` yoxdur, sistem nginx-ə (80-ci port) və `/etc/nginx`-ə **toxunma**
- `<ad>`, `<nömrən>` kimi `< >` içindəkini **öz dəyərinlə əvəz et** (`< >` işarələrini də sil!)

---

## Kim hansı portda? — hamının `N`-i

<style scoped>td, th { padding: 4px 12px; }</style>

| Tələbə | `N` | Sayt portu `P` | Backend portu `B` |
|---|---|---|---|
| **yusif** | 1 | `8081` | `9081` |
| **nazrin** | 2 | `8082` | `9082` |
| **valeh** | 3 | `8083` | `9083` |
| **turkan** | 4 | `8084` | `9084` |
| **vusal** | 5 | `8085` | `9085` |
| **kanan** | 6 | `8086` | `9086` |
| **cavad** | 7 | `8087` | `9087` |
| **seid** | 8 | `8088` | `9088` |

- `N` = siyahıdakı sıra nömrən. `P = 8080 + N`, `B = 9080 + N`
- **Yalnız öz sətrini işlət.** Başqasının portunu yazsan, onun nginx-i ilə toqquşarsan (`Address already in use`)
- Yoxla: `cat ~/nginx-lab/TASKS.md` — orada da sənin `N`, `P`, `B` dəyərlərin yazılıb. İkisi **eyni** olmalıdır

---

## Hər faza necə işləyir

| Blok | Nə üçün |
|---|---|
| 🎯 **Məqsəd** | bu fazada nə qururuq və niyə |
| ⌨️ **Et** | əmrləri bir-bir yaz (köçürə bilərsən, amma **oxu**) |
| ✅ **Gözlənilən** | düzgün nəticə belə görünür. Fərqli görürsənsə, dayan! |
| 📝 **Jurnal** | `j "F?: …"` — nə etdim, nə gördüm |

**Özünü yoxla:** istənilən vaxt `bash ~/nginx-lab/selfcheck.sh` yaz — hansı şərt ✅, hansı ❌ və hansı fazaya qayıtmalı olduğunu göstərir.

**İlişəndə:** (1) xətanı **sona qədər oxu**, (2) `tail ~/nginx-lab/logs/error.log`, (3) AI köməkçiyə konkret sual ver (bax: "AI-yə necə sual verim"), (4) müəllimə yaz.

---

## Əmri necə oxumaq — 8 işarə

| İşarə | Mənası | Misal |
|---|---|---|
| `~` | ev qovluğun (`/home/<ad>`) | `ls ~/nginx-lab` |
| `$X` / `$(əmr)` | dəyişənin / əmrin **nəticəsi** əvəz olunur | `echo $USER` · `$(date +%T)` |
| `>` / `>>` | nəticəni fayla **yaz (silir!)** / **sonuna əlavə et** | `echo a >> f` |
| `\|` | soldakı əmrin nəticəsini sağdakına ötür | `ps … \| grep nginx` |
| `&&` / `\|\|` | uğurlu olsa davam et / uğursuz olsa alternativ | `ngx -t && ngx -s reload` |
| `&` | əmri **arxa planda** işlət | `python3 -m http.server &` |
| `2>/dev/null` | xəta mesajlarını **gizlət** | `apt list 2>/dev/null` |
| `<<EOF … EOF` | çox sətirli mətni fayla yaz (here-doc) | `cat > f <<EOF` |

> Bilmədiyin işarəni görəndə bu slayda qayıt. **Əmri başa düşmədən icra etmə.**

---

## Layihə xəritəsi — hansı faza hansı Chapter-i əhatə edir

| Faza | Nə edirik | Chapter |
|---|---|---|
| F0–F1 | Server yoxlanışı, iş sahəsi, `journal.txt` | Ch1 · Ch2 |
| F2–F3 | Paketi araşdır: `apt-cache`, `dpkg` | Ch6 |
| F4–F5 | Fayl xəritəsi, sahiblik və icazə | Ch1 · Ch3 · Ch4 |
| F6–F8 | Sayt + `nginx.conf` yaz, yoxla, başlat | Ch2 · Ch5 |
| F9 | Proses, reload, `curl` ilə test | Ch5 · Ch7 |
| F10–F11 | Loglar, `grep` / `find`, `cp` · `sed` · `mv` | Ch3 |
| F12 | 404, sərtləşdirmə, `403` | Ch3 · Ch4 |
| F13–F14 | Reverse proxy, `502`, `kill`, şəbəkə | Ch5 · Ch7 |
| F15–F16 | Yeniləmə / `hold` (simulyasiya), təmizlik | Ch6 · Ch5 |

---

## Nginx nədir və nə üçün lazımdır?

- **Veb server** — HTML, CSS, şəkil fayllarını brauzerə verir
- **Reverse proxy** — sorğunu arxadakı tətbiqə (Python, Node, Java) ötürür
- **Load balancer** — sorğunu bir neçə serverə bölür
- Çox sorğunu az yaddaşla idarə edir, production-da standartdır

> Bu gün sən nginx-i **adi istifadəçi** kimi, **öz konfiqinlə** işlədəcəksən. Eyni üsul CI runner-lərdə və konteynerlərdə də istifadə olunur.

---

## Niyə öz qovluğumuz hazırlayırıq?

**Normalda** nginx sistem qovluqlarından istifadə edir və onları dəyişmək üçün **root / `sudo`** lazımdır:

| | Normal nginx (sistem) | Bizim nginx (öz qovluğumuz) |
|---|---|---|
| Konfiq | `/etc/nginx/nginx.conf` | `~/nginx-lab/conf/nginx.conf` |
| Sayt faylları | `/var/www/html/` | `~/nginx-lab/site/` |
| Loglar | `/var/log/nginx/` | `~/nginx-lab/logs/` |
| PID faylı | `/run/nginx.pid` | `~/nginx-lab/run/nginx.pid` |
| Port | `80` (root lazımdır) | `808N` (öz portun) |

> **Biz ortaq serverdə adi istifadəçiyik** (8 nəfər eyni serverdə). `/etc/nginx` və `/var/log/nginx`-ə **yaza bilmirik**, sistem nginx-ini də dəyişməməliyik. Ona görə **lazım olan hər şeyi öz `~/nginx-lab` qovluğumuzda hazırlayırıq.**


---

## `-p` və `-c` flag-ları nə üçün lazımdır?

<style scoped>td, th { padding: 3px 9px; font-size: 0.74em; } blockquote { font-size: 0.76em; padding: 5px 12px; margin: 4px 0; } p { margin: 4px 0; font-size: 0.9em; }</style>

nginx flag-sız işə düşsə, **avtomatik olaraq `/etc/nginx`-ə baxır** və `Permission denied` verir. Ona **öz qovluğumuzu göstərməliyik**:

| Flag | Mənası |
|---|---|
| `-p ~/nginx-lab` | **iş qovluğu (prefix)** — nginx öz fayllarını (logs, run, tmp) burda axtarsın |
| `-c ~/nginx-lab/conf/nginx.conf` | **konfiq faylı** — `/etc/nginx/nginx.conf` yox, **bizimki** |
| `-t` | konfiqi **yoxla** (başlatmadan) |
| `-s reload` / `-s stop` | işləyən nginx-ə **"konfiqi yenidən oxu" / "dayan"** siqnalı göndər |

```bash
nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf -t           # yoxla
nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf -s reload    # yenidən oxu
```

> **Qeyd:** adi (sistem) nginx-də eyni işi `systemctl` görür: `sudo systemctl reload nginx` ≈ `nginx -s reload`, `sudo systemctl stop nginx` ≈ `nginx -s stop`. Bizdə **`systemctl` işləməz** — o, **sistem nginx-ini** idarə edir və `sudo` tələb edir. Biz öz prosesimizi `nginx -s …` siqnalı ilə idarə edirik.

> Bu çox uzundur — F8-də **`ngx`** qısa adını yaradacağıq: **`ngx -t`** = birinci əmr, **`ngx -s reload`** = ikinci əmr.

---

## F0 · Server yoxlanışı — `Ch1 · Ch5`

🎯 **Məqsəd:** harada olduğunu, kim olduğunu və nginx-in hazır olduğunu yoxla.

```bash
cat /etc/os-release | head -2        # hansı OS?
whoami; id; echo $HOME               # mən kiməm?
nginx -v                             # sistemdə nginx var?
ss -tlnp | head                      # hansı portlar məşğuldur?
```

✅ **Gözlənilən:**
```
PRETTY_NAME="Ubuntu 26.04 LTS"        ← OS
<ad>   uid=… gid=…   /home/<ad>       ← sənin adın, sənin ev qovluğun (root OLMAMALIDIR)
nginx version: nginx/1.28.3 (Ubuntu)
LISTEN … 0.0.0.0:80 …                 ← 80-ci portu SİSTEM nginx-i tutur (ona toxunma)
```

---

## F0 · Şəxsi dəyişənlər və `~/.bashrc` — `Ch2`

`TASKS.md`-dən öz `N`-ni və `/health` kodunu götür. **Əvvəl `cat ~/nginx-lab/TASKS.md` ilə bax**, sonra yaz (`<…>` yerinə dəyəri yaz):

```bash
echo 'export N=<nömrən>' >> ~/.bashrc                  # məs.:  export N=3
echo 'export P=$((8080+N)) B=$((9080+N))' >> ~/.bashrc
echo 'export CODE=<health-kodun>' >> ~/.bashrc         # məs.:  export CODE=6a917a
source ~/.bashrc
echo "N=$N port=$P backend=$B kod=$CODE"
```

✅ **Gözlənilən** (N=3 üçün): `N=3 port=8083 backend=9083 kod=6a917a`

> **`~/.bashrc` nədir?** Hər dəfə terminal açılanda **avtomatik oxunan şəxsi başlanğıc faylıdır** (`~` = ev qovluğun, `.` = gizli fayl). Orada yazdığın dəyişən və alias-lar hər yeni sessiyada hazır olur. `source ~/.bashrc` — dəyişikliyi **dərhal** götürür.
>
> `>>` faylın **sonuna əlavə edir**, `>` isə faylı **silib** yenidən yazar. `.bashrc`-yə həmişə `>>` işlət!

---

## F1 · İş sahəsi və jurnal — `Ch2`

🎯 **Məqsəd:** bütün işini bir qovluqda topla, hər addımı jurnala yaz.

```bash
cat ~/nginx-lab/TASKS.md                         # fərdi tapşırığın
mkdir -p ~/nginx-lab/{conf,site,logs,run,tmp}    # 5 qovluq bir əmrlə
cd ~/nginx-lab
tree -L 1 || ls -l                               # tree yoxdursa ls
j() { echo "$(date +%T) $*" >> ~/nginx-lab/journal.txt; }
echo 'j() { echo "$(date +%T) $*" >> ~/nginx-lab/journal.txt; }' >> ~/.bashrc
j "F1: iş sahəsi hazırdır"
cat -n ~/nginx-lab/journal.txt
```

✅ **Gözlənilən:** `tree` → `conf  logs  run  site  tmp  TASKS.md  selfcheck.sh`. `cat -n` → `1  19:42:05 F1: iş sahəsi hazırdır`

- **`A || B`** — A **uğursuz olsa** B işləyir. **`A && B`** — A **uğurlu olsa** B işləyir
- Qovluqlar: `conf` (konfiq) · `site` (HTML) · `logs` · `run` (pid) · `tmp` (nginx müvəqqəti)

---

## `j` nədir? — öz əmrimizi yaradırıq — `Ch2`

```bash
j() { echo "$(date +%T) $*" >> ~/nginx-lab/journal.txt; }
j "F1: iş sahəsi hazırdır"          # istifadə
```
```
19:42:05 F1: iş sahəsi hazırdır      ← journal.txt-yə düşən sətir
```

| Hissə | Mənası |
|---|---|
| `j()` | `j` adlı **qısa əmr** (funksiya) yaradır |
| `{ … }` | `j` yazanda icra olunacaq əmrlər |
| `$(date +%T)` | indiki **saat** (`19:42:05`) |
| `$*` | `j`-dən sonra yazdığın **mətn** |
| `>> …/journal.txt` | sətri faylın **sonuna əlavə edir** |

> **Niyə?** Hər dəfə uzun `echo "…" >> journal.txt` yazmaq əvəzinə `j "nə etdim"` yazırsan, saatı özü qoyur. `~/.bashrc`-yə yazırıq ki, terminalı bağlayıb açanda `j` itməsin.

---

## F2 · Paketi araşdır (quraşdırma yox!) — `Ch6`

🎯 **Məqsəd:** nginx hansı paketdir, hansı versiyadır, hardan gəlir.

```bash
apt-cache policy nginx          # Installed / Candidate / mənbə
apt show nginx 2>/dev/null | head -12
apt-cache depends nginx | head
apt install -s nginx | tail -3  # -s = simulyasiya, heç nə dəyişmir
j "F2: nginx versiyası $(nginx -v 2>&1)"
```

✅ **Gözlənilən:** `Installed: 1.28.3-…` və `Candidate: 1.28.3-…` · sonda `nginx is already the newest version` · `0 newly installed`

- `Installed` ≠ `(none)` → paket qurulub. `Candidate` → depodakı ən yeni versiya
- **`-s` simulyasiyadır:** nə edəcəyini göstərir, amma **etmir**. Ona görə `sudo` lazım deyil və serveri sındırmaz
- **Sual:** niyə `0 newly installed` yazdı?

---

## F3 · Paketin içinə bax: `dpkg` — `Ch6`

🎯 **Məqsəd:** paket hansı faylları gətirib, hər fayl hansı paketə məxsusdur.

```bash
dpkg -l nginx | tail -1            # status, versiya
dpkg -L nginx | head -20           # paket hansı fayllar gətirib
dpkg -S /usr/sbin/nginx            # bu fayl hansı paketdəndir
which nginx; ls -l $(which nginx)

cd /tmp && apt download nginx      # .deb faylı (sudo-suz)
dpkg -x nginx_*.deb ~/nginx-lab/tmp/deb && find ~/nginx-lab/tmp/deb -type f | head -5
```

✅ **Gözlənilən:** `dpkg -l` → `ii  nginx  1.28.3-…` · `dpkg -S` → `nginx: /usr/sbin/nginx` · `which` → `/usr/sbin/nginx`

- `ii` = paket quraşdırılıb · `dpkg -x` paketi **sistemə qurmadan** qovluğa açır
- 📝 `pkg.txt`-ni **F3-də hazırla** (`TASKS.md`-dəki 2-ci tapşırıq): `version=…`, `package=…`, `files=…`, `conf=…`

---

## F4 · Fayl xəritəsi və sistem konfiqini oxu — `Ch1 · Ch3`

🎯 **Məqsəd:** nginx faylları harada saxlayır və sistem konfiqi necə görünür.

```bash
tree -L 1 /etc/nginx 2>/dev/null || ls /etc/nginx
grep -Ev '^\s*(#|$)' /etc/nginx/nginx.conf | head -25   # komentarsız
ls /var/log/nginx /var/www/html
```

| Yol | Nə |
|---|---|
| `/usr/sbin/nginx` | proqramın özü |
| `/etc/nginx/` | **sistem** konfiqi (oxuya bilərsən, dəyişə bilməzsən) |
| `/etc/nginx/mime.types` | fayl tipləri — bizim konfiq `include` edəcək |
| `~/nginx-lab/conf/` | **sənin** konfiqin |

> `grep -Ev '^\s*(#|$)'` — `-v` uyğun gələnləri **at**, `-E` genişlənmiş regex: komentarsız və boş sətirsiz oxu.

---

## F5 · Sahiblik və icazə — `Ch4`

🎯 **Məqsəd:** niyə `/etc/nginx`-ə yaza bilmirsən, öz qovluğuna yaza bilirsən.

```bash
id; groups                              # uid, qruplar
ls -ld /etc/nginx ~/nginx-lab ~/nginx-lab/site
stat -c '%U:%G %a %n' ~/nginx-lab/site /etc/nginx/nginx.conf
touch /etc/nginx/test.txt               # Permission denied  ← gözlənilən XƏTA
echo "yaza bilirəm" > ~/nginx-lab/site/test.txt && echo OK
rm ~/nginx-lab/site/test.txt
```

✅ **Gözlənilən:** `<ad>:<ad> 755 …/site` · `root:root 644 /etc/nginx/nginx.conf` · `Permission denied` · `OK`

- **`stat -c '%U:%G %a %n'`** — faylın "pasportu" bir sətirdə: `%U` sahib · `%G` qrup · `%a` icazə (rəqəmlə) · `%n` ad
- `/etc/nginx` sahibi `root`, icazə `644` → sən yalnız **oxuya** bilərsən. Qovluğun **sənindir** → yaza bilirsən
- `j "F5: /etc/nginx sahibi root, mənim qovluğum $USER"`

---

## F6 · Saytı yaz — özünün adı ilə — `Ch2 · Ch4`

🎯 **Məqsəd:** səhifədə **öz adın**, portun və bugünkü tarix görünsün.

```bash
cat > ~/nginx-lab/site/index.html <<EOF
<!doctype html>
<html><head><meta charset="utf-8"><title>$USER · DataCras</title></head>
<body><h1>Salam, $USER!</h1>
<p>Server: $(hostname) · Port: $P · Tarix: $(date +%F)</p></body></html>
EOF
echo '<h1>404 — belə səhifə yoxdur</h1>' > ~/nginx-lab/site/404.html
chmod 755 ~/nginx-lab/site; chmod 644 ~/nginx-lab/site/*.html
cat ~/nginx-lab/site/index.html
```

✅ **Gözlənilən:** `cat` → `<h1>Salam, <ad>!</h1>` və `Port: 808N · Tarix: 2026-…` (`$USER`, `$P` **dəyərlə əvəz olunub**)

- `<<EOF … EOF` here-doc: iki `EOF` arasındakı mətn fayla yazılır. `$USER`, `$P`, `$(…)` **dəyərlə əvəz olunur**
- `chmod 755` qovluq, `chmod 644` fayl: sən yaza bilirsən, başqaları yalnız oxuyur

---

## F7 · `nginx.conf` — öz konfiqin (bütöv) — `Ch2`

🎯 **Məqsəd:** nginx-ə de ki: harada dinləmək, fayllar hardadır, logları hara yazmaq.

```bash
cat > ~/nginx-lab/conf/nginx.conf <<EOF
pid $HOME/nginx-lab/run/nginx.pid;
error_log $HOME/nginx-lab/logs/error.log warn;
events { worker_connections 64; }
http {
  include /etc/nginx/mime.types;
  access_log $HOME/nginx-lab/logs/access.log;
  client_body_temp_path $HOME/nginx-lab/tmp/body;
  proxy_temp_path       $HOME/nginx-lab/tmp/proxy;
  fastcgi_temp_path     $HOME/nginx-lab/tmp/fcgi;
  uwsgi_temp_path       $HOME/nginx-lab/tmp/uwsgi;
  scgi_temp_path        $HOME/nginx-lab/tmp/scgi;
  server_tokens off;
  server {
    listen $P;
    root $HOME/nginx-lab/site;
    index index.html;
    error_page 404 /404.html;
    include $HOME/nginx-lab/conf/extra.conf;
    location / { try_files \$uri \$uri/ =404; }
  }
}
EOF
touch ~/nginx-lab/conf/extra.conf     # boş fayl — sonra əlavə edəcəyik
```

---

## F7 · Konfiq nə deyir? — sətir-sətir — `Ch2`

| Sətir | Sadə dillə |
|---|---|
| `pid …` · `error_log …` · `access_log …` · `*_temp_path …` | nginx-in **yazdığı** fayllar **öz qovluğundadır** (sistem yollarına yazmaq üçün root lazımdır) |
| `events { … }` | eyni anda neçə bağlantı (kiçik rəqəm bəsdir) |
| `include …/mime.types` | `.html` → `text/html` kimi fayl tiplərinin siyahısı |
| `server_tokens off` | cavabda **nginx versiyasını gizlət** (təhlükəsizlik) |
| `listen $P` | **sənin portunda** dinlə |
| `root …/site` | saytın faylları burdadır |
| `index index.html` | `/` istənəndə bu faylı ver |
| `error_page 404 /404.html` | tapılmasa bu səhifəni göstər |
| `include …/extra.conf` | əlavə qaydalar **ayrı faylda** (F12–F13-də doldururuq) |
| `location / { try_files … =404 }` | faylı tap, yoxdursa `404` |

> **`\$uri`** — `\` var, çünki `$uri` **nginx-in** dəyişənidir. `\` olmasa shell onu boş əvəz edərdi. `$P`, `$HOME` isə shell-in dəyişənidir, əvəz olunmalıdır.
>
> `j "F7: konfiq yazıldı, port $P"`

---

## F8 · Yoxla → başlat → test — `Ch5 · Ch7`

🎯 **Məqsəd:** konfiqi yoxla, nginx-i **öz hesabınla** başlat və səhifənin gəldiyini gör.

```bash
alias ngx='nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf'
echo "alias ngx='nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf'" >> ~/.bashrc
ngx -t                       # sintaksis yoxlanışı — HƏMİŞƏ əvvəlcə
ngx                          # başlat
sleep 1
curl -s http://localhost:$P  # sənin səhifən
curl -I http://localhost:$P  # status 200, Server: nginx
ss -tlnp | grep ":$P"
```

✅ **Gözlənilən:**
```
nginx: configuration file …/nginx.conf test is successful
<h1>Salam, <ad>!</h1> …                     ← curl
HTTP/1.1 200 OK  ·  Server: nginx           ← versiya YOXDUR (server_tokens off)
LISTEN … 0.0.0.0:808N … "nginx"             ← sənin portun
```
📝 `j "F8: nginx $P portunda işləyir"` · Xəta olsa → "Sazlama" slaydına bax

---

## `ngx` nədir? — alias (qısa ad) — `Ch2`

**Problem:** nginx-i öz konfiqinlə işlətmək üçün hər dəfə bu qədər yazmaq lazımdır:

```bash
nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf -t
nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf -s reload
```

**Həll:** uzun əmrə **qısa ad** veririk — buna **alias** deyilir:

```bash
alias ngx='nginx -p ~/nginx-lab -c ~/nginx-lab/conf/nginx.conf'
ngx -t            # = nginx -p … -c … -t
ngx -s reload     # = nginx -p … -c … -s reload
```

| Əmr | Nə edir |
|---|---|
| `alias ngx='…'` | **bu terminalda** `ngx` yazanda `'…'` içindəki əmr işləsin |
| `echo "alias ngx='…'" >> ~/.bashrc` | eyni sətri `.bashrc`-yə **yadda saxlayır** — terminalı bağlayıb açanda alias itməsin |

> **Niyə vacibdir?** `-p` və `-c` yazmasan nginx **sistem konfiqini** (`/etc/nginx`) axtarır və icazə xətası verir. Alias bu səhvi unutmaqdan qoruyur: `ngx` həmişə **sənin** konfiqini işlədir.

---

## F9 · Proses, reload və `curl` testi — `Ch5 · Ch7`

🎯 **Məqsəd:** nginx-in hansı proseslərlə işlədiyini gör, konfiqi **dayandırmadan** yenilə.

```bash
ps -u $USER -o pid,ppid,user,cmd | grep '[n]ginx'   # master + worker
cat ~/nginx-lab/run/nginx.pid                      # master PID
echo '<p>v2</p>' >> ~/nginx-lab/site/index.html
ngx -s reload; sleep 1                              # konfiqi yenidən oxu
curl -s localhost:$P | tail -2
```

✅ **Gözlənilən:** iki sətir `nginx` (biri `master process`, biri `worker process`) · `nginx.pid`-də master-in PID-i · `curl` sonunda `<p>v2</p>`

Serverə yalnız SSH ilə qoşulduğun üçün **brauzer lazım deyil** — `curl localhost:$P` ilə yoxla. Başqa tələbənin portuna da bax: `curl -sI localhost:808M` (M = onun nömrəsi, slayd 4).

- master prosesin `PPID`-i `1`, worker-in `PPID`-i master-dir
- `reload` asinxrondur — dərhal `curl` etsən köhnə cavabı görə bilərsən, **1 san gözlə**
- Başqasının portu cavab vermirsə, deməli onun nginx-i hələ işləmir — bu normaldır

---

## F10 · Loglar — server nə görür? — `Ch3`

🎯 **Məqsəd:** hər sorğunun logda **canlı** iz buraxdığını gör. **İki terminal** lazımdır.

```bash
# ── 1-ci terminal ──
tail -n 5 ~/nginx-lab/logs/access.log        # son 5 sətir

# ── 2-ci terminal: yeni pəncərə aç, eyni  ssh …  əmri ilə qoşul ──
tail -f ~/nginx-lab/logs/access.log          # canlı izlə (dayandırmaq: Ctrl+C)

# ── yenə 1-ci terminalda ──
curl -s localhost:$P/yoxdur >/dev/null       # 404 yarat → 2-cidə dərhal görünür
cat ~/nginx-lab/logs/error.log | tail -3
```

✅ **Gözlənilən (2-ci terminalda):** `127.0.0.1 - - [09/Nov/2026:19:42:05 +0000] "GET /yoxdur HTTP/1.1" 404 … "curl/8…"`

- ⚠ **`tail -f` terminalı tutur** (əmr bitmir, yeni əmr yazmağa imkan vermir) — ona görə **ikinci terminal**. Bitirəndə `Ctrl+C`
- **Oxu:** IP · tarix · `"GET /yol …"` · **status (404)** · bayt · `"agent"`
- `curl` ilə 3 fərqli sorğu et (`/`, `/yoxdur`, `/index.html`) və 2-ci terminalda hər birini gör

---

## F10 · Logda axtarış — `Ch3`

```bash
grep -c ' 200 ' ~/nginx-lab/logs/access.log     # neçə uğurlu?
grep ' 404 ' ~/nginx-lab/logs/access.log        # 404-lər
grep -v ' 200 ' ~/nginx-lab/logs/access.log     # 200 olmayanlar
awk '{print $9}' ~/nginx-lab/logs/access.log | sort | uniq -c | sort -rn
find ~/nginx-lab -name '*.log' -size -1M
grep -R 'listen' ~/nginx-lab/conf /etc/nginx/sites-enabled 2>/dev/null
```

✅ **Gözlənilən:** `awk … | sort | uniq -c | sort -rn` →
```
      5 200
      2 404
```
- `awk '{print $9}'` — hər sətirdən **9-cu sözü** (status kodu) götür · `sort | uniq -c` — **say** · `sort -rn` — çoxdan aza
- **Sual:** sistem nginx-in `listen` dəyəri nədir, sənin? Niyə toqquşmur?

---

## F11 · Dəyişdir: `cp` · `sed` · `mv` — `Ch3`

🎯 **Məqsəd:** konfiqi **təhlükəsiz** dəyiş: əvvəl ehtiyat, sonra dəyişiklik, sonra yoxla.

```bash
cd ~/nginx-lab
cp -a conf/nginx.conf conf/nginx.conf.bak        # 1) ehtiyat həmişə!
sed -i "s/listen $P;/listen $P default_server;/" conf/nginx.conf   # 2) dəyiş
diff conf/nginx.conf.bak conf/nginx.conf         # 3) nə dəyişdi?
cp site/index.html site/index.html.bak
mv site/index.html site/home.html
sed -i 's/index index.html;/index home.html;/' conf/nginx.conf
ngx -t && ngx -s reload; sleep 1; curl -s localhost:$P | head -3
```

✅ **Gözlənilən:** `diff` → `< listen 8083;` / `> listen 8083 default_server;` · `curl` səhifəni yenə göstərir
- **`sed -i "s/KÖHNƏ/YENİ/" fayl`** — faylda KÖHNƏ-ni YENİ ilə **əvəz et** (`-i` = faylın özündə)
- Xəta olsa: `mv conf/nginx.conf.bak conf/nginx.conf` ilə **geri qaytar**
- `j "F11: index.html → home.html, ehtiyat götürdüm"`

---

## F12 · Sərtləşdirmə: `.env` qadağası və `/health` — `Ch3 · Ch4`

🎯 **Məqsəd:** nöqtə ilə başlayan fayllar (`.env`, `.git`) açılmasın; `/health` sənin kodunu qaytarsın; 404 səhifəsinin işlədiyini yoxla.

```bash
cat >> ~/nginx-lab/conf/extra.conf <<EOF
location ~ /\. { deny all; }
location = /health { return 200 "ok-$CODE\n"; }
EOF
echo 'gizli=1' > ~/nginx-lab/site/.env
ngx -t && ngx -s reload; sleep 1
curl -s -o /dev/null -w '%{http_code}\n' localhost:$P/.env     # 403
curl -s localhost:$P/health                                      # ok-KOD
curl -s localhost:$P/yoxdur                                      # F6-da yaratdığımız 404.html
```

✅ **Gözlənilən:** `403` · `ok-6a917a` (sənin kodun) · `<h1>404 — belə səhifə yoxdur</h1>`

> `.env` faylı veb-kökdədirsə və qadağan etməsən, **hamı oxuya bilər** — real hadisələrin ən çox rast gəlinən səbəbi.
> `>>` **əlavə edir** (silmir). Bura `>` yazma — əvvəlki qaydaları itirərsən!
> **404 səhifəsi** burda yeni yazılmır: `404.html` faylını **F6**-da yaratdıq, `error_page 404 /404.html;` isə **F7** konfiqindədir. Sonuncu `curl` yalnız onun işlədiyini yoxlayır.

---

## F12 · İcazə xətasını özümüz yaradaq: `403` — `Ch4`

🎯 **Məqsəd:** `403 Forbidden` xətasını yaradıb səbəbini logda tap.

```bash
chmod 000 ~/nginx-lab/site/home.html
curl -s -o /dev/null -w '%{http_code}\n' localhost:$P    # 403
tail -n 2 ~/nginx-lab/logs/error.log                     # Permission denied
namei -l ~/nginx-lab/site/home.html                      # yol boyunca icazələr
chmod 644 ~/nginx-lab/site/home.html                     # ← GERİ QAYTAR!
curl -s -o /dev/null -w '%{http_code}\n' localhost:$P    # 200
```

✅ **Gözlənilən:** `403` · `error.log`: `open() "…/home.html" failed (13: Permission denied)` · `namei`: `---------- <ad> <ad> home.html` · sonda `200`

- `namei -l` yolun **hər pilləsini** göstərir — kök qovluqda `x` bit yoxdursa fayl görünməz
- 📸 **Skrinşot 2:** `403` + `error.log` sətri
- ⚠ `chmod 644`-ü **unutma**: `000` icazəli fayl qalsa tapşırıq yoxlanışı pozulur

---

## F13 · Reverse proxy — arxa plan prosesi — `Ch5`

🎯 **Məqsəd:** nginx `/api/` sorğularını arxadakı kiçik tətbiqə ötürsün.

```bash
cat >> ~/nginx-lab/conf/extra.conf <<EOF
location /api/ { proxy_pass http://127.0.0.1:$B/; }
EOF
ngx -t && ngx -s reload

mkdir -p ~/nginx-lab/backend && echo "backend $USER" > ~/nginx-lab/backend/hello.txt
cd ~/nginx-lab/backend
python3 -m http.server $B --bind 127.0.0.1 >/dev/null 2>&1 &
jobs; ps -o pid,cmd -C python3; ss -tlnp | grep ":$B"
```

✅ **Gözlənilən:** `jobs` → `[1]+ Running python3 -m http.server …` · `ss` → `127.0.0.1:908N`

- **Backend** = "arxadakı tətbiq" (burada Python-un hazır kiçik veb serveri). `&` onu **arxa planda** işlədir, `jobs` siyahılayır
- Yalnız `127.0.0.1`-də dinləyir → xaricə yalnız nginx açıqdır. `proxy_pass` sorğunu ona yönləndirir

---

## F13 · Test, `kill` və `502` — `Ch5`

```bash
curl -s localhost:$P/api/hello.txt          # backend <ad>
pkill -f "http.server $B"                   # backend-i öldür
sleep 1
curl -s -o /dev/null -w '%{http_code}\n' localhost:$P/api/hello.txt   # 502
tail -n 2 ~/nginx-lab/logs/error.log        # connect() failed (111: Connection refused)
```

✅ **Gözlənilən:** `backend <ad>` → sonra `502` → `error.log`: `connect() failed (111: Connection refused) while connecting to upstream`

- **`502 Bad Gateway`** = nginx işləyir, amma **arxadakı tətbiq yoxdur**
- `pkill -f "http.server $B"` yalnız **sənin** backend-ini öldürür (portun fərqlidir). `pkill nginx` kimi **ümumi** yazma!
- 📸 **Skrinşot 3:** `502` + `error.log` sətri
- `j "F13: backend öldü → 502, error.log-da Connection refused"`

---

## F14 · Şəbəkə səviyyəsində baxış — `Ch7`

🎯 **Məqsəd:** portların, IP-lərin və bağlantının "alt qatda" necə göründüyünü gör.

```bash
ip -br addr                                 # IP-lər
ip route | head -3                          # default gateway
ss -tln | grep -E ':80|:90'                 # kimin hansı portu var
curl -sI http://127.0.0.1:$P | head -1      # loopback
curl -sI http://192.168.0.31:$P | head -1   # şəbəkə IP-si
nc -vz 127.0.0.1 $P                         # port açıqdır?
nc -vz 127.0.0.1 9099                       # bağlı port
```

✅ **Gözlənilən:** `lo … 127.0.0.1` və `ens33 … 192.168.0.31` · iki `curl` → `HTTP/1.1 200 OK` · `nc` → `succeeded!` (açıq) / `Connection refused` (bağlı)

- `nc` yoxdursa: `(echo > /dev/tcp/127.0.0.1/$P) && echo açıq` (bash-in özündə)
- **Sual:** `ss -tln`-də başqa tələbələrin portlarını görürsən. Onların prosesinə (`-p`) niyə baxa bilmirsən?

---

## F15 · Yeniləmə və versiyanı dondurmaq (simulyasiya) — `Ch6`

🎯 **Məqsəd:** `sudo` olmadan, **serveri dəyişmədən**, paket əməliyyatlarının nəyi dəyişəcəyini gör.

```bash
apt list --upgradable 2>/dev/null | head -5
apt install -s --only-upgrade nginx | tail -2    # nginx yenilənərdimi?
apt-mark showhold                                # dondurulmuş paketlər
apt purge -s nginx nginx-common | grep -E '^(Remv|Purg)' | head
apt-cache policy nginx | head -3
```

✅ **Gözlənilən:** `Purg nginx […]` və `Purg nginx-common […]` (**simulyasiya**, silinmir!) · `nginx is already the newest version`

- Real `install` / `hold` / `purge` üçün `sudo` lazımdır — **sən yalnız simulyasiya edirsən**, çünki bir nəfərin `purge`-i hamının nginx-ini silər
- **Sual 1:** `purge` etsəydin `/etc/nginx` nə olardı? `remove`-dan fərqi nədir?
- **Sual 2:** production-da niyə bəzən `hold` edilir?
- 📝 `j "F15: remove paketi silir amma konfiqi saxlayır, purge …"` — davamını öz cümlənlə yaz

---

## `nginx -t` xətası — bilərəkdən pozaq — `Ch2`

🎯 **Məqsəd:** `nginx -t`-nin xətanı necə göstərdiyini və pozuq konfiqlə nginx-in necə davrandığını gör.

```bash
cp -a ~/nginx-lab/conf/nginx.conf ~/nginx-lab/conf/nginx.conf.ok
sed -i "s/listen $P/listen $P xyz/" ~/nginx-lab/conf/nginx.conf
ngx -t
ngx -s reload; echo "çıxış kodu: $?"
curl -s localhost:$P | head -1          # köhnə konfiq işləyir?
mv ~/nginx-lab/conf/nginx.conf.ok ~/nginx-lab/conf/nginx.conf   # ← BƏRPA ET
ngx -t && ngx -s reload
```

✅ **Gözlənilən:** `[emerg] invalid parameter "xyz" in …/nginx.conf:NN` · `ngx -t` → `test failed` · `çıxış kodu: 1` · `curl` səhifəni yenə göstərir
- Pozuq konfiqlə `reload` **uğursuz olur, amma** işləyən nginx **köhnə konfiqlə davam edir**
- 📸 **Skrinşot 1:** `ngx -t` xətası (fayl adı və sətir nömrəsi ilə)
- 📝 `j "F-test: invalid parameter xyz … nginx.conf:NN"` — xətanı journal-a köçür

---

## Təhlükəli əmrlər — səhv olsa necə qaytarım?

| Əmr | Nə risk var | Geri qaytarma |
|---|---|---|
| `> fayl` | faylı **silib** yenidən yazır | həmişə `>>` və ya əvvəl `cp -a` ehtiyatı |
| `sed -i …` | faylı **yerində** dəyişir | `conf/nginx.conf.bak`-dan `mv` ilə geri |
| `chmod 000 …` | fayl oxunmaz olur | `chmod 644 …` |
| `pkill -f "…"` | uyğun **bütün** prosesləri öldürür | **dəqiq** ad yaz (`"http.server $B"`) |
| `rm -r …` | geri qayıtmaz | əvvəl `ls` ilə yolu yoxla |
| `ngx -s reload` pozuq konfiqlə | dəyişiklik tətbiq olunmur | əvvəl **həmişə** `ngx -t &&` |
| `sudo …`, `apt install/purge` (`-s`-siz) | serverdə **hamıya** təsir | **etmə** — yalnız `-s` |

> Qayda: **dəyişməzdən əvvəl ehtiyat, dəyişəndən sonra `ngx -t`.**

---

## Sazlama — simptom → səbəb → yoxla

<style scoped>td, th { padding: 3px 9px; font-size: 0.74em; }</style>

| Simptom | Səbəb | Yoxla |
|---|---|---|
| `bind() … (98: Address already in use)` | port tutulub (öz köhnə prosesin və ya başqası) | `ss -tlnp \| grep :$P` · `cat run/nginx.pid` |
| `bind() … (13: Permission denied)` | port < 1024 | portu `$P` ilə yaz, 80 yox |
| `open() "/var/log/nginx/error.log" failed (13)` | `-c` / `-p` verməmisən | `ngx` alias-ı ilə işlət |
| `nginx.pid` yoxdur / `reload` işləmir | proses işləmir | `ps -u $USER`, sonra `ngx` |
| `403` | icazə / `chmod` / `deny` | `namei -l`, `error.log` |
| `404` | fayl yolu / `root` səhvdir | `ls site`, `root` sətri |
| `502` | backend yoxdur | `ss -tlnp \| grep :$B` |
| `Welcome to nginx!` | sistem nginx-in 80-ci portuna baxırsan | URL-də `:$P` yoxdur |
| `command not found: ngx` | alias yoxdur | `source ~/.bashrc` |

---

## AI-yə necə sual verim? (AI-Assisted bootcamp)

AI köməkçi **ilişəndə** kömək edir. Yaxşı sual 4 hissədən ibarətdir:

```
1) Nə etmək istəyirəm:  nginx-i sudo-suz öz portumda (8083) işlətmək
2) Nə yazdım:           ngx -t   (konfiq faylını bura yapışdır)
3) Nə gördüm:           [emerg] invalid parameter "xyz" in …/nginx.conf:14
4) Nə başa düşmürəm:    bu xəta nə deməkdir və SƏBƏBİNİ izah et (həllini yox)
```

- ✅ **Xətanı sona qədər, dəqiq kopyala** və əmri göstər. "İşləmir" yetərli deyil
- ✅ **Səbəbi soruş:** "niyə bu xəta olur?" — tapşırığı özün başa düş
- ❌ Tapşırığın **hazır həllini** istəmə və **köçürmə** — yoxlayıcı bunu görür
- ❌ **Paylaşma:** `/health` kodunu, parolları, başqasının fayllarını

---

## F16 · Təmizlik — sən başladığını sən dayandır — `Ch5`

```bash
ngx -s stop; sleep 1
pkill -f "http.server $B"                    # backend hələ işləyirsə
ps -u $USER -o pid,cmd | grep -E '[n]ginx|[h]ttp.server' || echo "proses yoxdur"
ss -tln | grep ":$P" || echo "port azaddır"
bash ~/nginx-lab/selfcheck.sh                # son yoxlama
```

✅ **Gözlənilən:** `proses yoxdur` · `port azaddır` · selfcheck-də nginx qismi `⚪ dayanıb` göstərir (normaldır, müəllim yoxlayarkən qaldırır)

- Dayandırmasan port məşğul qalar, növbəti dəfə `Address already in use` alarsan
- **Faylları silmə** — `journal.txt`, `conf`, `pkg.txt`, `codes.txt` təhvil üçün lazımdır
- `j "F16: nginx dayandırıldı, port azaddır"`

---

## Xülasə — nə tətbiq etdik?

| Chapter | Tətbiq |
|---|---|
| Ch1 | `os-release`, fayl sistemi, `/etc`, `/var/log` |
| Ch2 | `>` `>>` `\|` here-doc, `{}`, `cat -n`, `wc`, `&&` `\|\|`, alias, funksiya, `.bashrc` |
| Ch3 | `cp -a` `mv` `sed -i` `grep` `find` `diff` `awk` `tail -f` |
| Ch4 | `id`, `ls -l`, `stat`, `chmod`, `namei`, `403`, `deny all` |
| Ch5 | `ps`, `&`, `jobs`, `kill`, `pkill`, `reload`, pid faylı |
| Ch6 | `apt-cache`, `apt show`, `-s`, `dpkg -l/-L/-S`, `apt download`, `hold`, `purge` |
| Ch7 | `ss`, `ip`, `nc`, `curl -I`, `502`, port, loopback |

---

## Ev tapşırığı — Nginx Challenge (Ch2–7)

<style scoped>li { font-size: 0.78em; margin-bottom: 0; } p { font-size: 0.84em; margin: 4px 0; }</style>

Hər şey **öz portunda** (`808N`), `~/nginx-lab/` daxilində. Dəyərlər: `cat ~/nginx-lab/TASKS.md`

1. **Ch2 · Ch1** `journal.txt` — F1–F16 hər faza üçün ən azı 1 sətir
2. **Ch6** `pkg.txt` — `version=`, `package=` (fərdi fayl), `files=`, `conf=` (4 sətir, `dpkg` ilə)
3. **Ch2 · Ch4** `site/index.html` — səhifədə **öz adın**, portun və tarix
4. **Ch2 · Ch3** `conf/nginx.conf` + `extra.conf` — öz portun, `server_tokens off`, `404.html`, `.env` qadağan, `/health` → `ok-<KOD>`
5. **Ch5** nginx **özünün** pid faylı ilə işləyir, `reload` işləyir
6. **Ch3** `codes.txt` — status say (`sort | uniq -c`); 200, 404, 403, 502 olsun
7. **Ch5 · Ch7** `/api/` → `127.0.0.1:908N` proxy, backend `&` ilə, `502` yaradılıb
8. **Ch6** `purge` və `--only-upgrade` simulyasiyası + `remove` vs `purge` fərqi (öz sözünlə)
9. **Ch7** `curl -s localhost:808N` — səhifən görünür (adın və portun)

**Təhvil:** `journal.txt` + 3 skrinşot (`nginx -t` xətası · `403` · `502`). Təhvildən əvvəl `bash ~/nginx-lab/selfcheck.sh` → hamısı ✅ olsun.
