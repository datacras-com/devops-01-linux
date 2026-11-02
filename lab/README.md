# DevOps Linux Lab — izahlı praktika

Hər dərsin praktikası bir skriptdir. Skript **özü izah edir**: nə edəcəyini, niyə, hər əmrin hissələrini, gözlənilən nəticəni, sonra əmri icra edib çıxışı şərh edir. Sonda siz özünüz tapşırıq həll edirsiniz və skript dərhal ✅/❌ ilə yoxlayır.

## Başlamaq (Ubuntu VM-də)
```bash
git clone https://github.com/datacras-com/devops-01-linux.git
cd devops-01-linux/lab
./run list          # dərslər
./run 03            # Sessiya 03-ü addım-addım keç
```

## Rejimlər
| Əmr | Nə edir | Kim üçün |
|---|---|---|
| `./run 03` | Hər addımdan əvvəl dayanır (**Enter**=icra, `s`=keç, `q`=çıx) | Tələbə |
| `./run 03 --auto` | Özü gedir, tapşırıqların nümunə həllini icra edir | Müəllim demosu |
| `./run 03 --explain` | Heç nə icra etmir, yalnız izahları oxuyur | Dərsdən əvvəl oxu |
| `./run 03 --verify` | Yalnız tapşırıqlarınızı yoxlayır | Müəllim / öz-özünə yoxlama |
| `./run 03 --dry` | Əmrləri göstərir, icra etmir | Sınaq |

## Təhlükəsizlik
- Hər şey `~/devops-lab/sNN/` qovluğunda baş verir və hər başlanğıcda sıfırlanır.
- Sistemi dəyişən dərslər (istifadəçi, paket) `lab_` prefiksli ad işlədir və bitəndə (və ya Ctrl+C-də) özü geri qaytarır.
- Yenə də **öz VM-də** işlədin, iş serverində yox.

## Öyrənmə axını (hər dərsdə)
1. 🎯 Məqsəd → 2. 🧠 Qısa konsept → 3. Addımlar: 💡 niyə → ⌨️ əmr → ├─ hissələr → 🔮 gözlənti → 🤔 proqnoz → çıxış → 📖 şərh → 4. ✍️ Tapşırıqlar (✅/❌, ipucu, həll) → 5. 💥 Failure injection → 6. 📋 Xülasə

Dərs logu `~/devops-lab/lab-log-sNN.md` faylına yazılır (portfolio üçün: GitHub-a `lab-notes` kimi commit edin).

## Müəllim üçün
- Test: `./test.sh` (bütün dərsləri təmiz Ubuntu 24.04 konteynerində `--auto` ilə yoxlayır, Docker lazımdır) və ya `./test.sh 07`.
- Yeni dərs: `AUTHORING.md` + `lessons/03-basic-commands/lesson.sh` nümunəsi.
