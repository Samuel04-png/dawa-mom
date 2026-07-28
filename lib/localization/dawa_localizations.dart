import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class DawaLanguages {
  static const english = 'English';
  static const nyanja = 'Nyanja';
  static const bemba = 'Bemba';
  static const tonga = 'Tonga';
  static const lozi = 'Lozi';

  static const names = <String>[
    english,
    nyanja,
    bemba,
    tonga,
    lozi,
  ];

  static const locales = <Locale>[
    Locale('en', 'ZM'),
    Locale('ny', 'ZM'),
    Locale('bem', 'ZM'),
    Locale('toi', 'ZM'),
    Locale('loz', 'ZM'),
  ];

  static Locale localeForName(String? name) => switch (name?.toLowerCase()) {
        'nyanja' || 'chichewa' => locales[1],
        'bemba' => locales[2],
        'tonga' => locales[3],
        'lozi' => locales[4],
        _ => locales[0],
      };

  static String nameForLocale(Locale locale) =>
      switch (locale.languageCode.toLowerCase()) {
        'ny' => nyanja,
        'bem' => bemba,
        'toi' => tonga,
        'loz' => lozi,
        _ => english,
      };
}

class DawaLocaleController extends ChangeNotifier {
  DawaLocaleController._();

  static final instance = DawaLocaleController._();
  static const preferenceKey = 'dawa_preference_language';

  Locale _locale = DawaLanguages.locales.first;

  Locale get locale => _locale;
  String get languageName => DawaLanguages.nameForLocale(_locale);

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    _locale = DawaLanguages.localeForName(
      preferences.getString(preferenceKey),
    );
  }

  Future<void> reload() async {
    final preferences = await SharedPreferences.getInstance();
    await setLanguage(
      preferences.getString(preferenceKey) ?? DawaLanguages.english,
      persist: false,
    );
  }

  Future<void> setLanguage(
    String language, {
    bool persist = true,
  }) async {
    final next = DawaLanguages.localeForName(language);
    if (persist) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        preferenceKey,
        DawaLanguages.nameForLocale(next),
      );
    }
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
  }
}

extension DawaTranslationContext on BuildContext {
  String tr(String source) => DawaTranslations.translate(
        source,
        Localizations.maybeLocaleOf(this) ??
            DawaLocaleController.instance.locale,
      );
}

abstract final class DawaTranslations {
  static String translate(String source, Locale locale) {
    var normalized = source
        .replaceAll('Dawa Mom', 'DawaMom')
        .replaceAll('DAWA MOM', 'DAWAMOM');
    final languageIndex = switch (locale.languageCode.toLowerCase()) {
      'ny' => 0,
      'bem' => 1,
      'toi' => 2,
      'loz' => 3,
      _ => -1,
    };
    if (languageIndex < 0 || normalized.trim().isEmpty) return normalized;

    final exact = _messages[normalized];
    if (exact != null) return exact[languageIndex];

    for (final entry in _orderedMessages) {
      normalized = _replacePhrase(
        normalized,
        entry.key,
        entry.value[languageIndex],
      );
    }
    return normalized;
  }

  static String _replacePhrase(
    String source,
    String phrase,
    String replacement,
  ) {
    var cursor = 0;
    final output = StringBuffer();
    while (cursor < source.length) {
      final match = source.indexOf(phrase, cursor);
      if (match < 0) {
        output.write(source.substring(cursor));
        break;
      }
      final beforeIsWord = match > 0 &&
          _isEnglishWordCharacter(source.codeUnitAt(match - 1)) &&
          _isEnglishWordCharacter(phrase.codeUnitAt(0));
      final afterIndex = match + phrase.length;
      final afterIsWord = afterIndex < source.length &&
          _isEnglishWordCharacter(source.codeUnitAt(afterIndex)) &&
          _isEnglishWordCharacter(phrase.codeUnitAt(phrase.length - 1));
      if (beforeIsWord || afterIsWord) {
        output.write(source.substring(cursor, afterIndex));
        cursor = afterIndex;
        continue;
      }
      output
        ..write(source.substring(cursor, match))
        ..write(replacement);
      cursor = afterIndex;
    }
    return output.toString();
  }

  static bool _isEnglishWordCharacter(int codeUnit) =>
      codeUnit >= 48 && codeUnit <= 57 ||
      codeUnit >= 65 && codeUnit <= 90 ||
      codeUnit >= 97 && codeUnit <= 122;

  static String? maybeTranslate(String? source, Locale locale) =>
      source == null ? null : translate(source, locale);

