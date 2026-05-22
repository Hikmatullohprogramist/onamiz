// ─── Baby cry types & advice ──────────────────────────────────
class CryType {
  final String emoji;
  final String label;
  final String description;
  final String advice;
  const CryType({
    required this.emoji, required this.label,
    required this.description, required this.advice,
  });
}

const babyCryTypes = [
  CryType(
    emoji: '🍼',
    label: 'Och qolgan',
    description: 'Muntazam, ritmik yig\'i. Ovoz kuchayib boradi.',
    advice: 'Emizib ko\'ring — och qolganda yig\'i tezda to\'xtaydi. '
        'Oxirgi emizishdan 2-3 soat o\'tgan bo\'lsa, ehtimol och.',
  ),
  CryType(
    emoji: '😴',
    label: 'Uxlagisi kelmoqda',
    description: 'Past, monoton yig\'i. Ko\'zlari yumiladi.',
    advice: 'Xona yorug\'ini kamaytiring. Chayqating yoki erkalang. '
        'Dam olish vaqti — hadeb uyg\'otmang.',
  ),
  CryType(
    emoji: '💧',
    label: 'Qulog\'i namlangan',
    description: 'Birdan boshlanadi. Oyoqlarini qimirlatadi.',
    advice: 'Qulog\'ini tekshiring. Quruq quloq — quruq chaqaloq. '
        'Almashtirib, toza va quruq saqlang.',
  ),
  CryType(
    emoji: '🤒',
    label: 'Og\'rig\'i bor',
    description: 'Kuchli, o\'tkir, to\'xtovsiz yig\'i. Old tomonga egiladi.',
    advice: 'Haroratini o\'lchang. Qorni katta bo\'lsa, gaz bo\'lishi mumkin — '
        'oyoqlarini velosiped kabi aylantiring. 38°C dan yuqori bo\'lsa shifokorga.',
  ),
  CryType(
    emoji: '🤗',
    label: "E'tibor istayapti",
    description: 'Tanaffusli yig\'i. To\'xtatib, kutib turishadi.',
    advice: "Bag'ringizga oling, gapiring, kuling. Ko\'z aloqasi o\'rnating. "
        "3 oydan oldin bolalar ko'p e'tibor talab qiladi — bu normal.",
  ),
];

// ─── Monthly development data ─────────────────────────────────
class MonthData {
  final int month;
  final String babyVoice;    // bolaning "aytishi"
  final List<String> milestones;
  final String weight;
  final String height;
  final String? vaccine;     // bu oyda emlash bo'lsa

  const MonthData({
    required this.month,
    required this.babyVoice,
    required this.milestones,
    required this.weight,
    required this.height,
    this.vaccine,
  });
}

class BabyData {
  static MonthData forMonth(int month) {
    final m = month.clamp(0, 24);
    return _data[m] ?? _data[_nearest(m)]!;
  }

  static int _nearest(int m) =>
      _data.keys.reduce((a, b) => (a - m).abs() < (b - m).abs() ? a : b);

