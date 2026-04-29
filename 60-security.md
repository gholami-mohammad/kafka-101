# امنیت در کافکا - Security

امنیت در کافکا در سه گروه بررسی می شود:

- [ رمزنگاری - Encryption](./61-security-encryption.md)
- [ احراز هویت - Authentication](./62-security-authentication.md)
- [تعیین سطح دسترسی به منابع - Authorization](./66-security-authorization.md)

**بسیار مهم:**
در تمام مراحلی که فایلی بین دو پوشه secrets و secrets-client جابجا میشود، در حقیقت میتواند این جابجایی بین ماشینی باشد که سرور در حال اجرا است و ماشینی که کلاینت در حال اجرا است. همچنین در برخی موارد جابجایی بین سرور CA و کلاینت یا سرور کافکا است. لطفا در زمان مطالعه به تفکیک این موارد دقت کنید.

در تمام طول این آموزش، فایل ها روی یک ماشین اجرا شده اند که هم نقش CA هم نقش سرور کافکا و هم کلاینت کافکا را دارا است.

// TODO: move this section somewhere

# General Security recommendations

- Using full dist encryption or volume encryption is highly recommended for secure data store.
-
