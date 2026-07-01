# Contributing to open_sinc

This document defines guidelines and conventions that are specific to the open_sinc RTL repository.

This project welcomes contributions and suggestions. Most contributions require you to
agree to a Contributor License Agreement (CLA) declaring that you have the right to,
and actually do, grant us the rights to use your contribution. For details, visit
https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need
to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the
instructions provided by the bot. You will only need to do this once across all repositories using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Guidelines for code contributions

* Changes must be made via pull request
* [Branch protection rules](GitHubRules.md) ensure pull requests are reviewed
  by project members
* [Maintainers](MAINTAINERS.md) are expected to enforce `CODEOWNERS` rights
  where necessary. Maintainers are also the sole owners of the repo's
  configuration.
* The branch protection rules include constraints to maintain a linear history
  and avoid merges in pull requests.
* Please maintain a clean commit history on the `main` branch.
  - Effort should be made to ensure Pull Requests are clean and pass required
    tests, to prevent a long series of subsequent Pull Requests with simple
    'fixup' patches.
  - By the same criteria, if a Pull Request has a number of 'fixup' patches, it
    must be Squash and Merged.
  - Whereas a Pull Request with logically separate, well defined commits, with
    articulate descriptions, can be merged without squashing.
* New code files must include the Apache license 2.0 header. Commit verification
  tools enforce this.
* With the exception of the Rust toolchain, all third-party code necessary for
  building release firmware binaries must be placed in the
  `caliptra-sw/third-party` directory
* Third party vendored repos included into Caliptra repos may not be ASL 2.0
  license. However, all vendored repos must be ASL 2.0 compliant and not
  introduce additional restrictions or encumbrances. Ask the TAC if in doubt.
* Fork the repos into your personal repo, and create pull requests from your
  personal repo. Do not pollute the main repo with your personal branches.

## Design discussion

* All design issues are discussed via GitHub issues.
* Please reference the issue in your commit where appropriate.
* Chat channels should be primarily used for short, tactical discussions
  (example, coordinate resolution of a merge conflict, coordinate update of
  settings, meeting coordinates)

## Git Conventions

### Commit conventions
Git documentation provides some guidance on preparing good quality commit messages here:<BR>
https://git-scm.com/docs/SubmittingPatches#describe-changes

Main points:
  - Imperative mood, present tense for subject line
  - Capitalized first-word of subject line
  - 50-character subject line
  - 72-character line breaks in the body
  - Tell "what" and "why"
    - e.g. "Fix bug in UVM testbench causing AXI transaction mismatch"
    - e.g. "Update FSM transitions based on XYZ to resolve missed error states"
  - NOTE: Prefixes are recommended for each commit in Git documentation. In oepn_sinc, the prefix is mandated for Pull Request titles, but not for individual commits within a feature branch due to the use of squash-and-merge strategy.

### Pull Request Conventions

open_sinc repository uses the squash strategy to merge changes from a Pull Request to the destination branch. This means that the title of the PR becomes the subject of the commit in the destination branch's history. To improve debug, triage, readability, and preparation of change-lists, it is imperative that these commit subject lines be concise, meaningful, and consistent. The following conventions are used:
  - Title of the Pull Request should match conventions for an individual commit subject line, as shown above (imperative mood, etc).
  - Title:
    - First word of Pull Request Title is in [BRACKETS] and tells which area the commit affects (e.g. RTL, RDL, DOC, VAL, ENV, etc).
    - Options for "area", in decreasing precedence (i.e., only one tag should be applied, matching the highest precedence tag from this list).
      - BUG FIX (An RTL fix that specifically resolves a bug in the source code)
      - RTL (i.e. for enhancements, features, refactoring)
      - RDL (illustrates that the commit may affect address map, might require RTL regeneration, etc)
      - VAL (The commit _only_ affects the test plan and bench design. This tag may be used for fixing bugs in test code, rather than the BUG FIX tag, because that tag is reserved for RTL bug fixes. If both RTL source code and testbenches are modified, the "RTL" area should be used)
      - UVM (A subset of VAL, but demonstrates that the commit only impacts UVM testbenches)
      - DOC (Only documentation files are affected, i.e. .md, .png, .jpg, .xlsx, .html)
      - ENV (compile.yml, *.vf file lists, any GH workflow file, tools/scripts/* changes, etc).
  - Title should be concise and capture highest-impact items. Pull Requests should ideally contain only the necessary changes for a single feature, fix, testcase, documentation area, or other area. However, RTL changes should always be accompanied by appropriate verification collateral and relevant documentation. In this case, the RTL change should be described in the Title, as this is the most meaningful change, while verification and documentation updates are implicit to the proposed changes. In some cases, multiple features may need to be compressed into a single Pull Request. In this circumstance, the title should capture the most impactful changes as concisely as possible as a comma-separated list.
  - Example Title:
    - `[RTL] Update sinc apply lint fixes, coverage updates`
  - Pull Request Description:
    - Include one bullet point for each item that is touched (i.e., 1 bullet for each bug fixed, 1 bullet for each feature addition, 1 bullet for each TB modification, 1 bullet for each documentation update, etc).
    - Include one line for each GitHub issue that is resolved by the PR. That line should follow the format:<BR>`Resolves #<issue number>`<BR>This format causes GitHub to automatically close the issue upon Pull Request merge.