  static const Map<int, MonthData> _data = {
    0: MonthData(
      month: 0,
      babyVoice: "Onajon, men shu yerdaman! Sening yuzingni ko'rish menga eng "
          "yaxshi tuhfa. Sening hidingni taniyapman — meni quching! 🤱",
      milestones: [
        'Reflex harakatlari (so\'rish, ushlash)',
        'Yorug\'lik va kuchli ovozga reaksiya',
        'Ko\'z bilan kuzatib borolmaydi (20-30sm oralig\'i)',
        'Yig\'ish — yagona muloqot usuli',
      ],
      weight: '3.0–4.5 kg',
      height: '48–52 sm',
      vaccine: 'BCG (sil kasalligi), Gepatit B — 1',
    ),
    1: MonthData(
      month: 1,
      babyVoice: "Onajon, men sening yuzingni ko'ra boshladim! Kulishni "
          "o'rganyapman — bu mening 'rahmat' aytishim 😊",
      milestones: [
        'Birinchi ijtimoiy tabassum',
        'Boshini qisqa vaqt ko\'tara oladi',
        'Ovozga buriladi',
        'Ko\'zini kuzatib boradi',
      ],
      weight: '4.0–5.5 kg',
      height: '52–56 sm',
      vaccine: null,
    ),
    2: MonthData(
      month: 2,
      babyVoice: "Onajon, 'agu-gu' deyman! Bu mening gapim — men siz bilan "
          "suhbatlashmoqchiman. Rangli narsalarga qiziqaman 🌈",
      milestones: [
        'Agu-gu tovushlari',
        'Boshini 45 darajaga ko\'tara oladi',
        'Qo\'llarini va oyoqlarini harakatlantirishga qiziqadi',
        'Ko\'zlarini suyuqlikka ergashtira oladi',
      ],
      weight: '5.0–6.5 kg',
      height: '55–59 sm',
      vaccine: 'DTP-1, IPV-1, Hib-1, Gepatit B — 2, PCV-1',
    ),
    3: MonthData(
      month: 3,
      babyVoice: "Onajon, men kulgichman! Har narsadan kulaman. "
          "Qo\'llarimni ko\'ryapman — bu nimalar? 🤔 Men rivojlanyapman!",
      milestones: [
        'Qat\'iy kulish (qahqaha)',
        'Qo\'llarini og\'ziga oladi',
        'Narsalarga qo\'l uzatishga urinadi',
        'Boshini yaxshi ushlab turadi',
      ],
      weight: '5.8–7.5 kg',
      height: '58–62 sm',
      vaccine: 'DTP-2, IPV-2, Hib-2, PCV-2',
    ),
    4: MonthData(
      month: 4,
      babyVoice: "Onajon, men narsalarni ushlayapman! Hamma narsa og\'zimga "
          "kiradi — bu mening o\'rganish usulim. O\'tirishga tayyorlanmoqdaman 🧸",
      milestones: [
        'Narsalarni ushlab ola oladi',
        'Ko\'kragini ko\'tarib tura oladi',
        'Yon tomonga ag\'anaydi (qorindan orqaga)',
        'Yuzlarni taniydi',
      ],
      weight: '6.5–8.0 kg',
      height: '61–65 sm',
      vaccine: 'DTP-3, IPV-3, Hib-3, Gepatit B — 3, PCV-3',
    ),
    6: MonthData(
      month: 6,
      babyVoice: "Onajon, men o\'tirmoqdaman! 'mama', 'baba' deyman — "
          "seni chaqiryapman. Qo\'shimcha ovqat vaqti boshlandi 🥣",
      milestones: [
        'Qo\'llab o\'tiradi',
        'Birinchi bo\'g\'inli tovushlar (ba, ma, da)',
        'Begonalarga ehtiyotkorlik',
        'Narsani bir qo\'ldan ikkinchisiga uzatadi',
      ],
      weight: '7.5–9.0 kg',
      height: '65–69 sm',
      vaccine: 'Gepatit A — 1 (tavsiya etiladi)',
    ),
    9: MonthData(
      month: 9,
      babyVoice: "Onajon, men siljib yuraman! Hamma narsa qiziq. "
          "'Mama' va 'baba' ni bilaman. Tushirsangiz yig\'layman — "
          "chunki seni sog\'inaman 💕",
      milestones: [
        'Emaklab yuradi yoki siljiydi',
        'O\'tirib yotadi va aksincha',
        'Ko\'rsatma tushunadi ("yo\'q", "kel")',
        'Pinset ushlash (bosh va ko\'rsatkich barmoq)',
      ],
      weight: '8.5–10.5 kg',
      height: '69–74 sm',
      vaccine: null,
    ),
    12: MonthData(
      month: 12,
      babyVoice: "Onajon, men bir yoshdaman! Birinchi qadamlarim — "
          "hayajonlimi? Birinchi so\'zlarim bor. Kek kerak 🎂",
      milestones: [
        'Birinchi qadamlar (10-14 oy oralig\'ida normal)',
        'Ma\'no anglatuvchi 1-3 so\'z',
        'Ko\'rsatish va imlash ishoralari',
        'Oddiy topshiriqlarni bajaradi',
      ],
      weight: '9.0–11.5 kg',
      height: '73–78 sm',
      vaccine: 'MMR — 1 (qizamiq, parotit, qizilcha), Varicella',
    ),
    18: MonthData(
      month: 18,
      babyVoice: "Onajon, men yurayapman! Ko\'p so\'zlarim bor. "
          "'Yo\'q' — sevimli so\'zim. Mustaqil bo\'lmoqchiman! 🚶",
      milestones: [
        'Mustaqil yuradi, egiladi',
        '10-20 so\'z lug\'ati',
        'Kalit, qoshiq, shisha kabi narsalarni ishlatadi',
        'Naqsh kitoblarini ko\'radi',
      ],
      weight: '10.0–13.0 kg',
      height: '78–84 sm',
      vaccine: 'DTP — 4 (revaksinatsiya), OPV — 4, MMR — 2',
    ),
    24: MonthData(
      month: 24,
      babyVoice: "Onajon, men ikki yoshdaman! 2-3 so\'zli jumlalar gapiraman. "
          "'Men o\'zim!' — eng sevimli gapim. Katta bolaman! 🦁",
      milestones: [
        '50+ so\'z lug\'ati, 2-3 so\'zli jumlalar',
        'Yuguradi, sakraydi',
        'Qoshiq va vilkadan foydalanadi',
        'Kattalar o\'yinini kuzatib o\'ynaydi',
      ],
      weight: '11.0–14.5 kg',
      height: '83–89 sm',
      vaccine: null,
    ),
  };
}

// ─── Vaccination schedule ─────────────────────────────────────
class Vaccine {
  final int month;
  final String name;
  final String fullName;
  final String description;

  const Vaccine({
    required this.month, required this.name,
    required this.fullName, required this.description,
  });
}

const vaccineSchedule = [
  Vaccine(
    month: 0, name: 'BCG + Hep B-1',
    fullName: "BCG (Sil) + Gepatit B birinchi dozasi",
    description: "Tug'ilgandan so'ng kasalxonada qilinadi.",
  ),
  Vaccine(
    month: 2, name: 'DTP-1 + boshqalar',
    fullName: "DTP, IPV, Hib, Hep B-2, PCV birinchi dozalar",
    description: "5 ta emlash bir vaqtda — kuchli himoya.",
  ),
  Vaccine(
    month: 3, name: 'DTP-2 + boshqalar',
    fullName: "DTP, IPV, Hib, PCV ikkinchi dozalar",
    description: "Immunitetni mustahkamlash.",
  ),
  Vaccine(
    month: 4, name: 'DTP-3 + boshqalar',
    fullName: "DTP, IPV, Hib, Hep B-3, PCV uchinchi dozalar",
    description: "Asosiy emlash kursi tugaydi.",
  ),
  Vaccine(
    month: 12, name: 'MMR + Varicella',
    fullName: "Qizamiq, Parotit, Qizilcha + Suv puchasi",
    description: "Bir yoshda muhim emlashlar.",
  ),
  Vaccine(
    month: 18, name: 'DTP-4 + MMR-2',
    fullName: "DTP, OPV revaksinatsiya + MMR ikkinchi doza",
    description: "Immunitetni qayta oshirish.",
  ),
];
