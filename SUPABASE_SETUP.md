# Beyond Basics — Supabase setup

The website uses the Supabase project URL and **publishable** browser key configured in `index.html`. A publishable key is intended for browser use. Never put a Supabase service-role or secret key in the repository.

## 1. Apply the database setup

1. Open the Supabase project used by Beyond Basics.
2. Open **SQL Editor**.
3. Copy the entire contents of `supabase/setup.sql` into a new SQL query and run it.
4. The script creates or updates the learner progress table, private baseline-assessment results, chapter-question results, form submissions, row-level security policies, and supervisor-only reporting functions. It also aligns older `completed_lessons` columns to JSONB without deleting learner rows.

Run the full updated SQL after deploying these changes. The founder dashboard needs the new tables and RPC functions to display assessments, chapter answers, and form submissions.

## 2. Allow student sign-up

1. In Supabase, open **Authentication → Providers → Email** and make sure Email is enabled.
2. In **Authentication → URL Configuration**, set the Site URL to the deployed Beyond Basics website and add the production URL to allowed Redirect URLs.
3. Allow new user sign-ups. Email confirmation is recommended; learners should verify their email before signing in if confirmation is enabled.

## 3. Authorise the founder account

1. Create the founder account through the normal website sign-in page and verify it if required.
2. In Supabase Dashboard → **Authentication → Users**, copy that account's **User UID**.
3. Run the following SQL after replacing the placeholder with the founder's real UID:

   ```sql
   insert into public.admin_users (user_id)
   values ('PASTE-FOUNDER-USER-UUID-HERE')
   on conflict (user_id) do nothing;
   ```

Only add trusted supervisor accounts to `public.admin_users`. The founder reporting functions check this allowlist server-side; they do not trust a role chosen in the website.

## 4. How learner evaluations work

- The first time a student signs in, they must complete the **English** and **Digital skills** starting assessments before the learning library opens.
- Each assessment result and its question-by-question answers are saved to `public.learner_baseline_assessments`. Students can read or update only their own rows.
- When a learner checks a multiple-choice question in a lesson, the selected answer and correctness are saved to `public.learner_chapter_results`. Written responses are saved when the learner clicks **Save answer**.
- The founder dashboard includes learner progress, starting-assessment scores, chapter-by-chapter scores and responses, Get involved enquiries, and Student suggestions.
- The original Formspree endpoint remains active for email/form delivery. A private database copy is also stored so authorised founder accounts can view submissions in the dashboard. If the database copy fails, the website displays a warning even if Formspree has accepted the submission.

## 5. Privacy and access checks

- Learners can access only their own progress, baseline assessments, and chapter results through direct table access.
- Public visitors can submit a form but cannot read form submissions. Founder-only SQL functions provide access to the inbox and all-learner results.
- Keep founder access limited to trusted people. The dashboard displays learner emails and written responses, so share only what is necessary.
- Do not store service-role keys in browser code, and do not add supervisor access based on an email field or a user-controlled form.
- Before broad use with learners, review applicable school requirements, consent, retention, and deletion procedures.

## 6. Deploy and test

After merging the changes, wait for Vercel to finish deploying, then run the updated SQL in Supabase. Test with a separate learner account:

1. Sign in and complete both starting assessments. Confirm the learning library stays gated until both are submitted.
2. Sign out and sign in again. Confirm completed starting assessments remain completed and the learner can open lessons.
3. Answer a multiple-choice question and save a written response. Confirm the founder's **Chapter results** panel shows them.
4. Submit both the Get involved form and Student suggestions form. Confirm they still reach Formspree and appear in the corresponding founder panels.
5. Sign in as another learner and confirm that account cannot read the first learner's data or open the founder dashboard.

A Vercel deployment marked **Ready** does not by itself confirm that the database policies and forms are configured correctly.
