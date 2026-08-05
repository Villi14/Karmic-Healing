import Foundation

public extension String {
  func localized(for locale: Locale) -> String {
    let languageCode = locale.language.languageCode?.identifier ?? "en"
    
    // Custom translations map
    let translations: [String: [String: String]] = [
      "divine_self": [
        "en": "Divine Self", 
        "ru": "Божественное Я",
        "uk": "Божественне Я"
      ],
      "essential_self": [
        "en": "Essential Self",
        "ru": "Сущностное Я",
        "uk": "Сутнісне Я"
      ],
      "settings": [
        "en": "Settings",
        "ru": "Настройки", 
        "uk": "Налаштування"
      ],
      "sound": [
        "en": "Sound",
        "ru": "Звук",
        "uk": "Звук"
      ],
      "vibration": [
        "en": "Vibration",
        "ru": "Вибрация",
        "uk": "Вібрація"
      ],
      "duration": [
        "en": "Duration",
        "ru": "Длительность",
        "uk": "Тривалість"
      ],
      "language": [
        "en": "Language",
        "ru": "Язык",
        "uk": "Мова"
      ],
      "min": [
        "en": "min",
        "ru": "мин",
        "uk": "хв"
      ],
      "sec": [
        "en": "sec",
        "ru": "сек",
        "uk": "с"
      ],
      "delay": [
        "en": "Delay",
        "ru": "Задержка",
        "uk": "Затримка"
      ],
      "screen_rest": [
        "en": "Screen rest",
        "ru": "Отдых экрана",
        "uk": "Відпочинок екрана"
      ],
      "en": [
        "en": "English",
        "ru": "Английский",
        "uk": "Англійська"
      ],
      "uk": [
        "en": "Ukrainian",
        "ru": "Украинский",
        "uk": "Українська"
      ],
      "ru": [
        "en": "Russian",
        "ru": "Русский",
        "uk": "Російська"
      ],
      "step1": [
        "en": "Ask permission to speak with the Lords of Karma.",
        "ru": "Спросите разрешения поговорить с Властителями Кармы.",
        "uk": "Запитайте дозвіл говорити з Володарями Карми."
      ],
      "step2": [
        "en": "Ask them to align your energy bodies and set up contacts between them.",
        "ru": "Попросите их выстроить ваши энергетические тела и настроить контакты между ними",
        "uk": "Попросіть їх вирівняти ваші енергетичні тіла та налаштувати контакти між ними."
      ],
      "step3": [
        "en": "Ask to clear, heal, activate and open:",
        "ru": "Попросите очистить, исцелить, активировать и открыть:",
        "uk": "Попросіть очистити, зцілити, активувати та відкрити:"
      ],
      "step3text": [
        "en": "a) Ka Matrix;\nb) Etheric Matrix;\nc) Ketheric Matrix;\nd) Celestial Matrix;\nd) I-Am Matrix.",
        "ru": "а) Матрицу Ка;\nb) Эфирную Матрицу;\nc) Кетерическую Матрицу;\nd) Небесную Матрицу;\nd) Матрицу Я-Есть.",
        "uk": "а) Матрицю Ка;\nb) Ефірну Матрицю;\nc) Кетеричну Матрицю;\nd) Небесну Матрицю;\nd) Матрицю Я-Є."
      ],
      "steplast": [
        "en": "Return to today, but continue to lie down for at least two hours.",
        "ru": "Возвращайтесь в сегодняшний день, но продолжайте лежать не менее двух часов.",
        "uk": "Повертайтеся в сьогоднішній день, але продовжуйте лежати не менше двох годин."
      ],
      "part1step11": [
        "en": "Ask your Higher Self to clear, align, open, activate and fill the Hara line channels and chakras.",
        "ru": "Попросите свое Высшее Я очистить, выстроить, открыть, активировать и заполнить собой каналы и чакры линии Хара.",
        "uk": "Попросіть своє Вище Я очистити, вирівняти, відкрити, активувати та заповнити собою канали та чакри лінії Хара."
      ],
      "part1step12": [
        "en": "Ask your Higher Self to clear, align, open, activate and fill the Kundalini channels and chakras.",
        "ru": "Попросите свое Высшее Я очистить, выстроить, открыть, активировать и заполнить собой каналы и чакры Кундалини.",
        "uk": "Попросіть своє Вище Я очистити, вирівняти, відкрити, активувати та заповнити собою канали та чакри Кундаліні."
      ],
      "part2step4": [
        "en": "Ask to restore, heal and activate your Silver Cord.",
        "ru": "Попросите восстановить, исцелить и активировать вашу Серебряную Нить.",
        "uk": "Попросіть відновити, зцілити та активувати вашу Срібну Нитку."
      ],
      "part2step5": [
        "en": "Ask your Higher Self to come to you.",
        "ru": "Попросите свое Высшее Я явиться к вам.",
        "uk": "Попросіть своє Вище Я явитися до вас."
      ],
      "part2step8": [
        "en": "Ask to clear, heal, align, open and activate the three Galactic Matrices.",
        "ru": "Попросите очистить, исцелить, выстроить, открыть и активировать три Галактические Матрицы.",
        "uk": "Попросіть очистити, зцілити, вирівняти, відкрити та активувати три Галактичні Матриці."
      ],
      "part2step9": [
        "en": "Ask to clear, heal, align, open and activate the five Galactic Chakras.",
        "ru": "Попросите очистить, исцелить, выстроить, открыть и активировать пять Галактических Чакр.",
        "uk": "Попросіть очистити, зцілити, вирівняти, відкрити та активувати п'ять Галактичних Чакр."
      ],
      "part2step10": [
        "en": "Ask your Essence Self/Star Self to come forth and merge with your Higher Self.",
        "ru": "Попросите свое Сущностное Я/Звездное Я явиться и слиться с вашим Высшим Я.",
        "uk": "Попросіть своє Сутнісне Я/Зоряне Я явитися та злитися з вашим Вищим Я."
      ],
      "part2step11": [
        "en": "Talk to him a little and ask him to connect with you forever.",
        "ru": "Поговорите с ним немного и попросите соединиться с вами навсегда.",
        "uk": "Поспілкуйтеся з ним трохи та попросіть з'єднатися з вами назавжди."
      ],
      "part3step11": [
        "en": "Ask to clear, heal, align, open and activate the three Matrices of the causal body.",
        "ru": "Попросите очистить, исцелить, выстроить, открыть и активировать три Матрицы каузального тела.",
        "uk": "Попросіть очистити, зцілити, вистроїти, відкрити та активувати три Матриці каузального тіла."
      ],
      "part3step12": [
        "en": "Ask to clear, heal, align, open and activate the five chakras of the causal body.",
        "ru": "Попросите очистить, исцелить, выстроить, открыть и активировать пять чакр каузального тела.",
        "uk": "Попросіть очистити, зцілити, вистроїти, відкрити та активувати п'ять чакр каузального тіла."
      ],
      "part3step13": [
        "en": "Ask your Divine Self/OverSoul to come and merge with your Higher Self and Essential Self.",
        "ru": "Попросите свое Божественное Я/Сверхдушу прийти и слиться с вашим Высшим Я и Сущностным Я.",
        "uk": "Попросіть своє Божественне Я/Наддушу прийти та злитися з вашим Вищим Я та Сутнісним Я."
      ],
      "part3step14": [
        "en": "Ask his name, talk to him.",
        "ru": "Спросите его имя, поговорите с ним.",
        "uk": "Запитайте його ім'я, поспілкуйтеся з ним."
      ],
      "part3step15": [
        "en": "Ask your Divine Self to stay with you forever (the process may take several days).",
        "ru": "Попросите свое Божественное Я остаться с вами навсегда (процесс может длиться несколько дней).",
        "uk": "Попросіть своє Божественне Я залишитися з вами назавжди (процес може тривати кілька днів)."
      ],
      "part3step16": [
        "en": "Invite your Goddess to come into you and merge with your Divine Self, and also connect your energy with the energy of all your bodies. Talk to her, ask her name.",
        "ru": "Пригласите свою Богиню войти в вас и слиться с вашим Божественным Я, а также соединить свою энергию с энергией всех ваших тел. Поговорите с ней, спросите ее имя.",
        "uk": "Запросіть свою Богиню ввійти до вас та злитися з вашим Божественним Я, а також з'єднати свою енергію з енергією всіх ваших тіл. Поспілкуйтеся з нею, запитайте її ім'я."
      ],
      "part3step17": [
        "en": "Ask that the process just completed become permanent.",
        "ru": "Попросите, чтобы только что завершенный процесс приобрел постоянный характер.",
        "uk": "Попросіть, щоб щойно завершений процес набув постійного характеру."
      ],
      "paused": [
        "en": "Paused",
        "ru": "Пауза",
        "uk": "Пауза"
      ],
      "pause": [
        "en": "Pause",
        "ru": "Пауза",
        "uk": "Пауза"
      ],
      "resume": [
        "en": "Resume",
        "ru": "Продолжить",
        "uk": "Продовжити"
      ]
    ]
    
    if let languageTranslations = translations[self],
       let translation = languageTranslations[languageCode] {
      return translation
    }
    
    // Fallback to original string
    return self
  }
}
