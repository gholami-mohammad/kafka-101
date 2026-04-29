# امنیت در کافکا - Security

امنیت در کافکا در سه گروه بررسی می شود:

- [ رمزنگاری - Encryption](./61-security-encryption.md)
- [ احراز هویت - Authentication](./62-security-authentication.md)
- [تعیین سطح دسترسی به منابع - Authorization](./66-security-authorization.md)

**بسیار مهم:**

در تمامی مراحل کار، در پوشه secrets، سه زیرپوشه ایجاد خواهیم کرد.

۱) فایل هایی که در پوشه ca ساخته میشوند، به این پوشه منتقل میشوند، یا از این پوشه کپی میشوند، در حقیقت مربوط به سرور CA خواهد بود.

۲) فایل هایی که در پوشه server قرار میگیرند،‌ در حقیقت فایل هایی هستند که مربوط به سرور کافکا میباشد.

۳) فایل هایی که در پوشه client قرار میگیرند مربوط به کلاینت کافکا است.

پس هرگونه کپی فایل بین این پوشه ها، میتواند در محیط های پروداکشن، در حقیقت کپی فایل بین سرور ها تعبیر شود.
در این آموزش هر سه محیط به در یک ماشین اند.

// TODO: move this section somewhere

# General Security recommendations

- Using full dist encryption or volume encryption is highly recommended for secure data store.
-
