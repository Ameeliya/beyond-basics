# Beyond Basics — Supabase setup

The website code uses the Supabase project URL and **publishable** browser key configured in `index.html`. A publishable key is designed for public browser use; never put a Supabase service-role or secret key in this repository.

## 1. Create the progress table and security policies

1. Open the Supabase project whose URL is configured in `index.html`.
2. Open **SQL Editor**.
3. Open `supabase/setup.sql` from this repository, copy its contents into the SQL Editor, and run it.
4. Confirm that `public.learner_progress` exists and Row Level Security is enabled.

The policies restrict each signed-in student to the progress row whose `user_id` matches their own authenticated user ID.

## 2. Allow student sign-up

1. In Supabase, open **Authentication → Providers → Email** and make sure the Email provider is enabled.
2. In **Authentication → Settings / URL Configuration**, set the Site URL to the deployed Beyond Basics website.
3. Add the production website URL and any Vercel preview URLs you use to the allowed Redirect URLs.
4. Ensure the project allows new user sign-ups rather than invite-only registration. Keeping email confirmation enabled is recommended; new students should follow the verification email before signing in.

The website does not provide an admin/teacher role through a form or by trusting an email address.

## 3. Deploy and test

After merging the code changes, wait for Vercel to finish deploying. Test with a new student account:

- Create an account, verify the email if required, and sign in.
- Open a lesson and mark it complete.
- Confirm the dashboard updates and shows the saved progress.
- Sign out and sign in again, then confirm the completed lesson remains.
- Test with a second account and verify that it cannot read or change the first account's progress.
- Submit a Student Suggestions form and confirm it arrives in Formspree.
- Submit the existing general contact form and confirm it still works.

If progress does not sync, check the browser console and the Supabase table/policies. A Vercel deployment marked **Ready** does not prove that Supabase settings or form submissions are working.


## 4. Set up the private supervisor overview

The same sign-in page serves everyone. An account added to `public.admin_users` is routed to the supervisor overview after sign-in; other accounts go to their own student dashboard. The overview shows student email, account creation date, completed lessons, percentage of the current lesson library completed, and last progress activity.

1. Run the **entire updated** `supabase/setup.sql` in Supabase Dashboard → SQL Editor.
2. Create your account on the normal website sign-in page (choose **Create student account**) and verify the email if required.
3. In Supabase Dashboard → **Authentication → Users**, find your account and copy its **User UID**.
4. In Supabase SQL Editor, run this after replacing the placeholder with your User UID:

   ```sql
   insert into public.admin_users (user_id)
   values ('PASTE-YOUR-SUPABASE-USER-UUID-HERE')
   on conflict (user_id) do nothing;
   ```

5. Sign out and sign in again. Your account should open **Supervisor overview**; student accounts should open **My Dashboard**.
6. Test with a separate student account. It should not see the supervisor link, and the database function should deny that account access to the all-student overview.

Only add trusted supervisor accounts to `admin_users`. Do not assign supervisor access based on a form field or email typed into the website, and never expose a Supabase service-role/secret key in browser code. The overview includes learner email addresses, so keep it private and share only necessary summary figures with supervisors.
