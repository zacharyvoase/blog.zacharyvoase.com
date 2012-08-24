---
created_at: 2012-05-21
kind: article
title: "Pinned Pull Requests"
---

I was taking a look at the [Crossroads I/O](http://www.crossroads.io/) project
today, and stumbled across this in the [FAQ](http://www.crossroads.io/faq):

> **Why do you not accept pull requests?**
>
> Pull requests can change while being reviewed. This makes it impossible to
> ensure that the code being merged is the same code that has been reviewed and
> discussed, which compromises integrity of the codebase.
>
> Pull requests are meant for delegation of work to sub-maintainers and require
> an established web of trust. We may consider moving to this model in future.
>
> The method for contributing that we are currently using is posting patches to
> the mailing list, as explained
> [here](http://www.crossroads.io/dev:start#toc3).

What this refers to is the fact that GitHub Pull Requests are dynamic; if you
nominate a branch for a pull request, and then push to that branch, the pull
request is updated with the new commits. I’m no gitmeister, but I’m aware that
git doesn’t merge histories, it merges trees (albeit with an awareness of
history). A branch, in git, is simply a pointer to a tree which is updated as
you make subsequent commits. Therefore, I figured, it should be possible to
create a pull request which references a *specific* commit and doesn’t change
with the branch.

And it is.

I create a branch with some commits and push it to GitHub:

![](1-branch-and-push.png)

I submit my pull request using the commit identifier instead of the branch
name. Helpfully, if you just enter the branch name into the input box, GitHub
will display the most recent commit identifier, which you can just
copy-and-paste into the box:

![](2-submit-pull-request.png)

I go back to my terminal and add some more commits to the branch:

![](3-add-second-commit.png)

Note that the pull request hasn’t changed. It was pinned to that commit, rather
than following the branch:

![](4-pull-request-does-not-change.png)

The only issue from GitHub’s end is that it still displays the message about
being able to add commits to the pull request (which I’m pretty sure I can’t).

I wonder if this will change the attitudes of the Crossroads I/O maintainers to
pull requests.
