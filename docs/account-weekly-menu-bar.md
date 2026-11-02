---
summary: "Show both Claude and Codex accounts' weekly allowance in the menu bar."
read_when:
  - Configuring the custom account display
---

# Weekly allowance per account

In Settings > Menu Bar, enable **Weekly allowance per account**. Use the Icon & percent style and leave Merge icons off. Claude and Codex each show two labeled rows with the weekly percentage remaining. The existing account menus still open from their provider icons.

This display uses the same cached accounts as the menus. Rename Codex accounts in Settings > Codex to give them short labels. Claude uses the aliases from its configured account feed. Hide Personal Info substitutes the existing private account labels.

Rows omit the weekly window marker. Labels reserve at least three digits' width, and percentages align at the right edge in a column wide enough for 100%.

An unavailable account keeps its label and displays a dash. Claude feed failures and last-known measurements do not appear as current allowance. Updating either account redraws its provider's display. Session limits are not included.

The setting is off by default. It applies when the provider has exactly two accounts. Other providers and other account counts retain their saved layouts. Turn it off to restore each provider's saved layout.
