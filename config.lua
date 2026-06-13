Config = {}

-- Whitelist فعال است یا خیر
Config.WhitelistEnabled = true

-- ورود فقط با اکانت (username/password) — بدون نیاز به license/steam هنگام اتصال
Config.AccountAuth = {
    enabled = true,
    -- شناسه steam برای essentialmode از دیتابیس اکانت ساخته می‌شود
    hexPrefix = '1100001',
    -- اگر کلاینت license داشت، فقط ذخیره می‌شود (اجباری نیست)
    saveClientLicenseIfAvailable = true,
}

-- تنظیمات امنیتی
Config.Security = {
    minUsernameLength = 4,
    maxUsernameLength = 16,
    minPasswordLength = 6,
    maxPasswordLength = 32,
    maxLoginAttempts = 3,
    loginCooldown = 60,
}

-- پیام‌های پنل (Adaptive Card — بدون کد رنگ FiveM)
Config.Messages = {
    menuTitle = 'به سرور خوش آمدید',
    chooseOption = 'لطفاً یکی از گزینه‌ها را انتخاب کنید:',
    btnLogin = 'ورود',
    btnRegister = 'ثبت‌نام',
    btnBack = 'بازگشت',
    btnSubmitLogin = 'ورود به حساب',
    btnSubmitRegister = 'ساخت حساب',

    loginTitle = 'ورود به حساب',
    registerTitle = 'ثبت‌نام حساب جدید',
    usernamePlaceholder = 'نام کاربری (4-16 کاراکتر)',
    passwordPlaceholder = 'رمز عبور (6-32 کاراکتر)',
    confirmPasswordPlaceholder = 'تکرار رمز عبور',

    registerSuccess = 'ثبت‌نام موفق!\nنام کاربری: %s\nدر حال اتصال به سرور...',
    registerFailed = 'ثبت‌نام ناموفق بود. دوباره تلاش کنید.',
    usernameExists = 'این نام کاربری قبلاً استفاده شده است.',
    passwordMismatch = 'رمز عبور و تکرار آن یکسان نیستند.',
    usernameTooShort = 'نام کاربری باید حداقل 4 کاراکتر باشد.',
    usernameTooLong = 'نام کاربری حداکثر 16 کاراکتر مجاز است.',
    passwordTooShort = 'رمز عبور باید حداقل 6 کاراکتر باشد.',
    passwordTooLong = 'رمز عبور حداکثر 32 کاراکتر مجاز است.',
    invalidUsername = 'نام کاربری فقط حروف انگلیسی، عدد و _ مجاز است.',
    fieldsRequired = 'لطفاً همه فیلدها را پر کنید.',

    loginSuccess = 'ورود موفق!\nدر حال اتصال به سرور...',
    loginFailed = 'نام کاربری یا رمز عبور اشتباه است.',
    accountInactive = 'این حساب غیرفعال است.',
    maxAttempts = 'تعداد تلاش‌ها بیش از حد مجاز است.\n60 ثانیه صبر کنید.',
    accountLocked = 'حساب موقتاً قفل است. %s ثانیه صبر کنید.',
    attemptsLeft = 'تلاش باقی‌مانده: %s',

    welcome = 'به سرور خوش آمدید!',
    connecting = 'در حال بررسی اتصال...',
    cancelled = 'اتصال لغو شد.',
    timeout = 'زمان اتصال تمام شد. دوباره تلاش کنید.',

    notWhitelisted = 'شما مجاز به ورود نیستید.\nTeamSpeak: 45.81.17.37:5020',
}

-- پیام‌های چت کلاینت (با کد رنگ)
Config.ChatMessages = {
    welcome = '~g~به سرور خوش آمدید!',
}

-- اطلاعات تماس
Config.ContactInfo = {
    teamspeak = '45.81.17.37:5020',
    website = 'https://yourserver.com'
}
