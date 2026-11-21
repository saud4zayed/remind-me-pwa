# REMIND ME V0.3 — GitHub + Cloudflare

هذه النسخة معدّة لربط مستودع GitHub بتطبيق Cloudflare Worker الحالي `quiet-silence-73ff`، وليس لإنشاء تطبيق جديد.

إعدادات الربط في Workers & Pages > quiet-silence-73ff > Settings > Builds > Git repository > Connect:
- Root directory: `/`
- Production branch: `main`
- Build command: `npm install` (يمكن تركه فارغاً إذا سمحت الواجهة)
- Deploy command: `npx wrangler deploy`
- اسم Worker يجب أن يطابق الاسم في `wrangler.jsonc`.

هذه نسخة PWA ثابتة فقط، دون تنبيهات Web Push خلفية حقيقية أو D1 أو Cron، ولا تدعم اللسان العائم فوق شاشة iPhone الرئيسية. الحفظ محلي في المتصفح.

بعد إعداد الربط مرة واحدة، أي `push` إلى الفرع `main` يشغّل النشر تلقائياً.

لا تنشر أسرار دخول أو رموز API داخل المستودع.
