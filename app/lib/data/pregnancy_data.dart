class WeekData {
  final String babyVoice;
  final String developing;
  final String momTip;
  final String dadTip;
  final String nutrition;

  const WeekData({
    required this.babyVoice,
    required this.developing,
    required this.momTip,
    required this.dadTip,
    required this.nutrition,
  });
}

class PregnancyData {
  static WeekData forWeek(int week) {
    final w = week.clamp(1, 40);
    return _data[w] ?? _data[_nearest(w)]!;
  }

  static int _nearest(int w) {
    return _data.keys.reduce((a, b) => (a - w).abs() < (b - w).abs() ? a : b);
  }

  static const Map<int, WeekData> _data = {
    1: WeekData(
      babyVoice: "Onajon, men hali ko'zga ko'rinmayman — lekin men shu yerdaman! "
          "Hujayralarim bo'linib, hayotim boshlanmoqda. Siz meni sezmasangiz ham, "
          "tanangiz menga joy tayyorlamoqda 🌱",
      developing: "Urug'lanish va embrion shakllanishi",
      momTip: "Folatli kislota qabul qiling — kuniga 400 mkg. "
          "Spirt va tamaki mutlaqo taqiqlanadi.",
      dadTip: "Onani stress va og'ir yuk ko'tarishdan saqlang. "
          "Bu davrda uning ruhiy holati juda muhim.",
      nutrition: "Sabzavot, meva, yorug' non. Ko'proq suv iching. "
          "Xom go'sht va pishloqdan saqlaning.",
    ),
    4: WeekData(
      babyVoice: "Onajon, men loviya kabi kichkinaman! Lekin mening yuragim "
          "ura boshladi — bu daqiqada seningki bilan birga uradi 💗 "
          "Menga folatli kislota juda kerak.",
      developing: "Yurak urishi, asosiy organlar kurtaklari",
      momTip: "Ertalab ko'ngil aynishi normal — kichik, tez-tez ovqatlanish yordam beradi. "
          "Shifokor nazorati boshlaning.",
      dadTip: "Uyda keskin hidli narsalarni (bo'yoq, parfyum) kamaytiring. "
          "Ertalab onaga noʻxat krakeri taklif qiling.",
      nutrition: "B6 vitamini (banan, tuxum) ko'ngil aynishiga yordam beradi. "
          "Kichik porsiyalarda, tez-tez ovqatlaning.",
    ),
    6: WeekData(
      babyVoice: "Onajon, mening miyam rivojlanyapdi! Kichkina qo'llarim va "
          "oyoqlarim paydo bo'lmoqda. Men hozir uzum kabi. "
          "Sening ovozingni eshita olmayman hali, lekin tez orada eshitaman 👂",
      developing: "Miya, orqa miya, qo'l va oyoq kurtaklari",
      momTip: "Birinchi UZI ni rejalang. Charchoq va ko'ngil aynishi T1 da normal. "
          "Ko'proq dam oling.",
      dadTip: "Uy ishlarini ko'proq o'z zimmangizga oling. "
          "Ona hozir juda charchaydi — bu normal.",
      nutrition: "Temir (sabzi, qovurilgan go'sht) va kalsiy (sut, kefir) muhim. "
          "Qahva kuniga 1 kosadan oshmasin.",
    ),
    8: WeekData(
      babyVoice: "Onajon, mening barmoqlarim shakllandi! Ko'zlarim, burnim, "
          "lablarim paydo bo'lmoqda. Men uzum kabi bo'ldim. "
          "Tanangda harakat qila boshladim, lekin siz hali his qilmaysiz 🤏",
      developing: "Barmoqlar, yuz xususiyatlari, quloqlar",
      momTip: "Ko'ngil aynishi kamayishi kerak T2 boshida. "
          "Tishlarni muntazam tekshiring — homiladorlikda tish muammolari ko'payadi.",
      dadTip: "Birinchi UZI ga birga boring — bu lahzani o'tkazib yubormang. "
          "Embrionning yuragini ko'rish mo''jiza.",
      nutrition: "Yod (dengiz mahsulotlari, yodalangan tuz) miya rivojlanishi uchun. "
          "Xom baliqdan saqlaning.",
    ),
    10: WeekData(
      babyVoice: "Onajon, men endi rasman chaqaloqman — embrion emas! "
          "Barcha organlarim bor, endi kattalashish vaqti. "
          "Mening tirnoqlarim o'sib chiqdi 🌟 Men limondan biroz kichik.",
      developing: "Barcha organlar shakllangan, o'sish bosqichi",
      momTip: "Homiladorlik xaritangizni oling. "
          "Diqqatni jamlash qiyinlashishi mumkin — bu normal 'pregnancy brain'.",
      dadTip: "Homiladorlik vitamini va folat kislotasini tekshiring — "
          "onaga vaqtida eslatib turing.",
      nutrition: "Oqsil (tuxum, tovuq, baliq) juda muhim. "
          "Kuniga kamida 8 stakan suv iching.",
    ),
    12: WeekData(
      babyVoice: "Onajon, men 1-trimesterning oxirida limon kabi! "
          "Reflekslarim bor — barmoqlarimni og'zimga olaman. "
          "Buyraklarim ishlayapti, siydik hosil qilyapman 😄 "
          "Xavf davri o'tdi, keling nishonlaylik!",
      developing: "Reflekslar, buyraklar, jinsiy organlar",
      momTip: "Birinchi trimester tugadi — xursand bo'ling! "
          "Endi yaqinlaringizga aytishingiz mumkin.",
      dadTip: "Onani nishonlang — bu katta bosqich. "
          "Birga yangi narsalar reja qiling.",
      nutrition: "Hozirdan tug'ruqdan keyingi vitamin haqida o'ylang. "
          "Omega-3 (baliq, zig'ir urug'i) miya uchun muhim.",
    ),
    14: WeekData(
      babyVoice: "Onajon, men limon kabi! Yuzim ifodali — "
          "qoshu kipriqlarim o'sdi. Bosh barmoqimni so'raman 👍 "
          "Tana tukchalarim (lanugo) o'sayapti.",
      developing: "Yuz ifodasi, lanugo, o'sish",
      momTip: "T2 boshida ko'p onalar yaxshi his qiladi. "
          "Asta-sekin sport: yurish, suzish, yoga qilsa bo'ladi.",
      dadTip: "Bola xonasini rejalashtirishni boshlang. "
          "Ota-onalik kurslariga yoziling.",
      nutrition: "Kalsiy (kuniga 1000mg) — suyaklar uchun. "
          "Broccoli, lavash, sut mahsulotlari ko'proq yeng.",
    ),
    16: WeekData(
      babyVoice: "Onajon, men apelsin kabi! Suyaklarim qotib bormoqda. "
          "Eshita olasizmi? Yuragim minutiga 150 marta uradi! "
          "Ko'zlarim yopiq bo'lsa ham, yorug'likni his qilaman ☀️",
      developing: "Suyaklar, eshitish, ko'z reaksiyasi",
      momTip: "Tez orada birinchi harakat his qilinadi — 'kapalak uchgandek'. "
          "Qorin massaji qiling — tana moyi yoki kokos moyi bilan.",
      dadTip: "Qoringa gapiring — bola eshita boshlaydi! "
          "Musiqa qo'ying — klassik musiqa ayniqsa foydali.",
      nutrition: "Temir (kuniga 27mg) — anemiyani oldini olish. "
          "Jigar, qizil go'sht, no'xat ko'proq yeng.",
    ),
    18: WeekData(
      babyVoice: "Onajon, men harakat qilyapman! Sezyapsizmi? "
          "Bu men — suzib, aylanib, tepilyapman 🤸 "
          "Mening quloqlarim rivojlandi — siz gapirganda eshitaman. "
          "Sizning ovozingiz menga eng yoqimli ovoz!",
      developing: "Harakat, eshitish organi, miya",
      momTip: "UZI da jinsi bilinishi mumkin — bilmoqchimisiz? "
          "Bel og'rig'i uchun homilador ayollar yostiqchasini oling.",
      dadTip: "Qoringa murojaat qiling — ismini aytib gapiring. "
          "Bola ovozingizni taniy boshlaydi.",
      nutrition: "Vitamin D (quyosh, baliq yog'i) suyak uchun. "
          "Gunpor, bodring, pomidor salatlar yeng.",
    ),
    20: WeekData(
      babyVoice: "Onajon, men banan kabi! Yarmi yo'l o'tdik! 🎉 "
          "Qoplamalari bor — vernix — terimi himoya qilyapti. "
          "Ichimda yutaman va chiqaraman — o'pkam mashq qilyapti. "
          "Siz mening tepishlarimni aniq sezyapsiz endi!",
      developing: "O'pka mashqi, vernix, faol harakat",
      momTip: "Yarim yo'l! Buyuk ish qilyapsiz. "
          "Har kuni 10 ta tepishni sanoqqa oling — bu muhim.",
      dadTip: "Tepishlarni his qiling — qo'lingizni qoringa qo'ying. "
          "Bu sizni ota qiladi.",
      nutrition: "Kuniga 300-500 kalori qo'shimcha kerak. "
          "Sog'lom sneklar: yong'oq, meva, yogurt.",
    ),
    22: WeekData(
      babyVoice: "Onajon, mening sezgi organlarim rivojlanyapdi! "
          "Yorug'lik, tovush, ta'm — barchasini his qila boshlayman. "
          "Qornimda o'ynayman — ichimda sal tor. "
          "Meni yaxshi ko'rishingizni his qilyapman 💕",
      developing: "Sezgi organlar, ta'm, yorug'lik sezgisi",
      momTip: "Oyoq shishi normal — ko'proq dam oling, oyoqlarni ko'taring. "
          "Tuz kamroq iste'mol qiling.",
      dadTip: "Uy ishlarida yanada ko'proq yordam bering. "
          "Ona endi kamroq egilib, ko'tarib harakat qila oladi.",
      nutrition: "Magnesiy (qovoq, tarvuz urug'i) — oyoq tortishmalari uchun. "
          "Banana tongi non bilan.",
    ),
    24: WeekData(
      babyVoice: "Onajon, men makkajo'xori kabi! "
          "Ko'zlarim ochilib-yopila boshladi 👀 "
          "O'pkam rivojlanyapdi — hali nafas ololmayman, lekin mashq qilyapman. "
          "Agar hozir tug'ilsam, tirik qolish imkonim bor — bu katta qadam!",
      developing: "Ko'z ochilishi, o'pka rivojlanishi",
      momTip: "Glyukoza testi vaqti (24-28 hafta). "
          "Uyqu qiyinlashishi mumkin — yonboshlab, chap tomonda yoting.",
      dadTip: "Kechki massaj bering — oyoq va bel uchun. "
          "Tug'ruqxonani birga tanlang.",
      nutrition: "Kolin (tuxum, jigar) miya rivojlanishi uchun. "
          "Probiotiklar (kefir, yogurt) immunitetni mustahkamlaydi.",
    ),
    26: WeekData(
      babyVoice: "Onajon, ko'zlarim to'liq ochildi! "
          "Qoʻlim bilan yuzimni ushlayapman 🤗 "
          "Miyam juda tez rivojlanyapdi — "
          "so'nggi 3 oyda miyam 3 baravar kattalashadi. "
          "Sizning yuragingiz gursillab eshitiladi.",
      developing: "Ko'z, miya keskin o'sishi, harakat koordinatsiyasi",
      momTip: "Tug'ruq rejasini yozing. "
          "Nafas olish mashqlari (Lamaze) boshlang.",
      dadTip: "Tug'ruq kurslariga birga boring. "
          "Tug'ruqda yonida bo'lish rejalanmoqda — tayyorlaning.",
      nutrition: "DHA (losos, sardina) — miya uchun eng muhim omega-3. "
          "Haftada 2 marta yog'li baliq.",
    ),
    28: WeekData(
      babyVoice: "Onajon, 3-trimestrga xush kelibsiz! "
          "Men brokkoli kabi bo'ldim. Tushlar ko'raman! 💭 "
          "Uyqu va uyg'oqlik siklim bor. "
          "Miyam milliardlab neyronlar bilan ulanyapdi. "
          "Bugungi musiqa ertaga eslab qolaman.",
      developing: "Uyqu sikli, miya neyronlari, ko'z ochilishi",
      momTip: "Tez-tez kichik ovqatlanish — oshqozon siqiladi. "
          "Brakston-Hiks qisqarishlari normal.",
      dadTip: "Ona uchun doim tayyor bo'ling — 3-trimester og'irroq. "
          "Tug'ruq sumkasini birga yig'ing.",
      nutrition: "Temir (kuniga 27-30mg) — qon hosil qilish uchun. "
          "Vitamin C bilan birga temir yaxshi so'riladi.",
    ),
    30: WeekData(
      babyVoice: "Onajon, men kokos kabi! "
          "Suyaklarim qotib bo'ldi faqat bosh suyagim yumshoq — "
          "tug'ilish uchun. Men endi to'g'ri turyapman — boshim pastga 👇 "
          "Tug'ilishga 10 hafta qoldi!",
      developing: "Suyaklar, to'g'ri holat, o'pka pishishi",
      momTip: "Kegel mashqlari — tug'ruqqa tayyorgarlik. "
          "Qorin pastki qismida bosim his etilishi normal.",
      dadTip: "Shifoxonaga yo'l, parking, xonani oldindan biling. "
          "Avtomobil o'rindig'ini o'rnating.",
      nutrition: "Kalsiy va vitamin D birgalikda. "
          "Sutli ovqatlar (sutli bo'tqa, kefir) har kuni.",
    ),
    32: WeekData(
      babyVoice: "Onajon, men kokos kabi! "
          "Tirnoqlarim o'sayapti 💅 "
          "Sizning dam olish vaqtingizda men ham dam olaman. "
          "Tug'ilishga 8 hafta — vaqt tez o'tyapdi!",
      developing: "Tirnoqlar, soch, yog' to'planishi",
      momTip: "Tug'ruq belgilerini o'rganing. "
          "Shifokor bilan tug'ruq rejasini muhokama qiling.",
      dadTip: "Ish joyingizda paternity leave haqida so'rang. "
          "Onaga 'siz ajoyibsiz' deb aytishni unutmang.",
      nutrition: "Ko'proq kichik porsiyalar. "
          "Qabziyat uchun: olcha, o'rik, zig'ir urug'i.",
    ),
    34: WeekData(
      babyVoice: "Onajon, men qovoq kabi deyarli! "
          "Immun sistemam kuchaymoqda — sizdan antitelalar olaman. "
          "O'pkam 80% tayyor! Tilim borligini his qilaman — yutinaman 👅",
      developing: "Immunitet, o'pka pishishi, tilak refleksi",
      momTip: "Haftalik shifokor tekshiruvi muhim. "
          "Uyda tug'ruq belgilerini kuzating.",
      dadTip: "Hamisha telefon yonida bo'lsin. "
          "Ish joyiga tug'ruq yaqin ekanini aytib qo'ying.",
      nutrition: "Faol harakatlanib turing — engil yurish. "
          "Limon, zanjabil — ko'ngil aynishiga yordam.",
    ),
    36: WeekData(
      babyVoice: "Onajon, deyarli tayyor! "
          "Men qovoq kabi — to'la yetilgan. "
          "Pastga tushyapman — tug'ilishga tayyorlanmoqda 📍 "
          "Siz endi nafas olishingiz osonlashdi, lekin hojatxonaga ko'p borasiz — "
          "kechirasiz 😅",
      developing: "Pastga tushish, o'pka to'liq tayyor",
      momTip: "Muddatidan oldin tug'ruq belgileri: qisqarishlar 10 daqiqada 1 marta, "
          "suv ketishi.",
      dadTip: "Tug'ruq sumkasi tayyor bo'lsin. "
          "Har kuni ahvolini so'rang.",
      nutrition: "Xurmo (tug'ruqni osonlashtiradi, ilmiy tasdiqlangan). "
          "Malina choy ichi.",
    ),
    38: WeekData(
      babyVoice: "Onajon, men to'liq yetildim! "
          "Barcha organlarim ishlayapti. "
          "Mening sochim, tirnoqlarim, kipriqlarim bor. "
          "Sizni ushlagim kelyapdi — tez orada! 🤱",
      developing: "To'liq yetilish, barcha organlar tayyor",
      momTip: "Istalgan kunda tug'ruq boshlanishi mumkin. "
          "Qisqarishlarni sanab boring.",
      dadTip: "Har doim tayyor, telefon zaryadlangan bo'lsin. "
          "Onani yolg'iz qoldirmang.",
      nutrition: "Engil, hazm bo'ladigan ovqat. "
          "Ko'p suv iching.",
    ),
    40: WeekData(
      babyVoice: "Onajon, MEN TAYYOR! 🌟 "
          "Bu kichkina joy endi torlik qilyapdi. "
          "Sizi ko'rishni orziqlayapman. "
          "Kuchingizni yig'ing — biz birga bu safarni boshlagan edik, "
          "endi birga yakunlaymiz. Oʻzingiz bilan faxrlaning! 💕",
      developing: "To'liq yetilgan, tug'ilishga tayyor",
      momTip: "Sabrli bo'ling — har bir homiladorlik o'ziga xos. "
          "Siz qahramonsiz.",
      dadTip: "Onaning qo'lini ushlab turing. "
          "Bu lahza umr bo'yi esda qoladi.",
      nutrition: "Engil, energiya beradigan ovqat. "
          "Ko'p suv. Xurmo.",
    ),
  };
}
