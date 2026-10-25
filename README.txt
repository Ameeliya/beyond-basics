BEYOND BASICS — UPDATED STATIC WEBSITE

CONTENTS
- index.html: the updated website, retaining the existing visual design and pages.
- assets/slides/: lightweight WebP renderings of the original slides for the in-page slide viewer.
- assets/*.pdf: lightweight PDF slide decks for opening in a new tab or downloading.

DEPLOY TO VERCEL THROUGH YOUR EXISTING GITHUB REPOSITORY
1. Download and extract beyond-basics-updated.zip.
2. Open the GitHub repository connected to your Vercel project.
3. Replace the existing index.html with this version.
4. Upload the entire assets folder, preserving its folder structure:
   assets/Titanic Reading Comprehension.pdf
   assets/Tenses and Reading Comprehension.pdf
   assets/Microsoft Google Applications and Digital Safety.pdf
   assets/slides/*.webp
5. Commit the changes to the same branch that Vercel deploys (usually main).
6. Wait for Vercel to finish the automatic deployment, then refresh the live site.

IMPORTANT
- Do not upload only index.html. The slide images and PDFs in assets/ are required.
- Keep the assets folder beside index.html at the repository root.
- The new content is loaded from the embedded defaults using a new browser storage key so old demo lessons do not override it.
- Learner progress and admin edits remain browser-local. This is still a static front-end prototype, not secure multi-user authentication or a shared database.
- The three PDFs in assets/ are optimised visual copies of the provided slide decks to keep the website lightweight; they preserve slide appearance rather than the original PDF's underlying editable text.
