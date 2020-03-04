# 💅 Style Guide

This documentation, and contributions, should conform to the [Google developer documentation style guide](https://developers.google.com/style/), with the following added opinions for consistency and clarity. 

## Code blocks

**Always check your formatting are able to be run in a terminal**. 

Some command line tools are more particular about their formatting than others. Always opt on the side of 'this-works' over 'looks-pretty'.

The following convensions are followed by [the aforementioned style guide](https://developers.google.com/style/command-line-terminology); the descriptiveness below has been added for explicit clarity.

### Parameters, flags and arguments

Where there are multiple options for command inputs, opt for spaces over equal-signs. This allows the command to be more easily read by a human. 

```shell,exclude
# 👍 Recommended
gcloud sample command --parameter option

# not recommended
gcloud sample command --parameter=option
```

Some parameters must be passed literally with no spaces, so preserve those. Also wrap special characters that would otherwise interupt terminal execution in double-quote marks. 

```shell,exclude
# 👍 Recommended
gcloud sample command --parameter "option=values(csv)"

# will error
gcloud sample command --parameter option values(csv)
```

### Shell variables

When documenting replacement shell environment variables, use literal replacements where possible, opting for variable expansion when literal replacements will not produce the desired result. 

```shell,exclude
# 👍 Recommended
gcloud sample command option --name $NAME --parameter "option=${VALUES}"
```

### Long commands

In the event a command cannot fit on one line, opt to split lines on: 
 * position arguments, then
 * pairs of positional arguments

The ordering of positional arguments, if unimportant to the execution of the command, should be ordered in whatever logic pertains to the operation. 

Split lines should be noted with a trailing backslash, ensuring no whitespace follows. Indentation of extra lines should be two spaces. 


```shell,exclude
# 👍 Recommended
gcloud sample command ofincredible length \
  --parameter option \
  --yetanother option \
  --which-keeps-going "and-on"

# not recommended
gcloud sample command ofincredible length --parameter option --yetanother option --which-keeps-going "and-on"
```


### Automation

Code blocks that are intended to be run as part of a sequence as defined in `.util` should be prefaced with "shell". 

Code blocks that are **descriptive** only should be prefaced with "shell,exclude"

For examples of these, see the source code for this page (as it is difficult to show backticks in markdown without them being explicitly rendered).

