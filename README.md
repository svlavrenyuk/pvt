# pvt
Tool intended to update plugin version in dependent applications.

pvt.sh - main script. No flags / special keys. It is interactive.

pvt_config.sh - configuration. Probably you will need to change file paths.

pvt_auto_test.sh - not actually a real tests. Some stuff is printed. If you know what should be printed and if there are no obvious errors - tests are passed.

pvt_test_with_mocked_git.sh - for manual testing. Function "git" is declared, which mocks all calls to git. Looks like currently it doesn't work correctly (because git diff-files and diff-index are not mocked properly).

Push functionality is not tested yet. 
But when it will be ready, it would be convenient to disable login/password verification on each push. 
Or ssh passphrase input, depending on wich connection type you are using - ssh or https.
I am using a solution described here http://git-scm.com/docs/git-credential-store.

Currently end-to-end was tested the case when new branch is created (and that is actually a new branch, not an attempt to create a new branch while branch with such name already exists).
If there are uncommitted/ustaged changes script will stash and then unstash them. Checkout to required branch and then checkout to initial branch is also done.   
Git push is disabled (commented). Search by "push" keyword and you will find it. 

TODO
- use so-called git plumbing commands
- verify if during execution there was git error and handle it
- improve / test case when updating existing branch and it need to be pulled and merged or rebased (maybe skip such app?). or if branch already exists but there is no corresponding remote branch.
- create push failover (e.g. due to network problem)
- add ability to modify affected applications during execution (e.g. for some app plugin is already updated)
- what if I want to update several plugins and push all that changes in one commit/branch? this feature is not implemented. is it required?
- for sure there are uncovered git cases, find and cover them