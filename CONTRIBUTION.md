#Contributing to OpsManagerCLI

OpsManagerCLI is an open source project and we welcome all contributions! 

We use GitHub to manage reviews of pull requests.

## Making changes
- Fork the OpsManagerCLI repository. For developing new features and bug fixes, the `master` branch should be pulled and built upon.
- Create a topic branch where you want to base your work `git checkout -b fix/master/my_contribution master`.
- Make commits of logical units in the correct format.
- Do **not** make commits through the GitHub web interface due to issues with the automated CLA management.
- Check for uncecessary whitespace with `git diff --check` before committing.
- Ensure tests have been added for your changes.
- Use `git rebase` (not `git merge`) to sync your work with the latest version: `git fetch upstream` `git rebase upstream/master`.
- Run **all** the tests to assure nothing else was accidentally broken.
- Create a pull request and include the platform team `@compozed/platform` in the description.
- Ensure all pull request checks (such as continuous integration) are passing.
- [Sign our Contributing License Agreement] (https://compozed-cla.cfapps.io/agreements/compozed/ops_manager_cli "Compozed CLA") if this is your first contribution.


## Adding Features
- If you plan to do something more involved, first discuss your ideas using [Waffle](https://waffle.io/compozed/ops_manager_cli). This will avoid unnecessary work and will surely give you and us a good deal of inspiration.
