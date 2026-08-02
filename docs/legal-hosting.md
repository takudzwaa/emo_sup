# Legal pages (Privacy Policy / Terms of Service)

Static pages live at `public/legal/privacy.html` and `public/legal/terms.html`,
served via Firebase Hosting (`firebase.json` → `hosting`). The in-app copies
(`lib/screens/legal_stub_screen.dart`) mirror the same content — keep both in
sync when you edit either.

## Before this can go live

1. Fill in every `[PLACEHOLDER]` in both `.html` files and in
   `legal_stub_screen.dart`: legal entity name, support email, jurisdiction,
   data-residency region, effective date.
2. Have the content reviewed by a lawyer for your launch jurisdiction — this
   draft is grounded in what the app actually does (see `docs/firestore_schema.md`,
   `functions/src/index.ts`), but it is not legal advice.
3. Deploy: `firebase use prod && firebase deploy --only hosting`.
   Resulting URLs: `https://emo-sup-prod.web.app/legal/privacy.html` and
   `.../legal/terms.html` (swap `prod` for `staging` on that project).
4. Enter the Privacy Policy URL in App Store Connect and Play Console, and the
   Terms URL wherever your store listing asks for it.
5. Update the hardcoded `https://emo-sup-prod.web.app/legal/...` reference in
   `legal_stub_screen.dart` if you end up hosting elsewhere (custom domain,
   different project).