  static final _orderedMessages = _messages.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));

  // Each entry is English: [Nyanja, Bemba, Tonga, Lozi].
  // Clinical copy remains intentionally plain and should be reviewed by
  // qualified native-language reviewers before public health campaigns.
  static const _messages = <String, List<String>>{
    'DawaMom': ['DawaMom', 'DawaMom', 'DawaMom', 'DawaMom'],
    'Educational image about cervical health and screening': [
      'Chithunzi chophunzitsa cha thanzi la khomo la chiberekero ndi kuyezetsa',
      'Ichikope ca masambililo pa bumi bwa mulomo wa chibako no kupimwa',
      'Chikozyanyo chakuyiisya atala abuumibwabukaintu akupimwa',
      'Seswaniso sa tuto ya buiketo bwa popelo ni kuhlolwa',
    ],
    'Educational image about preparing for health screening': [
      'Chithunzi chophunzitsa cha kukonzekera kuyezetsa thanzi',
      'Ichikope ca masambililo pa kupekanya ukupimwa ubumi',
      'Chikozyanyo chakuyiisya atala akulibambila kupimwa buumi',
      'Seswaniso sa tuto ya kulukela kuhlolwa kwa buiketo',
    ],
    'Educational image about pregnancy wellbeing': [
      'Chithunzi chophunzitsa cha umoyo pa mimba',
      'Ichikope ca masambililo pa bumi bwa bukulu',
      'Chikozyanyo chakuyiisya atala abuumi bwamukaintu uuli alimita',
      'Seswaniso sa tuto ya buiketo mwa nako ya mba',
    ],
    'Educational image about balanced food during pregnancy': [
      'Chithunzi chophunzitsa cha chakudya choyenera pa mimba',
      'Ichikope ca masambililo pa filyo fyalingana mu bukulu',
      'Chikozyanyo chakuyiisya atala azyakulya ziluleme mumita',
      'Seswaniso sa tuto ya lico za swanelo mwa nako ya mba',
    ],
    'Educational image about preparing for a clinic visit': [
      'Chithunzi chophunzitsa cha kukonzekera kupita ku chipatala',
      'Ichikope ca masambililo pa kupekanya ukuya ku ciliniki',
      'Chikozyanyo chakuyiisya atala akulibambila kuya kukiliniki',
      'Seswaniso sa tuto ya kulukela ku ya kwa kiliniki',
    ],
    'Educational image about discussing health myths and facts': [
      'Chithunzi chophunzitsa cha kukambirana nthano ndi zoona za thanzi',
      'Ichikope ca masambililo pa landanya inkaani ne fishinka pa bumi',
      'Chikozyanyo chakuyiisya atala amitwezyo amazima abuumi',
      'Seswaniso sa tuto ya kukanelisana za lipuzo ni niti za buiketo',
    ],
    'Educational image about periods and cycle tracking': [
      'Chithunzi chophunzitsa cha kusamba kwa mwezi ndi kutsatira nthawi',
      'Ichikope ca masambililo pa menshi ya mwezi no kulondolola inshita',
      'Chikozyanyo chakuyiisya atala akusamba kwamwezi akulondola ciindi',
      'Seswaniso sa tuto ya linako za khoeli ni kuzilandula',
    ],
    'Educational image about antenatal visits and pregnancy stages': [
      'Chithunzi chophunzitsa cha maulendo a pakati ndi magawo a mimba',
      'Ichikope ca masambililo pa maendo ya bukulu ne miputule ya bukulu',
      'Chikozyanyo chakuyiisya atala akuya kukiliniki amatanho amita',
      'Seswaniso sa tuto ya maeto a mba ni likalulo za mba',
    ],
    'Educational image about postpartum recovery and support': [
      'Chithunzi chophunzitsa cha kuchira pambuyo pobereka ndi thandizo',
      'Ichikope ca masambililo pa kupola panuma ya kufyala no kwafwa',
      'Chikozyanyo chakuyiisya atala akupola musule akuzyaala arukwabililo',
      'Seswaniso sa tuto ya kufola hamulaho wa peho ni tuso',
    ],
    'DawaMom maternal health': [
      'DawaMom thanzi la amayi',
      'DawaMom ubumi bwa ba mayo',
      'DawaMom buumi bwabamayi',
      'DawaMom buiketo bwa bomme',
    ],
    'Welcome to DawaMom': [
      'Takulandirani ku DawaMom',
      'Mwaiseni ku DawaMom',
      'Twaamutambula ku DawaMom',
      'Mwa amuhelwa ku DawaMom',
    ],
    'Home': ['Kunyumba', 'Ku Ng’anda', 'Ku Ng’anda', 'Kwa hae'],
    'Track': ['Tsatirani', 'Londololeni', 'Londolani', 'Latelela'],
    'Care': ['Chisamaliro', 'Ukusakamana', 'Lutalililo', 'Pabalelo'],
    'Learn': ['Phunzirani', 'Sambilileni', 'Iya', 'Ithute'],
    'Profile': ['Mbiri yanga', 'Imbila yandi', 'Makani aangu', 'Taba za ka'],
    'Your pregnancy': [
      'Mimba yanu',
      'Ifumo lyenu',
      'Bulemu bwanu',
      'Boimana bwa hao',
    ],
    'Your cycle today': [
      'Kayendedwe kanu lero',
      'Cycle yenu ubushiku buno',
      'Kuzunguluka kwanu sunu',
      'Mukoloko wa hao kacenu',
    ],
    'Your health today': [
      'Thanzi lanu lero',
      'Ubumi bwenu ubushiku buno',
      'Buumi bwanu sunu',
      'Buiketo bwa hao kacenu',
    ],
    'Every small step matters.': [
      'Chinthu chilichonse chaching’ono n’chofunika.',
      'Icitampulo conse icinono cilafwa.',
      'Citaambo ciliconse ciceya cilayandika.',
      'Muhato omunyinyani kaufela wa butokwa.',
    ],
    'View pregnancy': [
      'Onani za mimba',
      'Moneni ifya ifumo',
      'Bona makani aabulemu',
      'Bona za boimana',
    ],
    'View cycle': [
      'Onani kayendedwe',
      'Moneni cycle',
      'Bona kuzunguluka',
      'Bona mukoloko',
    ],
    'Explore Learn': [
      'Pitani ku Phunzirani',
      'Kabiyeni ku Sambilileni',
      'Amuye ku Iya',
      'Ya ku Ithute',
    ],
    'Finish your health profile': [
      'Malizani mbiri yanu ya thanzi',
      'Pwisheni imbila yenu iya ubumi',
      'Manizya makani aanu aabuumi',
      'Feleza taba za hao za buiketo',
    ],
    'Next step: add your name and date of birth.': [
      'Chotsatira: onjezani dzina ndi tsiku lobadwa.',
      'Icilakonkapo: bikenimo ishina na bushiku mwafyelwe.',
      'Cilakonzyaho: bikkani zina abuzuba bwakuzyalwa.',
      'Muhato o latela: kenya libizo ni lizazi la peho.',
    ],
    'Next step: add a phone number and address.': [
      'Chotsatira: onjezani nambala ya foni ndi adiresi.',
      'Icilakonkapo: bikenimo namba ya foni na keyala.',
      'Cilakonzyaho: bikkani namba yafoni akkeyala.',
      'Muhato o latela: kenya nombolo ya foni ni keyala.',
    ],
    'Next step: choose your pregnancy status.': [
      'Chotsatira: sankhani momwe mulili pa nkhani ya mimba.',
      'Icilakonkapo: saleni ifya ifumo lyenu.',
      'Cilakonzyaho: sankhani makani aabulemu bwanu.',
      'Muhato o latela: keta taba ya boimana bwa hao.',
    ],
    'Next step: add the first day of your last period.': [
      'Chotsatira: onjezani tsiku loyamba la msambo womaliza.',
      'Icilakonkapo: bikenimo ubushiku bwa ntanshi ubwa mweshi walekelesha.',
      'Cilakonzyaho: bikkani buzuba bwakusaanguna bwamwezi wakumamanino.',
      'Muhato o latela: kenya lizazi la pili la linako la mafelelezo.',
    ],
    'Your health profile is ready.': [
      'Mbiri yanu ya thanzi yakonzeka.',
      'Imbila yenu iya ubumi yapangwa.',
      'Makani aanu aabuumi alilibambilwe.',
      'Taba za hao za buiketo li lukile.',
    ],
    'Today’s pick': [
      'Zosankhidwa lero',
      'Ifyasankwa ubushiku buno',
      'Zyasankwa sunu',
      'Ze ketilwe kacenu',
    ],
    'The Mother’s Path': [
      'Njira ya Amayi',
      'Inshila ya ba Mayo',
      'Nzila ya Bamayi',
      'Nzila ya Bomme',
    ],
    'Your guide and friend': [
      'Wokutsogolerani ndi mnzanu',
      'Kapokolola kabili cibusa wenu',
      'Mulongwezi alimwi munzuma wanu',
      'Mueteleli ni mulikani wa hao',
    ],
    'Bana Chenjela, your guide': [
      'Bana Chenjela, wokutsogolerani',
      'Bana Chenjela, kapokolola wenu',
      'Bana Chenjela, mulongwezi wanu',
      'Bana Chenjela, mueteleli wa hao',
    ],
    'Settings': ['Zokonda', 'Amafunde', 'Misetelo', 'Litukiso'],
    'Language': ['Chilankhulo', 'Ululimi', 'Mulaka', 'Puo'],
    'English': ['Chingelezi', 'IciNgeleshi', 'Chingisi', 'Sikuwa'],
    'Nyanja': ['Chinyanja', 'Chinyanja', 'Chinyanja', 'Sinyanja'],
    'Bemba': ['Chibemba', 'Ichibemba', 'Chibemba', 'Sibemba'],
    'Tonga': ['Chitonga', 'Chitonga', 'Chitonga', 'Sitonga'],
    'Lozi': ['Chilozi', 'Silozi', 'Chilozi', 'Silozi'],
    'Choose language': [
      'Sankhani chilankhulo',
      'Saleni ululimi',
      'Sankhani mulaka',
      'Keta puo',
    ],
    'Select the language you’re most comfortable with.': [
      'Sankhani chilankhulo chimene mumamasuka nacho.',
      'Saleni ululimi ulo mwatemwa ukusebenzisa.',
      'Sankhani mulaka ngwamuyanda.',
      'Keta puo ye uikutwa hande ka yona.',
    ],
    'Use this language for lessons': [
      'Gwiritsani chilankhulochi pa maphunziro',
      'Bomfyeni ululimi ulu mu masambililo',
      'Amugwasye mulaka ooyu mumakani aakuyi',
      'Sebenzisa puo ye kwa lituto',
    ],
    'Use this language with Rudo': [
      'Gwiritsani chilankhulochi ndi Rudo',
      'Bomfyeni ululimi ulu na Rudo',
      'Amugwasye mulaka ooyu a Rudo',
      'Sebenzisa puo ye ni Rudo',
    ],
    'Articles and lessons use this preference.': [
      'Nkhani ndi maphunziro zidzagwiritsa ntchito chilankhulochi.',
      'Ifyakubelenga na masambililo fikabomfya ululimi ulu.',
      'Makani aakubelenga azyakuyi zilagwasya mulaka ooyu.',
      'Lisengolwa ni lituto li ka sebelisa puo ye.',
    ],
    'Rudo will use this language when supported.': [
      'Rudo adzagwiritsa ntchito chilankhulochi ngati chilipo.',
      'Rudo akabomfya ululimi ulu nga lwasuminishiwa.',
      'Rudo ulakonzya kugwasya mulaka ooyu naa ulipo.',
      'Rudo u ka sebelisa puo ye ha i sebeliswa.',
    ],
    'Save language': [
      'Sungani chilankhulo',
      'Sungeni ululimi',
      'Bikkani mulaka',
      'Buluka puo',
    ],
    'Cancel': ['Letsani', 'Lesheni', 'Lekani', 'Hana'],
    'Save': ['Sungani', 'Sungeni', 'Bikkani', 'Buluka'],
    'Done': ['Zatha', 'Chapwa', 'Kwamana', 'Felezi'],
    'Continue': ['Pitirizani', 'Twilileni', 'Amuyaanjilile', 'Tswelapili'],
    'Back': ['Bwererani', 'Bwelaleni', 'Bwela', 'Ku mulao'],
    'Close': ['Tsekani', 'Isaleni', 'Jala', 'Kwala'],
    'Retry': ['Yesaninso', 'Esheni na kabili', 'Ezyanisya alimwi', 'Leka hape'],
    'Check again': [
      'Onaninso',
      'Moneni na kabili',
      'Amulange alimwi',
      'Bona hape',
    ],
    'Try again': [
      'Yesaninso',
      'Esheni na kabili',
      'Ezyanisya alimwi',
      'Leka hape',
    ],
    'Loading': ['Ikutsegula', 'Ileloleka', 'Kuyobolola', 'Kulayisa'],
    'Search': ['Sakani', 'Fwayeni', 'Jana', 'Bata'],
    'Select date': [
      'Sankhani tsiku',
      'Saleni ubushiku',
      'Sankhani buzuba',
      'Keta lizazi',
    ],
    'Select year': [
      'Sankhani chaka',
      'Saleni umwaka',
      'Sankhani mwaka',
      'Keta silimo',
    ],
    'Select date range': [
      'Sankhani masiku',
      'Saleni inshiku',
      'Sankhani mazuba',
      'Keta mazazi',
    ],
    'Select time': [
      'Sankhani nthawi',
      'Saleni inshita',
      'Sankhani ciindi',
      'Keta nako',
    ],
    'Enter date': [
      'Lembani tsiku',
      'Lembeni ubushiku',
      'Lembani buzuba',
      'Ngola lizazi',
    ],
    'Enter time': [
      'Lembani nthawi',
      'Lembeni inshita',
      'Lembani ciindi',
      'Ngola nako',
    ],
    'Hour': ['Ola', 'Insa', 'Aawola', 'Hora'],
    'Minute': ['Mphindi', 'Miniti', 'Miniti', 'Muzuzu'],
    'Enter a valid time': [
      'Lembani nthawi yolondola',
      'Lembeni inshita iyalungama',
      'Lembani ciindi ciluzi',
      'Ngola nako ye nepa',
    ],
    'Switch to calendar': [
      'Pitani pa kalendala',
      'Alukileni ku kalenda',
      'Amucincile ku kalenda',
      'Fetolela kwa khalenda',
    ],
    'Switch to text input': [
      'Pitani polemba',
      'Alukileni ku kulemba',
      'Amucincile kukulemba',
      'Fetolela kwa ku ngola',
    ],
    'Switch to clock': [
      'Pitani pa koloko',
      'Alukileni ku koloko',
      'Amucincile ku wachi',
      'Fetolela kwa watjhi',
    ],
    'Invalid date format.': [
      'Kalembedwe ka tsiku ndi kolakwika.',
      'Ifyalembwa fya bushiku tafyalungama.',
      'Kalembelo kabuzuba takaluzi.',
      'Mongolelo wa lizazi ha u nepa.',
    ],
    'Invalid date range.': [
      'Masiku osankhidwa ndi olakwika.',
      'Inshiku shasankwa tashalungama.',
      'Mazuba aasankwa taaluzi.',
      'Mazazi a ketilwe ha a nepa.',
    ],
    'Date is out of range.': [
      'Tsikuli lili kunja kwa malire.',
      'Ubushiku buli panse ya mpela.',
      'Buzuba buli aande lyampaka.',
      'Lizazi li kwa nze a sikala.',
    ],
    'Clear': ['Chotsani', 'Fumyeni', 'Fumyani', 'Tlosa'],
    'Delete': ['Chotsani', 'Fumyeni', 'Fumyani', 'Tima'],
    'More': ['Zambiri', 'Nafimbi', 'Zimbi', 'Ze ñata'],
    'Selected': ['Yasankhidwa', 'Casalwa', 'Cakasankwa', 'I ketilwe'],
    'Dismiss': ['Tsekani', 'Isaleni', 'Jala', 'Kwala'],
    'Copy': ['Koperani', 'Kopololeni', 'Kopolola', 'Kopisa'],
    'Cut': ['Dulani', 'Putuleni', 'Gonkola', 'Poma'],
    'Paste': ['Matani', 'Patikeni', 'Bikka', 'Kgomaretsa'],
    'Select all': [
      'Sankhani zonse',
      'Saleni fyonse',
      'Sankhani zyoonse',
      'Keta kaufela',
    ],
    'OK': ['Chabwino', 'Ee', 'Kabotu', 'Hande'],
    'Open navigation menu': [
      'Tsegulani menyu',
      'Isuleni menu',
      'Isuleni menu',
      'Atolosa menyu',
    ],
    'Next month': [
      'Mwezi wotsatira',
      'Umweshi ukonkapo',
      'Mwezi utobela',
      'Kwezi ye latela',
    ],
    'Previous month': [
      'Mwezi wapitawo',
      'Umweshi wapitapo',
      'Mwezi wakunyuma',
      'Kwezi ye fetile',
    ],
    'All': ['Zonse', 'Fyonse', 'Zyoonse', 'Ze kaufela'],
    'Got it': ['Ndamva', 'Nalyumfwa', 'Ndamvwa', 'Ni utwile'],
    'Set': ['Ikani', 'Pangeni', 'Bikkani', 'Beha'],
    'Ok': ['Chabwino', 'Ee', 'Kabotu', 'Hande'],
    'Offline': [
      'Palibe intaneti',
      'Takuli intaneti',
      'Kunyina intaneti',
      'Ha ku na intaneti',
    ],
    'When': ['Nthawi', 'Inshita', 'Ciindi', 'Nako'],
    'Location': ['Malo', 'Incende', 'Mbubonya', 'Sibaka'],
    'Recorded': ['Zalembedwa', 'Fyalembwa', 'Zyalembwa', 'I ngolilwe'],
    'Recommendations': ['Malangizo', 'Amalango', 'Malailile', 'Litaelo'],
    'Yes': ['Inde', 'Ee', 'Inzya', 'Eeni'],
    'No': ['Ayi', 'Awe', 'Peepe', 'Batili'],
    'Today': ['Lero', 'Uno Mushi', 'Sunu', 'Kacenu'],
    'January': ['Januwale', 'Januari', 'Januali', 'Sopa'],
    'February': ['Febuluwale', 'Februari', 'Febulali', 'Tlhakola'],
    'March': ['Malichi', 'Machi', 'Malichi', 'Hlakubele'],
    'April': ['Epulo', 'Epulelo', 'Apulelo', 'Mesa'],
    'May': ['Meyi', 'Meyi', 'Meyi', 'Motshehanong'],
    'June': ['Juni', 'Juni', 'Juni', 'Phupjane'],
    'July': ['Julayi', 'Julai', 'Julayi', 'Phupu'],
    'August': ['Ogasiti', 'Ogasiti', 'Ogasiti', 'Phato'],
    'September': ['Seputembala', 'Septemba', 'Seputemba', 'Loetse'],
    'October': ['Okutobala', 'Oktoba', 'Okutoba', 'Mphalane'],
    'November': ['Novembala', 'Novemba', 'Novemba', 'Pulungoana'],
    'December': ['Disembala', 'Desemba', 'Disemba', 'Tšitoe'],
    'Monday': ['Lolemba', 'Cimo', 'Muvulo', 'Musulo'],
    'Tuesday': ['Lachiwiri', 'Cibili', 'Chipiri', 'Labobeli'],
    'Wednesday': ['Lachitatu', 'Citatu', 'Chitatu', 'Laboraro'],
    'Thursday': ['Lachinayi', 'Cine', 'China', 'Labone'],
    'Friday': ['Lachisanu', 'Cisano', 'Chisanu', 'Labohlano'],
    'Saturday': ['Loweruka', 'Cibelushi', 'Mugibelo', 'Moqebelo'],
    'Sunday': ['Lamlungu', 'Pa Mulungu', 'Sondo', 'Sontaha'],
    'Notifications': ['Zidziwitso', 'Ifilango', 'Zizibisyo', 'Litsebiso'],
    'Notification preferences': [
      'Zokonda za zidziwitso',
      'Amafunde ya ifilango',
      'Misetelo yazizibisyo',
      'Litukiso za litsebiso',
    ],
    'Your updates': [
      'Zosintha zanu',
      'Ifya cinja fyenu',
      'Zyakacinca zyanu',
      'Linchafazo za hao',
    ],
    'Preferences': ['Zokonda', 'Amafunde', 'Misetelo', 'Liketo'],
    'Appointments': [
      'Maapointimenti',
      'Ama appointment',
      'Ma appointment',
      'Likopano'
    ],
    'Appointment': ['Apoyintimenti', 'Appointment', 'Appointment', 'Kopano'],
    'Book appointment': [
      'Sungitsani nthawi',
      'Bikisheni appointment',
      'Bamba appointment',
      'Beha kopano',
    ],
    'Book an appointment': [
      'Sungitsani nthawi yokumana',
      'Bikisheni appointment',
      'Bamba appointment',
      'Beha kopano',
    ],
    'Book': ['Sungitsani', 'Bikisheni', 'Bamba', 'Beha'],
    'Clinic': ['Chipatala', 'Kiliniki', 'Chipatala', 'Kiliniki'],
    'Clinician': ['Wachipatala', 'Shinganga', 'Mukoti', 'Muokoti'],
    'Date': ['Tsiku', 'Ubushiku', 'Buzuba', 'Lizazi'],
    'Time': ['Nthawi', 'Inshita', 'Ciindi', 'Nako'],
    'Upcoming appointment': [
      'Nthawi yakuchipatala ikubwera',
      'Appointment ileisa',
      'Appointment iisala',
      'Kopano ye taha',
    ],
    'Appointment reminder': [
      'Chikumbutso cha nthawi',
      'Icibukisho ca appointment',
      'Cikumbusyo ca appointment',
      'Khopotso ya kopano',
    ],
    'Appointment details': [
      'Zambiri za nthawi',
      'Ifyebo fya appointment',
      'Makani aa appointment',
      'Lintlha za kopano',
    ],
    'Available times': [
      'Nthawi zomwe zilipo',
      'Inshita shilipo',
      'Ziindi zilipo',
      'Linako ze li teñi',
    ],
    'Booking information': [
      'Zambiri zosungitsa',
      'Ifyebo fya kubikisha',
      'Makani aakubamba',
      'Lintlha za ku beha kopano',
    ],
    'Booking notes': [
      'Zolemba zosungitsa',
      'Ifyalembwa fya kubikisha',
      'Zilembo zyakubamba',
      'Litemana za kopano',
    ],
    'Choose a time that works for you.': [
      'Sankhani nthawi yabwino kwa inu.',
      'Saleni inshita iyamukwanila.',
      'Sankhani ciindi camuyanda.',
      'Keta nako ye ku swanela.',
    ],
    'Reason for appointment (optional)': [
      'Chifukwa cha nthawi (ngati mukufuna)',
      'Umulandu wa appointment (nga mulefwaya)',
      'Kaambo ka appointment (naa muyanda)',
      'Libaka la kopano (ha u bata)',
    ],
    'Reason for visit': [
      'Chifukwa cha ulendo',
      'Umulandu wa visit',
      'Kaambo kakuya',
      'Libaka la kopano',
    ],
    'Appointment booked': [
      'Nthawi yasungitsidwa',
      'Appointment yabikishiwa',
      'Appointment yabambwa',
      'Kopano i behilwe',
    ],
    'Set a reminder': [
      'Ikani chikumbutso',
      'Pangeni icibukisho',
      'Bikkani cikumbusyo',
      'Beha khopotso',
    ],
    'Set an appointment reminder': [
      'Ikani chikumbutso cha nthawi',
      'Pangeni icibukisho ca appointment',
      'Bikkani cikumbusyo ca appointment',
      'Beha khopotso ya kopano',
    ],
    'View appointment': [
      'Onani nthawi',
      'Moneni appointment',
      'Bona appointment',
      'Bona kopano',
    ],
    'Cancel appointment': [
      'Letsani nthawi',
      'Fumyeni appointment',
      'Lekani appointment',
      'Hana kopano',
    ],
    'Change date': [
      'Sinthani tsiku',
      'Cinsheni ubushiku',
      'Cinca buzuba',
      'Fetola lizazi',
    ],
    'Consultation results': [
      'Zotsatira za kukaonana',
      'Ifyafuma mu kupimwa',
      'Zizwa mukubonwa',
      'Lipholo za kopano',
    ],
    'Recommendations and next steps': [
      'Malangizo ndi zochita zotsatira',
      'Amalango na fyakucita panuma',
      'Malailile azyakutobela',
      'Litaelo ni mehato ye latela',
    ],
    'Recommended next visit': [
      'Ulendo wotsatira wolimbikitsidwa',
      'Visit iyakonkapo iyapandulwa',
      'Kuya kutobela kwapandulwa',
      'Kopano ye latelang ye eletsiwa',
    ],
    'Confirmed': [
      'Yatsimikizidwa',
      'Yasuminishiwa',
      'Yakasinizyigwa',
      'E tiisitizwe'
    ],
    'Pending confirmation': [
      'Ikuyembekezera kutsimikizidwa',
      'Ilelolela ukusuminishiwa',
      'Ilindila kusinizyigwa',
      'I emetse tiisetso',
    ],
    'Cancelled': ['Yaletsedwa', 'Yafutwa', 'Yalekwa', 'E hanilwe'],
    'Rescheduled': [
      'Nthawi yasinthidwa',
      'Inshita yacinjishiwa',
      'Ciindi cakacinjigwa',
      'Nako i fetohile',
    ],
    'Care history': [
      'Mbiri ya chisamaliro',
      'Imbila ya ukusakamana',
      'Makani aalutalililo',
      'Histori ya pabalelo',
    ],
    'Your care': [
      'Chisamaliro chanu',
      'Ukusakamana kwenu',
      'Lutalililo lwanu',
      'Pabalelo ya hao',
    ],
    'We’re here for you, every step of the way.': [
      'Tili nanu pa gawo lililonse.',
      'Tuli na imwe pa nshila yonse.',
      'Tuli andinywe panzila yoonse.',
      'Lu na ni wena kwa muhato kaufela.',
    ],
    'Nearby clinics': [
      'Zipatala zapafupi',
      'Ama kiliniki ya mupepi',
      'Zipatala zyaafwiifwi',
      'Likiliniki za pepi',
    ],
    'Clinics currently available for booking.': [
      'Zipatala zomwe zilipo kuti musungitse.',
      'Ama kiliniki yalipo yakubikishapo.',
      'Zipatala zilipo zyakubambapo.',
      'Likiliniki ze li teñi za ku beha kopano.',
    ],
    'Completed and past visits will appear here.': [
      'Maulendo omalizidwa ndi akale adzaoneka pano.',
      'Ama visit yapwa na yakale yakamoneka pano.',
      'Kuya kwakamana akwakale kulabonwa aano.',
      'Likopano ze felile ni za kale li ka bonahala fa.',
    ],
    'Your previous appointment details and results will remain available here.':
        [
      'Zambiri ndi zotsatira za nthawi zanu zakale zidzakhalabe pano.',
      'Ifyebo na fyafuma mu ma appointment yakale fikashala pano.',
      'Makani azizwa muma appointment aanu aakale zilakkomana aano.',
      'Lintlha ni lipholo za likopano za hao za kale li ka sala fa.',
    ],
    'Plan your next care visit': [
      'Konzani ulendo wanu wotsatira wa chisamaliro',
      'Pekanyeni ulwendo lwenu ulukonkapo ulwa kusakamana',
      'Bambizya kuya kwanu kutobela kwalutalililo',
      'Lukisa ku ya kwa hao ku latelang kwa pabalelo',
    ],
    'Choose a clinic, clinician, date and an available time that works for you.':
        [
      'Sankhani chipatala, wachipatala, tsiku ndi nthawi yomwe ili yabwino kwa inu.',
      'Saleni kiliniki, shinganga, ubushiku ne nshita ilipo iyamukwanila.',
      'Sankhani chipatala, mukoti, buzuba aciindi cilipo camuyanda.',
      'Keta kiliniki, muokoti, lizazi ni nako ye li teñi ye ku swanela.',
    ],
    'Care information could not be loaded.': [
      'Zambiri za chisamaliro sizinatseguke.',
      'Ifyebo fya kusakamana tafyaloleka.',
      'Makani aalutalililo taakayoboloka.',
      'Litaba za pabalelo ha li a layisiwa.',
    ],
    'Care team': [
      'Gulu losamalira',
      'Ibumba lya kusakamana',
      'Bakwabilila',
      'Sikwata sa pabalelo',
    ],
    'Book visit': [
      'Sungitsani ulendo',
      'Bikisheni visit',
      'Bambani kuya',
      'Beha kopano',
    ],
    'View care records': [
      'Onani zolemba za chisamaliro',
      'Moneni ifyalembwa fya kusakamana',
      'Bona zilembo zyalutalililo',
      'Bona lingoliloeng za pabalelo',
    ],
    'Health profile': [
      'Mbiri ya thanzi',
      'Imbila ya ubumi',
      'Makani aabuumi',
      'Taba za buiketo',
    ],
    'Health summary': [
      'Chidule cha thanzi',
      'Icipasho ca ubumi',
      'Bupanduluzi bwabuumi',
      'Kakaretso ya buiketo',
    ],
    'Blood pressure': [
      'Kuthamanga kwa magazi',
      'Icipimo ca mulopa',
      'Mweelwe wabulowa',
      'Khatello ya mali',
    ],
    'Heart rate': [
      'Kugunda kwa mtima',
      'Ukupuma kwa mutima',
      'Kupuma kwamoyo',
      'Ku uba kwa pilu',
    ],
    'Haemoglobin': ['Hemoglobini', 'Hemoglobin', 'Hemoglobin', 'Hemoglobini'],
    'Baby heartbeat': [
      'Kugunda kwa mtima wa mwana',
      'Ukupuma kwa mutima wa mwana',
      'Kupuma kwamoyo wamwana',
      'Ku uba kwa pilu ya ñwana',
    ],
    'Heartbeat quality': [
      'Mmene mtima ukugundira',
      'Ifyo mutima ulepuma',
      'Mbomoyo upuma',
      'Boemo bwa ku uba kwa pilu',
    ],
    'Womb position': [
      'Malo a chiberekero',
      'Incende ya cifukushi',
      'Mbubonya bwacibalo',
      'Sibaka sa popelo',
    ],
    'Estimated baby size': [
      'Kukula koyerekeza kwa mwana',
      'Ubukulu bwa mwana bwalelengwa',
      'Bupati bwamwana buyeyelwa',
      'Bukwala bwa ñwana bo lekanyelizwe',
    ],
    'Consultation summary': [
      'Chidule cha kukaonana',
      'Icipasho ca kupimwa',
      'Bupanduluzi bwakubonwa',
      'Kakaretso ya kopano',
    ],
    'CONSULTATION SUMMARY': [
      'CHIDULE CHA KUKAONANA',
      'ICIPASHO CA KUPIMWA',
      'BUPANDULUZI BWAKUBONWA',
      'KAKARETSO YA KOPANO',
    ],
    'Follow-up': [
      'Kutsatiranso',
      'Ukukonkapo',
      'Kulondela',
      'Ku latelela',
    ],
    'Follow-up recommended': [
      'Kulimbikitsidwa kubweranso',
      'Mwapandulwa ukubwelako',
      'Mwapandulwa kubwelela',
      'Ku bulela ku eletsiwa',
    ],
    'Routine care': [
      'Chisamaliro cha nthawi zonse',
      'Ukusakamana kwa lyonse',
      'Lutalililo lwaciyanza',
      'Pabalelo ya ka mehla',
    ],
    'Referral': ['Kutumizidwa', 'Ukutumishiwa', 'Kutumwa', 'Ku romelwa'],
    'Discharge': [
      'Kuloledwa kupita',
      'Ukusuminishiwa ukufuma',
      'Kuzumizigwa kuzwa',
      'Ku lumelwa ku tuma'
    ],
    'Normal': ['Zabwinobwino', 'Fyalungama', 'Kabotu', 'Za ka mehla'],
    'Low': ['Zochepa', 'Zanono', 'Zitunta', 'Fa tlase'],
    'High': ['Zambiri', 'Zapingi', 'Zili atala', 'Fa halimu'],
    'Critical': [
      'Zoopsa kwambiri',
      'Fyabipa sana',
      'Zyakuyoosya kapati',
      'Za kotsi hahulu'
    ],
    'Not measured': [
      'Sizinayesedwe',
      'Tafipimwa',
      'Tazipimwa',
      'Ha i a kalelwa',
    ],
    'Not applicable': [
      'Sizikukhudza',
      'Tafilikonka',
      'Tazikwami',
      'Ha i amani',
    ],
    'Unable to obtain': [
      'Sizinapezeke',
      'Tafyasangwa',
      'Tazijanikwi',
      'Ha i a fumaniwa',
    ],
    'Pregnancy': ['Mimba', 'Ifumo', 'Bulemu', 'Boimana'],
    'Pregnancy overview': [
      'Chidule cha mimba',
      'Icipasho ca ifumo',
      'Bupanduluzi bwabulemu',
      'Kakaretso ya boimana',
    ],
    'Pregnancy guides': [
      'Malangizo a mimba',
      'Ifilangililo fya ifumo',
      'Malailile aabulemu',
      'Lituto za boimana',
    ],
    'Pregnancy basics': [
      'Zoyambira za mimba',
      'Ifya kutendekela pa ifumo',
      'Makani aakutalikila aabulemu',
      'Likalulo za boimana',
    ],
    'Estimated due date': [
      'Tsiku loyerekeza lobereka',
      'Ubushiku bwa kufyalila',
      'Buzuba bwakulelela',
      'Lizazi la peho ya mwana',
    ],
    'Currently pregnant': [
      'Ndili ndi mimba pano',
      'Ndi ne fumo nomba',
      'Ndili abulemu lino',
      'Ni moimana cwale',
    ],
    'Last menstrual period': [
      'Msambo womaliza',
      'Imyeshi ya kulekelesha',
      'Mwezi wakumamanino',
      'Linako za mafelelezo',
    ],
    'Due date': [
      'Tsiku lobereka',
      'Ubushiku bwa kufyalila',
      'Buzuba bwakulelela',
      'Lizazi la peho',
    ],
    'Trimester': [
      'Gawo la miyezi itatu',
      'Iciputulwa ca myeshi itatu',
      'Cibeela camyeezi yotatwe',
      'Kalulo ya likwezi ze talu',
    ],
    'Baby development': [
      'Kukula kwa mwana',
      'Ukukula kwa mwana',
      'Kukula kwamwana',
      'Ku kula kwa ñwana',
    ],
    'Body changes': [
      'Kusintha kwa thupi',
      'Ukucinja kwa mubili',
      'Kucinca kwamubili',
      'Ku fetola kwa mubili',
    ],
    'Pregnancy information': [
      'Zambiri za mimba',
      'Ifyebo fya ifumo',
      'Makani aabulemu',
      'Litaba za boimana',
    ],
    'Pregnancy information saved.': [
      'Zambiri za mimba zasungidwa.',
      'Ifyebo fya ifumo fyasungwa.',
      'Makani aabulemu abikkwa.',
      'Litaba za boimana li bulukilwe.',
    ],
    'Complete pregnancy details': [
      'Malizani zambiri za mimba',
      'Pwisheni ifyebo fya ifumo',
      'Manizya makani aabulemu',
      'Feleza litaba za boimana',
    ],
    'Review health profile': [
      'Onaninso mbiri ya thanzi',
      'Moneni imbila ya ubumi',
      'Bona makani aabuumi',
      'Bona taba za buiketo',
    ],
    'Your profile says you are pregnant. Add your last menstrual period or expected delivery date for relevant guidance.':
        [
      'Mbiri yanu ikusonyeza kuti muli ndi mimba. Onjezani msambo womaliza kapena tsiku loyembekezera kubereka kuti mulandire malangizo oyenera.',
      'Imbila yenu ilanga ati muli ne fumo. Ongefyeni imyeshi ya kulekelesha nangu ubushiku bwa kufyalila pakuti mupokelele amalango ayawama.',
      'Makani aanu alanga kuti muli abulemu. Bikkani mwezi wakumamanino naa buzuba bwakulelela kuti mutambule malailile aayandika.',
      'Taba za hao li bonisa kuli u moimana. Ekeza linako za mafelelezo kapa lizazi la peho kuli u amuhele litaelo ze swanela.',
    ],
    'Period': ['Msambo', 'Imyeshi', 'Mwezi', 'Linako za basali'],
    'Period Tracker': [
      'Chotsatira msambo',
      'Icalondolola imyeshi',
      'Cakulondola mwezi',
      'Mulati wa linako',
    ],
    'Period & cycle': [
      'Msambo ndi kayendedwe',
      'Imyeshi na cycle',
      'Mwezi a kuzunguluka',
      'Linako ni mukoloko',
    ],
    'Cycle': ['Kayendedwe', 'Cycle', 'Kuzunguluka', 'Mukoloko'],
    'Cycle tracker': [
      'Chotsatira kayendedwe',
      'Icalondolola cycle',
      'Cakulondola kuzunguluka',
      'Mulati wa mukoloko',
    ],
    'Cycle calendar': [
      'Kalendala ya kayendedwe',
      'Kalenda ya cycle',
      'Kalenda yakuzunguluka',
      'Khalenda ya mukoloko',
    ],
    'Cycle settings': [
      'Zokonda za kayendedwe',
      'Amafunde ya cycle',
      'Misetelo yakuzunguluka',
      'Litukiso za mukoloko',
    ],
    'Add period': [
      'Onjezani msambo',
      'Ongefyeni imyeshi',
      'Amubikke mwezi',
      'Ekeza linako',
    ],
    'Average cycle': [
      'Kayendedwe ka masiku ambiri',
      'Ubulefu bwa cycle',
      'Bupati bwakuzunguluka',
      'Butelele bwa mukoloko',
    ],
    'Typical period': [
      'Msambo wanthawi zonse',
      'Imyeshi ya lyonse',
      'Mwezi waciyanza',
      'Linako za ka mehla',
    ],
    'Current cycle': [
      'Kayendedwe ka pano',
      'Cycle ya nomba',
      'Kuzunguluka kwalino',
      'Mukoloko wa cwale',
    ],
    'Calendar legend': [
      'Tanthauzo la kalendala',
      'Ifilangililo fya kalenda',
      'Bupanduluzi bwakalenda',
      'Taluso ya khalenda',
    ],
    'Estimate quality': [
      'Kudalirika kwa kuyerekeza',
      'Icipimo ca kulelenga',
      'Bubotu bwakuyeyela',
      'Boemo bwa tekanyetso',
    ],
    'Estimated fertile window': [
      'Masiku oyerekeza obereka',
      'Inshiku sha kubutuka shalelengwa',
      'Mazuba aakunyina aayeyelwa',
      'Mazazi a peho a lekanyelizwe',
    ],
    'Estimated ovulation': [
      'Tsiku loyerekeza lotulutsa dzira',
      'Ubushiku bwa ovulation ubwalelengwa',
      'Buzuba bwa ovulation buyeyelwa',
      'Lizazi la ovulation le lekanyelizwe',
    ],
    'About cycle estimates': [
      'Za kuyerekeza kayendedwe',
      'Pa kulelenga cycle',
      'Makani aakuyeyela kuzunguluka',
      'Ka za tekanyetso ya mukoloko',
    ],
    'Recorded cycle history': [
      'Mbiri ya kayendedwe yolembedwa',
      'Imbila ya cycle yalembwa',
      'Makani aakuzunguluka aalembwa',
      'Histori ya mukoloko ye ngolilwe',
    ],
    'Regular cycle': [
      'Kayendedwe ka nthawi zonse',
      'Cycle iyalungama',
      'Kuzunguluka kwaciyanza',
      'Mukoloko wa ka mehla',
    ],
    'Set up cycle tracking': [
      'Khazikitsani kutsatira kayendedwe',
      'Pangeni ukulondolola cycle',
      'Bambani kulondola kuzunguluka',
      'Lukisa ku latelela mukoloko',
    ],
    'Set up tracker': [
      'Khazikitsani chotsatira',
      'Pangeni icalondolola',
      'Bambani cakulondola',
      'Lukisa mulati',
    ],
    'Add your latest period to begin receiving cycle estimates.': [
      'Onjezani msambo wanu waposachedwa kuti muyambe kuona zoyerekeza za kayendedwe.',
      'Ongefyeni imyeshi yenu iya nombaline pakuti mutendeke ukumona ifyalelengwa fya cycle.',
      'Amubikke mwezi wanu wamamanino kuti mutalike kubona zyeyelwa zyakuzunguluka.',
      'Ekeza linako za hao za swalisano kuli u kale ku bona tekanyetso ya mukoloko.',
    ],
    'Add your last period and usual cycle length to see estimates.': [
      'Onjezani msambo womaliza ndi masiku a kayendedwe kanu kuti muone zoyerekeza.',
      'Ongefyeni imyeshi ya kulekelesha no bulefu bwa cycle pakuti mumone ifyalelengwa.',
      'Amubikke mwezi wakumamanino abupati bwakuzunguluka kuti mubone zyeyelwa.',
      'Ekeza linako za mafelelezo ni butelele bwa mukoloko kuli u bone tekanyetso.',
    ],
    'Turn off to hide fertile-window estimates.': [
      'Zimitsani kuti mubise masiku oyerekeza obereka.',
      'Fumyeni pakuti mufise inshiku sha kubutuka shalelengwa.',
      'Jala kuti musise mazuba aakunyina aayeyelwa.',
      'Tima kuli u pate mazazi a peho a lekanyelizwe.',
    ],
    'Turn this off if cycle length varies considerably.': [
      'Zimitsani izi ngati masiku a kayendedwe amasiyanasiyana kwambiri.',
      'Fumyeni ici nga ubulefu bwa cycle bulacinja sana.',
      'Jala eeci naa bupati bwakuzunguluka bulacinca kapati.',
      'Tima se ha butelele bwa mukoloko bu fetofetola hahulu.',
    ],
    'Select any symptoms you’re experiencing': [
      'Sankhani zizindikiro zomwe mukumva',
      'Saleni ifilangililo muleumfwa',
      'Sankhani zizindikilo zyomulimvwa',
      'Keta matšoao a u ikutwa',
    ],
    'Log sexual activity': [
      'Lembani zogonana',
      'Lembeni ifya kugonana',
      'Lembani makani aakwakoonana',
      'Ngola za ku kopana',
    ],
    'Was protection used?': [
      'Kodi munagwiritsa ntchito chitetezo?',
      'Bushe mwabomfya icakucinjilisha?',
      'Sena mwakagwasya cakusungwa?',
      'A ku sebelisitwe silelezo?',
    ],
    'My period ended': [
      'Msambo wanga watha',
      'Imyeshi yandi yapwa',
      'Mwezi wangu wamana',
      'Linako za ka li felile',
    ],
    'Mark period start': [
      'Chongani kuyamba kwa msambo',
      'Lembeni ukutendeka kwa myeshi',
      'Bikkani kutalika kwamwezi',
      'Swaya ku kala kwa linako',
    ],
    'View or update history': [
      'Onani kapena sinthani mbiri',
      'Moneni nangu lungamikeni imbila',
      'Bona naa cinca makani aakale',
      'Bona kapa fetola histori',
    ],
    'Predictions are estimates and should not be used as contraception or a diagnosis.':
        [
      'Zonenedweratu ndi zoyerekeza ndipo musazigwiritse ntchito popewa mimba kapena kudziwa matenda.',
      'Ifyalelengwa fye; te fyakulesha ifumo nangu ukupima ubulwele.',
      'Zyakambwa nkuyeyela buyeyesi; tazili zyakulesya bulemu naa kupima malwazi.',
      'Lipalo ki za ku lekanyela feela; u se ke wa li sebelisa kwa ku sileletsa boimana kapa ku sibolla butuku.',
    ],
    'Cramps': [
      "Kupweteka m'mimba",
      'Ubukali bwa munda',
      'Kukolwa mumala',
      'Butuku bwa mpa'
    ],
    'Headache': [
      'Mutu kuwawa',
      'Mutwe ukukalipa',
      'Mutwe kukolwa',
      'Butuku bwa toho'
    ],
    'Mood': ['Mmene mukumvera', 'Ifyo muleumfwa', 'Mbomulimvwa', 'Maikutlo'],
    'Energy': ['Mphamvu', 'Amaka', 'Nguzu', 'Maata'],
    'Last period': [
      'Msambo womaliza',
      'Imyeshi ya kulekelesha',
      'Mwezi wakumamanino',
      'Linako za mafelelezo'
    ],
    'Next period': [
      'Msambo wotsatira',
      'Imyeshi ilekonkapo',
      'Mwezi utobela',
      'Linako ze latelang'
    ],
    'Start date': [
      'Tsiku loyamba',
      'Ubushiku bwa kutendeka',
      'Buzuba bwakutalika',
      'Lizazi la ku kala'
    ],
    'End date': [
      'Tsiku lomaliza',
      'Ubushiku bwa kulekelesha',
      'Buzuba bwakumamanino',
      'Lizazi la mafelelezo'
    ],
    'Log today': [
      'Lembani za lero',
      'Lembeni ifya uno mushi',
      'Lembani zyasunu',
      'Ngola za kacenu'
    ],
    'Symptoms': ['Zizindikiro', 'Ifilangililo', 'Zizindikilo', 'Matšoao'],
    'Pain level': [
      'Mlingo wa ululu',
      'Icipimo ca ubukali',
      'Mweelwe wabuya',
      'Boemo bwa butuku'
    ],
    'Notes': ['Zolemba', 'Ifyalembwa', 'Zilembo', 'Litemana'],
    'Learn and feel supported': [
      'Phunzirani ndi kulandira thandizo',
      'Sambilileni no kwafwa',
      'Iya alimwi mutambulwe',
      'Ithute ni ku tuswa',
    ],
    'Learning': ['Maphunziro', 'Amasambililo', 'Kuyi', 'Lituto'],
    'My library': [
      'Laibulale yanga',
      'Laibulale yandi',
      'Laibulale yangu',
      'Laeborari ya ka'
    ],
    'Lessons': ['Maphunziro', 'Amasambililo', 'Zyakuyi', 'Lituto'],
    'Browse lessons': [
      'Onani maphunziro',
      'Moneni amasambililo',
      'Bona zyakuyi',
      'Bona lituto',
    ],
    'Related learning': [
      'Maphunziro okhudzana',
      'Amasambililo ayalingana',
      'Zyakuyi zyamukowa',
      'Lituto ze amana',
    ],
    'Lesson progress': [
      'Kupita patsogolo pa phunziro',
      'Ukutwalilila mu lisambililo',
      'Kuyungizya muzilayi',
      'Tswelopele ya tuto',
    ],
    'Transcript available offline': [
      'Mawu olembedwa alipo popanda intaneti',
      'Amashiwi yalembwa yalipo ukwabula intaneti',
      'Mubala ulembedwe ulipo kakunyina intaneti',
      'Manzwi a ngolilwe a teñi kusina intaneti',
    ],
    'What to expect': [
      'Zomwe mungayembekezere',
      'Ifyo mwingalolela',
      'Zyomukonzya kulindila',
      'Ze u ka li lindela',
    ],
    'What you learned': [
      'Zomwe mwaphunzira',
      'Ifyo mwasambilila',
      'Zyomwayiya',
      'Ze u ithutile',
    ],
    'Why it matters': [
      'Chifukwa chake n’kofunika',
      'Umulandu ciwamina',
      'Kaambo ncocili ciyandikana',
      'Libaka la butokwa',
    ],
    'Choose an answer': [
      'Sankhani yankho',
      'Saleni ubwasuko',
      'Sankhani bwandulo',
      'Keta kalabo',
    ],
    'Choose one answer.': [
      'Sankhani yankho limodzi.',
      'Saleni ubwasuko bumo.',
      'Sankhani bwandulo bomwi.',
      'Keta kalabo kaliswi.',
    ],
    'Choose the best answer.': [
      'Sankhani yankho labwino kwambiri.',
      'Saleni ubwasuko ubusuma.',
      'Sankhani bwandulo bubotu.',
      'Keta kalabo ka hande.',
    ],
    'How health games work': [
      'Momwe masewera a thanzi amagwirira ntchito',
      'Ifyo ifyangalo fya ubumi fibomba',
      'Mbomisebero yabuumi ibomba',
      'Moo lipapali za buiketo li sebeza',
    ],
    'Choose a game': [
      'Sankhani masewera',
      'Saleni icangalo',
      'Sankhani musebero',
      'Keta papali',
    ],
    'Let’s play': [
      'Tiyeni tisewere',
      'Tuleangala',
      'Atusewere',
      'Ha lu bapale',
    ],
    'Myth vs Fact': [
      'Nthano kapena Zoona',
      'Ubufi nangu Icishinka',
      'Lukondo naa Mazubizyi',
      'Taba ya maaka kapa ya niti',
    ],
    'MYTH VS FACT': [
      'NTHANO KAPENA ZOONA',
      'UBUFI NANGU ICISHINKA',
      'LUKONDO NAA MAZUBIZYI',
      'TABA YA MAAKA KAPA YA NITI',
    ],
    'Myth': ['Nthano', 'Ubufi', 'Lukondo', 'Taba ya maaka'],
    'Fact': ['Zoona', 'Icishinka', 'Mazubizyi', 'Niti'],
    'I understand': [
      'Ndamvetsa',
      'Namfwikisha',
      'Ndamvwisisya',
      'Ni utwisisa',
    ],
    'I’ve heard this': [
      'Ndinamvapo izi',
      'Nalumfwapo ulu',
      'Ndalimvwa eeci',
      'Ni utwile se',
    ],
    'I didn’t know this': [
      'Sindinadziwe izi',
      'Nshamanyile ici',
      'Nsindaziba eeci',
      'Ni ne ni sa zibi se',
    ],
    'I’m still worried': [
      'Ndidakali ndi nkhawa',
      'Nacili na mano',
      'Ncili akulibilika',
      'Ni sa na ni pilu',
    ],
    'What is screening?': [
      'Kuyezetsa ndi chiyani?',
      'Ukupimiwa cinshi?',
      'Kusikilwa ncinzi?',
      'Tlhahlobo ki ñi?',
    ],
    'What is cervical cancer?': [
      'Khansa ya khomo la chiberekero ndi chiyani?',
      'Kansa ya mulomo wa cifukushi cinshi?',
      'Kansa yamulomo wacibalo ncinzi?',
      'Kankere ya molomo wa popelo ki ñi?',
    ],
    'What happens during screening?': [
      'N’chiyani chimachitika poyezetsa?',
      'Finshi ficitika pa kupimiwa?',
      'Ncinzi cicitika mukusikilwa?',
      'Ku ezahala ñi kwa tlhahlobo?',
    ],
    'What happens at the clinic': [
      'Zomwe zimachitika kuchipatala',
      'Ificitika ku kiliniki',
      'Zicitika kuchipatala',
      'Ze ezahala kwa kiliniki',
    ],
    'Will it hurt?': [
      'Kodi zidzawawa?',
      'Bushe cikakalipa?',
      'Sena cilakolwa?',
      'A ku ka utwisisa butuku?',
    ],
    'Who should ask about screening?': [
      'Ndani ayenera kufunsa za kuyezetsa?',
      'Nani afwile ukwipusha pa kupimiwa?',
      'Nguni weelede kubuzya akusikilwa?',
      'Ki mañi ya swanela ku buza ka tlhahlobo?',
    ],
    'Before you leave': [
      'Musanachoke',
      'Tamulati mwafuma',
      'Komutanazwa',
      'Ha u sa tuma',
    ],
    'During the visit': [
      'Pa ulendo wachipatala',
      'Pa visit',
      'Mukuya kuchipatala',
      'Kwa kopano',
    ],
    'Before you go home': [
      'Musanapite kunyumba',
      'Tamulati mwaya ku ng’anda',
      'Komutanaya kung’anda',
      'Ha u sa ya kwa hae',
    ],
    'You stay in control': [
      'Inu ndi amene mumasankha',
      'Imwe ebo musala',
      'Ndimwe musala',
      'Ki wena ya keta',
    ],
    'First step': [
      'Gawo loyamba',
      'Intampulo yakubalilapo',
      'Citobela cakusaanguna',
      'Muhato wa pili',
    ],
    'Quick screening test': [
      'Mayeso achidule a kuyezetsa',
      'Ukupimiwa kwa bwangu',
      'Kusikilwa kwakufwambaana',
      'Tlhahlobo ya ka putako',
    ],
    'Screening Champion': [
      'Katswiri wa Kuyezetsa',
      'Shimapepo wa Kupimiwa',
      'Sikatana wa Kusikilwa',
      'Muwini wa Tlhahlobo',
    ],
    'Quest progress': [
      'Kupita patsogolo pa ulendo',
      'Ukutwalilila kwa quest',
      'Kuyungizya kwa quest',
      'Tswelopele ya quest',
    ],
    'Quest complete': [
      'Ulendo watha',
      'Quest yapwa',
      'Quest yamana',
      'Quest i felile',
    ],
    'Quest Checkpoint': [
      'Malo oona kupita patsogolo',
      'Incende yakumona quest',
      'Cibeela cakubona quest',
      'Sibaka sa ku bona quest',
    ],
    'Start screening quest': [
      'Yambani ulendo wa kuyezetsa',
      'Tendekeni quest ya kupimiwa',
      'Amutalike quest yakusikilwa',
      'Kala quest ya tlhahlobo',
    ],
    'Replay from beginning': [
      'Yambiraninso pachiyambi',
      'Tendekeni na kabili',
      'Amutalike alimwi',
      'Kala hape kwa makalelo',
    ],
    'Story unlocked': [
      'Nkhani yatsegulidwa',
      'Ilyashi lyaisulwa',
      'Makani ajuligwa',
      'Taba i atolositwe',
    ],
    'Teacher': ['Mphunzitsi', 'Kasambilisha', 'Muyi', 'Mututi'],
    'Tips': ['Malangizo', 'Amalango', 'Malailile', 'Litaelo'],
    'Women’s health': [
      'Thanzi la amayi',
      'Ubumi bwa banakashi',
      'Buumi bwabamayi',
      'Buiketo bwa basali',
    ],
    'Every card gives immediate feedback and a short explanation.': [
      'Khadi lililonse limapereka yankho nthawi yomweyo ndi kufotokoza mwachidule.',
      'Cila card cilepela ubwasuko bwangu ne cilondolwe cifupi.',
      'Cila kaadi cilapa bwandulo cakufwambaana abupanduluzi bufwiifwi.',
      'Karata ni karata i fana kalabo ka putako ni taluso ye kufi.',
    ],
    'Health choices become easier with practice': [
      'Zosankha za thanzi zimakhala zosavuta mukamazichita',
      'Ukusala ifya ubumi kulanguka nga muleibomba',
      'Kusala zyabuumi kulayunguka nomukabicita',
      'Liketo za buiketo li ba bunolo ha u li ita',
    ],
    'Free scan voucher': [
      'Voucha ya sikani yaulere',
      'Voucher ya scan iya mahala',
      'Voucher yakusikilwa kwa mahala',
      'Voucher ya scan ya mahala',
    ],
    'FREE SCAN VOUCHER': [
      'VOUCHA YA SIKANI YAULERE',
      'VOUCHER YA SCAN IYA MAHALA',
      'VOUCHER YAKUSIKILWA KWA MAHALA',
      'VOUCHER YA SCAN YA MAHALA',
    ],
    'Show this code at a participating Dawa clinic.': [
      'Onetsani khodi iyi kuchipatala cha Dawa chogwira nawo ntchito.',
      'Langisheni code iyi ku kiliniki ya Dawa iyasangana.',
      'Langa code eeyi kuchipatala ca Dawa citola lubazu.',
      'Bonisa code ye kwa kiliniki ya Dawa ye amana.',
    ],
    'Cervical cancer is highly preventable when screening finds cell changes early and treatment is available.':
        [
      'Khansa ya khomo la chiberekero ingapewedwe kwambiri ngati kuyezetsa kwapeza kusintha kwa maselo msanga ndipo chithandizo chilipo.',
      'Kansa ya mulomo wa cifukushi ingaishibikwa bwangu nga ukupimiwa kwasanga ukusintha kwa maselo kabili na ukundapa kulipo.',
      'Kansa yamulomo wacibalo ilakonzya kulesyegwa naa kusikilwa kwajana kucinca kwamaselo ciindi abundapisi bulipo.',
      'Kankere ya molomo wa popelo i ka silelezwa ha tlhahlobo i fumana ku fetola kwa maselo ka putako ni kalafi i li teñi.',
    ],
    'Rudo provides general health information and is not a substitute for professional medical advice.':
        [
      'Rudo amapereka zambiri za thanzi basi ndipo salowa m’malo mwa malangizo a wachipatala.',
      'Rudo apele fye ifyebo fya ubumi kabili te cakupyanina amalango ya shinganga.',
      'Rudo ulapa makani aabuumi buyeyesi alimwi takali mubusena bwamalailile aamukoti.',
      'Rudo u fana litaba za buiketo feela mi ha a peli taelo ya muokoti.',
    ],
    'Article': ['Nkhani', 'Icilangililo', 'Makani', 'Sengolwa'],
    'Audio': ['Mawu', 'Iliwi', 'Mubala', 'Mulumo'],
    'AUDIO LESSON': [
      'PHUNZIRO LA MAWU',
      'ILISAMBILILO LYA ILIWI',
      'CIYI CAMUBALA',
      'TUTO YA MULUMO',
    ],
    'Listen': ['Mverani', 'Umfweni', 'Amuteelele', 'Utele'],
    'Transcript': [
      'Mawu olembedwa',
      'Amashiwi yalembwa',
      'Mubala ulembedwe',
      'Manzwi a ngolilwe'
    ],
    'Games': ['Masewera', 'Ifyangalo', 'Misebero', 'Lipapali'],
    'Health games': [
      'Masewera a thanzi',
      'Ifyangalo fya ubumi',
      'Misebero yabuumi',
      'Lipapali za buiketo',
    ],
    'Play': ['Sewerani', 'Angaleni', 'Sewera', 'Bapala'],
    'Rewards': ['Mphotho', 'Ifilambu', 'Zilumbu', 'Mupuzo'],
    'My rewards': [
      'Mphotho zanga',
      'Ifilambu fyandi',
      'Zilumbu zyangu',
      'Mupuzo ya ka'
    ],
    'Reward points': [
      'Mapointi a mphotho',
      'Ama points ya cilambu',
      'Mapoints aazilumbu',
      'Liponti za mupuzo'
    ],
    'Achievements': [
      'Zomwe mwakwanitsa',
      'Ifyo mwafikapo',
      'Zyomwakwanisya',
      'Ze u fitile'
    ],
    'Current balance': [
      'Ndalama zomwe zilipo',
      'Ama points yalipo',
      'Mapoints aalipo',
      'Liponti ze li teñi'
    ],
    'Rudo': ['Rudo', 'Rudo', 'Rudo', 'Rudo'],
    'Ask Rudo': ['Funsani Rudo', 'Ipusheni Rudo', 'Buzya Rudo', 'Buza Rudo'],
    'Chat now': [
      'Chezani tsopano',
      'Landeni nomba',
      'Amwaambile lino',
      'Bulela cwale'
    ],
    'Type your message...': [
      'Lembani uthenga wanu...',
      'Lembeni ubukombe bwenu...',
      'Lembani mulumbe wanu...',
      'Ngola mulaeza wa hao...',
    ],
    'Account': ['Akaunti', 'Account', 'Akaunti', 'Akanti'],
    'Create account': [
      'Pangani akaunti',
      'Pangeni account',
      'Pangani akaunti',
      'Bupa akanti'
    ],
    'Log in': ['Lowani', 'Ingilenimo', 'Njila', 'Kena'],
    'Logout': ['Tulukani', 'Fumeni', 'Zwa', 'Tuma'],
    'Welcome back': [
      'Takulandiraninso',
      'Mwaiseni na kabili',
      'Twaamutambula alimwi',
      'Mwa amuhelwa hape'
    ],
    'Simple care for every mother': [
      'Chisamaliro chosavuta kwa mayi aliyense',
      'Ukusakamana ukwanguka kuli ba mayo bonse',
      'Lutalililo luluba kubamayi boonse',
      'Pabalelo ye bunolo kwa bomme kaufela',
    ],
    'Track your cycle': [
      'Tsatirani kayendedwe kanu',
      'Londololeni cycle yenu',
      'Londolani kuzunguluka kwanu',
      'Latelela mukoloko wa hao',
    ],
    'Understand your period, fertile days and pregnancy journey with simple daily guidance.':
        [
      'Mvetsetsani msambo, masiku obereka ndi ulendo wa mimba ndi malangizo osavuta a tsiku ndi tsiku.',
      'Mumfwikishe imyeshi, inshiku sha kubutuka na ulwendo lwa ifumo na malango ayanguka cila bushiku.',
      'Mumvwisye mwezi, mazuba aakunyina a ulwendo lwabulemu amalangililo aluba buzuba abuzuba.',
      'Utwisisa linako, mazazi a peho ni nzila ya boimana ka litaelo ze bunolo za kacenu ni kacenu.',
    ],
    'Book care easily': [
      'Sungitsani chisamaliro mosavuta',
      'Bikisheni ukusakamana ukwabula ubuyantanshi',
      'Bamba lutalililo cakufwambaana',
      'Beha pabalelo ka bunolo',
    ],
    'Schedule appointments, get reminders and connect with Dawa clinicians without stress.':
        [
      'Sungitsani nthawi, landirani zikumbutso ndi kulumikizana ndi achipatala a Dawa mosavuta.',
      'Bikisheni ama appointment, pokeleleni ifibukisho no kwampana na bashinganga ba Dawa ukwabula umwenso.',
      'Bambani ma appointment, tambulani zikumbusyo alimwi mwaambile bakoti ba Dawa kakunyina kunyema.',
      'Beha likopano, amuhela likhopotso ni ku amana ni baokoti ba Dawa ka kusina mataata.',
    ],
    'Play, learn and earn': [
      'Sewerani, phunzirani ndi kupeza mphotho',
      'Angaleni, sambilileni no kupata ifilambu',
      'Sewerani, iya alimwi mujane zilumbu',
      'Bapala, ithute ni ku fumana mupuzo',
    ],
    'Build confidence with short health games, earn Dawa points once per game and unlock meaningful care rewards.':
        [
      'Limbani mtima ndi masewera afupi a thanzi, pezani mapointi a Dawa kamodzi pa masewera ndi kutsegula mphotho za chisamaliro.',
      'Kulisheni icetekelo na fyangalo fya ubumi ifyipi, pateni ama points ya Dawa kamo pa cangalo no kwisula ifilambu fya kusakamana.',
      'Yakulani bulangizi amisebero mifwiifwi yabuumi, jana mapoints aa Dawa kamwi pamusebero alimwi mujane zilumbu zyalutalililo.',
      'Aha ku ikanya ka lipapali za buiketo ze kufi, fumana liponti za Dawa hangwi ka papali ni ku fumana mupuzo ya pabalelo.',
    ],
    'Maternal-health support, appointments and cycle tracking in one place.': [
      'Thandizo la thanzi la amayi, nthawi zachipatala ndi kutsatira kayendedwe pamalo amodzi.',
      'Ubwafwilisho bwa ubumi bwa ba mayo, ama appointment no kulondolola cycle pamo pene.',
      'Lugwasyo lwabuumi bwabamayi, ma appointment akulondola kuzunguluka antoomwe.',
      'Tuso ya buiketo bwa bomme, likopano ni ku latelela mukoloko kwa sibaka siliswi.',
    ],
    'Choose a clinic, clinician, date and available appointment time.': [
      'Sankhani chipatala, wachipatala, tsiku ndi nthawi yomwe ilipo.',
      'Saleni kiliniki, shinganga, ubushiku ne nshita ilipo.',
      'Sankhani chipatala, mukoti, buzuba aciindi cilipo.',
      'Keta kiliniki, muokoti, lizazi ni nako ye li teñi.',
    ],
    'Record periods and view estimated cycle information when it is useful to you.':
        [
      'Lembani misambo ndi kuona zambiri zoyerekeza za kayendedwe pamene zikuthandizani.',
      'Lembeni imyeshi no kumona ifyebo fya cycle nga filemwafwa.',
      'Lembani myeezi alimwi mubone makani aakuyeyela kuzunguluka naa alamugwasya.',
      'Ngola linako ni ku bona makani a mukoloko ha a ku tusa.',
    ],
    'Complete short health games, collect one-time Dawa points and follow your rewards progress.':
        [
      'Malizani masewera afupi a thanzi, sonkhanitsani mapointi a Dawa kamodzi ndi kutsatira mphotho zanu.',
      'Pwisheni ifyangalo fya ubumi ifyipi, pateni ama points ya Dawa kamo no kulondolola ifilambu fyenu.',
      'Manizya misebero mifwiifwi yabuumi, jana mapoints aa Dawa kamwi alimwi mulondole zilumbu zyanu.',
      'Feleza lipapali za buiketo ze kufi, fumana liponti za Dawa hangwi ni ku latelela mupuzo ya hao.',
    ],
    'Complete your health profile': [
      'Malizani mbiri yanu ya thanzi',
      'Pwisheni imbila yenu iya ubumi',
      'Manizya makani aanu aabuumi',
      'Feleza taba za hao za buiketo',
    ],
    'Add relevant health information for more personalised guidance.': [
      'Onjezani zambiri za thanzi kuti mulandire malangizo okhudza inu.',
      'Ongefyeni ifyebo fya ubumi pakuti mupokelele amalango ayenu.',
      'Amubikke makani aabuumi kuti mutambule malailile aamwe.',
      'Ekeza litaba za buiketo kuli u amuhele litaelo za hao.',
    ],
    'Open the Rudo assistant whenever you need health support and guidance.': [
      'Tsegulani Rudo nthawi iliyonse mukafuna thandizo ndi malangizo a thanzi.',
      'Isuleni Rudo lyonse nga mulefwaya ubwafwilisho na malango ya ubumi.',
      'Isuleni Rudo ciindi coonse nomuyanda lugwasyo amalangililo aabuumi.',
      'Atolosa Rudo nako kaufela ha u bata tuso ni litaelo za buiketo.',
    ],
    'Skip': ['Dumphani', 'Pitilileni', 'Amusye', 'Tlola'],
    'Skip for now': [
      'Dumphani pakali pano',
      'Pitilileni pali nomba',
      'Amusye lino',
      'Tlola cwale',
    ],
    'Maybe later': [
      'Mwina nthawi ina',
      'Limbi panuma',
      'Ambweni kumbele',
      'Kamba hamorao',
    ],
    'Already have an account?': [
      'Muli kale ndi akaunti?',
      'Mwalikwata kale account?',
      'Mulaakaunti kale?',
      'U se u na ni akanti?',
    ],
    'Don’t have an account?': [
      'Mulibe akaunti?',
      'Tamwakwata account?',
      'Tamuna akaunti?',
      'Ha u na akanti?',
    ],
    'Full name': [
      'Dzina lonse',
      'Amashina yonse',
      'Zina lyoonse',
      'Libizo ka botlalo'
    ],
    'Email address': ['Imelo', 'Email', 'Imelo', 'Imeili'],
    'Email': ['Imelo', 'Email', 'Imelo', 'Imeili'],
    'Email or phone number': [
      'Imelo kapena nambala ya foni',
      'Email nangu namba ya foni',
      'Imelo naa namba yafoni',
      'Imeili kapa nombolo ya foni',
    ],
    'Phone number': [
      'Nambala ya foni',
      'Namba ya foni',
      'Namba yafone',
      'Nombolo ya foni'
    ],
    'Password': [
      'Mawu achinsinsi',
      'Icipaso ca nkama',
      'Ijwi lyakusisya',
      'Linzwi la sifumu'
    ],
    'Create password': [
      'Pangani mawu achinsinsi',
      'Pangeni icipaso',
      'Pangani ijwi lyakusisya',
      'Bupa linzwi la sifumu',
    ],
    '6-digit verification code': [
      'Khodi yotsimikizira ya manambala 6',
      'Code yakusuminisha iya namba 6',
      'Code yakusinizya iili anamba 6',
      'Code ya tiisetso ya linombolo ze 6',
    ],
    'Confirm password': [
      'Tsimikizani mawu achinsinsi',
      'Suminisheni icipaso',
      'Sinizya ijwi',
      'Tiisa linzwi'
    ],
    'Enter your email or phone number.': [
      'Lembani imelo kapena nambala ya foni.',
      'Lembeni email nangu namba ya foni.',
      'Lembani imelo naa namba yafoni.',
      'Ngola imeili kapa nombolo ya foni.',
    ],
    'Enter your password.': [
      'Lembani mawu anu achinsinsi.',
      'Lembeni icipaso cenu.',
      'Lembani ijwi lyanu lyakusisya.',
      'Ngola linzwi la hao la sifumu.',
    ],
    'Enter your full name.': [
      'Lembani dzina lanu lonse.',
      'Lembeni amashina yenu yonse.',
      'Lembani zina lyanu lyoonse.',
      'Ngola libizo la hao ka botlalo.',
    ],
    'Enter a valid phone number.': [
      'Lembani nambala ya foni yolondola.',
      'Lembeni namba ya foni iyalungama.',
      'Lembani namba yafoni iiluzi.',
      'Ngola nombolo ya foni ye nepa.',
    ],
    'Enter a valid mobile number.': [
      'Lembani nambala ya foni yolondola.',
      'Lembeni namba ya foni iyalungama.',
      'Lembani namba yafoni iiluzi.',
      'Ngola nombolo ya foni ye nepa.',
    ],
    'Enter a valid email address.': [
      'Lembani imelo yolondola.',
      'Lembeni email iyalungama.',
      'Lembani imelo iiluzi.',
      'Ngola imeili ye nepa.',
    ],
    'Use at least 8 characters.': [
      'Gwiritsani zilembo zosachepera 8.',
      'Bomfyeni amalembo ayakwana 8.',
      'Gwasya zilembo zili 8 naakwiinda.',
      'Sebenzisa litaku ze 8 kapa ku feta.',
    ],
    'Use 15 to 60 days.': [
      'Gwiritsani masiku 15 mpaka 60.',
      'Bomfyeni inshiku ukufuma 15 ukufika 60.',
      'Gwasya mazuba 15 kusika 60.',
      'Sebenzisa mazazi a 15 ku ya ku 60.',
    ],
    'Use 1 to 15 days.': [
      'Gwiritsani tsiku 1 mpaka masiku 15.',
      'Bomfyeni ubushiku 1 ukufika inshiku 15.',
      'Gwasya buzuba 1 kusika mazuba 15.',
      'Sebenzisa lizazi 1 ku ya ku mazazi a 15.',
    ],
    'Enter a number from 15 to 60.': [
      'Lembani nambala kuyambira 15 mpaka 60.',
      'Lembeni namba ukufuma 15 ukufika 60.',
      'Lembani namba kuzwa 15 kusika 60.',
      'Ngola nombolo ku zwa 15 ku ya ku 60.',
    ],
    'Enter a number from 1 to 15.': [
      'Lembani nambala kuyambira 1 mpaka 15.',
      'Lembeni namba ukufuma 1 ukufika 15.',
      'Lembani namba kuzwa 1 kusika 15.',
      'Ngola nombolo ku zwa 1 ku ya ku 15.',
    ],
    'Must be shorter than the cycle.': [
      'Iyenera kukhala yochepa kuposa kayendedwe.',
      'Cifwile ukuba cifupi ukucila cycle.',
      'Ceelede kube cifwiifwi kwiinda kuzunguluka.',
      'I swanela ku ba ye kufi ku feta mukoloko.',
    ],
    'Must be shorter than the cycle length.': [
      'Iyenera kukhala yochepa kuposa kutalika kwa kayendedwe.',
      'Cifwile ukuba cifupi ukucila ubulefu bwa cycle.',
      'Ceelede kube cifwiifwi kwiinda bupati bwakuzunguluka.',
      'I swanela ku ba ye kufi ku feta butelele bwa mukoloko.',
    ],
    'Passwords do not match.': [
      'Mawu achinsinsi sakufanana.',
      'Ifipaso tafyalingana.',
      'Majwi aakusisya taakweelelani.',
      'Manzwi a sifumu ha a swani.',
    ],
    'Choose your date of birth.': [
      'Sankhani tsiku lanu lobadwa.',
      'Saleni ubushiku mwafyalilwe.',
      'Sankhani buzuba mbomwakazyalwa.',
      'Keta lizazi la pepo ya hao.',
    ],
    'Enter your address.': [
      'Lembani adiresi yanu.',
      'Lembeni address yenu.',
      'Lembani adilesi yanu.',
      'Ngola adiresi ya hao.',
    ],
    'Choose date': [
      'Sankhani tsiku',
      'Saleni ubushiku',
      'Sankhani buzuba',
      'Keta lizazi',
    ],
    'Choose date of birth': [
      'Sankhani tsiku lobadwa',
      'Saleni ubushiku mwafyalilwe',
      'Sankhani buzuba bwakuzyalwa',
      'Keta lizazi la pepo',
    ],
    'Choose period start date': [
      'Sankhani tsiku loyamba la msambo',
      'Saleni ubushiku bwa kutendeka kwa myeshi',
      'Sankhani buzuba bwakutalika mwezi',
      'Keta lizazi la ku kala kwa linako',
    ],
    'Choose period end date': [
      'Sankhani tsiku lomaliza la msambo',
      'Saleni ubushiku bwa kulekelesha kwa myeshi',
      'Sankhani buzuba bwakumana mwezi',
      'Keta lizazi la mafelelezo a linako',
    ],
    'Choose the first day of your period': [
      'Sankhani tsiku loyamba la msambo wanu',
      'Saleni ubushiku bwa kutendeka kwa myeshi yenu',
      'Sankhani buzuba bwakutalika mwezi wanu',
      'Keta lizazi la ku kala kwa linako za hao',
    ],
    'Choose estimated due date': [
      'Sankhani tsiku loyerekeza lobereka',
      'Saleni ubushiku bwa kufyalila',
      'Sankhani buzuba bwakulelela',
      'Keta lizazi la peho ya mwana',
    ],
    'Choose last period date': [
      'Sankhani tsiku la msambo womaliza',
      'Saleni ubushiku bwa myeshi ya kulekelesha',
      'Sankhani buzuba bwamwezi wakumamanino',
      'Keta lizazi la linako za mafelelezo',
    ],
    'Show password': [
      'Onetsani mawu achinsinsi',
      'Langisheni icipaso',
      'Langa ijwi lyakusisya',
      'Bonisa linzwi la sifumu',
    ],
    'Hide password': [
      'Bisani mawu achinsinsi',
      'Fiseni icipaso',
      'Sisa ijwi lyakusisya',
      'Pata linzwi la sifumu',
    ],
    'Forgot password?': [
      'Mwayiwala mawu achinsinsi?',
      'Mwalaba icipaso?',
      'Mwaluba ijwi?',
      'U lebetse linzwi?'
    ],
    'Forgot your password?': [
      'Mwayiwala mawu anu achinsinsi?',
      'Mwalaba icipaso cenu?',
      'Mwaluba ijwi lyanu?',
      'U lebetse linzwi la hao?',
    ],
    'Are you sure you want to log out?': [
      'Mukutsimikiza kuti mukufuna kutuluka?',
      'Mulesuminisha ukufuma?',
      'Mulasinizya kuzwa?',
      'U tiisa kuli u bata ku tuma?',
    ],
    'Your account was created. Some profile details can be completed after sign-in.':
        [
      'Akaunti yanu yapangidwa. Zina za mbiri yanu mungazimalize mutalowa.',
      'Account yenu yapangwa. Ifyebo fimbi fya imbila mwingapwisha nga mwingila.',
      'Akaunti yanu yapangwa. Makani ambi aambila yanu ingaamanizigwa mwanjila.',
      'Akanti ya hao i bupilwe. Litaba ze ñwi za taba za hao u ka li feleza ha u kena.',
    ],
    'Reset your password': [
      'Sinthani mawu achinsinsi',
      'Pangeni icipaso cipya',
      'Cinca ijwi lyakusisya',
      'Fetola linzwi la sifumu'
    ],
    'Personal details': [
      'Zambiri zanu',
      'Ifyebo fyenu',
      'Makani aanu',
      'Lintlha za hao'
    ],
    'Edit profile': [
      'Sinthani mbiri',
      'Lungamikeni imbila',
      'Cinca makani',
      'Fetola taba'
    ],
    'Privacy': ['Chinsinsi', 'Ubunkama', 'Busisikantu', 'Sifumu'],
    'Help & support': ['Thandizo', 'Ubwafwilisho', 'Lugwasyo', 'Tuso'],
    'About DawaMom': [
      'Za DawaMom',
      'Pa DawaMom',
      'Makani aa DawaMom',
      'Ka za DawaMom'
    ],
    'Delete account': [
      'Chotsani akaunti',
      'Fumyeni account',
      'Fumyani akaunti',
      'Tima akanti'
    ],
    'Permanently delete account?': [
      'Chotsani akaunti kosatha?',
      'Fumyeni account umuyayaya?',
      'Fumyani akaunti kukabelekela?',
      'Tima akanti ka nako kaufela?',
    ],
    'Type DELETE to confirm.': [
      'Lembani DELETE kuti mutsimikize.',
      'Lembeni DELETE pa kusuminisha.',
      'Lembani DELETE kuti musinizye.',
      'Ngola DELETE kuli u tiise.',
    ],
    'Keep account': [
      'Sungani akaunti',
      'Sungeni account',
      'Bikkani akaunti',
      'Buluka akanti',
    ],
    'Delete permanently': [
      'Chotsani kosatha',
      'Fumyeni umuyayaya',
      'Fumyani kukabelekela',
      'Tima ka nako kaufela',
    ],
    'Profile could not be loaded': [
      'Mbiri sinathe kutseguka',
      'Imbila tayaloleka',
      'Makani taakayoboloka',
      'Taba ha li a layisiwa',
    ],
    'How can we help?': [
      'Tingakuthandizeni bwanji?',
      'Twingamwafwa shani?',
      'Tulamugwasya buti?',
      'Lu ka ku tusa cwañi?',
    ],
    'General guidance and help finding the right feature.': [
      'Malangizo onse ndi thandizo lopeza chinthu choyenera.',
      'Amalango ya onse no bwafwilisho bwa kusanga ico mulefwaya.',
      'Malailile aajatikizya alubwasuko bwakujana comuyanda.',
      'Litaelo za kaufela ni tuso ya ku fumana se u bata.',
    ],
    'Care and appointments': [
      'Chisamaliro ndi nthawi zachipatala',
      'Ukusakamana na ma appointment',
      'Lutalililo ama appointment',
      'Pabalelo ni likopano',
    ],
    'For severe pain, heavy bleeding, trouble breathing, fainting, or pregnancy danger signs, seek urgent local medical care now.':
        [
      'Pa ululu waukulu, kutuluka magazi kwambiri, kupuma movuta, kukomoka kapena zizindikiro zoopsa za mimba, pitani kuchipatala mwachangu.',
      'Pa bukali ubwingi, ukufuma umulopa mwingi, ukutontonkanya, ukupwa amaka nangu ifilangililo fyabipa fya ifumo, fwayeni ubwafwilisho bwa cipatala nomba.',
      'Naa mulakolwa kapati, mulafuluka bulowa bungi, mulapenga, mulakomoka naa muli azizindikilo zyakuyoosya zya bulemu, amuya kuchipatala cakufwambaana.',
      'Ha u na ni butuku bo mañata, mali a mañata, ku hema ka tata, ku idibala kapa matšoao a kotsi a boimana, bata pabalelo ya bookelo ka putako.',
    ],
    'Change password': [
      'Sinthani mawu achinsinsi',
      'Cinsheni icipaso',
      'Cinca ijwi',
      'Fetola linzwi'
    ],
    'Quiet hours': [
      'Nthawi yachete',
      'Inshita ya mutende',
      'Ciindi cakutalala',
      'Nako ya kulobala'
    ],
    'Weekly summary': [
      'Chidule cha sabata',
      'Icipasho ca mulungu',
      'Bupanduluzi bwamvwiki',
      'Kakaretso ya viki'
    ],
    'Private lock-screen wording': [
      'Mawu achinsinsi pa sikilini',
      'Amashiwi ya nkama pa screen',
      'Majwi aabusisikantu pa screen',
      'Manzwi a sifumu kwa sikilini',
    ],
    'What you want to receive': [
      'Zomwe mukufuna kulandira',
      'Ifyo mulefwaya ukupokelela',
      'Zyomuyanda kutambula',
      'Ze u bata ku amuhela',
    ],
    'Notification channels': [
      'Njira za zidziwitso',
      'Inshila sha ifilango',
      'Nzila zyazizibisyo',
      'Linzila za litsebiso',
    ],
    'Booking updates and reminders you create.': [
      'Zosintha za kusungitsa ndi zikumbutso zomwe mumapanga.',
      'Ifyacinja pa kubikisha na fibukisho ifyo mulepanga.',
      'Zyakacinca pakubamba azikumbusyo zyomubamba.',
      'Linchafazo za likopano ni likhopotso ze u bupa.',
    ],
    'Eligibility and redemption updates.': [
      'Zosintha za kuyenerera ndi kutenga mphotho.',
      'Ifyacinja pa kukwanisha no kupokelela icilambu.',
      'Zyakacinca pakweelela akutambula cilumbu.',
      'Linchafazo za ku swanela ni ku fumana mupuzo.',
    ],
    'Shown inside DawaMom on this device.': [
      'Zimaonekera mkati mwa DawaMom pa chipangizochi.',
      'Filamoneka muli DawaMom pa cipangizo ici.',
      'Zilabonwa muli DawaMom pacintu eeci.',
      'Li bonahala mwa DawaMom kwa sesebeliswa se.',
    ],
    'In-app notification': [
      'Chidziwitso mkati mwa app',
      'Icilango muli app',
      'Cizibisyo muli app',
      'Tsebiso mwa app',
    ],
    'SMS': ['SMS', 'SMS', 'SMS', 'SMS'],
    'Requires a verified +260 mobile number and server delivery.': [
      'Imafunikira nambala ya +260 yotsimikizidwa ndi kutumiza kwa seva.',
      'Cilefwaya namba ya +260 yasuminishiwa no kutumwa na server.',
      'Ciyanda namba ya +260 yakasinizyigwa akutumwa kwaserver.',
      'I bata nombolo ya +260 ye tiisitizwe ni ku romelwa kwa server.',
    ],
    'Requires a verified email and server delivery.': [
      'Imafunikira imelo yotsimikizidwa ndi kutumiza kwa seva.',
      'Cilefwaya email yasuminishiwa no kutumwa na server.',
      'Ciyanda imelo yakasinizyigwa akutumwa kwaserver.',
      'I bata imeili ye tiisitizwe ni ku romelwa kwa server.',
    ],
    'Show “You have a Dawa reminder” instead of health details.': [
      'Onetsani “Muli ndi chikumbutso cha Dawa” m’malo mwa zambiri za thanzi.',
      'Langisheni “Muli ne cibukisho ca Dawa” mu ncende ya fyebo fya ubumi.',
      'Langa “Muli acikumbusyo ca Dawa” mubusena bwamakani aabuumi.',
      'Bonisa “U na ni khopotso ya Dawa” mwa sibaka sa litaba za buiketo.',
    ],
    'One optional summary of lessons, check-ins, care and your next action.': [
      'Chidule chimodzi cha maphunziro, kulemba mmene mulili, chisamaliro ndi chochita chotsatira.',
      'Icipasho cimo ca masambililo, ukulemba ifyo muli, ukusakamana ne cakucita panuma.',
      'Bupanduluzi bomwi bwazyakuyi, kulemba mbomuli, lutalililo acitobela.',
      'Kakaretso iliñwi ya lituto, ku ngola kamuso, pabalelo ni muhato ye latela.',
    ],
    'Timing and privacy': [
      'Nthawi ndi chinsinsi',
      'Inshita no bunkama',
      'Ciindi a busisikantu',
      'Nako ni sifumu',
    ],
    'Mark all as read': [
      'Chongani zonse kuti zawerengedwa',
      'Lembeni fyonse ati fyabelengwa',
      'Amubike zyoonse kuti zyabelengwa',
      'Swaya kaufela kuli li balilwe',
    ],
    'Recent': ['Zaposachedwa', 'Ifya nombaline', 'Zyamanje', 'Za swalisano'],
    'Read more': [
      'Werengani zambiri',
      'Belengeni nafimbi',
      'Amubeleke makani',
      'Bala hahulu'
    ],
    'View details': [
      'Onani zambiri',
      'Moneni ifyebo',
      'Bona makani',
      'Bona lintlha'
    ],
    'View all': [
      'Onani zonse',
      'Moneni fyonse',
      'Bona zyoonse',
      'Bona kaufela'
    ],
    'Open profile': [
      'Tsegulani mbiri',
      'Isuleni imbila',
      'Isuleni makani',
      'Atolosa taba',
    ],
    'Open care and appointments': [
      'Tsegulani chisamaliro ndi nthawi zachipatala',
      'Isuleni ukusakamana na ma appointment',
      'Isuleni lutalililo ama appointment',
      'Atolosa pabalelo ni likopano',
    ],
    'Open pregnancy guides': [
      'Tsegulani malangizo a mimba',
      'Isuleni ifilangililo fya ifumo',
      'Isuleni malailile aabulemu',
      'Atolosa lituto za boimana',
    ],
    'Minimize': ['Chepetsani', 'Cepesheni', 'Amuceesye', 'Fokotza'],
    'Remind me': [
      'Ndikumbutseni',
      'Munjibukishe',
      'Mundikumbusye',
      'Ni hopoze',
    ],
    'Update password': [
      'Sinthani mawu achinsinsi',
      'Cinsheni icipaso',
      'Cinca ijwi lyakusisya',
      'Fetola linzwi la sifumu',
    ],
    'Personal information': [
      'Zambiri zanu',
      'Ifyebo fyenu',
      'Makani aanu',
      'Litaba za hao',
    ],
    'Prefer not to say': [
      'Sindikufuna kunena',
      'Nshilefwaya ukulanda',
      'Nsiyandi kwaamba',
      'Ha ni bati ku bulela',
    ],
    'Not currently pregnant': [
      'Sindili ndi mimba pano',
      'Nshili ne fumo nomba',
      'Nsili abulemu lino',
      'Ha ni moimana cwale',
    ],
    'Not provided': [
      'Sizinaperekedwe',
      'Tafyapelelwe',
      'Tazyaambilwa',
      'Ha i a fiwa',
    ],
    'Quick actions': [
      'Zochita mwachangu',
      'Ifyakucita bwangu',
      'Zyakucita cakufwambaana',
      'Liketo za ka putako'
    ],
    'Dashboard could not be loaded': [
      'Tsamba loyamba silinatseguke',
      'Dashboard tayaloleka',
      'Dashboard tiyakonzya kuyoboloka',
      'Dashboard ha i a layisiwa',
    ],
    'Check your connection and try again.': [
      'Onani intaneti yanu ndipo yesaninso.',
      'Moneni intaneti yenu no kweshamo na kabili.',
      'Amulange intaneti yanu alimwi mweezye.',
      'Bona intaneti ya hao mi u leke hape.',
    ],
    'Your health at a glance': [
      'Thanzi lanu mwachidule',
      'Ubumi bwenu mu cipasho',
      'Buumi bwanu mubupanduluzi',
      'Buiketo bwa hao ka bukuswani',
    ],
    'Cycle dates are estimates based on your available logs.': [
      'Masiku a kayendedwe ndi oyerekeza kuchokera pa zomwe mwalemba.',
      'Inshiku sha cycle shalelengwa ukufuma mu fyalembwa fyenu.',
      'Mazuba aakuzunguluka alayeyelwa kuzwa mumakani ngomwalemba.',
      'Mazazi a mukoloko a lekanyelizwe ku za u ngolile.',
    ],
    'Cycle day': [
      'Tsiku la kayendedwe',
      'Ubushiku bwa cycle',
      'Buzuba bwakuzunguluka',
      'Lizazi la mukoloko',
    ],
    'CYCLE DAY': [
      'TSIKU LA KAYENDEDWE',
      'UBUSHIKU BWA CYCLE',
      'BUZUBA BWAKUZUNGULUKA',
      'LIZAZI LA MUKOLOKO',
    ],
    'No appointment booked': [
      'Palibe nthawi yosungitsidwa',
      'Takuli appointment yabikishiwa',
      'Takuna appointment yabambwa',
      'Ha ku na kopano ye behilwe',
    ],
    'Plan your next clinic visit': [
      'Konzani ulendo wanu wotsatira kuchipatala',
      'Pekanyeni ulwendo lwenu ulukonkapo ku kiliniki',
      'Bambizya kuya kwanu kutobela kuchipatala',
      'Lukisa ku ya kwa hao ku latelang kwa kiliniki',
    ],
    'Choose a Zambian clinic, clinician and time that work for you.': [
      'Sankhani chipatala cha ku Zambia, wachipatala ndi nthawi yabwino kwa inu.',
      'Saleni kiliniki ya mu Zambia, shinganga ne nshita iyamukwanila.',
      'Sankhani chipatala ca mu Zambia, mukoti aciindi camuyanda.',
      'Keta kiliniki ya Zambia, muokoti ni nako ye ku swanela.',
    ],
    'Continue your journey': [
      'Pitirizani ulendo wanu',
      'Twilileni ulwendo lwenu',
      'Amuyaanjilile ulwendo lwanu',
      'Tswelapili ni nzila ya hao',
    ],
    'Begin your story': [
      'Yambani nkhani yanu',
      'Tendekeni ilyashi lyenu',
      'Amutalike makani aanu',
      'Kala taba ya hao',
    ],
    'Today’s tip': [
      'Langizo la lero',
      'Ilanda lya uno mushi',
      'Malailile aasunu',
      'Taelo ya kacenu',
    ],
    'Good morning': [
      'Mwauka bwanji',
      'Mwashibukeni',
      'Mwabuka buti',
      'Mu zuhile cwañi',
    ],
    'Good afternoon': [
      'Mwaswera bwanji',
      'Mwashibukeni',
      'Mwaswera buti',
      'Mu sihile cwañi',
    ],
    'Good evening': [
      'Madzulo abwino',
      'Cungulo cabwino',
      'Gwasya',
      'Manzibwana',
    ],
    'History': ['Mbiri', 'Imbila', 'Makani aakale', 'Histori'],
    'About you': [
      'Za inu',
      'Pali imwe',
      'Makani aanu',
      'Ka za hao',
    ],
    'Contact details': [
      'Zambiri zolumikizirana',
      'Ifyebo fya kwampana',
      'Makani aakwambila',
      'Lintlha za ku amana',
    ],
    'My profile': [
      'Mbiri yanga',
      'Imbila yandi',
      'Makani aangu',
      'Taba za ka',
    ],
    'Profile complete': [
      'Mbiri yatha',
      'Imbila yapwa',
      'Makani aamana',
      'Taba li felezi',
    ],
    'Cycle tracking': [
      'Kutsatira kayendedwe',
      'Ukulondolola cycle',
      'Kulondola kuzunguluka',
      'Ku latelela mukoloko',
    ],
    'Active': ['Yayamba', 'Ilebomba', 'Ilaambila', 'I ya sebeza'],
    'Not set up': [
      'Sizinakhazikitsidwe',
      'Tafilapangwa',
      'Tazilabambwa',
      'Ha i so lukiswa',
    ],
    'Needs attention': [
      'Ikufuna kusamalidwa',
      'Ilefwaya ukubombapo',
      'Iyanda kulangwa',
      'I bata tlhokomelo',
    ],
    'Connected': ['Yalumikizidwa', 'Yalumikana', 'Yakomena', 'I amani'],
    'Pending': ['Ikuyembekezera', 'Ilelolela', 'Ilindila', 'I emetse'],
    'Replay app tour': [
      'Onaninso ulendo wa app',
      'Moneni na kabili ulwendo lwa app',
      'Bona alimwi mulawo wa app',
      'Bona hape nzila ya app',
    ],
    'Account actions': [
      'Zochita za akaunti',
      'Ifyakucita pa account',
      'Zyakucita pa akaunti',
      'Liketo za akanti',
    ],
    'Danger zone': [
      'Malo oopsa',
      'Incende yakusamala',
      'Cibeela cakuyoosya',
      'Sibaka sa kotsi',
    ],
    'Deleting your account is permanent.': [
      'Kuchotsa akaunti yanu sikungabwezedwe.',
      'Ukufumyapo account yenu takubwelela.',
      'Kufumya akaunti yanu takubwezegwi.',
      'Ku tima akanti ya hao ha ku buselizwi.',
    ],
    'Recommended for you': [
      'Zolimbikitsidwa kwa inu',
      'Ifyasalilwa imwe',
      'Zyamupandulilwa',
      'Ze u eletsa'
    ],
    'For you': ['Kwa inu', 'Kuli imwe', 'Kuli nduwe', 'Kwa hao'],
    'Nutrition': ['Zakudya', 'Ifyakulya', 'Zyakulya', 'Lico'],
    'Cervical health': [
      'Thanzi la khomo la chiberekero',
      'Ubumi bwa mulomo wa cifukushi',
      'Buumi bwamulomo wacibalo',
      'Buiketo bwa molomo wa popelo'
    ],
    'Cervical cancer awareness': [
      'Kudziwa khansa ya khomo la chiberekero',
      'Ukumanya kansa ya mulomo wa cifukushi',
      'Kumanya kansa yamulomo wacibalo',
      'Kuziba kankere ya molomo wa popelo'
    ],
    'Screening Without Fear': [
      'Kuyezedwa Mopanda Mantha',
      'Ukupimiwa Ukwabula Umwenso',
      'Kusikilwa Kakunyina Kuyoowa',
      'Tlhahlobo Kwa Saba'
    ],
    'Mother’s Path': [
      'Njira ya Amayi',
      'Inshila ya Ba Mayo',
      'Nzila ya Bamayi',
      'Nzila ya Bomme'
    ],
    'THE MOTHER’S PATH': [
      'NJIRA YA AMAYI',
      'INSHILA YA BA MAYO',
      'NZILA YA BAMAYI',
      'NZILA YA BOMME',
    ],
    'Get started': ['Yambani', 'Tendekeni', 'Amutalike', 'Kala'],
    'Get your next steps': [
      'Onani zomwe mutsatire',
      'Moneni ifyakucita',
      'Bona zyakutobela',
      'Bona mehato ye latela'
    ],
    'Check in': [
      'Lembani momwe mulili',
      'Lembeni ifyo muli',
      'Lembani mbomuli',
      'Ngola kamuso ya hao'
    ],
    'Symptoms today': [
      'Zizindikiro za lero',
      'Ifilangililo fya uno mushi',
      'Zizindikilo zyasunu',
      'Matšoao a kacenu'
    ],
    'How are you feeling today?': [
      'Mukumva bwanji lero?',
      'Muli shani uno mushi?',
      'Mulimvwa buti sunu?',
      'U ikutwa cwañi kacenu?'
    ],
    'Warning signs': [
      'Zizindikiro zoopsa',
      'Ifilangililo fyabipa',
      'Zizindikilo zyakuyoosya',
      'Matšoao a kotsi'
    ],
    'Urgent care': [
      'Chisamaliro chadzidzidzi',
      'Ukusakamana kwa bwangu',
      'Lutalililo lwakufwambaana',
      'Pabalelo ya ka putako'
    ],
    'Seek urgent medical care': [
      'Pitani kuchipatala mwachangu',
      'Fwayeni ubwafwilisho bwa bwangu',
      'Amuya ku chipatala cakufwambaana',
      'Bata pabalelo ya ka putako',
    ],
    'medical care': [
      'chisamaliro cha chipatala',
      'ukusakamana kwa cipatala',
      'lutalililo lwachipatala',
      'pabalelo ya bookelo'
    ],
    'clinician': ['wachipatala', 'shinganga', 'mukoti', 'muokoti'],
    'your clinic': [
      'chipatala chanu',
      'kiliniki yenu',
      'chipatala canu',
      'kiliniki ya hao'
    ],
    'your baby': ['mwana wanu', 'umwana wenu', 'mwana wanu', 'ñwana hao'],
    'your health': [
      'thanzi lanu',
      'ubumi bwenu',
      'buumi bwanu',
      'buiketo bwa hao'
    ],
    'your account': [
      'akaunti yanu',
      'account yenu',
      'akaunti yanu',
      'akanti ya hao'
    ],
    'your profile': ['mbiri yanu', 'imbila yenu', 'makani aanu', 'taba za hao'],
    'could not be loaded': [
      'sizinathe kutsegulidwa',
      'tafyaloleka',
      'tazyaloleka',
      'ha i a layisiwa'
    ],
    'could not be saved': [
      'sizinathe kusungidwa',
      'tafyaloleka ukusungwa',
      'tazyaloleka kubikkwa',
      'ha i a bulukiwa'
    ],
    'unavailable': ['sikupezeka', 'tailepo', 'tachilipo', 'ha i yo'],
    'not available': ['sikupezeka', 'tailepo', 'tachilipo', 'ha i yo'],
    'Please try again.': [
      'Chonde yesaninso.',
      'Napapata esheni na kabili.',
      'Amweezye alimwi.',
      'Ka kopo leka hape.'
    ],
    'Please wait': [
      'Chonde dikirani',
      'Napapata loleleni',
      'Amulindile',
      'Ka kopo emela'
    ],
    'Saved': ['Zasungidwa', 'Fyasungwa', 'Zyabikkwa', 'I bulukilwe'],
    'Saving...': [
      'Ikusunga...',
      'Ilesunga...',
      'Ilabikka...',
      'I a buluka...',
    ],
    'Save changes': [
      'Sungani zosintha',
      'Sungeni ifyacinjishiwa',
      'Bikkani zyakacinjigwa',
      'Buluka linchafazo',
    ],
    'Completed': ['Zamalizidwa', 'Fyapwa', 'Zyamana', 'I felile'],
    'points': ['mapointi', 'ama points', 'mapoints', 'liponti'],
    'days': ['masiku', 'inshiku', 'mazuba', 'mazazi'],
    'day': ['tsiku', 'ubushiku', 'buzuba', 'lizazi'],
    'week': ['sabata', 'umulungu', 'mvwiki', 'viki'],
    'minutes': ['mphindi', 'imineti', 'miniti', 'mizuzu'],
    'min read': [
      'mphindi zowerenga',
      'imineti yakubelenga',
      'miniti yakubelenga',
      'mizuzu ya ku bala'
    ],
    'Next': ['Kenako', 'Konkapo', 'Citobela', 'Latela'],
    'Previous': ['Mmbuyo', 'Ifyalenga', 'Cakunyuma', 'Sa pili'],
    'Expand sidebar': [
      'Kulitsani menyu',
      'Isuleni menu',
      'Amuyandisye menu',
      'Atolosa menyu'
    ],
    'Collapse sidebar': [
      'Chepetsani menyu',
      'Isaleni menu',
      'Amuceesye menu',
      'Fokotza menyu'
    ],
    'TODAY WITH DAWAMOM': [
      'LERO NDI DAWAMOM',
      'UNO MUSHI NA DAWAMOM',
      'SUNU A DAWAMOM',
      'KACENU NI DAWAMOM',
    ],
    'YOUR PREGNANCY TODAY': [
      'MIMBA YANU LERO',
      'UBWIMI BWENU UNO MUSHI',
      'BULEMU BWANU SUNU',
      'BUIMANA BWA HAO KACENU',
    ],
    'For today': [
      'Za lero',
      'Ifya uno mushi',
      'Zyasunu',
      'Za kacenu',
    ],
    'These dates come from the periods you added.': [
      'Masikuwa achokera ku msambo umene munalemba.',
      'Inshiku ishi shafuma ku menshi mwalembile.',
      'Mazuba aaya azwa kumasusu ngamwalemba.',
      'Mazazi a a zwa kwa linako la ku ya ku likulo le u ngolile.',
    ],
    'What do you need?': [
      'Mukufuna chiyani?',
      'Finshi mulefwaya?',
      'Ncinzi ncomuyanda?',
      'U bata ñi?',
    ],
    'YOUR NEXT VISIT': [
      'ULENDO WANU WOTSATIRA',
      'UKWALA KWENU UKUKONKAPO',
      'KUYA KWANU KUTOBELA',
      'KUTAHA KWA HAO KO LATELA',
    ],
    'Choose a clinic, health worker and time that suit you.': [
      'Sankhani chipatala, wogwira ntchito zaumoyo ndi nthawi yabwino kwa inu.',
      'Saleni kiliniki, umubomfi wa bumi na nshita iyamukwanila.',
      'Sankhani chipatala, mubelesi wabwami aciindi cimweelede.',
      'Keta kiliniki, mubeleki wa buiketo ni nako ye ku swanela.',
    ],
    'Short stories, clear steps and rewards.': [
      'Nkhani zazifupi, magawo omveka ndi mphotho.',
      'Inkani inshipi, intampulo ishalumfwika na malipilo.',
      'Twaano tufwiifwi, mitobelo iitanganana amipego.',
      'Likande ze kuswani, mihato ye utwahala ni limpho.',
    ],
    'If a pregnancy symptom worries you, talk to a health worker.': [
      'Ngati chizindikiro cha mimba chikukudetsani nkhawa, lankhulani ndi wogwira ntchito zaumoyo.',
      'Nga icilangililo ca bwimi camipeela umwenso, landeni na mubomfi wa bumi.',
      'Naa cizindikilo cabulemu camupa moyo, amwaambile mubelesi wabwami.',
      'Ha sina sesupo sa buimana si ku swabisa, bulela ni mubeleki wa buiketo.',
    ],
    'Your health profile': [
      'Mbiri ya thanzi lanu',
      'Imbila ya bumi bwenu',
      'Makani aabuumi bwanu',
      'Taba za buiketo bwa hao',
    ],
    'Tell us a little about you': [
      'Tiuzeni pang’ono za inu',
      'Twebeleni panono pali imwe',
      'Mutwaambile baniini muli ndinywe',
      'Lubulela hanyinyani ka za hao',
    ],
    'This helps DawaMom show the right care and tips.': [
      'Izi zithandiza DawaMom kukusonyezani chisamaliro ndi malangizo oyenera.',
      'Ici cilafwa DawaMom ukumilanga ukusakamana na malango ayafwa.',
      'Eezi zigwasya DawaMom kumutondezya lutalililo amalailile aabotu.',
      'Se si tusa DawaMom ku ku bonisa pabalelo ni likeletso ze swanela.',
    ],
    'Finish all four steps for better tips and faster booking.': [
      'Malizani magawo onse anayi kuti mupeze malangizo abwino ndi kusungitsa msanga.',
      'Maneni intampulo shonse shine pa malango ayawama na ukubuka bwangu.',
      'Mumane mitobelo yoonse yobile kuti mujane malailile aabotu akubuka cakufwambaana.',
      'Feleza mihato kaufela ye mine ku fumana likeletso ze nde ni ku beela ka putako.',
    ],
    'Your four steps': [
      'Magawo anu anayi',
      'Intampulo shenu shine',
      'Mitobelo yanu yobile',
      'Mihato ya hao ye mine',
    ],
    'Tap any step to add or change an answer.': [
      'Dinani gawo lililonse kuti muonjezere kapena kusintha yankho.',
      'Tomfyeni intampulo iili yonse ukulundapo nangu ukucinja icasuko.',
      'Amutantame mutobelo oonse kuti muongezye naa mucince bwaambulo.',
      'Tobetsa muhato ufi kapa ufi ku ekeza kapa ku fetola karabo.',
    ],
    'How to reach you': [
      'Mmene tingakufikireni',
      'Ifyo twingamishikilapo',
      'Mbomukonzya kujanika',
      'Moo re ka ku fumana',
    ],
    'Pregnancy choice': [
      'Zokhudza mimba',
      'Ukusala pa bwimi',
      'Kusala kwabulemu',
      'Kuketa ka za buimana',
    ],
    'Your period dates': [
      'Masiku anu a msambo',
      'Inshiku shenu sha menshi',
      'Mazuba aanu amasusu',
      'Mazazi a hao a ku ya ku likulo',
    ],
    'To do': ['Zoti muchite', 'Ifyakucita', 'Zyakucita', 'Ze u ka eza'],
    'Add now': [
      'Onjezani tsopano',
      'Lundapo nomba',
      'Amubikke lino',
      'Ekeza cwale',
    ],
    'Choose now': [
      'Sankhani tsopano',
      'Saleni nomba',
      'Amusale lino',
      'Keta cwale',
    ],
    'Close for now': [
      'Tsekani pakadali pano',
      'Isaleni pali nomba',
      'Amujale lino',
      'Kwala ka nako ye',
    ],
    'ALL DONE': [
      'ZONSE ZATHA',
      'FYONSE FYAPWA',
      'ZYOONSE ZYAMANA',
      'KAUFELA KU FELILE'
    ],
    'MADE FOR YOU': [
      'ZAPANGIDWIRA INU',
      'IFYAPANGILWE IMWE',
      'ZYAKUPANGILWA INYWE',
      'ZE ETSITWE WENA',
    ],
    'Small lessons. Clear answers.': [
      'Maphunziro afupi. Mayankho omveka.',
      'Amasambililo ayafupi. Amasuko ayalumfwika.',
      'Zyakuyi zyifwiifwi. Bwaambulo butanganana.',
      'Lituto ze kuswani. Likarabo ze utwahala.',
    ],
    'Read or listen in the language you chose.': [
      'Werengani kapena mvetserani m’chilankhulo chimene mwasankha.',
      'Belengeni nangu umfweni mu lulimi mwasala.',
      'Amubelenga naa kumvwa mumulaka ngomwasala.',
      'Bala kapa u teeleze ka puo ye u ketile.',
    ],
    'Search health lessons': [
      'Sakani maphunziro a zaumoyo',
      'Fwayeni amasambililo ya bumi',
      'Jana zyakuyi zyabuumi',
      'Bata lituto za buiketo',
    ],
    'No lesson found': [
      'Palibe phunziro lopezeka',
      'Takuli isambililo lyasangwa',
      'Kunyina ciyiyo cajanika',
      'Ha ku na tuto ye fumanehile',
    ],
    'Try a shorter word or choose another topic.': [
      'Yesani mawu afupi kapena sankhani mutu wina.',
      'Esheni ishiwi ilyaipi nangu saleni umutwe umbi.',
      'Amweezye bbala lifwiifwi naa musale makani ambi.',
      'Leka linzwi le likuswani kapa u kete taba ye ñwi.',
    ],
    'Picked for you': [
      'Takusankhirani',
      'Ifyasankilwa imwe',
      'Zyakamusalilwa',
      'Ze u ketetswe',
    ],
    'Clear health tips you can save for later.': [
      'Malangizo omveka a zaumoyo amene mungasunge.',
      'Amalango ya bumi ayalumfwika ayo mwingasunga.',
      'Malailile aabuumi aatanganana ngomukonzya kubikka.',
      'Likeletso za buiketo ze utwahala ze u ka buluka.',
    ],
    'Book a visit with ease': [
      'Sungitsani ulendo mosavuta',
      'Bukeni ukwalamuka bwino',
      'Bukeni kuya canguzu',
      'Beela ku taha hande',
    ],
    'Choose a clinic, health worker and time. DawaMom will remind you.': [
      'Sankhani chipatala, wogwira ntchito zaumoyo ndi nthawi. DawaMom idzakukumbutsani.',
      'Saleni kiliniki, umubomfi wa bumi na nshita. DawaMom ikamibukisha.',
      'Sankhani chipatala, mubelesi wabwami aciindi. DawaMom ilamwiibukizya.',
      'Keta kiliniki, mubeleki wa buiketo ni nako. DawaMom i ka ku hupulisa.',
    ],
    'Health answers you can trust': [
      'Mayankho a zaumoyo amene mungakhulupirire',
      'Amasuko ya bumi ayo mwingacetekela',
      'Bwaambulo bwabuumi ngomukonzya kusyoma',
      'Likarabo za buiketo ze u ka sepa',
    ],
    'Read or listen to short health lessons in the language you chose.': [
      'Werengani kapena mvetserani maphunziro afupi a zaumoyo m’chilankhulo chimene mwasankha.',
      'Belengeni nangu umfweni amasambililo ayafupi aya bumi mu lulimi mwasala.',
      'Amubelenga naa kumvwa zyakuyi zyifwiifwi zyabuumi mumulaka ngomwasala.',
      'Bala kapa u teeleze lituto ze kuswani za buiketo ka puo ye u ketile.',
    ],
    'Know your cycle': [
      'Dziwani kayendedwe ka msambo wanu',
      'Ishibeni umutebeto wa menshi yenu',
      'Muzyibe kutambula kwamasusu aanu',
      'Tseba nako ya hao ya ku ya ku likulo',
    ],
    'Add periods and symptoms. See simple dates that help you plan.': [
      'Onjezani msambo ndi zizindikiro. Onani masiku osavuta okuthandizani kukonza.',
      'Lembeni menshi na filangililo. Moneni inshiku ishalama ishamwafwa ukupanga.',
      'Lembani masusu azizindikilo. Amubone mazuba aanguzu aamugwasya kupanga.',
      'Ngola linako la ku ya ku likulo ni matšoao. Bona mazazi a bunolo a ku tusa ku rula.',
    ],
    'Learn, play and earn': [
      'Phunzirani, sewerani ndi kupeza',
      'Sambilileni, angaleni no kupoka',
      'Iya, kosanina akupeza',
      'Ithute, bapala ni ku fumana',
    ],
    'Play short health games, earn Dawa points and work towards care rewards.':
        [
      'Sewerani masewera afupi a zaumoyo, pezani mapointi a Dawa ndipo gwirani ntchito yopeza mphotho za chisamaliro.',
      'Angaleni imisebelo iyafupi iya bumi, pokeleni ama point ya Dawa no kubombela amalipilo ya kusakamana.',
      'Amukosane misobano mifwiifwi yabuumi, mupeze mapointi a Dawa akulanga kumipego yalutalililo.',
      'Bapala lipapali ze kuswani za buiketo, fumana liponti za Dawa ni ku ya kwa limpho za pabalelo.',
    ],
    'Visit booked': [
      'Ulendo wasungitsidwa',
      'Ukwala kwabukwa',
      'Kuya kwabukwa',
      'Ku taha ku beezi',
    ],
    'Health worker': [
      'Wogwira ntchito zaumoyo',
      'Umubomfi wa bumi',
      'Mubelesi wabwami',
      'Mubeleki wa buiketo',
    ],
    'Visit reminder': [
      'Chikumbutso cha ulendo',
      'Icibukisho ca kwala',
      'Ciibukizyo cakuya',
      'Kuhupuliswa ka ku taha',
    ],
    'Short lessons': [
      'Maphunziro afupi',
      'Amasambililo ayafupi',
      'Zyakuyi zyifwiifwi',
      'Lituto ze kuswani',
    ],
    'Myth or fact': [
      'Nthano kapena zoona',
      'Ulupiya nangu icine',
      'Lwaano naa kasimpe',
      'Mukiti kapa niti',
    ],
    'Period dates': [
      'Masiku a msambo',
      'Inshiku sha menshi',
      'Mazuba amasusu',
      'Mazazi a ku ya ku likulo',
    ],
    'How you feel': [
      'Mmene mukumvera',
      'Ifyo muleumfwa',
      'Mbomulimvwa',
      'Moo u ikutwela',
    ],
  };
}

class DawaMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const DawaMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => DawaLanguages.locales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<MaterialLocalizations> load(Locale locale) async =>
      DawaMaterialLocalizations(locale);

  @override
  bool shouldReload(DawaMaterialLocalizationsDelegate old) => false;
}

class DawaMaterialLocalizations extends DefaultMaterialLocalizations {
  const DawaMaterialLocalizations(this.locale);

  final Locale locale;

  String _tr(String source) => DawaTranslations.translate(source, locale);

  static const _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  String formatShortDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  String formatMediumDate(DateTime date) =>
      '${_tr(_weekdays[date.weekday - 1])}, ${date.day}/${date.month}';

  @override
  String formatFullDate(DateTime date) =>
      '${_tr(_weekdays[date.weekday - 1])}, ${date.day} '
      '${_tr(_months[date.month - 1])} ${date.year}';

  @override
  String formatMonthYear(DateTime date) =>
      '${_tr(_months[date.month - 1])} ${date.year}';

  @override
  String formatShortMonthDay(DateTime date) => '${date.day}/${date.month}';

  @override
  String formatCompactDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year.toString().padLeft(4, '0')}';

  @override
  DateTime? parseCompactDate(String? inputString) {
    final parts = inputString?.split('/');
    if (parts == null || parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final value = DateTime(year, month, day);
    return value.year == year && value.month == month && value.day == day
        ? value
        : null;
  }

  @override
  List<String> get narrowWeekdays => [
        _tr('Sunday').characters.first,
        _tr('Monday').characters.first,
        _tr('Tuesday').characters.first,
        _tr('Wednesday').characters.first,
        _tr('Thursday').characters.first,
        _tr('Friday').characters.first,
        _tr('Saturday').characters.first,
      ];

  @override
  int get firstDayOfWeekIndex => 1;

  @override
  String get dateHelpText => 'dd/mm/yyyy';

  @override
  String get selectYearSemanticsLabel => _tr('Select year');

  @override
  String get unspecifiedDate => _tr('Date');

  @override
  String get unspecifiedDateRange => _tr('Date range');

  @override
  String get dateInputLabel => _tr('Enter date');

  @override
  String get dateRangeStartLabel => _tr('Start date');

  @override
  String get dateRangeEndLabel => _tr('End date');

  @override
  String dateRangeStartDateSemanticLabel(String formattedDate) =>
      '${_tr('Start date')} $formattedDate';

  @override
  String dateRangeEndDateSemanticLabel(String formattedDate) =>
      '${_tr('End date')} $formattedDate';

  @override
  String get invalidDateFormatLabel => _tr('Invalid date format.');

  @override
  String get invalidDateRangeLabel => _tr('Invalid date range.');

  @override
  String get dateOutOfRangeLabel => _tr('Date is out of range.');

  @override
  String get saveButtonLabel => _tr('Save');

  @override
  String get datePickerHelpText => _tr('Select date');

  @override
  String get dateRangePickerHelpText => _tr('Select date range');

  @override
  String get calendarModeButtonLabel => _tr('Switch to calendar');

  @override
  String get inputDateModeButtonLabel => _tr('Switch to text input');

  @override
  String get timePickerDialHelpText => _tr('Select time');

  @override
  String get timePickerInputHelpText => _tr('Enter time');

  @override
  String get timePickerHourLabel => _tr('Hour');

  @override
  String get timePickerMinuteLabel => _tr('Minute');

  @override
  String get invalidTimeLabel => _tr('Enter a valid time');

  @override
  String get dialModeButtonLabel => _tr('Switch to clock');

  @override
  String get inputTimeModeButtonLabel => _tr('Switch to text input');

  @override
  String get openAppDrawerTooltip => _tr('Open navigation menu');

  @override
  String get backButtonTooltip => _tr('Back');

  @override
  String get clearButtonTooltip => _tr('Clear');

  @override
  String get closeButtonTooltip => _tr('Close');

  @override
  String get deleteButtonTooltip => _tr('Delete');

  @override
  String get moreButtonTooltip => _tr('More');

  @override
  String get nextMonthTooltip => _tr('Next month');

  @override
  String get previousMonthTooltip => _tr('Previous month');

  @override
  String get searchFieldLabel => _tr('Search');

  @override
  String get currentDateLabel => _tr('Today');

  @override
  String get selectedDateLabel => _tr('Selected');

  @override
  String get modalBarrierDismissLabel => _tr('Dismiss');

  @override
  String get cancelButtonLabel => _tr('Cancel');

  @override
  String get closeButtonLabel => _tr('Close');

  @override
  String get continueButtonLabel => _tr('Continue');

  @override
  String get copyButtonLabel => _tr('Copy');

  @override
  String get cutButtonLabel => _tr('Cut');

  @override
  String get okButtonLabel => _tr('OK');

  @override
  String get pasteButtonLabel => _tr('Paste');

  @override
  String get selectAllButtonLabel => _tr('Select all');
}

class DawaCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const DawaCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => DawaLanguages.locales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(DawaCupertinoLocalizationsDelegate old) => false;
}
